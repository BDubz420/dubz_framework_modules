DubzCredits = DubzCredits or {}
DubzCredits.Boosts = DubzCredits.Boosts or { active = {} }
DubzCredits.BoostHistory = DubzCredits.BoostHistory or {}
DubzCredits.WeeklyItems = DubzCredits.WeeklyItems or {}
DubzCredits.DailyDeal = DubzCredits.DailyDeal or nil

util.AddNetworkString("DubzCredits_BoostSync")
util.AddNetworkString("DubzCredits_SyncShop")

local DATA_DIR = "dubz_credits"
local BOOST_FILE = DATA_DIR .. "/boosts.json"
local HISTORY_FILE = DATA_DIR .. "/boost_history.json"

file.CreateDir(DATA_DIR)

local function Now()
    return os.time()
end

-------------------------------------------------
-- LOAD / SAVE
-------------------------------------------------
function DubzCredits:LoadBoosts()
    if file.Exists(BOOST_FILE, "DATA") then
        local t = util.JSONToTable(file.Read(BOOST_FILE, "DATA") or "")
        if istable(t) and istable(t.active) then
            self.Boosts = t
        end
    end

    if file.Exists(HISTORY_FILE, "DATA") then
        local h = util.JSONToTable(file.Read(HISTORY_FILE, "DATA") or "")
        if istable(h) then
            self.BoostHistory = h
        end
    end
end

function DubzCredits:SaveBoosts()
    file.Write(BOOST_FILE, util.TableToJSON(self.Boosts, true))
    file.Write(HISTORY_FILE, util.TableToJSON(self.BoostHistory, true))
end

-------------------------------------------------
-- WEEKLY ITEMS
-------------------------------------------------

local function PickWeeklyItems()
    local all = DubzCredits.Config.Items
    local keys = {}

    for id, def in pairs(all) do
        if def.enabled ~= false then table.insert(keys, id) end
    end

    table.Shuffle(keys)

    DubzCredits.WeeklyItems = {}

    for i = 1, math.min(5, #keys) do
        table.insert(DubzCredits.WeeklyItems, keys[i])
    end

    DubzCredits.DailyDeal = #DubzCredits.WeeklyItems > 0 and DubzCredits.WeeklyItems[math.random(#DubzCredits.WeeklyItems)] or ""

    DubzCredits.NextRefresh = os.time() + (60 * 60 * 24 * 7)

    print("[DubzCredits] Weekly shop refreshed.")
end

hook.Add("Initialize", "DubzCredits_InitShop", function()
    PickWeeklyItems()
end)

function DubzCredits:SyncShop(ply)
    net.Start("DubzCredits_SyncShop")
        net.WriteTable(self.WeeklyItems or {})
        net.WriteString(self.DailyDeal or "")
        net.WriteUInt(self.NextRefresh or 0, 32)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "DubzCredits_SendShop", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            DubzCredits:SyncShop(ply)
        end
    end)
end)

timer.Create("DubzCredits_WeeklyRefresh", 60 * 60 * 24 * 7, 0, function()
    PickWeeklyItems()

    for _, ply in ipairs(player.GetAll()) do
        DubzCredits:SyncShop(ply)
    end
end)
-------------------------------------------------
-- STACKING RULES
-------------------------------------------------
function DubzCredits:GetActiveBoostsByCategory(category)
    self:CleanupExpiredBoosts() -- 🔥 CRITICAL

    local count = 0
    local now = os.time()

    for id, info in pairs(self.Boosts.active or {}) do
        local def = self.Config.Boosts[id] or self.Config.Events[id]
        if def and def.category == category and info.expires > now then
            count = count + 1
        end
    end

    return count
end

-------------------------------------------------
-- BOOST STATE
-------------------------------------------------
function DubzCredits:IsBoostActive(id)
    local b = self.Boosts.active[id]
    if not b then return false end

    if b.expires <= Now() then
        self.Boosts.active[id] = nil
        self:SaveBoosts()
        return false
    end

    return true
end

-------------------------------------------------
-- ACTIVATE BOOST
-------------------------------------------------
function DubzCredits:ActivateBoost(id, ply)
    local def = self.Config.Boosts[id] or self.Config.Events[id]
    if not def then return false, "Invalid boost." end

    local catCfg = self.Config.BoostCategories[def.category]
    if catCfg and catCfg.maxActive then
        if self:GetActiveBoostsByCategory(def.category) >= catCfg.maxActive then
            return false, "A boost of this type is already active."
        end
    end

    self.Boosts.active[id] = {
        expires = Now() + (def.duration or 0),
        by = IsValid(ply) and ply:SteamID64() or "SERVER"
    }

    table.insert(self.BoostHistory, {
        id = id,
        name = def.name,
        category = def.category,
        scope = def.scope,
        by = IsValid(ply) and ply:SteamID64() or "SERVER",
        started = Now(),
        duration = def.duration
    })

    self:SaveBoosts()
    self:LogInfo(
        "BOOST STARTED: " .. id ..
        " by " .. (IsValid(ply) and ply:SteamID64() or "SERVER")
    )

    -- 🔔 Immediately sync boosts to all players
    for _, p in ipairs(player.GetAll()) do
        self:SyncBoosts(p)
    end
    return true
end

-------------------------------------------------
-- MULTIPLIER (USED BY GAMEPLAY)
-------------------------------------------------
function DubzCredits:GetMultiplier(category, ply)
    if not DubzCredits.Enabled() then return 1 end
    local mult = 1
    local now = Now()

    for id, info in pairs(self.Boosts.active) do
        local def = self.Config.Boosts[id] or self.Config.Events[id]
        if not def then continue end
        if def.category ~= category then continue end
        if info.expires <= now then continue end

        if def.scope == "job" then
            if not IsValid(ply) or not table.HasValue(def.jobs or {}, ply:Team()) then
                continue
            end
        end

        mult = mult * (def.multiplier or 1)
    end

    return mult
end

-------------------------------------------------
-- CLIENT SYNC
-------------------------------------------------
function DubzCredits:SyncBoosts(ply)
    if not IsValid(ply) then return end

    self:CleanupExpiredBoosts() -- 🔥 IMPORTANT

    local now = os.time()
    local data = {}

    for id, info in pairs(self.Boosts.active or {}) do
        if info.expires > now then
            data[id] = {
                remaining = math.max(info.expires - os.time(), 0)
            }
        end
    end

    net.Start("DubzCredits_BoostSync")
        net.WriteTable(data)
    net.Send(ply)
end


-------------------------------------------------
-- CLEAN UP BOOSTS
-------------------------------------------------

function DubzCredits:CleanupExpiredBoosts()
    local now = os.time()
    local changed = false

    for id, info in pairs(self.Boosts.active or {}) do
        if not info.expires or info.expires <= now then
            self.Boosts.active[id] = nil
            changed = true
        end
    end

    if changed then
        self:SaveBoosts()
    end
end

-------------------------------------------------
-- INIT + PERIODIC SYNC
-------------------------------------------------
hook.Add("Initialize", "DubzCredits_LoadBoosts", function()
    DubzCredits:LoadBoosts()
end)

timer.Create("DubzCredits_BoostSyncTimer", 10, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        DubzCredits:SyncBoosts(ply)
    end
end)
