local Kinds = DubzDarkRP.Kinds
local Fields = DubzDarkRP.Fields
local LINK_PREFIX = "drp."

local function describe(kind, ref)
    local entry = Kinds.Engine(kind).Get(ref)

    if not entry then return nil end

    return Fields.Extract(entry, kind).name or ref
end

local function choices(kind)
    local list = {}

    for _, row in ipairs(Kinds.Engine(kind).List()) do
        if not row.entry.dubzDisabled then
            list[#list + 1] = {label = Fields.Extract(row.entry, kind).name or row.id, ref = row.id}
        end
    end

    return list
end

hook.Add("DubzWorkflowRegisterLinks", "DubzDarkRP_Links", function(register)
    for _, kind in ipairs(Kinds.Order) do
        local meta = Kinds.Meta[kind]

        register({
            id = LINK_PREFIX .. kind,
            label = "DarkRP " .. DubzDarkRP.Phrase(meta.single),
            icon = meta.icon,
            describe = function(ref) return describe(kind, ref) end,
            choices = function() return choices(kind) end,
            open = function(ref) DubzDarkRP.OpenBoard(kind, ref) end
        })
    end
end)
