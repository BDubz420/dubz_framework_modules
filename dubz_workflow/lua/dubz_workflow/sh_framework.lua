local config = DubzWorkflow.Config

local function listColumn(label, maxLength)
    return {key = "value", label = label, type = "string", width = 1, maxLength = maxLength}
end

local specs = {
    {path = "StaffMode", label = "Who Counts As Staff", choices = {"admin", "ranks"}, group = "Staff", public = false,
        description = "admin: every admin and superadmin. ranks: only the usergroups and SteamIDs listed below."},

    {path = "DefaultWorking", label = "New Staff Start As Working", group = "Presence", public = false},
    {path = "JoinPopupDelay", label = "Join Popup Delay (Seconds)", min = 1, max = 120, decimals = 0, group = "Presence", public = false},
    {path = "ReminderMinutes", label = "Reminder Interval (Minutes)", min = 1, max = 240, decimals = 0, group = "Presence", public = false,
        description = "Working staff with tasks due today or overdue are reminded this often. Changes need a restart."},
    {path = "ShowServerTime", label = "Show Server Time Under The Clock", group = "Presence"},

    {path = "DefaultPriority", label = "Default Priority", group = "Tasks", maxLength = 20},
    {path = "TitleMax", label = "Title Maximum Length", min = 10, max = 200, decimals = 0, group = "Tasks", public = false},
    {path = "SummaryMax", label = "Summary Maximum Length", min = 20, max = 500, decimals = 0, group = "Tasks", public = false},
    {path = "InstructionsMax", label = "Instructions Maximum Length", min = 200, max = 8000, decimals = 0, group = "Tasks", public = false},
    {path = "NoteMax", label = "Notes Maximum Length", min = 100, max = 4000, decimals = 0, group = "Tasks", public = false},
    {path = "ChecklistMax", label = "Checklist Maximum Items", min = 1, max = 60, decimals = 0, group = "Tasks", public = false},
    {path = "TagMax", label = "Most Tags Per Task", min = 1, max = 20, decimals = 0, group = "Tasks", public = false},
    {path = "HistoryMax", label = "History Entries Kept Per Task", min = 5, max = 200, decimals = 0, group = "Tasks", public = false},

    {path = "LinkMax", label = "Most Links Per Task", min = 1, max = 20, decimals = 0, group = "Tasks", public = false},
    {path = "TimeMinuteStep", label = "Time Picker Minute Step", min = 1, max = 30, decimals = 0, group = "Tasks", public = false,
        description = "How many minutes each arrow click or scroll moves the time picker."},
    {path = "ScheduleMax", label = "Most Scheduled Days Per Task", min = 1, max = 120, decimals = 0, group = "Tasks", public = false},
    {path = "ConvertSetsPlanned", label = "Converting A Suggestion Marks It Planned", group = "Suggestions", public = false,
        description = "Needs the Suggestions module. Suggestions still waiting for approval are left alone."},
    {path = "SuggestionDialogWidth", label = "Suggestion Window Width", min = 400, max = 1200, decimals = 0, group = "Window"},
    {path = "SuggestionDialogHeight", label = "Suggestion Window Height", min = 300, max = 1000, decimals = 0, group = "Window"},
    {path = "JobDialogWidth", label = "Job Dialog Width", min = 300, max = 900, decimals = 0, group = "Window"},
    {path = "JobDialogHeight", label = "Job Dialog Height", min = 200, max = 700, decimals = 0, group = "Window"},

    {path = "ConsoleCommand", label = "Console Command", group = "Commands", maxLength = 30,
        description = "Lowercase, no spaces. Changes need a restart."},

    {path = "WindowWidth", label = "Window Width", min = 900, max = 2200, decimals = 0, group = "Window"},
    {path = "WindowHeight", label = "Window Height", min = 500, max = 1300, decimals = 0, group = "Window"},
    {path = "ColumnWidth", label = "Board Column Width", min = 220, max = 500, decimals = 0, group = "Window"},
    {path = "DetailWidth", label = "Task Window Width", min = 500, max = 1400, decimals = 0, group = "Window"},
    {path = "DetailHeight", label = "Task Window Height", min = 400, max = 1300, decimals = 0, group = "Window"},
    {path = "EditorWidth", label = "Editor Width", min = 500, max = 1400, decimals = 0, group = "Window"},
    {path = "EditorHeight", label = "Editor Height", min = 400, max = 1300, decimals = 0, group = "Window"}
}

