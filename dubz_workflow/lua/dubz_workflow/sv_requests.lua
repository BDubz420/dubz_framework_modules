local Sync = DubzWorkflow.Sync
local Staff = DubzWorkflow.Staff
local Store = DubzWorkflow.Store
local SMALL_BITS = 8
local JSON_BITS = 8 * 12288
local REQUEST_COOLDOWN = 1
local ACTION_COOLDOWN = 0.3

local function allowed(ply)
    if not DubzWorkflow.Enabled() then
        Sync.Result(ply, false, DubzWorkflow.Phrase("ErrorDisabled"))
        return false
    end

    if not Staff.IsStaff(ply) then
        Sync.Result(ply, false, DubzWorkflow.Phrase("ErrorAccess"))
        return false
    end

    return true
end

local function finish(ply, ok, message, task, added, removed)
    Sync.Result(ply, ok, message)

    if not ok or not task then return end

    if removed then Sync.Remove(task.id) else Sync.Task(task) end

    if #(added or {}) > 0 then DubzWorkflow.Notify.Assigned(task, added) end
end

DFW.Net.Receive("wf_request", function(_, ply)
    if not allowed(ply) then return end

    Sync.Subscribe(ply)
    Sync.State(ply)
end, {maxBits = SMALL_BITS, cooldown = REQUEST_COOLDOWN})

DFW.Net.Receive("wf_close", function(_, ply)
    Sync.Unsubscribe(ply)
end, {maxBits = SMALL_BITS})

DFW.Net.Receive("wf_save", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and allowed(ply)) then return end

    finish(ply, DubzWorkflow.Tasks.Save(ply, request))
end, {maxBits = JSON_BITS, cooldown = ACTION_COOLDOWN})

DFW.Net.Receive("wf_action", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and isstring(request.action) and allowed(ply)) then return end

    finish(ply, DubzWorkflow.Tasks.Act(ply, request))
end, {maxBits = JSON_BITS, cooldown = ACTION_COOLDOWN})

DFW.Net.Receive("wf_presence", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and allowed(ply)) then return end

    local wasWorking = Staff.Working(ply)

    Staff.SetWorking(ply, request.working == true)
    Sync.Team()

    if request.working == true and not wasWorking then DubzWorkflow.Notify.Unseen(ply, "NoticeMissed") end
end, {maxBits = JSON_BITS, cooldown = REQUEST_COOLDOWN})
