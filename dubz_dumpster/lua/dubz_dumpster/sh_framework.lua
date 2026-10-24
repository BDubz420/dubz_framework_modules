-- Registers the dumpsters with the Dubz Framework: settings plus two editable tables (junk props and item drops)
-- in the admin config menu (!dubzconfig). The values in sh_config.lua stay the defaults.
local defaultProps, defaultDrops = {}, {}
for _, model in ipairs(DubzDumpster.DefaultProps) do defaultProps[#defaultProps + 1] = {model = model} end
for _, drop in ipairs(DubzDumpster.DefaultDrops) do defaultDrops[#defaultDrops + 1] = {class = drop[1], chance = drop[2]} end

DFW.Bind.Module({
	id = "dumpsters",
	name = "Dumpsters",
	version = "2.0.0",
	icon = "economy/inventory_2",
	description = "Searchable dumpsters: cooldown, junk, cash and item drops.",
	dependencies = {"dubz_core"},
}, DubzDumpster.Config, {
	{path = "cooldown", label = "Search Cooldown (Seconds)", min = 5, max = 3600, decimals = 0, group = "Searching"},
	{path = "searchTime", label = "Search Takes (Seconds)", min = 0, max = 30, decimals = 1, group = "Searching", description = "How long a search takes, with the hand-in-the-dumpster animation. 0 = instant."},

	{path = "emptyChance", label = "Empty Search Chance (%)", min = 0, max = 100, decimals = 0, group = "Searching", description = "How often a search finds nothing at all."},
	{path = "emptyChancePerLevel", label = "Fewer Empty Searches Per Scavenging Level (%)", min = 0, max = 10, decimals = 1, group = "Searching"},
	{path = "propsMin", label = "Junk Props Per Search: Fewest", min = 0, max = 20, decimals = 0, group = "Junk"},
	{path = "propsAmount", label = "Junk Props Per Search: Most", min = 0, max = 20, decimals = 0, group = "Junk"},
	{path = "propLifetime", label = "Junk Lifetime (Seconds)", min = 5, max = 600, decimals = 0, group = "Junk"},

	{path = "moneyChance", label = "Cash Chance (%)", min = 0, max = 100, decimals = 0, group = "Cash"},
	{path = "moneyMin", label = "Cash Min", min = 0, max = 100000, decimals = 0, group = "Cash"},
	{path = "moneyMax", label = "Cash Max", min = 0, max = 100000, decimals = 0, group = "Cash"},

	{path = "entityRolls", label = "Item Rolls Per Search", min = 0, max = 10, decimals = 0, group = "Items",
		description = "Each roll picks a random row of the Item Drops table and succeeds with that row's chance."},
}, {
	collections = {
		{
			id = "props", label = "Junk Props",
			description = "Models the junk props are picked from.",
			preview = {kind = "model", model = "model"},
			columns = {{key = "model", label = "Model path", type = "string", width = 1, maxLength = 160}},
			default = defaultProps,
		},
		{
			id = "drops", label = "Item Drops",
			description = "Entities a search can drop and each one's chance (percent) when its roll comes up.",
			columns = {
				{key = "class", label = "Entity class", type = "string", width = 2, maxLength = 80, suggest = "entities"},
				{key = "chance", label = "Chance %", type = "number", min = 0, max = 100, decimals = 0, width = 1},
			},
			default = defaultDrops,
		},
		{
			id = "jobs", label = "Allowed Jobs", idKey = "job",
			description = "Only these jobs may search a dumpster. Leave the table empty to let every job search.",
			columns = {{key = "job", label = "Job name", type = "string", width = 1, maxLength = 60, suggest = "jobs"}},
			default = DFW.Collections.RowsFromSet(DubzDumpster.Config.jobs, "job"),
		},
	},
})

DFW.Collections.Watch("dumpsters", "jobs", function(rows)
	DubzDumpster.Config.jobs = DFW.Collections.SetFromRows(rows, "job")
end)

DFW.Collections.Watch("dumpsters", "props", function(rows)
	local list = {}
	for _, row in ipairs(rows) do
		if row.model ~= "" then list[#list + 1] = row.model end
	end
	DubzDumpster.Props = list
end)

DFW.Collections.Watch("dumpsters", "drops", function(rows)
	local list = {}
	for _, row in ipairs(rows) do
		if row.class ~= "" then list[#list + 1] = {class = row.class, chance = row.chance} end
	end
	DubzDumpster.Drops = list
end)
