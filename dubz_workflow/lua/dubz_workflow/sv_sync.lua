DubzWorkflow.Sync = DubzWorkflow.Sync or {}

local Sync = DubzWorkflow.Sync
local Store = DubzWorkflow.Store
local Staff = DubzWorkflow.Staff
local config = DubzWorkflow.Config

local subscribers = {}

local function send(name, data, target)
    DFW.Net.Start(name)

    local ok, reason = DFW.Net.WriteJSON(data)

    if not ok then
        DubzWorkflow.Report("could not send " .. name .. ": " .. tostring(reason))
        return false
    end

    net.Send(target)

    return true
end

Sync.Send = send

local function liveSubscribers()
    local list = {}

    for ply in pairs(subscribers) do
        if IsValid(ply) and Staff.IsStaff(ply) then list[#list + 1] = ply else subscribers[ply] = nil end
    end

    return list
end

function Sync.Me(ply)
    return {s = ply:SteamID64(), manager = Staff.IsManager(ply), working = Staff.Working(ply)}
end

function Sync.State(ply)
    send("wf_state", {
        tasks = Store.All(),
        me = Sync.Me(ply),
        team = Staff.Online(),
        settings = {
            priorities = DubzWorkflow.List("priorities"),
            serverTime = config.ShowServerTime and os.time() or nil
        }
    }, ply)
end

function Sync.Subscribe(ply)
    subscribers[ply] = true
end

function Sync.Unsubscribe(ply)
    subscribers[ply] = nil
end

function Sync.Task(task)
    local targets = liveSubscribers()

    if #targets > 0 then send("wf_task", task, targets) end
end

function Sync.Remove(id)
    local targets = liveSubscribers()

    if #targets > 0 then send("wf_remove", {id = id}, targets) end
end

function Sync.Team()
    local targets = liveSubscribers()

    if #targets > 0 then send("wf_presence", {team = Staff.Online()}, targets) end
end

function Sync.Result(ply, ok, message, extra)
    local payload = extra or {}

    payload.ok = ok
    payload.message = message

    send("wf_result", payload, ply)
end

function Sync.Notice(ply, kind, text, count)
    send("wf_notice", {kind = kind, text = text, count = count}, ply)
end

function Sync.Open(ply)
    send("wf_open", {}, ply)
end

hook.Add("PlayerDisconnected", "DubzWorkflow_Subscribers", function(ply)
    subscribers[ply] = nil
    timer.Simple(0, Sync.Team)
end)
