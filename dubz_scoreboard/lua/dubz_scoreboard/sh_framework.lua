-- Registers the scoreboard with the Dubz Framework: its settings and the ranks table appear in the admin config
-- menu (!dubzconfig). The values in sh_config.lua stay the defaults.
local defaultRows = {}
for _, row in ipairs(DubzScoreboard.DefaultGroups) do defaultRows[#defaultRows + 1] = table.Copy(row) end

DFW.Bind.Module({
	id = "scoreboard",
	name = "Scoreboard",
	version = "2.0.0",
	icon = "players/groups",
	description = "The TAB scoreboard: title, size, columns, ordering and staff buttons.",
	dependencies = {"dubz_core"},
}, DubzScoreboard.Config, {
	{path = "serverName", label = "Server Name", group = "Look", maxLength = 80, description = "Shown at the top of the scoreboard."},
	{path = "scale", label = "Size", min = 0.5, max = 1.2, decimals = 2, group = "Look", description = "1 = full size. Takes effect the next time you open it."},

	{path = "showGang", label = "Show Organisation", group = "Columns"},
	{path = "showJob", label = "Show Job", group = "Columns"},
	{path = "showMoney", label = "Show Money", group = "Columns"},
	{path = "showKD", label = "Show Kills / Deaths", group = "Columns"},
	{path = "showPing", label = "Show Ping", group = "Columns"},
	{path = "showRanks", label = "Show Ranks After Names", group = "Columns", description = "Uses the Ranks table."},

	{path = "sortBy", label = "Order Players By", choices = {"money", "name", "job", "ping"}, group = "Order"},
}, {
	collections = {
		{
			id = "groups", label = "Ranks", idKey = "id",
			description = "User group, the name shown for it and its colour.",
			preview = {kind = "chip", text = "name", color = "color"},
			columns = {
				{key = "id", label = "User group", type = "string", width = 1.4, maxLength = 40, suggest = "usergroups"},
				{key = "name", label = "Shown as", type = "string", width = 1.6, maxLength = 40},
				{key = "color", label = "Colour", type = "color", width = 0.8},
			},
			default = defaultRows,
		},
		{
			id = "staff", label = "Staff Groups", idKey = "group",
			description = "User groups that see the Go-To / Bring / Freeze / Jail / Spectate buttons when they open a player on the scoreboard.",
			columns = {
				{key = "group", label = "User group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"},
			},
			default = DFW.Collections.RowsFromSet(DubzScoreboard.Config.staffGroups, "group"),
		},
	},
	ui = true,
})

DFW.Collections.Watch("scoreboard", "staff", function(rows)
	DubzScoreboard.Config.staffGroups = DFW.Collections.SetFromRows(rows, "group")
end)

DFW.Collections.Watch("scoreboard", "groups", function(rows)
	local map = {}
	for _, row in ipairs(rows) do map[string.lower(row.id)] = {name = row.name, color = row.color} end
	DubzScoreboard.Groups = map
end)
