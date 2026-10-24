local config = DubzSuggestions.Config

local specs = {
    {path = "AllowAnonymous", label = "Allow Anonymous Suggestions", group = "Submitting",
        description = "Shows a Submit anonymously switch. Other players see Anonymous."},
    {path = "HideAuthorFromStaff", label = "Hide Anonymous Authors From Staff", group = "Submitting",
        description = "When on, staff cannot see who sent an anonymous suggestion either."},
    {path = "AllowCustomTopic", label = "Allow Custom Topics", group = "Submitting"},
    {path = "TitleMin", label = "Title Minimum Length", min = 1, max = 100, decimals = 0, group = "Submitting", public = false},
    {path = "TitleMax", label = "Title Maximum Length", min = 10, max = 200, decimals = 0, group = "Submitting"},
    {path = "BodyMin", label = "Details Minimum Length", min = 1, max = 500, decimals = 0, group = "Submitting", public = false},
    {path = "BodyMax", label = "Details Maximum Length", min = 50, max = 2000, decimals = 0, group = "Submitting"},
    {path = "TopicMax", label = "Custom Topic Maximum Length", min = 5, max = 64, decimals = 0, group = "Submitting"},
    {path = "CooldownSeconds", label = "Cooldown Between Suggestions (Seconds)", min = 0, max = 3600, decimals = 0, group = "Submitting", public = false},
    {path = "MaxOpenPerPlayer", label = "Most Waiting Suggestions Per Player", min = 1, max = 50, decimals = 0, group = "Submitting", public = false},

    {path = "AutoApprove", label = "Approve Automatically", group = "Moderation", public = false,
        description = "When off, every suggestion waits for staff approval before other players can see it."},
    {path = "WordFilter", label = "Word Filter", list = true, group = "Moderation", maxLength = 200, public = false,
        description = "Suggestions containing any of these words are held for approval even when auto-approve is on."},
    {path = "AllowOwnVote", label = "Allow Voting On Your Own Suggestion", group = "Moderation", public = false},
    {path = "VoteCooldown", label = "Vote Cooldown (Seconds)", min = 0.1, max = 10, decimals = 1, group = "Moderation", public = false,
        description = "Changes need a restart."},
    {path = "PingMode", label = "Staff Ping Without Workflow", choices = {"all", "none"}, group = "Moderation", public = false,
        description = "Who is told about a new suggestion when the Workflow module is not installed. With Workflow, only staff who are working are told."},

    {path = "ChatCommands", label = "Chat Commands", list = true, group = "Commands", maxLength = 120,
        description = "Typed in chat to open the suggestion window. Include the ! or / prefix."},
    {path = "ConsoleCommand", label = "Console Command", group = "Commands", maxLength = 30,
        description = "Lowercase, no spaces. Changes need a restart."},
    {path = "AdminCommand", label = "Approval Queue Console Command", group = "Commands", maxLength = 40,
        description = "Lowercase, no spaces. Changes need a restart."},

    {path = "WindowWidth", label = "Window Width", min = 800, max = 2000, decimals = 0, group = "Window"},
    {path = "WindowHeight", label = "Window Height", min = 500, max = 1300, decimals = 0, group = "Window"},
    {path = "PublicWidth", label = "Community List Width", min = 300, max = 800, decimals = 0, group = "Window"},
    {path = "AdminWidth", label = "Approval Window Width", min = 700, max = 2000, decimals = 0, group = "Window"},
    {path = "AdminHeight", label = "Approval Window Height", min = 450, max = 1300, decimals = 0, group = "Window"}
}

for key in SortedPairs(config.Text) do
    specs[#specs + 1] = {path = "Text." .. key, label = "Text: " .. key, group = "Text", maxLength = 120}
end

local function launchers()
    local text = DubzSuggestions.Phrase

    return {
        {
            label = text("LauncherPlayer"),
            description = text("LauncherPlayerHint"),
            button = text("LauncherButton"),
            fn = function() DubzSuggestions.Open() end
        },
        {
            label = text("LauncherAdmin"),
            description = text("LauncherAdminHint"),
            button = text("LauncherButton"),
            fn = function() DubzSuggestions.OpenAdmin() end
        }
    }
end

DFW.Bind.Module({
    id = "suggestions",
    name = "Suggestions",
    version = "0.1.0",
    icon = "communication/forum",
    description = "Players submit and vote on suggestions. Staff approve them before they go public.",
    dependencies = {"dubz_core"},
    launchers = launchers()
}, config, specs, {
    ui = true,
    collections = {
        {
            id = "topics",
            label = "Topics",
            description = "Your own topics. Player-facing modules that opt in add theirs automatically.",
            idKey = "id",
            columns = {
                {key = "id", label = "ID", type = "string", width = 1, maxLength = 30},
                {key = "label", label = "Label", type = "string", width = 2, maxLength = 32}
            },
            default = {
                {id = "rules", label = "Rules"},
                {id = "events", label = "Events"},
                {id = "bugs", label = "Bugs"},
                {id = "other", label = "Other"}
            }
        }
    }
})
