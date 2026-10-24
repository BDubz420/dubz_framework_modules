DubzCredits.Data = DubzCredits.Data or {}

util.AddNetworkString("DubzCredits_Sync")

function DubzCredits:GetBalance(ply)
    return self.Data[ply:SteamID64()] or 0
end

function DubzCredits:SetBalance(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    self.Data[ply:SteamID64()] = amount
    self.Storage:Save(ply:SteamID64(), amount)
    self:SyncToClient(ply)
end

function DubzCredits:Add(ply, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    if not IsValid(ply) then return end

    local steamid64 = ply:SteamID64()
    local before = self:GetBalance(ply)
    local after = before + amount

    self:SetBalance(ply, after)

    -- Player feedback
    if self.Notify then
        self:Notify(ply, "+" .. amount .. " credits", 0)
    end

    -- Server log
    if self.Log then
        self:LogInfo("ADD " .. steamid64 .. " +" .. amount .. " (now " .. after .. ")")
    end
end

function DubzCredits:Take(ply, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    if not IsValid(ply) then return false end

    local steamid64 = ply:SteamID64()
    local current = self:GetBalance(ply)

    if current < amount then
        -- Important: log failed attempts
        if self.Log then
            self:LogWarn("FAILED TAKE " .. steamid64 .. " -" .. amount .. " (balance " .. current .. ")")
        end
        return false
    end

    local after = current - amount
    self:SetBalance(ply, after)

    -- Player feedback
    if self.Notify then
        self:Notify(ply, "-" .. amount .. " credits", 0)
    end

    -- Server log
    if self.Log then
        self:LogInfo("TAKE " .. steamid64 .. " -" .. amount .. " (now " .. after .. ")")
    end

    return true
end

function DubzCredits:GetPropBonus(steamid64)
    return tonumber(file.Read("dubz_credits/props_" .. steamid64 .. ".txt", "DATA")) or 0
end

function DubzCredits:SetPropBonus(steamid64, amount)
    file.Write("dubz_credits/props_" .. steamid64 .. ".txt", tostring(amount))
end

function DubzCredits:SyncToClient(ply)
    net.Start("DubzCredits_Sync")
        net.WriteInt(self:GetBalance(ply), 32)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "DubzCredits_Load", function(ply)
    local steamid64 = ply:SteamID64()
    DubzCredits.Data[steamid64] = tonumber(DubzCredits.Storage:Load(steamid64)) or 0

    timer.Simple(1, function()
        if IsValid(ply) then
            DubzCredits:SyncToClient(ply)
            if DubzCredits.SyncBoosts then
                DubzCredits:SyncBoosts(ply)
            end
        end
    end)
end)

hook.Add("PlayerCheckLimit", "DubzCredits_PropLimitOverride", function(ply, type)
    if type ~= "props" then return end

    local base = GetConVar("sbox_maxprops"):GetInt()

    local bonus = 0
    bonus = bonus + DubzCredits:GetPersonalPropBonus(ply)

    local max = base + bonus

    if ply:GetCount("props") >= max then
        return false
    end

    return true
end)

-- Prometheus / external grant
function DubzCredits:GrantFromStore(steamid, amount)
    steamid = tostring(steamid or "")
    amount = math.floor(tonumber(amount) or 0)
    if steamid == "" or amount <= 0 then return end

    -- Normalize SteamID → SteamID64
    local steamid64 = steamid

    if string.StartWith(steamid, "STEAM_") then
        steamid64 = util.SteamIDTo64(steamid)
    end

    if not steamid64 or steamid64 == "0" then return end

    -- Check if player is online
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamid64 then
            -- ONLINE GRANT (live update)
            self.Data[steamid64] = (self.Data[steamid64] or 0) + amount
            self.Storage:Save(steamid64, self.Data[steamid64])
            self:SyncToClient(ply)

            if self.Notify then
                self:Notify(ply, "+" .. amount .. " credits", 0)
            end

            if self.Log then
                self:LogInfo("STORE ADD (ONLINE) " .. steamid64 .. " +" .. amount)
            end

            return
        end
    end

    -- OFFLINE GRANT (storage only)
    local cur = tonumber(self.Storage:Load(steamid64)) or 0
    self.Storage:Save(steamid64, cur + amount)

    if self.Log then
        self:LogInfo("STORE ADD (OFFLINE) " .. steamid64 .. " +" .. amount)
    end
end

-- ===============================
-- DAILY CREDITS SYSTEM
-- ===============================

local DAILY_FOLDER = "dubz_credits/daily/"

if not file.Exists("dubz_credits", "DATA") then
    file.CreateDir("dubz_credits")
end

if not file.Exists("dubz_credits/daily", "DATA") then
    file.CreateDir("dubz_credits/daily")
end

local function GetDailyPath(ply)
    return DAILY_FOLDER .. ply:SteamID64() .. ".txt"
end

local function LoadDaily(ply)
    local path = GetDailyPath(ply)

    if not file.Exists(path, "DATA") then
        return {}
    end

    return util.JSONToTable(file.Read(path, "DATA") or "") or {}
end

local function SaveDaily(ply, data)
    file.Write(GetDailyPath(ply), util.TableToJSON(data, true))
end

local function GiveDailyReward(ply)
    if not IsValid(ply) or not DubzCredits.Enabled() then return end

    local data = LoadDaily(ply)
    local last = data.lastClaim or 0

    local now = os.time()
    local cooldown = 86400 -- 24h

    if (now - last) < cooldown then return end

    -- Config
    local cfg = DubzCredits.Config.Daily.daily_credits
    local min = cfg.mincredits or 1
    local max = cfg.maxcredits or 5

    local amount = math.random(min, max)

    -- VIP multiplier
    if DubzCredits.IsVIP(ply) then
        local mult = cfg.vipmultiplier or 1
        amount = math.floor(amount * mult)
    end

    DubzCredits:Add(ply, amount)

    data.lastClaim = now
    SaveDaily(ply, data)

    local isVIP = DubzCredits.IsVIP(ply)

    if isVIP then
        DubzCredits:Notify(ply, "VIP Daily reward: +" .. amount .. " credits!", 0)
    else
        DubzCredits:Notify(ply, "Daily reward: +" .. amount .. " credits!", 0)
    end
end

-- VIP = the player's user group is in the VIP Ranks table (temporary ranks from dubz_temp_ranks count, since they
-- really change the group)
function DubzCredits.IsVIP(ply)
    local ranks = DubzCredits.Config.Daily.daily_credits.vip_ranks or {}
    local group = string.lower(ply:GetUserGroup() or "")

    for _, rank in ipairs(ranks) do
        if string.lower(rank) == group then return true end
    end

    return false
end

hook.Add("PlayerInitialSpawn", "DubzCredits_DailyReward", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) then
            GiveDailyReward(ply)
        end
    end)
end)