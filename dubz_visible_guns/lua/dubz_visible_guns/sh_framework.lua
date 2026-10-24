-- Registers Visible Weapons with the Dubz Framework (!dubzconfig > Visible Weapons).
local cfg = DubzVisibleGuns.Config

-- Rows for the weapon table: every class in the default rules
local ruleRows = {}
for class, rule in pairs(cfg.WeaponOverrides) do
    ruleRows[#ruleRows + 1] = { class = class, kind = rule.kind == "smg" and "smg" or rule.type, model = rule.model or "" }
end
table.sort(ruleRows, function(a, b) return a.class < b.class end)

local ignoreRows = {}
for class in pairs(cfg.IgnoreWeapons) do ignoreRows[#ignoreRows + 1] = { class = class } end
table.sort(ignoreRows, function(a, b) return a.class < b.class end)

local slotRows = {
    { slot = "back_1", name = "Back, first rifle", enabled = true },
    { slot = "back_2", name = "Back, second rifle", enabled = true },
    { slot = "hip_1", name = "Hip, first (pistol or submachine gun)", enabled = true },
    { slot = "hip_2", name = "Hip, second (pistol or submachine gun)", enabled = true },
}

DFW.Bind.Module({
    id = "visible_guns",
    name = "Visible Weapons",
    version = "1.1.0",
    icon = "economy/inventory_2",
    description = "Shows the weapons a player carries on their body: pistols and submachine guns on the hips, rifles on the back (placed around a worn backpack).",
    dependencies = { "dubz_core" },
}, cfg, {
    { path = "ShowActive", label = "Show The Weapon In Hand Too", group = "Drawing", description = "Off: only the weapons you are not holding are drawn on the body." },
    { path = "HolsterGesture", label = "Holster Gesture", group = "Drawing", description = "A small gesture when a weapon is put away or picked up." },
    { path = "DrawDistance", label = "Draw Distance", min = 200, max = 6000, decimals = 0, group = "Drawing", description = "Other players further away than this don't have their guns drawn (saves frames)." },
}, {
    collections = {
        {
            id = "slot_switches", label = "Slots", idKey = "slot",
            description = "Untick a slot to stop it being used: a weapon will go to the next free slot instead (or not be shown if there is none). To move guns around use the placement editor (the button, or dvg_editor).",
            -- A shortcut to the placement editor: the config window closes (it would be in the way) and the editor opens
            actions = {{
                label = "Placement editor", primary = true,
                fn = function()
                    if DFW.ConfigMenu and DFW.ConfigMenu.Close then DFW.ConfigMenu.Close() end

                    timer.Simple(0.1, function() RunConsoleCommand("dvg_editor") end)
                end,
            }},
            columns = {
                { key = "slot", label = "Slot", type = "string", width = 1, maxLength = 20 },
                { key = "name", label = "What it is", type = "string", width = 3, maxLength = 60 },
                { key = "enabled", label = "On", type = "bool", width = 0.6 },
            },
            default = slotRows,
        },
        {
            id = "weapon_rules", label = "Weapons",
            description = "Which weapons are shown and where: pistol and submachine gun on the hips, rifle on the back. Model empty = the weapon's own world model. A weapon not listed here is matched by name (pistol, ak, m4, smg ...).",
            columns = {
                { key = "class", label = "Weapon class", type = "string", width = 2, maxLength = 80, suggest = "weapons" },
                { key = "kind", label = "Where", type = "choice", choices = { "pistol", "smg", "rifle" }, width = 1 },
                { key = "model", label = "Model (optional)", type = "string", width = 3, maxLength = 200 },
            },
            default = ruleRows,
        },
        {
            id = "ignored_weapons", label = "Never Shown", idKey = "class",
            description = "Weapons that are never drawn on the body (tools, hands, keys, melee ...).",
            columns = { { key = "class", label = "Weapon class", type = "string", width = 1, maxLength = 80, suggest = "weapons" } },
            default = ignoreRows,
        },
    },
})

DFW.Collections.Watch("visible_guns", "slot_switches", function(rows)
    local off = {}
    for _, row in ipairs(rows) do
        if row.enabled == false and row.slot and row.slot ~= "" then off[row.slot] = true end
    end

    cfg.DisabledSlots = off
    if SERVER and DubzVisibleGuns.RefreshAll then DubzVisibleGuns.RefreshAll() end
end)

DFW.Collections.Watch("visible_guns", "weapon_rules", function(rows)
    local rules = {}

    for _, row in ipairs(rows) do
        local class = string.lower(string.Trim(row.class or ""))

        if class ~= "" then
            local kind = row.kind or "rifle"
            local model = string.Trim(row.model or "")

            rules[class] = { type = kind == "smg" and "pistol" or kind, kind = kind == "smg" and "smg" or nil, model = model ~= "" and model or nil }
        end
    end

    cfg.WeaponOverrides = rules
    if SERVER and DubzVisibleGuns.RefreshAll then DubzVisibleGuns.RefreshAll() end
end)

DFW.Collections.Watch("visible_guns", "ignored_weapons", function(rows)
    local ignored = {}
    for _, row in ipairs(rows) do
        if row.class and row.class ~= "" then ignored[string.lower(row.class)] = true end
    end

    cfg.IgnoreWeapons = ignored
    if SERVER and DubzVisibleGuns.RefreshAll then DubzVisibleGuns.RefreshAll() end
end)
