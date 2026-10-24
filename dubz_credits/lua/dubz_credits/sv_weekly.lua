DubzCredits = DubzCredits or {}
DubzCredits.WeeklyItems = DubzCredits.WeeklyItems or {}

local FILE_PATH = "dubz_credits/weekly_refresh_timer/time_remaining.txt"

file.CreateDir("dubz_credits")
file.CreateDir("dubz_credits/weekly_refresh_timer")

util.AddNetworkString("DubzCredits_SyncWeekly")

-------------------------------------------------
-- FILE IO
-------------------------------------------------
function DubzCredits:WriteWeeklyTime(time)
    file.Write(FILE_PATH, tostring(time))
end

function DubzCredits:ReadWeeklyTime()
    if file.Exists(FILE_PATH, "DATA") then
        return tonumber(file.Read(FILE_PATH, "DATA")) or 0
    end
    return 0
end

-------------------------------------------------
-- WEEKLY GENERATION
-------------------------------------------------
function DubzCredits:GenerateWeeklyShop()
    local pool = {}

    for id, def in pairs(self.Config.Items or {}) do
        if def.enabled ~= false then table.insert(pool, id) end
    end

    table.Shuffle(pool)

    self.WeeklyItems = {}

    for i = 1, math.min(5, #pool) do
        table.insert(self.WeeklyItems, pool[i])
    end

    self.NextRefresh = os.time() + (7 * 24 * 60 * 60)

    self:WriteWeeklyTime(self.NextRefresh)

    self:SyncWeeklyShop()
end

-------------------------------------------------
-- INIT
-------------------------------------------------
function DubzCredits:InitWeeklyTimer()
    local saved = self:ReadWeeklyTime()

    if saved <= os.time() then
        self:GenerateWeeklyShop()
    else
        self.NextRefresh = saved
    end
end

hook.Add("Initialize", "DubzCredits_InitWeekly", function()
    DubzCredits:InitWeeklyTimer()
end)

-------------------------------------------------
-- AUTO REFRESH CHECK
-------------------------------------------------
timer.Create("DubzCredits_WeeklyCheck", 60, 0, function()
    if not DubzCredits.NextRefresh then return end

    if os.time() >= DubzCredits.NextRefresh then
        DubzCredits:GenerateWeeklyShop()
    end
end)

-------------------------------------------------
-- NETWORKING
-------------------------------------------------
function DubzCredits:SyncWeeklyShop(ply)
    net.Start("DubzCredits_SyncWeekly")
        net.WriteTable(self.WeeklyItems or {})
        net.WriteUInt(self.NextRefresh or 0, 32)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

hook.Add("PlayerInitialSpawn", "DubzCredits_SendWeekly", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            DubzCredits:SyncWeeklyShop(ply)
        end
    end)
end)