for key in SortedPairs(config.Text) do
    specs[#specs + 1] = {path = "Text." .. key, label = "Text: " .. key, group = "Text", maxLength = 120}
end

local function launchers()
    local text = DubzWorkflow.Phrase

    return {
        {
            label = text("LauncherBoard"),
            description = text("LauncherBoardHint"),
            button = text("LauncherButton"),
            fn = function() DubzWorkflow.Open() end
        },
        {
            label = text("LauncherJobs"),
            description = text("LauncherJobsHint"),
            button = text("LauncherButton"),
            fn = function() DubzWorkflow.Open("jobs") end
        }
    }
end

DFW.Bind.Module({
    id = "workflow",
    name = "Workflow",
    version = "0.1.0",
    icon = "actions/check",
    description = "Plan, assign and track server work with staff presence, notes and an archive.",
    dependencies = {"dubz_core"},
    launchers = launchers()
}, config, specs, {
    ui = true,
    collections = {
        {
            id = "chat_commands",
            label = "Chat Commands",
            description = "Typed in chat to open Workflow. Include the ! or / prefix.",
            public = false,
            columns = {listColumn("Command", 60)},
            default = DFW.Collections.RowsFromList(DubzWorkflow.Lists.chat_commands, "value")
        },
        {
            id = "staff_ranks",
            label = "Staff Usergroups",
            description = "Used when staff mode is ranks. Works with SAM, ULX and xAdmin usergroups.",
            public = false,
            columns = {listColumn("Usergroup", 40)},
            default = {}
        },
        {
            id = "staff_steamids",
            label = "Extra Staff SteamID64s",
            description = "Always counted as staff, whatever their usergroup.",
            public = false,
            columns = {listColumn("SteamID64", 24)},
            default = {}
        },
        {
            id = "manager_ranks",
            label = "Manager Usergroups",
            description = "Managers create, edit, assign and approve tasks. Superadmins are always managers.",
            public = false,
            columns = {listColumn("Usergroup", 40)},
            default = {}
        },
        {
            id = "priorities",
            label = "Priorities",
            description = "From lowest at the top to highest at the bottom.",
            columns = {listColumn("Priority", 20)},
            default = DFW.Collections.RowsFromList(DubzWorkflow.Lists.priorities, "value")
        },
        {
            id = "palette",
            label = "Task Colours",
            description = "Optional colours staff can give a task. The colour is a hex code such as #e5484d.",
            preview = {kind = "chip", text = "name", color = "hex"},
            columns = {
                {key = "name", label = "Name", type = "string", width = 1, maxLength = 20},
                {key = "hex", label = "Hex Colour", type = "string", width = 1, maxLength = 7}
            },
            default = DubzWorkflow.PaletteDefault
        },
        {
            id = "logic_statuses",
            label = "Job Logic Statuses",
            description = "In order, from not started to finished. The first is the default for every job.",
            columns = {listColumn("Status", 30)},
            default = DFW.Collections.RowsFromList(DubzWorkflow.Lists.logic_statuses, "value")
        },
        {
            id = "job_task_steps",
            label = "Create-Task Starter Steps",
            description = "Become the instructions and checklist of a task created from a job.",
            public = false,
            columns = {listColumn("Step", 120)},
            default = DFW.Collections.RowsFromList(DubzWorkflow.Lists.job_task_steps, "value")
        }
    }
})
