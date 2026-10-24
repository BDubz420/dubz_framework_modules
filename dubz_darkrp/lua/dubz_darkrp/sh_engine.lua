local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds

function DubzDarkRP.NewEngine(def)
    local engine = {Kind = def.kind}
    local kind = def.kind
    local byId, originals = {}, {}

    local function freshId(entry, index)
        local base = Kinds.Slug(def.idOf(entry))
        local id

        if base == "" then base = kind .. index end

        id = base

        for suffix = 2, math.huge do
            if not byId[id] then break end

            id = base .. "_" .. suffix
        end

        return id
    end

    function engine.Capture()
        for index, entry in pairs(def.entries()) do
            if istable(entry) and not entry.dubzId then
                local id = freshId(entry, index)

                if def.prepare then def.prepare(entry) end

                entry.dubzId = id
                byId[id] = index
                originals[id] = Fields.Extract(entry, kind)
            end
        end
    end

    function engine.Index(id) return byId[id] end
    function engine.Original(id) return originals[id] end
    function engine.Count() return table.Count(def.entries()) end

    function engine.Get(id)
        return byId[id] and def.entries()[byId[id]]
    end

    function engine.Status(id)
        local entry = engine.Get(id)

        if not entry then return nil end
        if entry.dubzDisabled then return "removed" end
        if not originals[id] then return "custom" end
        if not DFW.Util.DeepEqual(Fields.Extract(entry, kind), originals[id]) then return "edited" end

        return "original"
    end

    function engine.List()
        local list = {}

        for index, entry in pairs(def.entries()) do
            if istable(entry) and entry.dubzId then
                list[#list + 1] = {id = entry.dubzId, index = index, entry = entry, status = engine.Status(entry.dubzId)}
            end
        end

        table.sort(list, function(a, b)
            if isnumber(a.index) and isnumber(b.index) then return a.index < b.index end

            return tostring(a.index) < tostring(b.index)
        end)

        return list
    end

    function engine.Apply(id, data, index)
        local existing = engine.Get(id)

        if existing then
            def.update(existing, data)
            existing.dubzDisabled = nil

            return existing
        end

        index = index or def.nextIndex(data)

        local entry = def.create(data, index)

        entry.dubzId = id
        byId[id] = index

        return entry
    end

    function engine.Disable(id)
        local entry = engine.Get(id)

        if not entry then return false end

        entry.dubzDisabled = true
        def.disable(entry)

        return true
    end

    function engine.Restore(id)
        local original = originals[id]

        if not original then return engine.Disable(id) end

        engine.Apply(id, original)

        return true
    end

    DubzDarkRP.Engines[kind] = engine

    return engine
end
