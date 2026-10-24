local Logic = DubzWorkflow.Logic
local Sync = DubzWorkflow.Sync
local Staff = DubzWorkflow.Staff
local config = DubzWorkflow.Config
local SMALL_BITS = 8
local JSON_BITS = 8 * 1024
local REQUEST_COOLDOWN = 1
local ACTION_COOLDOWN = 0.3
local LINK_TYPE = "drp.jobs"

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function allowed(ply)
    if DubzWorkflow.Enabled() and Staff.IsStaff(ply) then return true end

    Sync.Result(ply, false, phrase(DubzWorkflow.Enabled() and "ErrorAccess" or "ErrorDisabled"))

    return false
end

local function starterInstructions(job)
    local lines = {"# Goal", phrase("JobTaskGoal", {name = job.name}), "# Steps"}

    for index, step in ipairs(config.JobTaskSteps) do lines[#lines + 1] = index .. ". " .. step end

    return table.concat(lines, "\n")
end

local function createTask(ply, job)
    local ok, message, task = DubzWorkflow.Tasks.Save(ply, {
        title = phrase("JobTaskTitle", {name = job.name}),
        summary = phrase("JobTaskSummary", {name = job.name}),
        priority = config.DefaultPriority,
        instructions = starterInstructions(job),
        checklist = table.Copy(config.JobTaskSteps),
        links = {{type = LINK_TYPE, ref = job.id}},
        tags = {"job"}
    })

    if not ok then return false, message end

    Sync.Task(task)

    return true, phrase("JobTaskCreated", {name = job.name})
end

DFW.Net.Receive("wf_jobreq", function(_, ply)
    if DubzWorkflow.Enabled() and Staff.IsStaff(ply) then Logic.Send(ply) end
end, {maxBits = SMALL_BITS, cooldown = REQUEST_COOLDOWN})

DFW.Net.Receive("wf_jobset", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and isstring(request.status) and allowed(ply)) then return end

    local ok, message = Logic.Set(ply, request.id, request.status)

    Sync.Result(ply, ok, message)
end, {maxBits = JSON_BITS, cooldown = ACTION_COOLDOWN})

DFW.Net.Receive("wf_jobtask", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and allowed(ply)) then return end

    if not Staff.IsManager(ply) then
        Sync.Result(ply, false, phrase("ErrorManager"))
        return
    end

    local job = Logic.Find(request.id)

    if not job then
        Sync.Result(ply, false, phrase("ErrorJob"))
        return
    end

    Sync.Result(ply, createTask(ply, job))
end, {maxBits = JSON_BITS, cooldown = ACTION_COOLDOWN})
