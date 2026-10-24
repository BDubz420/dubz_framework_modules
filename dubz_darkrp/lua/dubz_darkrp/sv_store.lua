DubzDarkRP.Store = DubzDarkRP.Store or {}

local Store = DubzDarkRP.Store
local DATA_ROOT = "dubz_darkrp/"
local VERSION = 1

local states = {}

local function state(kind)
    states[kind] = states[kind] or {order = {}, entries = {}}

    return states[kind]
end

function Store.Load(kind)
    local saved = DFW.Data.ReadJSON(DATA_ROOT .. kind, {})
    local current = {order = {}, entries = {}}

    for _, row in ipairs(istable(saved.entries) and saved.entries or {}) do
        if isstring(row.id) and istable(row.data) then
            current.entries[row.id] = row
            current.order[#current.order + 1] = row.id
        end
    end

    states[kind] = current
end

function Store.Save(kind)
    local current = state(kind)
    local rows = {}

    for _, id in ipairs(current.order) do rows[#rows + 1] = current.entries[id] end

    local ok, reason = DFW.Data.WriteJSON(DATA_ROOT .. kind, {version = VERSION, entries = rows})

    if not ok then DubzDarkRP.Report("could not save " .. kind .. ": " .. tostring(reason)) end

    return ok
end

function Store.Get(kind, id)
    return state(kind).entries[id]
end

function Store.Set(kind, id, entry)
    local current = state(kind)

    if not current.entries[id] then current.order[#current.order + 1] = id end

    entry.id = id
    current.entries[id] = entry
end

function Store.Clear(kind, id)
    local current = state(kind)

    current.entries[id] = nil

    for index, value in ipairs(current.order) do
        if value == id then
            table.remove(current.order, index)
            break
        end
    end
end

function Store.Ids(kind)
    return table.Copy(state(kind).order)
end
