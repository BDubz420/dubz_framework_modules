local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local Adapter = DubzDarkRP.Adapter
local SYNC_DELAY = 2

local function capture()
    if not Adapter.Ready() then return end

    for _, kind in ipairs(Kinds.Order) do Kinds.Engine(kind).Capture() end
end

local function applyPayload(payload)
    if not (istable(payload) and isstring(payload.id) and istable(payload.data) and Kinds.Meta[payload.kind or ""]) then return end

    capture()

    local kind = payload.kind
    local engine = Kinds.Engine(kind)
    local ok, data = Fields.Normalize(payload.data, kind)

    if not ok then return end

    local outOfOrder = kind == "jobs" and isnumber(payload.index) and payload.index > engine.Count() + 1

    if outOfOrder and not engine.Get(payload.id) then
        DubzDarkRP.Report("job '" .. payload.id .. "' arrived out of order and was skipped")
        return
    end

    engine.Apply(payload.id, data, payload.index)

    if payload.disabled then engine.Disable(payload.id) end

    hook.Run("DubzDarkRPChanged", kind, payload.id, "sync")
end

hook.Add("postLoadCustomDarkRPItems", "DubzDarkRP_Capture", capture)
hook.Add("DarkRPFinishedLoading", "DubzDarkRP_Capture", capture)

hook.Add("InitPostEntity", "DubzDarkRP_Sync", function()
    capture()

    timer.Simple(SYNC_DELAY, function()
        DFW.Net.Start("drp_sync")
        net.SendToServer()
    end)
end)

DFW.Net.Receive("drp_sync", function()
    local payload = DFW.Net.ReadJSON()

    if not (payload and istable(payload.items)) then return end

    for _, item in ipairs(payload.items) do applyPayload(item) end
end)

DFW.Net.Receive("drp_job", function()
    applyPayload(DFW.Net.ReadJSON())
end)

DFW.Net.Receive("drp_result", function()
    local payload = DFW.Net.ReadJSON()

    if payload and payload.message then DFW.UI.Notify(payload.message, payload.ok and "success" or "danger") end

    if payload then hook.Run("DubzDarkRPResult", payload.ok == true, payload.message) end
end)

DFW.Net.Receive("drp_open", function()
    local payload = DFW.Net.ReadJSON()

    DubzDarkRP.OpenBoard(payload and payload.kind or "jobs")
end)
