-- Registers the New Life Rule with the Dubz Framework: every setting in sh_config.lua appears in the admin
-- config menu (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
DFW.Bind.Module({
	id = "nlr",
	name = "New Life Rule",
	version = "1.0.0",
	icon = "admin/shield",
	description = "NLR timer after death, the zone around where you died, and the OOC lines when you enter or leave it.",
	dependencies = {"dubz_core"},
}, DubzNLR.Config, {
	{path = "time", label = "NLR Time (Seconds)", min = 10, max = 1800, decimals = 0, group = "Rule",
		description = "How long after dying the New Life Rule applies."},
	{path = "zoneRadius", label = "Zone Radius", min = 200, max = 6000, decimals = 0, group = "Rule",
		description = "Units around where you died that count as your NLR zone."},
	{path = "checkInterval", label = "Check Interval (Seconds)", min = 0.2, max = 10, decimals = 1, group = "Rule"},

	{path = "announce", label = "Announce In OOC", group = "OOC Lines",
		description = "Entering the zone makes the player say a line in OOC chat, as if they typed it."},
	{path = "enterDelay", label = "Enter Delay (Seconds)", min = 0, max = 30, decimals = 1, group = "OOC Lines",
		description = "How long they must stay inside before the line goes out."},
	{path = "alertCooldown", label = "Alert Cooldown (Seconds)", min = 0, max = 600, decimals = 0, group = "OOC Lines"},
	{path = "chatPrefix", label = "OOC Command", group = "OOC Lines", description = "DarkRP's OOC command: // or /ooc"},
	{path = "enterMessage", label = "Entered Line", group = "OOC Lines"},
	{path = "leaveMessage", label = "Left Line", group = "OOC Lines"},
}, {
	OnChange = function(path, value)
		if SERVER and path == "checkInterval" and timer.Exists("DubzNLR_Watch") then
			timer.Adjust("DubzNLR_Watch", value)
		end
	end
})
