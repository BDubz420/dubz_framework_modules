local Adapter = DubzDarkRP.Adapter

local function jobEngine()
    return DubzDarkRP.Engines.jobs
end

local function jobIds(group)
    local ids = {}

    for _, index in ipairs(group) do
        local job = Adapter.Job(index)

        if job and job.dubzId then ids[#ids + 1] = job.dubzId end
    end

    return ids
end

local function jobIndices(ids)
    local list = {}

    for _, id in ipairs(ids) do
        local index = jobEngine().Index(id)

        if index then list[#list + 1] = index end
    end

    return list
end

local function clearTeams(group)
    for position = #group, 1, -1 do group[position] = nil end
end

local function fill(group, data)
    clearTeams(group)

    for position, index in ipairs(jobIndices(data.teams)) do group[position] = index end

    group.name = data.name
    group.teams = data.teams
end

local function createGroup(data)
    RPExtraTeamDoors = RPExtraTeamDoors or {}
    RPExtraTeamDoorIDs = RPExtraTeamDoorIDs or {}

    if AddDoorGroup then
        AddDoorGroup(data.name, unpack(jobIndices(data.teams)))
    else
        RPExtraTeamDoors[data.name] = {}
        RPExtraTeamDoorIDs[data.name] = table.Count(RPExtraTeamDoorIDs) + 1
    end

    local group = RPExtraTeamDoors[data.name]

    fill(group, data)

    return group
end

DubzDarkRP.NewEngine({
    kind = "doorgroups",
    entries = function() return RPExtraTeamDoors or {} end,
    idOf = function(group) return group.name end,
    nextIndex = function(data) return data.name end,
    prepare = function(group) group.teams = jobIds(group) end,
    create = function(data) return createGroup(data) end,
    update = fill,
    disable = clearTeams
})
