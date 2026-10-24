DubzWorkflow.Config = {
    ChatCommands = {"!workflow", "/workflow", "!tasks", "/tasks"},
    ConsoleCommand = "dubz_workflow",

    StaffMode = "admin",
    StaffRanks = {},
    StaffSteamIDs = {},
    ManagerRanks = {},

    DefaultWorking = true,
    JoinPopupDelay = 8,
    ReminderMinutes = 20,
    ShowServerTime = false,

    Priorities = {"low", "normal", "high", "urgent"},
    DefaultPriority = "normal",
    TitleMax = 80,
    SummaryMax = 200,
    InstructionsMax = 3000,
    NoteMax = 1000,
    ChecklistMax = 20,
    TagMax = 8,
    HistoryMax = 40,
    LinkMax = 6,

    LogicStatuses = {"Undefined", "Needs logic", "In progress", "Defined", "Completed"},
    JobTaskSteps = {"Decide what this job can and cannot do.", "Write the logic for it.", "Test it in game."},
    Palette = {"Red=#e5484d", "Orange=#f76b15", "Yellow=#ffc53d", "Green=#30a46c", "Blue=#3e63dd", "Purple=#8e4ec6", "Pink=#d6409f"},
    ScheduleMax = 31,
    ConvertSetsPlanned = true,
    SuggestionDialogWidth = 640,
    SuggestionDialogHeight = 560,
    JobDialogWidth = 460,
    JobDialogHeight = 300,

    WindowWidth = 1320,
    WindowHeight = 760,
    ColumnWidth = 300,
    DetailWidth = 760,
    DetailHeight = 720,
    EditorWidth = 760,
    EditorHeight = 760,

    Text = {
        WindowTitle = "Dubz Workflow",
        WindowSubtitle = "Plan, assign and track server work.",
        TabBoard = "Board",
        TabMine = "My tasks",
        TabDone = "Completed",
        TabReview = "Review queue",
        StatusPending = "Pending review",
        StatusTodo = "To do",
        StatusProgress = "In progress",
        StatusBlocked = "Blocked",
        StatusReview = "In review",
        StatusDone = "Done",
        Working = "Working",
        Playing = "Playing",
        ServerTime = "Server {time}",
        TeamWorking = "{count} working",
        NewTask = "New task",
        NoTasks = "Nothing here yet.",
        Unassigned = "Unassigned",
        ClaimedBy = "Claimed by {name}",
        Due = "Due {date}",
        Overdue = "Overdue {date}",
        DoneBy = "Completed by {name} on {date}",
        Claim = "Claim",
        Unclaim = "Release",
        MarkDone = "Mark done",
        Reopen = "Reopen",
        Approve = "Approve",
        Reject = "Reject",
        Delete = "Delete",
        Edit = "Edit",
        Close = "Close",
        Save = "Save",
        Cancel = "Cancel",
        EditorNew = "New task",
        EditorEdit = "Edit task",
        FieldTitle = "Title",
        FieldSummary = "Summary",
        FieldPriority = "Priority",
        FieldStatus = "Status",
        FieldDue = "Due date (YYYY-MM-DD)",
        FieldTags = "Tags (comma separated)",
        FieldAssignees = "Assigned to",
        FieldInstructions = "Instructions",
        FieldChecklist = "Checklist (one item per line)",
        FieldNotes = "Notes",
        InstructionsHint = "# Heading, - bullet, 1. step, `code`",
        AddAssignee = "Add or remove staff",
        ClearAssignees = "Clear",
        NoAssignees = "Nobody yet",
        AddNote = "Save notes",
        NotesPlaceholder = "Optional notes for whoever works on this.",
        SectionInstructions = "Instructions",
        SectionChecklist = "Checklist",
        SectionHistory = "History",
        SubmitForReview = "Submit for review",
        Saved = "Task saved.",
        Submitted = "Task sent for review.",
        Updated = "Task updated.",
        Deleted = "Task deleted.",
        ErrorAccess = "You do not have access to Workflow.",
        ErrorManager = "Only managers can do that.",
        ErrorTitle = "A task needs a title.",
        ErrorMissing = "That task no longer exists.",
        ErrorStatus = "That status is not valid.",
        ErrorDate = "Dates must look like 2026-01-31.",
        ErrorDisabled = "Workflow is turned off.",
        NoticeJoin = "You have {count} new tasks. Open the menu to see what to work on.",
        NoticeLive = "A task was assigned to you: {title}",
        NoticeReminder = "You have {count} tasks due today or overdue.",
        NoticeMissed = "While you were playing: {count} tasks changed for you.",
        NoticeOpen = "Open",
        NoticeTitle = "Workflow",
        HistoryCreated = "created the task",
        HistorySubmitted = "submitted the task for review",
        HistoryApproved = "approved the task",
        HistoryRejected = "rejected the task",
        HistoryEdited = "edited the task",
        HistoryClaimed = "claimed the task",
        HistoryReleased = "released the task",
        HistoryStatus = "moved the task to {status}",
        HistoryNotes = "updated the notes",
        HistoryChecklist = "updated the checklist",
        TabJobs = "Jobs",
        SectionLinks = "Links",
        LinkAdd = "Add link",
        LinkType = "Link to",
        LinkTarget = "Target",
        LinkUnavailable = "{label} (unavailable)",
        LinkClear = "Clear links",
        NoLinks = "No links",
        LinkNeedsTarget = "Pick what to link to first.",
        JobsNoDarkRP = "DarkRP is not loaded, so there are no jobs to track.",
        JobDialogTitle = "Job logic",
        JobStatus = "Logic status",
        JobCreateTask = "Create task",
        JobTaskTitle = "Define logic: {name}",
        JobTaskSummary = "Write and test the logic for the {name} job.",
        JobTaskGoal = "Make the {name} job work as designed.",
        JobTaskCreated = "Task created for {name}.",
        JobSaved = "Logic status saved.",
        ErrorJob = "That job no longer exists.",
        ErrorLogicStatus = "That logic status is not valid.",
        FieldColor = "Colour (optional)",
        ColorNone = "No colour",
        TabCalendar = "Calendar",
        CalToday = "Today",
        CalMonth = "Month",
        CalWeek = "Week",
        CalPick = "Schedule a task",
        CalPickNone = "Choose a task to schedule",
        CalFrom = "From (HH:MM)",
        CalTo = "To (HH:MM)",
        CalHint = "Pick a task, then click days to add or remove them. Shift-click adds a range.",
        CalMore = "+{count} more",
        SectionSchedule = "Scheduled days",
        ErrorSchedule = "Those dates or times are not valid.",
        HistoryScheduled = "updated the schedule",
        TabSuggestions = "Suggestions",
        SuggestDialogTitle = "Suggestion",
        SuggestFrom = "From {author}  •  {topic}  •  {score} points",
        SuggestConvert = "Convert to task",
        SuggestOpenTask = "Open task",
        SuggestTaskCreated = "Task created from the suggestion.",
        SuggestNone = "No suggestions in this column.",
        SuggestLinkLabel = "Suggestion",
        ErrorSuggestion = "That suggestion no longer exists.",
        ErrorSuggestionTask = "That suggestion already has a task.",
        ErrorSuggestionsOff = "The Suggestions module is not installed.",
        LauncherJobs ="Job logic overview",
        LauncherJobsHint = "See which jobs have their logic defined and which still need work.",
        LauncherBoard = "Open Workflow",
        LauncherBoardHint = "The task board, your tasks and the completed archive.",
        LauncherButton = "Open"
    }
}

