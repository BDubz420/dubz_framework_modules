local config = DubzWorkflow.Config

local specs = {
    {path = "StaffMode", label = "Who Counts As Staff", choices = {"admin", "ranks"}, group = "Staff", public = false,
        description = "admin: every admin and superadmin. ranks: only the usergroups and SteamIDs listed below."},
    {path = "StaffRanks", label = "Staff Usergroups", list = true, group = "Staff", maxLength = 40, public = false,
        description = "Used when staff mode is ranks. Works with SAM, ULX and xAdmin usergroups."},
    {path = "StaffSteamIDs", label = "Extra Staff SteamID64s", list = true, group = "Staff", maxLength = 24, public = false,
        description = "Always counted as staff, whatever their usergroup."},
    {path = "ManagerRanks", label = "Manager Usergroups", list = true, group = "Staff", maxLength = 40, public = false,
        description = "Managers create, edit, assign and approve tasks. Superadmins are always managers."},

    {path = "DefaultWorking", label = "New Staff Start As Working", group = "Presence", public = false},
    {path = "JoinPopupDelay", label = "Join Popup Delay (Seconds)", min = 1, max = 120, decimals = 0, group = "Presence", public = false},
    {path = "ReminderMinutes", label = "Reminder Interval (Minutes)", min = 1, max = 240, decimals = 0, group = "Presence", public = false,
        description = "Working staff with tasks due today or overdue are reminded this often. Changes need a restart."},
    {path = "ShowServerTime", label = "Show Server Time Under The Clock", group = "Presence"},

    {path = "Priorities", label = "Priorities", list = true, group = "Tasks", maxLength = 20,
        description = "From lowest to highest."},
    {path = "DefaultPriority", label = "Default Priority", group = "Tasks", maxLength = 20},
    {path = "TitleMax", label = "Title Maximum Length", min = 10, max = 200, decimals = 0, group = "Tasks", public = false},
    {path = "SummaryMax", label = "Summary Maximum Length", min = 20, max = 500, decimals = 0, group = "Tasks", public = false},
    {path = "InstructionsMax", label = "Instructions Maximum Length", min = 200, max = 8000, decimals = 0, group = "Tasks", public = false},
    {path = "NoteMax", label = "Notes Maximum Length", min = 100, max = 4000, decimals = 0, group = "Tasks", public = false},
    {path = "ChecklistMax", label = "Checklist Maximum Items", min = 1, max = 60, decimals = 0, group = "Tasks", public = false},
    {path = "TagMax", label = "Most Tags Per Task", min = 1, max = 20, decimals = 0, group = "Tasks", public = false},
    {path = "HistoryMax", label = "History Entries Kept Per Task", min = 5, max = 200, decimals = 0, group = "Tasks", public = false},

    {path = "LinkMax", label = "Most Links Per Task", min = 1, max = 20, decimals = 0, group = "Tasks", public = false},
    {path = "LogicStatuses", label = "Job Logic Statuses", list = true, group = "Job Logic", maxLength = 30,
        description = "In order, from not started to finished. The first is the default for every job."},
    {path = "JobTaskSteps", label = "Create-Task Starter Steps", list = true, group = "Job Logic", maxLength = 120, public = false,
        description = "Become the instructions and checklist of a task created from a job."},
    {path = "Palette", label = "Task Colours", list = true, group = "Tasks", maxLength = 40,
        description = "Optional colours staff can give a task. Each entry looks like Red=#e5484d."},
    {path = "ScheduleMax", label = "Most Scheduled Days Per Task", min = 1, max = 120, decimals = 0, group = "Tasks", public = false},
    {path = "ConvertSetsPlanned", label = "Converting A Suggestion Marks It Planned", group = "Suggestions", public = false,
        description = "Needs the Suggestions module. Suggestions still waiting for approval are left alone."},
    {path = "SuggestionDialogWidth", label = "Suggestion Window Width", min = 400, max = 1200, decimals = 0, group = "Window"},
    {path = "SuggestionDialogHeight", label = "Suggestion Window Height", min = 300, max = 1000, decimals = 0, group = "Window"},
    {path = "JobDialogWidth", label = "Job Dialog Width", min = 300, max = 900, decimals = 0, group = "Window"},
    {path = "JobDialogHeight", label = "Job Dialog Height", min = 200, max = 700, decimals = 0, group = "Window"},

    {path = "ChatCommands", label = "Chat Commands", list = true, group = "Commands", maxLength = 120,
        description = "Typed in chat to open Workflow. Include the ! or / prefix."},
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
}, config, specs, {ui = true})
