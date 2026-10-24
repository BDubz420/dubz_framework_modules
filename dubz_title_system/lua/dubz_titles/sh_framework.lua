-- Registers the Titles system with the Dubz Framework: its settings and two editable tables (Titles, Colors) appear
-- in the admin config menu (!dubzconfig). Edit or add titles and set each one's price right there.
local titleRows, colorRows = {}, {}

for _, title in ipairs(DubzTitles.DefaultTitles) do
    titleRows[#titleRows + 1] = {id = title.id, name = title.name, price = title.price, required = title.required or 0, vip = title.vip == true}
end

for _, colorInfo in ipairs(DubzTitles.DefaultColors) do
    colorRows[#colorRows + 1] = {id = colorInfo.id, name = colorInfo.name, color = {r = colorInfo.color.r, g = colorInfo.color.g, b = colorInfo.color.b, a = 255}, price = colorInfo.price}
end

DFW.Bind.Module({
    id = "titles",
    name = "Titles",
    version = "2.0.0",
    icon = "players/badge",
    description = "The title store: titles and colours players buy, their prices, and who counts as VIP.",
    dependencies = {"dubz_core"},
}, DubzTitles.Config, {
    {path = "CustomColorPrice", label = "Custom Colour Price", min = 0, max = 1000000, decimals = 0, group = "Prices",
        description = "Extra cost of picking any colour instead of a preset one."},
    {path = "UseMoneyTracker", label = "Use Money Tracker Addon", group = "Requirements",
        description = "On: use the DubzMoney tracker for 'money earned' requirements. Off: count earnings itself."},
}, {
    collections = {
        {
            id = "titles", label = "Titles", idKey = "id",
            description = "Every title for sale: its ID (never change an ID players already own), the name shown, its price, the money a player must have earned first (0 = none) and whether it is VIP only.",
            columns = {
                {key = "id", label = "ID", type = "string", width = 1.5, maxLength = 40},
                {key = "name", label = "Name", type = "string", width = 2, maxLength = 40},
                {key = "price", label = "Price", type = "number", min = 0, max = 100000000, decimals = 0, width = 1},
                {key = "required", label = "Earned first", type = "number", min = 0, max = 1000000000, decimals = 0, width = 1},
                {key = "vip", label = "VIP", type = "bool", width = 0.6},
            },
            default = titleRows,
        },
        {
            id = "colors", label = "Colours", idKey = "id",
            description = "Preset title colours and their prices.",
            preview = {kind = "chip", text = "name", color = "color"},
            columns = {
                {key = "id", label = "ID", type = "string", width = 1.2, maxLength = 40},
                {key = "name", label = "Name", type = "string", width = 1.5, maxLength = 40},
                {key = "color", label = "Colour", type = "color", width = 0.8},
                {key = "price", label = "Price", type = "number", min = 0, max = 100000000, decimals = 0, width = 1},
            },
            default = colorRows,
        },
        {
            id = "vip_groups", label = "VIP Groups", idKey = "group",
            description = "User groups that may buy VIP titles.",
            columns = {{key = "group", label = "User group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"}},
            default = DFW.Collections.RowsFromSet(DubzTitles.Config.VIPGroups, "group"),
        },
        {
            id = "admin_groups", label = "Admin Groups", idKey = "group",
            description = "User groups counted as title admins.",
            columns = {{key = "group", label = "User group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"}},
            default = DFW.Collections.RowsFromSet(DubzTitles.Config.AdminGroups, "group"),
        },
    },
    ui = true,
})

DFW.Collections.Watch("titles", "vip_groups", function(rows)
    DubzTitles.Config.VIPGroups = DFW.Collections.SetFromRows(rows, "group")
end)

DFW.Collections.Watch("titles", "admin_groups", function(rows)
    DubzTitles.Config.AdminGroups = DFW.Collections.SetFromRows(rows, "group")
end)

-- The rest of the addon reads DubzTitles.Titles / VIPTitles / Colors
DFW.Collections.Watch("titles", "titles", function(rows)
    local normal, vip = {}, {}

    for _, row in ipairs(rows) do
        local title = {id = row.id, name = row.name, price = row.price, vip = row.vip}
        if row.required > 0 then title.required = row.required end
        table.insert(row.vip and vip or normal, title)
    end

    DubzTitles.Titles, DubzTitles.VIPTitles = normal, vip
end)

DFW.Collections.Watch("titles", "colors", function(rows)
    local list = {}

    for _, row in ipairs(rows) do
        list[#list + 1] = {id = row.id, name = row.name, color = DFW.Collections.ToColor(row.color), price = row.price}
    end

    DubzTitles.Colors = list
end)
