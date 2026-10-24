DubzWorkflow.Logic = DubzWorkflow.Logic or {}

local Logic = DubzWorkflow.Logic
local Sync = DubzWorkflow.Sync
local Staff = DubzWorkflow.Staff
local config = DubzWorkflow.Config
local DATA_FILE = "dubz_workflow/logic"
local VERSION = 1
local SAVE_DELAY = 2
local SAVE_TIMER = "DubzWorkflow_LogicSave"

local map = {}
local watchers = {}

local function load()
    local saved = DFW.Data.ReadJSON(DATA_FILE, {})

    map = {}

    for _, row in ipairs(istable(saved.jobs) and saved.jobs or {}) do
        if isstring(row.id) and isstring(row.st) then map[row.id] = {st = row.st, by = row.by or "", at = row.at or 0} end
    end
end

function Logic.SaveNow()
    local rows = {}

    for id, entry in pairs(map) do rows[#rows + 1] = {id = id, st = entry.st, by = entry.by, at = entry.at} end

    local ok, reason = DFW.Data.WriteJSON(DATA_FILE, {version = VERSION, jobs = rows})

    if not ok then DubzWorkflow.Report("could not save job logic: " .. tostring(reason)) end
end

local function save()
    timer.Create(SAVE_TIMER, SAVE_DELAY, 1, Logic.SaveNow)
end

function Logic.ValidStatus(status)
    for _, entry in ipairs(config.LogicStatuses) do
        if entry == status then return true end
    end

    return false
end

function Logic.Status(id)
    local entry = map[id]

    if entry and Logic.ValidStatus(entry.st) then return entry.st end

    return config.LogicStatuses[1] or ""
end

function Logic.Jobs()
    local list = {}

    if not (DubzDarkRP and DubzDarkRP.Jobs and DubzDarkRP.Jobs.List) then return list end

    for _, row in ipairs(DubzDarkRP.Jobs.List()) do
        if not row.job.dubzDisabled then
            local color = row.job.color

            list[#list + 1] = {
                id = row.id,
                name = row.job.name,
                color = color and {r = color.r, g = color.g, b = color.b} or nil,
                status = Logic.Status(row.id)
            }
        end
    end

    return list
end

function Logic.Find(id)
    for _, job in ipairs(Logic.Jobs()) do
        if job.id == id then return job end
    end
end

local function payload()
    return {statuses = config.LogicStatuses, jobs = Logic.Jobs()}
end

function Logic.Send(ply)
    watchers[ply] = true
    Sync.Send("wf_jobs", payload(), ply)
end

local function broadcast()
    local targets = {}

    for ply in pairs(watchers) do
        if IsValid(ply) and Staff.IsStaff(ply) then targets[#targets + 1] = ply else watchers[ply] = nil end
    end

    if #targets > 0 then Sync.Send("wf_jobs", payload(), targets) end
end

function Logic.Set(ply, id, status)
    if not Logic.Find(id) then return false, DubzWorkflow.Phrase("ErrorJob") end

    if not Logic.ValidStatus(status) then return false, DubzWorkflow.Phrase("ErrorLogicStatus") end

    map[id] = {st = status, by = ply:Nick(), at = os.time()}
    save()
    broadcast()
    hook.Run("DubzWorkflowJobLogicChanged", id, status)

    return true, DubzWorkflow.Phrase("JobSaved")
end

hook.Add("PlayerDisconnected", "DubzWorkflow_LogicWatchers", function(ply)
    watchers[ply] = nil
end)

hook.Add("ShutDown", "DubzWorkflow_LogicSave", Logic.SaveNow)

load()