DubzWorkflow.Statuses = {"pending", "todo", "progress", "blocked", "review", "done"}
DubzWorkflow.StatusKeys = {
    pending = "StatusPending", todo = "StatusTodo", progress = "StatusProgress",
    blocked = "StatusBlocked", review = "StatusReview", done = "StatusDone"
}

function DubzWorkflow.Phrase(key, values)
    local text = DubzWorkflow.Config.Text[key] or key

    for name, value in pairs(values or {}) do
        text = string.Replace(text, "{" .. name .. "}", tostring(value))
    end

    return text
end

function DubzWorkflow.PaletteList()
    local list = {}

    for _, entry in ipairs(DubzWorkflow.Config.Palette) do
        local name, red, green, blue = string.match(entry, "^(.-)=#(%x%x)(%x%x)(%x%x)$")

        if name then
            list[#list + 1] = {
                name = name,
                hex = string.lower(string.sub(entry, #name + 2)),
                color = Color(tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16))
            }
        end
    end

    return list
end

function DubzWorkflow.PaletteColor(hex)
    for _, entry in ipairs(DubzWorkflow.PaletteList()) do
        if entry.hex == hex then return entry.color end
    end
end

function DubzWorkflow.Enabled()
    return not (DFW and DFW.Bind) or DFW.Bind.Enabled("workflow")
end

function DubzWorkflow.StatusLabel(status)
    return DubzWorkflow.Phrase(DubzWorkflow.StatusKeys[status] or "StatusTodo")
end
