local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds

local KIND = "categories"
local MAX_COLOR = 255

local engine = {Kind = KIND}
local byId, originals = {}, {}

local function flat()
    local list = {}

    for _, categories in pairs(DarkRP.getCategories()) do
        for _, category in ipairs(categories) do
            if istable(category) and category.categorises then list[#list + 1] = category end
        end
    end

    return list
end

local function freshId(category)
    local base = Kinds.IdFor(KIND, {categorises = category.categorises, name = category.name})
    local id = base

    for suffix = 2, math.huge do
        if not byId[id] then break end

        id = base .. "_" .. suffix
    end

    return id
end

local function adopt(id, category)
    category.dubzId = id
    byId[id] = category
end

function engine.Capture()
    for _, category in ipairs(flat()) do
        if not category.dubzId then
            local id = freshId(category)

            adopt(id, category)
            originals[id] = Fields.Extract(category, KIND)
        end
    end
end

function engine.Index(id) return byId[id] and id end
function engine.Get(id) return byId[id] end
function engine.Original(id) return originals[id] end
function engine.Count() return #flat() end

function engine.Status(id)
    local category = byId[id]

    if not category then return nil end
    if category.dubzDisabled then return "removed" end
    if not originals[id] then return "custom" end
    if not DFW.Util.DeepEqual(Fields.Extract(category, KIND), originals[id]) then return "edited" end

    return "original"
end

function engine.List()
    local list = {}

    for position, category in ipairs(flat()) do
        if category.dubzId then list[#list + 1] = {id = category.dubzId, index = position, entry = category, status = engine.Status(category.dubzId)} end
    end

    return list
end

local function toColor(value)
    return Color(value.r, value.g, value.b, value.a or MAX_COLOR)
end

local function create(id, data)
    local ok, err = pcall(DarkRP.createCategory, {
        name = data.name,
        categorises = data.categorises,
        startExpanded = data.startExpanded,
        color = toColor(data.color),
        sortOrder = data.sortOrder,
        canSee = function() return true end
    })

    if not ok then
        DubzDarkRP.Report("could not create category " .. data.name .. ": " .. tostring(err))
        return nil
    end

    for _, category in ipairs(DarkRP.getCategories()[data.categorises] or {}) do
        if category.name == data.name then
            adopt(id, category)
            return category
        end
    end
end

function engine.Apply(id, data)
    local category = byId[id]

    if not category then return create(id, data) end

    category.color = toColor(data.color)
    category.sortOrder = data.sortOrder
    category.startExpanded = data.startExpanded

    if category.dubzDisabled then
        category.canSee = category.dubzCanSee
        category.dubzDisabled = nil
    end

    return category
end

function engine.Disable(id)
    local category = byId[id]

    if not category then return false end

    category.dubzCanSee = category.dubzCanSee or category.canSee
    category.canSee = function() return false end
    category.dubzDisabled = true

    return true
end

function engine.Restore(id)
    if not originals[id] then return engine.Disable(id) end

    engine.Apply(id, originals[id])

    return true
end

DubzDarkRP.Engines[KIND] = engine
