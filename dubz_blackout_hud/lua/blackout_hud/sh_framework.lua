-- Registers the HUD with the Dubz Framework: every setting in sh_config.lua plus the top bar table appear in the
-- admin config menu (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
local barRows = {}
for _, bar in ipairs(BHUD.DefaultBars) do barRows[#barRows + 1] = {name = bar.name, side = bar.side, enabled = true} end

local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

local specs = {
	{path = "flip", label = "Bar At The Bottom", group = "Layout", description = "Put the top bar at the bottom of the screen."},
	{path = "barHeight", label = "Bar Height", min = 20, max = 60, decimals = 0, group = "Layout"},
	{path = "hideDefaultHunger", label = "Hide Stock Hunger Bar", group = "Layout"},
	{path = "replaceEntityDisplay", label = "Replace DarkRP Overhead / Door Text", group = "Layout",
		description = "On: the HUD draws the name, org and title lines above players and the ownership text on doors."},
	{path = "overheadDistance", label = "Overhead Info Distance", min = 100, max = 2000, decimals = 0, group = "Layout"},

	{path = "lawsKey", label = "Laws Key", keybind = true, group = "Keys"},
	{path = "lawsCooldown", label = "Laws Key Cooldown (Seconds)", min = 0, max = 5, decimals = 1, group = "Keys"},
	{path = "lawsDefaultOpen", label = "Laws Open At Start", group = "Keys"},
	{path = "promptYesKey", label = "Vote / Question: Yes Key", keybind = true, group = "Keys", description = "Answers the oldest vote or question card (the lottery too) with yes."},
	{path = "promptNoKey", label = "Vote / Question: No Key", keybind = true, group = "Keys"},
	{path = "hideDefaultArrest", label = "Hide DarkRP's Arrest Text", group = "Layout", description = "On: DarkRP's own arrested text never draws; the arrest popup and the bar timer show it instead."},
	{path = "cinematicKey", label = "Cinematic Key", keybind = true, group = "Keys",
		description = "Hides the whole HUD and chat for screenshots; press again to bring it back. The weapon wheel still works."},

	{path = "doorDistance", label = "Door Text Distance", min = 50, max = 800, decimals = 0, group = "Doors"},
	{path = "doorScale", label = "Door Text Size", min = 0.05, max = 0.4, decimals = 2, group = "Doors"},
	{path = "doorSurfaceOffset", label = "Door Text Offset", min = 0, max = 5, decimals = 1, group = "Doors",
		description = "How far in front of the door the text floats. Raise it if the text hides inside the door."},

	{path = "wantedDuration", label = "Wanted Time (Seconds)", min = 0, max = 3600, decimals = 0, group = "Wanted",
		description = "How long the wanted countdown runs on the bar. 0 = no countdown."},
	{path = "wantedAutoExpire", label = "Wanted Ends By Itself", group = "Wanted"},

	{path = "mayorTeamName", label = "Mayor Job (Team Constant)", group = "Mayor", maxLength = 40},
	{path = "mayorGraceTime", label = "Mayor Grace Period (Seconds)", min = 0, max = 3600, decimals = 0, group = "Mayor"},
}

for index, name in ipairs(dayNames) do
	specs[#specs + 1] = {path = "dayColors." .. index, label = name .. " Clock Colour", group = "Clock Colours"}
end

DFW.Bind.Module({
	id = "hud",
	name = "HUD",
	version = "2.0.0",
	icon = "darkrp/account_circle",
	description = "The top bar, laws, agenda, popups, ammo, overhead info, door text and death screen.",
	dependencies = {"dubz_core"},
}, BHUD.Config, specs, {
	collections = {
		{
			id = "bars", label = "Top Bar", idKey = "name",
			description = "Every entry on the top bar. Reorder them with the arrows, move one to the other side, or switch it off. Entries hide themselves when they have nothing to show (no armor, not wanted ...).",
			columns = {
				{key = "name", label = "Entry", type = "string", width = 1.4, maxLength = 30},
				{key = "side", label = "Side", type = "choice", choices = {"left", "right"}, width = 1},
				{key = "enabled", label = "Shown", type = "bool", width = 0.8},
			},
			default = barRows,
		},
	},
})

DFW.Collections.Watch("hud", "bars", function(rows)
	BHUD.BarRows = rows
end)
