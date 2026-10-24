-- Registers Characters with the Dubz Framework: start screen text, slots, name rules and the lists in the admin
-- config menu (!dubzconfig). The values in sh_config.lua stay the defaults.
local cfg = DubzChars.Config

DFW.Bind.Module({
	id = "characters",
	name = "Characters",
	version = "1.0.0",
	icon = "players/face",
	description = "The start screen: pick or create a character (name, model, starting outfit) before spawning.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "serverName", label = "Logo Text", group = "Start Screen", maxLength = 30},
	{path = "serverTag", label = "Logo Tag", group = "Start Screen", maxLength = 10, description = "The small grey text next to the logo."},
	{path = "subtitle", label = "Subtitle", group = "Start Screen", maxLength = 40},
	{path = "footer", label = "Footer Line", group = "Start Screen", maxLength = 120},
	{path = "discordUrl", label = "Discord Link", group = "Start Screen", maxLength = 200},
	{path = "blur", label = "Background Blur", min = 0, max = 10, decimals = 0, group = "Start Screen"},
	{path = "musicUrl", label = "Music Link", group = "Start Screen", maxLength = 240,
		description = "Direct link to an audio file played while the menu is open. Empty = silence."},
	{path = "musicVolume", label = "Music Volume", min = 0, max = 1, decimals = 2, group = "Start Screen"},

	{path = "slotsNormal", label = "Character Slots", min = 1, max = 10, decimals = 0, group = "Slots"},
	{path = "slotsPremium", label = "Premium Character Slots", min = 1, max = 10, decimals = 0, group = "Slots"},

	{path = "deleteMode", label = "Deleting A Character", choices = {"wipe", "archive"}, group = "Slots",
		description = "wipe: erases the character and all its saved data for good. archive: hides it so staff can restore it."},
	{path = "switchEnabled", label = "Switch Characters In Game", group = "Slots", description = "Let players change character (or make another) with the chat command, without rejoining."},
	{path = "switchCommand", label = "Switch Command", group = "Slots", maxLength = 30},
	{path = "switchCooldown", label = "Seconds Between Switches", min = 0, max = 3600, decimals = 0, group = "Slots"},

	{path = "nameMin", label = "Shortest Name Part", min = 1, max = 10, decimals = 0, group = "Names"},
	{path = "nameMax", label = "Longest Name Part", min = 4, max = 30, decimals = 0, group = "Names"},
	{path = "uniqueNames", label = "Unique Names", group = "Names", description = "No two characters can share the same full name."},

	{path = "welcomeEnabled", label = "Welcome Screen", group = "Welcome", description = "Show the welcome screen the first time a character spawns in."},
	{path = "logo", label = "Logo", group = "Welcome", maxLength = 120, description = "Material path of the picture shown at the top of the character screen (empty = the written server name)."},
	{path = "logoHeight", label = "Logo Height", group = "Welcome", min = 40, max = 400, decimals = 0},
	{path = "welcomeEveryTime", label = "Welcome Every Time", group = "Welcome", description = "Show the welcome screen each time a character is picked (off: only the first time for each character)."},
	{path = "welcomeTitle", label = "Welcome Title", group = "Welcome", maxLength = 60},
	{path = "welcomeCommand", label = "Welcome Command", group = "Welcome", maxLength = 30, description = "Chat command that opens it again."},
	{path = "welcomeShowControls", label = "Controls Page", group = "Welcome", description = "Adds a page with the key binds from the F4 How To Play table."},
	{path = "welcomeShowRules", label = "Rules Page", group = "Welcome", description = "Adds a page with the F4 rules."},
}, {
	ui = true,
	collections = {
		{
			id = "starter_outfits", label = "Starter Outfits", idKey = "outfit",
			description = "Clothing sets a new character can start in, in the order shown. The first is the default.",
			columns = {{key = "outfit", label = "Clothing set id", type = "string", width = 1, maxLength = 40, suggest = "clothing_sets"}},
			default = DubzChars.DefaultStarterOutfits,
		},
		{
			id = "welcome_text", label = "Welcome Text",
			description = "The welcome screen's paragraphs. Each row is one paragraph on the page named in 'Page' (pages show up in the order they first appear). Keep a paragraph under about 240 characters.",
			columns = {
				{key = "page", label = "Page", type = "string", width = 1.2, maxLength = 30},
				{key = "text", label = "Paragraph", type = "string", width = 4, maxLength = 240},
			},
			default = DubzChars.DefaultWelcome,
		},
		{
			id = "blocked_words", label = "Blocked Name Words", idKey = "word",
			description = "Names containing any of these words are refused.",
			columns = {{key = "word", label = "Word", type = "string", width = 1, maxLength = 30}},
			default = DubzChars.DefaultBlocked,
		},
		{
			id = "premium_groups", label = "Premium Groups", idKey = "group",
			description = "User groups that get the premium number of character slots.",
			columns = {{key = "group", label = "User group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"}},
			default = DubzChars.DefaultPremium,
		},
	},
})

DFW.Collections.Watch("characters", "starter_outfits", function(rows) DubzChars.StarterOutfits = DFW.Collections.ListFromRows(rows, "outfit") end)
DFW.Collections.Watch("characters", "welcome_text", function(rows) DubzChars.Welcome = rows end)
DFW.Collections.Watch("characters", "blocked_words", function(rows) DubzChars.Blocked = DFW.Collections.ListFromRows(rows, "word") end)
DFW.Collections.Watch("characters", "premium_groups", function(rows)
	DubzChars.PremiumGroups = {}
	for _, row in ipairs(rows) do DubzChars.PremiumGroups[string.lower(row.group)] = true end
end)
