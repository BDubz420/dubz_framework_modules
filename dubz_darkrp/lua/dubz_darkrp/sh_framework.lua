local config = DubzDarkRP.Config
local Kinds = DubzDarkRP.Kinds

local specs = {
    {path = "ApplyOnBoot", label = "Apply Saved Changes On Start", group = "General",
        description = "When off, the server starts with the DarkRP files as written and saved changes are ignored."},
    {path = "MaxJobs", label = "Job Limit", min = 1, max = 512, decimals = 0, group = "General", public = false},
    {path = "MaxItems", label = "Shop Item Limit (Per Area)", min = 1, max = 2048, decimals = 0, group = "General", public = false},
    {path = "VoteSeconds", label = "Job Vote Length (Seconds)", min = 5, max = 120, decimals = 0, group = "General", public = false},

    {path = "AuditLog", label = "Write Audit Log", group = "Access", public = false,
        description = "Records who changed what, with the before and after values."},
    {path = "AuditFile", label = "Audit Log File", group = "Access", maxLength = 60, public = false,
        description = "Written under garrysmod/data."},
    {path = "EditCooldown", label = "Edit Cooldown (Seconds)", min = 0.1, max = 10, decimals = 1, group = "Access", public = false,
        description = "Minimum time between edits from one admin. Changes need a restart."},
    {path = "SyncCooldown", label = "Sync Cooldown (Seconds)", min = 1, max = 60, decimals = 0, group = "Access", public = false,
        description = "Minimum time between a player's own sync requests. Changes need a restart."},

    {path = "EditorCommand", label = "Board Console Command", group = "Board", maxLength = 30,
        description = "Lowercase, no spaces. Add a kind to open it directly: jobs, shipments, entities or ammo. Changes need a restart."},
    {path = "BoardWidth", label = "Board Width", min = 900, max = 2400, decimals = 0, group = "Board"},
    {path = "BoardHeight", label = "Board Height", min = 500, max = 1400, decimals = 0, group = "Board"},
    {path = "ColumnWidth", label = "Column Width", min = 200, max = 500, decimals = 0, group = "Board"},
    {path = "DrawerWidth", label = "Edit Drawer Width", min = 320, max = 700, decimals = 0, group = "Board"}
}

for key in SortedPairs(config.Text) do
    specs[#specs + 1] = {path = "Text." .. key, label = "Text: " .. key, group = "Text", maxLength = 120}
end

local function openFromConfig(kind)
    DubzDarkRP.OpenBoard(kind)
end

local function launchers()
    local list = {{
        label = DubzDarkRP.Phrase("ShortcutTitle"),
        description = DubzDarkRP.Phrase("ShortcutHint"),
        button = DubzDarkRP.Phrase("OpenBoard"),
        fn = function() openFromConfig("jobs") end
    }}

    for _, kind in ipairs(Kinds.Order) do
        local name = DubzDarkRP.Phrase(Kinds.Meta[kind].label)

        list[#list + 1] = {
            label = DubzDarkRP.Phrase("BoardTitle", {kind = name}),
            description = DubzDarkRP.Phrase("BoardHint", {kind = string.lower(name)}),
            button = DubzDarkRP.Phrase("OpenBoard"),
            fn = function() openFromConfig(kind) end
        }
    end

    return list
end

DFW.Bind.Module({
    id = "drp_core",
    name = "DarkRP Management",
    version = "0.2.0",
    icon = "darkrp/agenda",
    description = "Kanban boards for jobs, shipments, entities and ammo. Changes reach every player immediately.",
    dependencies = {"dubz_core"},
    launchers = launchers()
}, config, specs, {
    ui = true,
    collections = {
        {
            id = "chat_commands",
            label = "Board Chat Commands",
            description = "Typed in chat to open the board. Include the ! or / prefix.",
            public = false,
            columns = {{key = "value", label = "Command", type = "string", width = 1, maxLength = 60}},
            default = DFW.Collections.RowsFromList(DubzDarkRP.Lists.chat_commands, "value")
        },
        {
            id = "ammo_models",
            label = "Ammo Model Presets",
            description = "Models offered in the ammo board's model picker. Players can still type any model path.",
            columns = {
                {key = "name", label = "Name", type = "string", width = 1, maxLength = 40},
                {key = "model", label = "Model", type = "string", width = 2, maxLength = 120}
            },
            default = DubzDarkRP.AmmoModelDefaults
        }
    }
})
