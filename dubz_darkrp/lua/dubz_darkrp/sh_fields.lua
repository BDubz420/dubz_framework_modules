DubzDarkRP.Fields = DubzDarkRP.Fields or {}

local Fields = DubzDarkRP.Fields
local MAX_ITEMS = 40
local MAX_ITEM_LENGTH = 120
local MAX_COLOR = 255
local MAX_MONEY = 10000000
local DEFAULT_KIND = "jobs"

Fields.Kinds = {}

function Fields.Define(kind, list, defaults)
    Fields.Kinds[kind] = {list = list, defaults = defaults}
end

function Fields.Specs(kind)
    return Fields.Kinds[kind or DEFAULT_KIND].list
end

function Fields.DefaultsOf(kind)
    return table.Copy(Fields.Kinds[kind or DEFAULT_KIND].defaults)
end

local function capital(key)
    return string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
end

function Fields.LabelKey(kind, key)
    local specific = "Field" .. capital(kind) .. capital(key)

    if DubzDarkRP.Config.Text[specific] then return specific end

    return "Field" .. capital(key)
end

local function listFrom(value)
    if isstring(value) then return {value} end
    if istable(value) then return table.Copy(value) end

    return {}
end

local function colorTable(value, fallback)
    if istable(value) and value.r then return {r = value.r, g = value.g, b = value.b, a = value.a or MAX_COLOR} end

    return table.Copy(fallback)
end

