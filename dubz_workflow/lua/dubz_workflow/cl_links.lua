DubzWorkflow.Links = DubzWorkflow.Links or {}

local Links = DubzWorkflow.Links
local types = {}
local order = {}
local gathered = false

function Links.Register(definition)
    if not (istable(definition) and isstring(definition.id) and isfunction(definition.open)) then
        DubzWorkflow.Report("a link type was registered without an id or open function")
        return
    end

    if not types[definition.id] then order[#order + 1] = definition.id end

    types[definition.id] = definition
end

local function gather()
    if gathered then return end

    gathered = true
    hook.Run("DubzWorkflowRegisterLinks", Links.Register)
end

function Links.Get(id)
    gather()

    return types[id]
end

function Links.All()
    gather()

    local list = {}

    for _, id in ipairs(order) do list[#list + 1] = types[id] end

    return list
end

function Links.Describe(link)
    local definition = Links.Get(link.type)

    if not definition then return link.type .. ": " .. link.ref, false end

    local text = definition.describe and definition.describe(link.ref)

    if not text then return definition.label .. ": " .. link.ref, false end

    return definition.label .. ": " .. text, true
end

function Links.Open(link)
    local definition = Links.Get(link.type)

    if not definition then return false end

    local ok, reason = pcall(definition.open, link.ref)

    if not ok then DubzWorkflow.Report("link " .. link.type .. " failed to open: " .. tostring(reason)) end

    return ok
end
