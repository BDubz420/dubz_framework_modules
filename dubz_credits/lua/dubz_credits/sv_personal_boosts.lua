DubzCredits = DubzCredits or {}
DubzCredits.PersonalBoosts = DubzCredits.PersonalBoosts or {}

util.AddNetworkString("DubzCredits_PersonalBoosts")

local DATA_FILE = "dubz_credits/personal_boosts.json"
file.CreateDir("dubz_credits")

local function Now()
    return os.time()
end

function DubzCredits:SyncPersonalBoosts(ply)
    if not IsValid(ply) then return end

    local sid = ply:SteamID64()
    local data = self.PersonalBoosts[sid] or {}

    net.Start("DubzCredits_PersonalBoosts")
        net.WriteTable(data)
    net.Send(ply)
end

-------------------------------------------------
-- LOAD / SAVE
-------------------------------------------------
function DubzCredits:LoadPersonalBoosts()
    if file.Exists(DATA_FILE, "DATA") then
        local t = util.JSONToTable(file.Read(DATA_FILE, "DATA") or "")
        if istable(t) then
            self.PersonalBoosts = t
        end
    end
end

function DubzCredits:SavePersonalBoosts()
    file.Write(DATA_FILE, util.TableToJSON(self.PersonalBoosts, true))
end

-------------------------------------------------
-- GET BOOST
-------------------------------------------------
function DubzCredits:GetPersonalBoost(ply, id)
    if not IsValid(ply) then return nil end

    local sid = ply:SteamID64()
    local data = self.PersonalBoosts[sid]
    if not data then return nil end

    local boost = data[id]
    if not boost then return nil end

    if not boost.expires or boost.expires <= Now() then
        data[id] = nil
        self:SavePersonalBoosts()
        return nil
    end

    return boost
end

-------------------------------------------------
-- APPLY BOOST
-------------------------------------------------
function DubzCredits:ApplyPersonalBoost(ply, id, cfg)
    if not IsValid(ply) then return end

    local sid = ply:SteamID64()
    self.PersonalBoosts[sid] = self.PersonalBoosts[sid] or {}
    self.PersonalBoosts[sid][id] = self.PersonalBoosts[sid][id] or {}

    table.insert(self.PersonalBoosts[sid][id], {
        expires = os.time() + (cfg.duration or 0),
        amount = cfg.amount
    })

    self:SavePersonalBoosts()

    -- 🔥 sync immediately
    self:SyncPersonalBoosts(ply)
end

function DubzCredits:GetPersonalBoostAmount(ply, id)
    if not IsValid(ply) then return 0 end

    local sid = ply:SteamID64()
    local data = self.PersonalBoosts[sid]
    if not data or not data[id] then return 0 end

    local now = os.time()
    local total = 0
    local changed = false

    for i = #data[id], 1, -1 do
        local boost = data[id][i]

        if not boost.expires or boost.expires <= now then
            table.remove(data[id], i)
            changed = true
        else
            total = total + (boost.amount or 0)
        end
    end

    if changed then
        self:SavePersonalBoosts()
    end

    return total
end

-- Total extra prop limit from every active personal boost (any boost in Config.PersonalBoosts that has an amount)
function DubzCredits:GetPersonalPropBonus(ply)
    local total = 0

    for id, def in pairs(self.Config.PersonalBoosts or {}) do
        if def.amount and def.enabled ~= false then total = total + self:GetPersonalBoostAmount(ply, id) end
    end

    return total
end

-------------------------------------------------
-- INIT
-------------------------------------------------
hook.Add("Initialize", "DubzCredits_LoadPersonalBoosts", function()
    DubzCredits:LoadPersonalBoosts()
end)

hook.Add("PlayerInitialSpawn", "DubzCredits_SyncPersonalBoosts", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            DubzCredits:SyncPersonalBoosts(ply)
        end
    end)
end)