function Fields.JobIds(allowed, spec)
    if isnumber(allowed) then allowed = {allowed} end

    local ids = {}

    for _, index in ipairs(istable(allowed) and allowed or {}) do
        local job = RPExtraTeams and RPExtraTeams[index]

        if job and job.dubzId then ids[#ids + 1] = job.dubzId end
    end

    if spec.empty == "all" and #ids >= #(RPExtraTeams or {}) then return {} end

    return ids
end

function Fields.JobIndices(ids, spec)
    local indices = {}

    for _, id in ipairs(ids) do
        local index = DubzDarkRP.Engines.jobs.Index(id)

        if index then indices[#indices + 1] = index end
    end

    if #indices > 0 then return indices end
    if spec.empty ~= "all" then return nil end

    for index in ipairs(RPExtraTeams) do indices[#indices + 1] = index end

    return indices
end

function Fields.Extract(entry, kind)
    local data, defaults = {}, Fields.Kinds[kind or DEFAULT_KIND].defaults

    for _, spec in ipairs(Fields.Specs(kind)) do
        local value = entry[spec.key]

        if value == nil then value = table.Copy(defaults[spec.key]) end

        if spec.type == "list" then
            value = listFrom(value)
        elseif spec.type == "jobs" then
            value = Fields.JobIds(value, spec)
        elseif spec.type == "color" then
            value = colorTable(value, defaults[spec.key])
        end

        data[spec.key] = value
    end

    return data
end

function Fields.Assign(entry, data, kind)
    for _, spec in ipairs(Fields.Specs(kind)) do
        local value = data[spec.key]

        if spec.type == "color" then
            value = Color(value.r, value.g, value.b, value.a)
        elseif spec.type == "jobs" then
            value = Fields.JobIndices(value, spec)
        elseif spec.collapse and #value == 1 then
            value = value[1]
        end

        entry[spec.key] = value
    end
end

local function normalizeText(spec, value)
    value = string.Trim(tostring(value or ""))

    if value == "" and spec.required then return false, "ReasonRequired" end
    if #value > spec.max then return false, "ReasonLength" end

    if spec.type == "command" then
        value = string.lower(value)

        if not string.match(value, "^[a-z0-9_]+$") then return false, "ReasonCommand" end
    end

    return true, value
end

local function normalizeNumber(spec, value)
    value = tonumber(value)

    if not (value and DFW.Util.IsFiniteNumber(value)) then return false, "ReasonRequired" end

    return true, DFW.Util.Round(math.Clamp(value, spec.min, spec.max), spec.decimals)
end

local function normalizeColor(value)
    if not (istable(value) and value.r and value.g and value.b) then return false, "ReasonRequired" end

    return true, {
        r = math.Clamp(math.floor(tonumber(value.r) or 0), 0, MAX_COLOR),
        g = math.Clamp(math.floor(tonumber(value.g) or 0), 0, MAX_COLOR),
        b = math.Clamp(math.floor(tonumber(value.b) or 0), 0, MAX_COLOR),
        a = math.Clamp(math.floor(tonumber(value.a) or MAX_COLOR), 0, MAX_COLOR)
    }
end

local function normalizeList(spec, value)
    if isstring(value) then value = string.Explode(",", value) end

    local items = {}

    for _, item in ipairs(istable(value) and value or {}) do
        item = string.Trim(tostring(item))

        if item ~= "" then items[#items + 1] = string.sub(item, 1, MAX_ITEM_LENGTH) end
    end

    if #items > MAX_ITEMS then return false, "ReasonLength" end
    if #items == 0 and spec.required then return false, "ReasonRequired" end

    return true, items
end

local function normalizeChoice(spec, value)
    if table.HasValue(spec.choices, value) then return true, value end

    return false, "ReasonRequired"
end

local function normalizeValue(spec, value)
    if spec.type == "choice" then return normalizeChoice(spec, value) end
    if spec.type == "string" or spec.type == "text" or spec.type == "command" then return normalizeText(spec, value) end
    if spec.type == "number" then return normalizeNumber(spec, value) end
    if spec.type == "bool" then return true, value == true end
    if spec.type == "color" then return normalizeColor(value) end

    return normalizeList(spec, value)
end

function Fields.Normalize(raw, kind)
    local data, defaults = {}, Fields.Kinds[kind or DEFAULT_KIND].defaults

    for _, spec in ipairs(Fields.Specs(kind)) do
        local value = raw[spec.key]

        if value == nil then value = table.Copy(defaults[spec.key]) end

        local ok, result = normalizeValue(spec, value)

        if not ok then return false, result, spec.key end

        data[spec.key] = result
    end

    return true, data
end

local function text(key, max, required) return {key = key, type = "string", max = max, required = required} end
local function money(key, max) return {key = key, type = "number", min = 0, max = max or MAX_MONEY, decimals = 0} end

Fields.Define("jobs", {
    {key = "name", type = "string", max = 40, required = true},
    {key = "command", type = "command", max = 30, required = true},
    {key = "category", type = "string", max = 40, required = true},
    {key = "description", type = "text", max = 1000},
    money("salary", 1000000),
    {key = "max", type = "number", min = 0, max = 128, decimals = 2},
    {key = "admin", type = "number", min = 0, max = 2, decimals = 0},
    {key = "vote", type = "bool"},
    {key = "hasLicense", type = "bool"},
    {key = "candemote", type = "bool"},
    {key = "color", type = "color"},
    {key = "model", type = "list", required = true, collapse = true, picker = "playermodels"},
    {key = "weapons", type = "list", picker = "weapons"}
}, {
    name = "New Job", command = "", category = "Citizens", description = "", salary = 45, max = 0, admin = 0,
    vote = false, hasLicense = false, candemote = true, color = {r = 120, g = 120, b = 120, a = 255},
    model = {"models/player/kleiner.mdl"}, weapons = {}
})

Fields.Define("shipments", {
    text("name", 40, true),
    {key = "entity", type = "string", max = 60, required = true, picker = "weapon"},
    text("model", 120, true),
    text("category", 40, true),
    money("price"),
    {key = "amount", type = "number", min = 1, max = 200, decimals = 0},
    {key = "separate", type = "bool"},
    money("pricesep"),
    {key = "noship", type = "bool"},
    {key = "allowed", type = "jobs", picker = "jobs", empty = "all"}
}, {
    name = "New Shipment", entity = "weapon_pistol", model = "models/weapons/w_pist_p228.mdl", category = "Weapons",
    price = 500, amount = 10, separate = false, pricesep = 60, noship = false, allowed = {}
})

Fields.Define("entities", {
    text("name", 40, true),
    text("ent", 60, true),
    {key = "cmd", type = "command", max = 30, required = true},
    {key = "model", type = "string", max = 120, required = true, picker = "props"},
    text("category", 40, true),
    money("price"),
    {key = "max", type = "number", min = 0, max = 100, decimals = 0},
    {key = "allowed", type = "jobs", picker = "jobs", empty = "nil"}
}, {
    name = "New Entity", ent = "", cmd = "", model = "models/props_c17/consolebox01a.mdl", category = "Other",
    price = 100, max = 1, allowed = {}
})

Fields.Define("ammo", {
    text("name", 40, true),
    text("ammoType", 30, true),
    {key = "model", type = "string", max = 120, required = true, picker = "ammomodels"},
    text("category", 40, true),
    money("price"),
    {key = "amountGiven", type = "number", min = 1, max = 1000, decimals = 0}
}, {
    name = "New Ammo", ammoType = "", model = "models/Items/BoxSRounds.mdl", category = "Ammo", price = 50, amountGiven = 30
})

Fields.CategoryTypes = {"jobs", "entities", "shipments", "weapons", "ammo", "vehicles"}

Fields.Define("categories", {
    {key = "name", type = "string", max = 40, required = true, immutable = true},
    {key = "categorises", type = "choice", choices = Fields.CategoryTypes, immutable = true},
    {key = "color", type = "color"},
    {key = "sortOrder", type = "number", min = 0, max = 1000, decimals = 0},
    {key = "startExpanded", type = "bool"}
}, {
    name = "New Category", categorises = "entities", color = {r = 0, g = 107, b = 0, a = 255}, sortOrder = 100, startExpanded = true
})

Fields.Define("doorgroups", {
    {key = "name", type = "string", max = 40, required = true, immutable = true},
    {key = "teams", type = "list", picker = "jobs"}
}, {
    name = "New Door Group", teams = {}
})
