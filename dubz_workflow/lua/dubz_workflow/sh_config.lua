DubzWorkflow.Config = {
    ConsoleCommand = "dubz_workflow",

    StaffMode = "admin",

    DefaultWorking = true,
    JoinPopupDelay = 8,
    ReminderMinutes = 20,
    ShowServerTime = false,

    DefaultPriority = "normal",
    TitleMax = 80,
    SummaryMax = 200,
    InstructionsMax = 3000,
    NoteMax = 1000,
    ChecklistMax = 20,
    TagMax = 8,
    HistoryMax = 40,
    LinkMax = 6,

    ScheduleMax = 31,
    TimeMinuteStep = 5,
    ConvertSetsPlanned = true,
    SuggestionDialogWidth = 640,
    SuggestionDialogHeight = 560,
    JobDialogWidth = 720,
    JobDialogHeight = 480,

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
        JobNote = "What this job still needs",
        JobNotePlaceholder = "Describe what the job logic needs, or what is already done.",
        JobLinkedTask = "Linked task",
        JobNoTask = "No linked task",
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
        PickerTimes = "Choose times",
        PickerDays = "Pick days",
        PickerDate = "Pick a date",
        TimeFrom = "From",
        TimeTo = "To",
        TimeNotSet = "Not set",
        TimesButton = "Times",
        TimesNone = "Any time",
        Done = "Done",
        ClearAll = "Clear",
        FieldSchedule = "Scheduled days",
        PickDays = "Pick days",
        PickDate = "Pick date",
        NoDate = "No date",
        NoDays = "No days picked",
        SortPriority = "Priority, highest first",
        SortNewest = "Newest first",
        SortDue = "Due date",
        FilterAll = "All priorities",
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

DubzWorkflow.Lists = {
    chat_commands = {"!workflow", "/workflow", "!tasks", "/tasks"},
    staff_ranks = {},
    staff_steamids = {},
    manager_ranks = {},
    priorities = {"low", "normal", "high", "urgent"},
    logic_statuses = {"Undefined", "Needs logic", "In progress", "Defined", "Completed"},
    job_task_steps = {"Decide what this job can and cannot do.", "Write the logic for it.", "Test it in game."}
}

DubzWorkflow.PaletteDefault = {
    {name = "Red", hex = "#e5484d"},
    {name = "Orange", hex = "#f76b15"},
    {name = "Yellow", hex = "#ffc53d"},
    {name = "Green", hex = "#30a46c"},
    {name = "Blue", hex = "#3e63dd"},
    {name = "Purple", hex = "#8e4ec6"},
    {name = "Pink", hex = "#d6409f"}
}

function DubzWorkflow.List(id, lower)
    local module = DFW and DFW.Collections

    if module and module.GetDefinition("workflow", id) then
        return module.ListFromRows(module.Get("workflow", id), "value", lower)
    end

    local list = {}

    for _, value in ipairs(DubzWorkflow.Lists[id] or {}) do list[#list + 1] = lower and string.lower(value) or value end

    return list
end

function DubzWorkflow.PaletteList()
    local module = DFW and DFW.Collections
    local rows = module and module.GetDefinition("workflow", "palette") and module.Get("workflow", "palette") or DubzWorkflow.PaletteDefault
    local list = {}

    for _, row in ipairs(rows) do
        local red, green, blue = string.match(tostring(row.hex), "^#(%x%x)(%x%x)(%x%x)$")

        if red and tostring(row.name) ~= "" then
            list[#list + 1] = {
                name = row.name,
                hex = string.lower(row.hex),
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
