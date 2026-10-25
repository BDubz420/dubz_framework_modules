DubzSuggestions.Config = {
    ConsoleCommand = "dubz_suggest",
    AdminCommand = "dubz_suggestions_admin",

    AllowAnonymous = true,
    HideAuthorFromStaff = false,
    AutoApprove = false,
    AllowOwnVote = false,
    AllowCustomTopic = true,
    PingMode = "all",

    TitleMin = 4,
    TitleMax = 80,
    BodyMin = 10,
    BodyMax = 800,
    TopicMax = 32,
    CooldownSeconds = 60,
    MaxOpenPerPlayer = 5,
    VoteCooldown = 0.4,

    WindowWidth = 1180,
    WindowHeight = 700,
    PublicWidth = 440,
    AdminWidth = 980,
    AdminHeight = 700,

    Text = {
        WindowTitle = "Suggestions",
        WindowSubtitle = "Share an idea and vote on other people's",
        SubmitTitle = "Submit a suggestion",
        PublicTitle = "Community suggestions",
        FieldTopic = "Topic",
        FieldTitle = "Title",
        FieldDetails = "Details",
        FieldCustomTopic = "Your topic",
        TitlePlaceholder = "A short summary",
        DetailsPlaceholder = "Explain your idea...",
        CustomTopicOption = "Custom topic...",
        Anonymous = "Submit anonymously",
        Submit = "Submit",
        Counter = "{used}/{max}",
        SortTop = "Top",
        SortNew = "New",
        AllTopics = "All topics",
        NoSuggestions = "No suggestions yet.",
        Loading = "Loading...",
        ByAuthor = "by {name}",
        AnonymousName = "Anonymous",
        Points = "{score} points",
        Submitted = "Thanks! Your suggestion was sent for review.",
        SubmittedPublic = "Thanks! Your suggestion is now live.",
        ErrorTitle = "Please give your suggestion a title of {min} to {max} characters.",
        ErrorBody = "Please describe it in {min} to {max} characters.",
        ErrorTopic = "Please choose a topic.",
        ErrorCooldown = "Please wait {seconds} seconds before sending another.",
        ErrorLimit = "You already have {max} suggestions waiting.",
        ErrorDisabled = "Suggestions are switched off.",
        ErrorVote = "You can't vote on that.",
        ErrorOwnVote = "You can't vote on your own suggestion.",
        ErrorAccess = "You do not have access to moderate suggestions.",
        ErrorMissing = "That suggestion no longer exists.",
        Ping = "A new suggestion has just been given.",
        StatusPending = "Pending",
        StatusNew = "Open",
        StatusReview = "Under review",
        StatusPlanned = "Planned",
        StatusDone = "Done",
        StatusDeclined = "Declined",
        StatusHidden = "Hidden",
        AdminTitle = "Suggestion Approval",
        AdminSubtitle = "{count} waiting for approval",
        AdminEmpty = "Nothing here.",
        AdminMeta = "{author}  {topic}  {score} points  {date}",
        Approve = "Approve",
        Reject = "Reject",
        Hide = "Hide",
        Delete = "Delete",
        Reopen = "Reopen",
        MarkReview = "Under review",
        MarkPlanned = "Planned",
        MarkDone = "Done",
        Moderated = "Updated.",
        Deleted = "Deleted.",
        LauncherPlayer = "Open the suggestion window",
        LauncherPlayerHint = "Submit an idea and vote on suggestions, the same window players use.",
        LauncherAdmin = "Suggestion approval queue",
        LauncherAdminHint = "Approve, reject and sort suggestions before they go public.",
        LauncherButton = "Open"
    }
}

function DubzSuggestions.Phrase(key, values)
    local text = DubzSuggestions.Config.Text[key] or key

    for name, value in pairs(values or {}) do
        text = string.Replace(text, "{" .. name .. "}", tostring(value))
    end

    return text
end

DubzSuggestions.Lists = {
    chat_commands = {"!suggestion", "/suggestion", "!suggest", "/suggest"},
    word_filter = {}
}

function DubzSuggestions.List(id, lower)
    local module = DFW and DFW.Collections

    if module and module.GetDefinition("suggestions", id) then
        return module.ListFromRows(module.Get("suggestions", id), "value", lower)
    end

    local list = {}

    for _, value in ipairs(DubzSuggestions.Lists[id] or {}) do list[#list + 1] = lower and string.lower(value) or value end

    return list
end

function DubzSuggestions.Enabled()
    return not (DFW and DFW.Bind) or DFW.Bind.Enabled("suggestions")
end
