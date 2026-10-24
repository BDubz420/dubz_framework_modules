-- Registers Karma and commends with the Dubz Framework: every setting in sh_config.lua appears in the admin
-- config menu (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
DFW.Bind.Module({
	id = "karma",
	name = "Karma & Commends",
	version = "1.0.0",
	icon = "players/smile",
	description = "Karma from kills, arrests and play time, and the daily commend allowance.",
	dependencies = {"dubz_core"},
}, DubzKarma.Config, {
	{path = "start", label = "Starting Karma", min = 0, max = 500, decimals = 0, group = "Range"},
	{path = "min", label = "Minimum Karma", min = 0, max = 500, decimals = 0, group = "Range"},
	{path = "max", label = "Maximum Karma", min = 1, max = 1000, decimals = 0, group = "Range"},

	{path = "killPlayer", label = "Killing A Player", min = -100, max = 100, decimals = 0, group = "Karma Changes",
		description = "Applied when you kill a player who wasn't wanted."},
	{path = "killWanted", label = "Killing A Wanted Player", min = -100, max = 100, decimals = 0, group = "Karma Changes"},
	{path = "arrestWanted", label = "Arresting A Criminal", min = -100, max = 100, decimals = 0, group = "Karma Changes"},
	{path = "playBonus", label = "Play Time Bonus", min = -50, max = 50, decimals = 0, group = "Karma Changes",
		description = "Karma gained for every interval below, while alive."},
	{path = "playBonusInterval", label = "Play Time Interval (Seconds)", min = 60, max = 7200, decimals = 0, group = "Karma Changes"},

	{path = "commendCooldown", label = "Commend Cooldown (Seconds)", min = 0, max = 7200, decimals = 0, group = "Commends",
		description = "Before the same player can commend the same target again."},
	{path = "commendsPerDay", label = "Commends Per Day", min = 0, max = 20, decimals = 0, group = "Commends"},

	{path = "healWindow", label = "Heal Window (Seconds)", min = 10, max = 600, decimals = 0, group = "Everyday Karma",
		description = "After using a healing entity while hurt, how long you have to reach full health for the healing karma to count."},
}, {
	collections = {
		{
			id = "sources", label = "Karma Sources",
			description = "Everyday ways to earn (or lose) karma: buying an entity, healing at a station, cooking. This is how raiders earn their karma back. Entity class names are the ones DarkRP uses (check them with the suggestions).",
			columns = {
				{key = "event", label = "When", type = "choice", choices = {"bought", "healed", "cooked"}, width = 1},
				{key = "class", label = "Entity class", type = "string", width = 1.8, maxLength = 80, suggest = "entities"},
				{key = "karma", label = "Karma", type = "number", min = -100, max = 100, decimals = 0, width = 0.7},
				{key = "who", label = "Who earns it", type = "choice", choices = {"actor", "owner"}, width = 1},
				{key = "cooldown", label = "Cooldown (s)", type = "number", min = 0, max = 86400, decimals = 0, width = 0.9},
				{key = "note", label = "Message", type = "string", width = 1.8, maxLength = 60},
			},
			default = DubzKarma.DefaultSources,
		},
	},
	OnChange = function(path, value)
		-- The play-time timer was created at load; retime it when its interval changes
		if SERVER and path == "playBonusInterval" and timer.Exists("DubzKarma_PlayBonus") then
			timer.Adjust("DubzKarma_PlayBonus", value)
		end
	end
})

DFW.Collections.Watch("karma", "sources", function(rows)
	DubzKarma.Sources = rows
end)
