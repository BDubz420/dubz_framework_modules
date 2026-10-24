DubzWorkflow.State = DubzWorkflow.State or {Tasks = {}, Me = {}, Team = {}, Settings = {}, Loaded = false}
DubzWorkflow.Client = DubzWorkflow.Client or {}

local State = DubzWorkflow.State
local Client = DubzWorkflow.Client

local function send(name, data)
    DFW.Net.Start(name)

    if data then DFW.Net.WriteJSON(data) end

    net.SendToServer()
end

function Client.Find(id)
    for _, task in ipairs(State.Tasks) do
        if task.id == id then return task end
    end
end

function Client.Request() send("wf_request") end
function Client.Close() send("wf_close") end
function Client.Save(data) send("wf_save", data) end
function Client.Act(id, action, extra)
    local request = extra or {}

    request.id = id
    request.action = action
    send("wf_action", request)
end
function Client.Presence(working) send("wf_presence", {working = working}) end

DFW.Net.Receive("wf_state", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    State.Tasks = payload.tasks or {}
    State.Me = payload.me or {}
    State.Team = payload.team or {}
    State.Settings = payload.settings or {}
    State.Settings.receivedAt = CurTime()
    State.Loaded = true
    hook.Run("DubzWorkflowState")
end)

DFW.Net.Receive("wf_task", function()
    local payload = DFW.Net.ReadJSON()

    if not (istable(payload) and isstring(payload.id)) then return end

    local existing = Client.Find(payload.id)

    if existing then
        table.Empty(existing)
        table.Merge(existing, payload)
    else
        State.Tasks[#State.Tasks + 1] = payload
    end

    hook.Run("DubzWorkflowState")
end)

DFW.Net.Receive("wf_remove", function()
    local payload = DFW.Net.ReadJSON()

    if not (istable(payload) and isstring(payload.id)) then return end

    for index, task in ipairs(State.Tasks) do
        if task.id == payload.id then
            table.remove(State.Tasks, index)
            break
        end
    end

    hook.Run("DubzWorkflowState")
    hook.Run("DubzWorkflowRemoved", payload.id)
end)

DFW.Net.Receive("wf_presence", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    State.Team = payload.team or {}

    for _, member in ipairs(State.Team) do
        if member.s == State.Me.s then State.Me.working = member.working end
    end

    hook.Run("DubzWorkflowTeam")
end)

DFW.Net.Receive("wf_result", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    if payload.message then DFW.UI.Notify(payload.message, payload.ok and "success" or "danger") end

    hook.Run("DubzWorkflowResult", payload.ok == true, payload.message)
end)

DFW.Net.Receive("wf_notice", function()
    local payload = DFW.Net.ReadJSON()

    if istable(payload) then hook.Run("DubzWorkflowNotice", payload) end
end)

DFW.Net.Receive("wf_open", function() DubzWorkflow.Open() end)
