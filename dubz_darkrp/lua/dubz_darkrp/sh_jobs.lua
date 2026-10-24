DubzDarkRP.Jobs = DubzDarkRP.Jobs or {}

local Jobs = DubzDarkRP.Jobs
local Adapter = DubzDarkRP.Adapter
local Fields = DubzDarkRP.Fields
local TEAM_PREFIX = "TEAM_"

local byId = {}
local originals = {}

local function teamVariable(index)
    for key, value in pairs(_G) do
        if isstring(key) and string.StartWith(key, TEAM_PREFIX) and value == index then return key end
    end
end

local function identifier(variable, index)
    local id = variable and string.lower(string.sub(variable, #TEAM_PREFIX + 1)) or ("job" .. index)

    return (string.gsub(id, "[^a-z0-9_]", "_"))
end

function Jobs.Capture()
    for index, job in ipairs(Adapter.Jobs()) do
        if not job.dubzId then
            local variable = teamVariable(index)
            local id = identifier(variable, index)

            job.dubzId = id
            job.jobvar = job.jobvar or variable
            byId[id] = index
            originals[id] = Fields.Extract(job)
        end
    end
end

function Jobs.Index(id)
    return byId[id]
end

function Jobs.Get(id)
    return byId[id] and Adapter.Job(byId[id])
end

function Jobs.Original(id)
    return originals[id]
end

function Jobs.Count()
    return #Adapter.Jobs()
end

function Jobs.Status(id)
    local job = Jobs.Get(id)

    if not job then return nil end
    if job.dubzDisabled then return "removed" end
    if not originals[id] then return "custom" end
    if not DFW.Util.DeepEqual(Fields.Extract(job), originals[id]) then return "edited" end

    return "original"
end

function Jobs.List()
    local list = {}

    for index, job in ipairs(Adapter.Jobs()) do
        if job.dubzId then list[#list + 1] = {id = job.dubzId, index = index, entry = job, job = job, status = Jobs.Status(job.dubzId)} end
    end

    return list
end

local function register(index, job)
    Adapter.SetupTeam(index, job.name, job.color)
    Adapter.EnsureCategory(job.category)
    Adapter.RemoveFromCategory(job)
    Adapter.AddToCategory(job)

    for _, model in ipairs(istable(job.model) and job.model or {job.model}) do Adapter.Precache(model) end
end

local function declare(job)
    Adapter.RemoveCommands(job.command)
    Adapter.DeclareCommands(job, function() return byId[job.dubzId] end)
end

local function create(id, data, index)
    index = index or (#Adapter.Jobs() + 1)

    local job = {}

    Fields.Assign(job, data)
    job.dubzId = id
    job.jobvar = TEAM_PREFIX .. string.upper(id)
    job.team = index
    job.teamKey = index
    job.default = false
    job.ammo = {}

    RPExtraTeams[index] = job
    _G[job.jobvar] = index
    byId[id] = index
    register(index, job)
    declare(job)

    return job
end

local function update(id, job, data)
    local before = {command = job.command, vote = job.vote, name = job.name, salary = job.salary, disabled = job.dubzDisabled}

    Fields.Assign(job, data)
    job.dubzDisabled = nil
    register(byId[id], job)

    if SERVER then Adapter.RefreshPlayers(byId[id], before, job) end

    if before.command ~= job.command or before.vote ~= job.vote or before.name ~= job.name or before.disabled then
        Adapter.RemoveCommands(before.command)
        declare(job)
    end

    return job
end

function Jobs.Apply(id, data, index)
    local existing = Jobs.Get(id)

    if existing then return update(id, existing, data) end

    return create(id, data, index)
end

function Jobs.Disable(id)
    local job = Jobs.Get(id)

    if not job then return false end

    job.dubzDisabled = true
    Adapter.RemoveFromCategory(job)
    Adapter.RemoveCommands(job.command)

    if SERVER then Adapter.MovePlayers(byId[id]) end

    return true
end

function Jobs.Restore(id)
    local original = originals[id]

    if not original then return Jobs.Disable(id) end

    Jobs.Apply(id, original)

    return true
end

DubzDarkRP.Engines.jobs = Jobs

hook.Add("playerCanChangeTeam", "DubzDarkRP_Disabled", function(_, teamId)
    local job = Adapter.Job(teamId)

    if job and job.dubzDisabled then return false, DubzDarkRP.Phrase("JobRemoved") end
end)
