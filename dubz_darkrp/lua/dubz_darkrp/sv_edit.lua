DubzDarkRP.Edit = DubzDarkRP.Edit or {}

local Edit = DubzDarkRP.Edit
local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local Store = DubzDarkRP.Store
local Adapter = DubzDarkRP.Adapter
local config = DubzDarkRP.Config

function DubzDarkRP.CanManage(ply)
    return not IsValid(ply) or DFW.Access.CanConfigure(ply)
end

local function failure(reason, values)
    return false, DubzDarkRP.Phrase("Invalid", {reason = DubzDarkRP.Phrase(reason, values)})
end

local function ready(kind)
    if not Kinds.Meta[kind] then return failure("ReasonKind") end
    if not DubzDarkRP.Enabled() then return failure("ReasonDisabled") end
    if not Adapter.Ready() then return failure("ReasonUnavailable") end

    return true
end

local function limitFor(kind)
    return kind == "jobs" and config.MaxJobs or config.MaxItems
end

local function sameScope(meta, entry, data)
    return not meta.scope or entry[meta.scope] == data[meta.scope]
end

local function uniqueOwner(kind, id, data)
    local meta = Kinds.Meta[kind]
    local key = meta.unique

    for _, row in ipairs(Kinds.Engine(kind).List()) do
        local entry = row.entry
        local same = string.lower(tostring(entry[key])) == string.lower(tostring(data[key]))

        if row.id ~= id and not entry.dubzDisabled and same and sameScope(meta, entry, data) then return entry.name end
    end
end

local function newId(kind, data)
    local engine = Kinds.Engine(kind)
    local base = Kinds.IdFor(kind, data)
    local id = base

    for suffix = 2, math.huge do
        if not engine.Index(id) then break end

        id = base .. "_" .. suffix
    end

    return id
end

local function merged(kind, existing, raw)
    local base = existing and Fields.Extract(existing, kind) or {}

    for _, spec in ipairs(Fields.Specs(kind)) do
        if raw[spec.key] ~= nil and not (spec.immutable and existing) then base[spec.key] = raw[spec.key] end
    end

    return base
end

local function finish(actor, kind, action, id, before, message)
    local engine = Kinds.Engine(kind)
    local entry = engine.Get(id)

    Store.Save(kind)
    DubzDarkRP.Sync.Delta(kind, id)
    DubzDarkRP.Audit.Log(actor, kind .. " " .. action, id, before, entry and Fields.Extract(entry, kind))
    hook.Run("DubzDarkRPChanged", kind, id, action)

    return true, message, id
end

function Edit.Save(actor, kind, id, raw)
    local ok, problem = ready(kind)

    if not ok then return false, problem end

    local engine = Kinds.Engine(kind)
    local existing = id and engine.Get(id)
    local valid, data, field = Fields.Normalize(merged(kind, existing, raw or {}), kind)

    if not valid then return failure(data, {field = DubzDarkRP.Phrase(Fields.LabelKey(kind, field))}) end
    if not existing and engine.Count() >= limitFor(kind) then return failure("ReasonLimit") end

    id = existing and id or newId(kind, data)

    local owner = uniqueOwner(kind, id, data)

    if owner then return failure("ReasonDuplicate", {job = owner}) end

    local before = existing and Fields.Extract(existing, kind)
    local entry = Store.Get(kind, id) or {created = existing == nil}

    engine.Apply(id, data)
    entry.data = data
    entry.deleted = nil
    Store.Set(kind, id, entry)

    return finish(actor, kind, existing and "update" or "create", id, before, DubzDarkRP.Phrase(existing and "Updated" or "Created", {job = data.name}))
end

function Edit.Remove(actor, kind, id)
    local ok, problem = ready(kind)

    if not ok then return false, problem end

    local engine = Kinds.Engine(kind)
    local entry = engine.Get(id)

    if not entry then return failure("NotFound", {id = tostring(id)}) end

    local before = Fields.Extract(entry, kind)
    local record = Store.Get(kind, id) or {created = false, data = before}

    engine.Disable(id)
    record.deleted = true
    Store.Set(kind, id, record)

    return finish(actor, kind, "remove", id, before, DubzDarkRP.Phrase("Removed", {job = entry.name}))
end

function Edit.Restore(actor, kind, id)
    local ok, problem = ready(kind)

    if not ok then return false, problem end

    local engine = Kinds.Engine(kind)
    local entry = engine.Get(id)

    if not entry then return failure("NotFound", {id = tostring(id)}) end
    if not engine.Original(id) then return Edit.Remove(actor, kind, id) end

    local owner = uniqueOwner(kind, id, engine.Original(id))

    if owner then return failure("ReasonDuplicate", {job = owner}) end

    local before = Fields.Extract(entry, kind)

    engine.Restore(id)
    Store.Clear(kind, id)

    return finish(actor, kind, "restore", id, before, DubzDarkRP.Phrase("Reset", {job = entry.name}))
end
