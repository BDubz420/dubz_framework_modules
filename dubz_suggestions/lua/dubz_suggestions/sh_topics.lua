DubzSuggestions.Topics = DubzSuggestions.Topics or {}

local Topics = DubzSuggestions.Topics
local MODULE_PREFIX = "module:"
local ADMIN_PREFIX = "topic:"
local CUSTOM_PREFIX = "custom:"

function Topics.List()
    local list = {}

    for id, module in pairs(DFW.Modules.Registry or {}) do
        if module.playerFacing then list[#list + 1] = {id = MODULE_PREFIX .. id, label = module.topic or module.name or id} end
    end

    for _, row in ipairs(DFW.Collections.Get("suggestions", "topics") or {}) do
        list[#list + 1] = {id = ADMIN_PREFIX .. row.id, label = row.label}
    end

    table.sort(list, function(a, b) return string.lower(a.label) < string.lower(b.label) end)

    return list
end

function Topics.Label(id)
    for _, topic in ipairs(Topics.List()) do
        if topic.id == id then return topic.label end
    end
end

function Topics.IsCustom(id)
    return string.StartWith(id or "", CUSTOM_PREFIX)
end

function Topics.CustomId(text)
    return CUSTOM_PREFIX .. text
end

function Topics.CustomText(id)
    return string.sub(id, #CUSTOM_PREFIX + 1)
end
