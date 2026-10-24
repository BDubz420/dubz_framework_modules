local config = DubzF4.Config
local state = DubzF4.State
local TAKEOVER_DELAY = 3
local REFRESH_DELAY = 0.25
local REFRESH_TIMER = "DubzF4_Refresh"

function DubzF4.Close()
    state.LastToggle = SysTime()

    if IsValid(state.Frame) then state.Frame:Close() end
end

function DubzF4.Toggle()
    if not DubzF4.Enabled() then return end
    if SysTime() - state.LastToggle < config.ToggleDebounce then return end

    state.LastToggle = SysTime()

    if IsValid(state.Frame) then state.Frame:Close() else DubzF4.Open() end
end

local function takeOver()
    if not DubzF4.Adapter.TakeOver(DubzF4.Toggle, DubzF4.Close) then
        DubzF4.Report("DarkRP was not found, so its F4 menu was not replaced.")
    end
end

local function scheduleRefresh()
    if IsValid(state.Frame) then timer.Create(REFRESH_TIMER, REFRESH_DELAY, 1, DubzF4.Refresh) end
end

concommand.Add("dubz_f4", DubzF4.Toggle)

hook.Add("PlayerButtonDown", "DubzF4_Key", function(_, button)
    if button == KEY_F4 and IsFirstTimePredicted() then DubzF4.Toggle() end
end)

hook.Add("InitPostEntity", "DubzF4_TakeOver", function()
    takeOver()
    timer.Simple(TAKEOVER_DELAY, takeOver)
end)

hook.Add("DarkRPFinishedLoading", "DubzF4_TakeOver", takeOver)
hook.Add("DubzDarkRPChanged", "DubzF4_Live", scheduleRefresh)
hook.Add("DFW_CollectionChanged", "DubzF4_Live", function(moduleId)
    if moduleId == "f4" then scheduleRefresh() end
end)
hook.Add("DFW_ConfigChanged", "DubzF4_Live", function(moduleId)
    if moduleId == "f4" then scheduleRefresh() end
end)

if DarkRP then DubzF4.Adapter.TakeOver(DubzF4.Toggle, DubzF4.Close) end
