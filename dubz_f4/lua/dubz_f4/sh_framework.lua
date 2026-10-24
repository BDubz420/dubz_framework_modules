local config = DubzF4.Config

local specs = {
    {path = "ServerName", label = "Server Name", group = "Window", maxLength = 40,
        description = "Shown in the window title."},
    {path = "Width", label = "Window Width", min = 700, max = 2200, decimals = 0, group = "Window"},
    {path = "Height", label = "Window Height", min = 450, max = 1300, decimals = 0, group = "Window"},
    {path = "SidebarWidth", label = "Sidebar Width", min = 160, max = 400, decimals = 0, group = "Window"},
    {path = "StartTab", label = "First Page", choices = DubzF4.TabIds, group = "Window",
        description = "The page shown the first time the menu opens. After that it reopens on the last page."},
    {path = "ToggleDebounce", label = "Key Debounce (Seconds)", min = 0.05, max = 2, decimals = 2, group = "Window",
        description = "Ignores a second F4 press this soon after the first."},

    {path = "ModelChoiceSeconds", label = "Chosen Model Lifetime (Seconds)", min = 5, max = 300, decimals = 0, group = "Jobs", public = false,
        description = "How long a model picked in the Jobs page stays valid after pressing Become."},
    {path = "ShowAnnouncement", label = "Show Announcement", group = "Home"},
    {path = "ShowStaff", label = "Show Staff Online", group = "Home"},

    {path = "JobListShare", label = "Job List Width Share", min = 0.25, max = 0.7, decimals = 2, group = "Jobs",
        description = "How much of the page the job list takes. The preview gets the rest."},
    {path = "ModelFov", label = "Preview Field Of View", min = 15, max = 90, decimals = 0, group = "Jobs"},
    {path = "ModelSpin", label = "Preview Spin Speed", min = 0, max = 180, decimals = 0, group = "Jobs"},

    {path = "StoreColumns", label = "Shop Columns", min = 1, max = 8, decimals = 0, group = "Shop"},
    {path = "CommandColumns", label = "Command Columns", min = 1, max = 6, decimals = 0, group = "Shop"},

    {path = "Sounds", label = "Open Sound", group = "Sound"},
    {path = "OpenSound", label = "Open Sound Path", group = "Sound", maxLength = 120}
}

for _, id in ipairs(DubzF4.TabIds) do
    specs[#specs + 1] = {path = "Tabs." .. id, label = "Page: " .. id, group = "Pages"}
end

for key in SortedPairs(config.Text) do
    specs[#specs + 1] = {path = "Text." .. key, label = "Text: " .. key, group = "Text", maxLength = 120}
end

local function textColumn(key, label, width, maxLength)
    return {key = key, label = label, type = "string", width = width, maxLength = maxLength}
end

DFW.Bind.Module({
    id = "f4",
    playerFacing = true,
    topic = "F4 Menu",
    name = "F4 Menu",
    version = "1.0.0",
    icon = "darkrp/agenda",
    description = "The DarkRP F4 menu: home, jobs, shop pages, commands and rules.",
    dependencies = {"dubz_core"}
}, config, specs, {
    ui = true,
    collections = {
        {
            id = "links",
            label = "Community Links",
            description = "Buttons on the Home page. A row with an empty address is hidden.",
            idKey = "name",
            columns = {textColumn("name", "Name", 1, 24), textColumn("url", "Address", 3, 200)},
            default = DubzF4.DefaultLinks
        },
        {
            id = "announcement",
            label = "Announcement",
            description = "Paragraphs of the announcement card on the Home page.",
            columns = {textColumn("text", "Paragraph", 1, 240)},
            default = DubzF4.DefaultAnnouncement
        },
        {
            id = "rules",
            label = "Rules",
            description = "One row per rule, in the order shown on the Rules page.",
            columns = {textColumn("text", "Rule", 1, 240)},
            default = DubzF4.DefaultRules
        },
        {
            id = "staff_groups",
            label = "Staff Groups",
            description = "Usergroups listed as staff on the Home page, with the label and colour shown.",
            idKey = "group",
            preview = {kind = "chip", text = "label", color = "color"},
            columns = {
                {key = "group", label = "Usergroup", type = "string", suggest = "usergroups", width = 2, maxLength = 40},
                textColumn("label", "Label", 2, 24),
                {key = "color", label = "Colour", type = "color", width = 1}
            },
            default = DubzF4.DefaultStaffGroups
        },
        {
            id = "commands",
            label = "Quick Commands",
            description = "Cards on the Commands page. Each runs the DarkRP command /<command>. Fill the prompt title to ask the player for text first.",
            idKey = "cmd",
            columns = {
                textColumn("name", "Name", 2, 30),
                textColumn("desc", "Description", 3, 100),
                textColumn("icon", "Icon", 2, 60),
                textColumn("cmd", "Command", 2, 40),
                textColumn("prompt_title", "Prompt Title", 2, 40),
                textColumn("prompt_text", "Prompt Question", 3, 120),
                {key = "enabled", label = "On", type = "bool", width = 0.6, default = true}
            },
            default = DubzF4.DefaultCommands
        }
    }
})
