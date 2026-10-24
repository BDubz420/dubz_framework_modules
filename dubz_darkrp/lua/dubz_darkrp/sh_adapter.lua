DubzDarkRP.Adapter = DubzDarkRP.Adapter or {}

local adapter = DubzDarkRP.Adapter
local config = DubzDarkRP.Config
local COMMAND_DELAY = 1.5
local CATEGORY_SORT = 100
local CATEGORY_COLOR = Color(0, 107, 0, 255)
local NOTIFY_ERROR = 1
local NOTIFY_SECONDS = 4

local function guard(label, fn, ...)
    local ok, err = pcall(fn, ...)

    if not ok then DubzDarkRP.Report(label .. " failed: " .. tostring(err)) end

    return ok
end

function adapter.Ready()
    return DarkRP ~= nil and RPExtraTeams ~= nil
end

function adapter.Jobs()
    return RPExtraTeams or {}
end

function adapter.Job(index)
    return RPExtraTeams and RPExtraTeams[index]
end

function adapter.SetupTeam(index, name, color)
    team.SetUp(index, name, color)
end

function adapter.Precache(model)
    if isstring(model) then util.PrecacheModel(model) end
end

function adapter.EnsureCategory(name, kind)
    kind = kind or "jobs"

    for _, category in ipairs(DarkRP.getCategories()[kind] or {}) do
        if category.name == name then return end
    end

    guard("create category " .. name, DarkRP.createCategory, {
        name = name,
        categorises = kind,
        startExpanded = true,
        color = CATEGORY_COLOR,
        sortOrder = CATEGORY_SORT,
        canSee = function() return true end
    })
end

function adapter.AddToCategory(entry, kind)
    guard("add " .. entry.name .. " to its category", DarkRP.addToCategory, entry, kind or "jobs", entry.category)
end

function adapter.RemoveFromCategory(entry, kind)
    guard("remove " .. entry.name .. " from its category", DarkRP.removeFromCategory, entry, kind or "jobs")
end

function adapter.RemoveCommands(command)
    guard("remove command " .. tostring(command), DarkRP.removeChatCommand, command)
    guard("remove command vote" .. tostring(command), DarkRP.removeChatCommand, "vote" .. tostring(command))
end

function adapter.Notify(ply, text)
    if IsValid(ply) then DarkRP.notify(ply, NOTIFY_ERROR, NOTIFY_SECONDS, text) end
end

function adapter.MovePlayers(index)
    local default = GAMEMODE and GAMEMODE.DefaultTeam

    if not default then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == index and ply.changeTeam then
            ply:changeTeam(default, true)
            adapter.Notify(ply, DubzDarkRP.Phrase("JobRemoved"))
        end
    end
end

function adapter.RefreshPlayers(index, before, job)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == index and ply.setDarkRPVar then
            if ply:getDarkRPVar("job") == before.name then ply:setDarkRPVar("job", job.name) end

            if before.salary ~= job.salary then ply:setSelfDarkRPVar("salary", job.salary) end
        end
    end
end

local function staffBlocked(ply, job)
    return (job.admin >= 1 and not ply:IsAdmin()) or (job.admin >= 2 and not ply:IsSuperAdmin())
end

local function becomeNow(ply, job, getIndex)
    if job.dubzDisabled then return adapter.Notify(ply, DubzDarkRP.Phrase("JobRemoved")) end
    if staffBlocked(ply, job) then return adapter.Notify(ply, DubzDarkRP.Phrase("NeedAdmin")) end
    if job.vote and not ply:IsAdmin() then return adapter.Notify(ply, DubzDarkRP.Phrase("NeedVote")) end

    ply:changeTeam(getIndex())
end

local function startVote(ply, job, getIndex)
    if job.dubzDisabled then return adapter.Notify(ply, DubzDarkRP.Phrase("JobRemoved")) end
    if staffBlocked(ply, job) then return adapter.Notify(ply, DubzDarkRP.Phrase("NeedAdmin")) end

    local index = getIndex()
    local question = DubzDarkRP.Phrase("VoteQuestion", {name = ply:Nick(), job = job.name})

    DarkRP.createVote(question, "job", ply, config.VoteSeconds, function(vote, choice)
        local target = vote.target

        if not IsValid(target) then return end

        if choice >= 0 then
            target:changeTeam(index)
        else
            DarkRP.notifyAll(NOTIFY_ERROR, NOTIFY_SECONDS, DubzDarkRP.Phrase("VoteDenied", {name = target:Nick(), job = job.name}))
        end
    end, nil, nil, {targetTeam = index})
end

function adapter.DeclareCommands(job, getIndex)
    local command = job.command

    guard("declare command " .. command, DarkRP.declareChatCommand, {
        command = command,
        description = DubzDarkRP.Phrase("CommandHelp", {job = job.name}),
        delay = COMMAND_DELAY,
        condition = function() return not job.dubzDisabled end
    })

    if job.vote then
        guard("declare command vote" .. command, DarkRP.declareChatCommand, {
            command = "vote" .. command,
            description = DubzDarkRP.Phrase("CommandVoteHelp", {job = job.name}),
            delay = COMMAND_DELAY,
            condition = function() return not job.dubzDisabled end
        })
    end

    if CLIENT then return end

    DarkRP.defineChatCommand(command, function(ply)
        becomeNow(ply, job, getIndex)

        return ""
    end)

    if job.vote then
        DarkRP.defineChatCommand("vote" .. command, function(ply)
            startVote(ply, job, getIndex)

            return ""
        end)
    end
end
