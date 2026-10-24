-- Registers Scrap with the Dubz Framework: the numbers and the two tables (scrap materials and trash) are edited live in the admin config
-- menu (!dubzconfig > Scrap). The values in sh_config.lua stay the defaults.
local cfg = DubzScrap.Config

DFW.Bind.Module({
	id = "scrap",
	name = "Scrap",
	version = "1.0.0",
	icon = "economy/inventory_2",
	description = "Trash from the dumpsters, scrapped into plastic, metal, cloth, leather and wood for crafting, melting and trading.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "scrapTime", label = "Time To Scrap One (Seconds)", min = 0.5, max = 60, decimals = 1, group = "Scrapping"},
	{path = "accessoryYields", label = "Accessory Scrap Gives", group = "Scrapping", maxLength = 120,
		description = "What scrapping an accessory from the pocket gives, as material=least-most, comma separated."},

	{path = "scavXpBase", label = "Scavenging XP Base", min = 5, max = 5000, decimals = 0, group = "Scavenging Skill", description = "XP to go from level L-1 to L is base x L ^ exponent."},
	{path = "scavXpExponent", label = "Scavenging XP Exponent", min = 1, max = 3, decimals = 2, group = "Scavenging Skill"},
	{path = "searchXpMin", label = "XP Per Dumpster Search: Least", min = 0, max = 1000, decimals = 0, group = "Scavenging Skill"},
	{path = "searchXpMax", label = "XP Per Dumpster Search: Most", min = 0, max = 1000, decimals = 0, group = "Scavenging Skill"},
	{path = "scrapXpMin", label = "XP Per Scrap: Least", min = 0, max = 1000, decimals = 0, group = "Scavenging Skill"},
	{path = "scrapXpMax", label = "XP Per Scrap: Most", min = 0, max = 1000, decimals = 0, group = "Scavenging Skill"},
	{path = "speedPerLevel", label = "Faster Scrapping Per Level (%)", min = 0, max = 20, decimals = 1, group = "Scavenging Skill"},
	{path = "speedMax", label = "Most Faster Scrapping (%)", min = 0, max = 90, decimals = 0, group = "Scavenging Skill"},
	{path = "bonusPerLevel", label = "Extra Scrap Chance Per Level (%)", min = 0, max = 20, decimals = 1, group = "Scavenging Skill"},
	{path = "bonusMax", label = "Most Extra Scrap Chance (%)", min = 0, max = 100, decimals = 0, group = "Scavenging Skill"},
	{path = "luckPerLevel", label = "Better Trash Per Level", min = 0, max = 10, decimals = 1, group = "Scavenging Skill", description = "Evens out the trash odds each level, so rarer trash turns up more often."},
	{path = "extraTrashEvery", label = "Extra Trash Every (Levels)", min = 1, max = 10, decimals = 0, group = "Scavenging Skill", description = "One more piece of trash from each dumpster search every this many levels."},
	{path = "scrapStack", label = "Scrap Per Pocket Slot", min = 1, max = 500, decimals = 0, group = "Pocket"},
	{path = "trashStack", label = "Trash Per Pocket Slot", min = 1, max = 500, decimals = 0, group = "Pocket"},

	{path = "meltScrap", label = "Meltable Scrap", group = "Forge", maxLength = 30, description = "The id of the scrap the forge melts into bars."},
	{path = "meltPerBar", label = "Scrap Per Bar", min = 1, max = 100, decimals = 0, group = "Forge"},
	{path = "meltBar", label = "Bar It Makes", group = "Forge", maxLength = 30, description = "A material id from the Mining materials table (steel)."},

	{path = "labels", label = "Labels Over Scrap", group = "Looks"},
}, {
	OnChange = function(path)
		if path == "scavXpBase" or path == "scavXpExponent" then DubzScrap.RegisterSkill() end
	end,
	collections = {
		{
			id = "materials", label = "Scrap Materials", idKey = "id",
			description = "What scrapping gives: plastic, metal, cloth ... The model, its scale, material and colour are how it looks in the world and in the pocket. Recipes use the name or id (Mining > Recipes: Plastic=3, Metal=2).",
			columns = {
				{key = "id", label = "ID", type = "string", width = 1, maxLength = 30},
				{key = "name", label = "Name", type = "string", width = 1, maxLength = 40},
				{key = "value", label = "Value", type = "number", min = 0, max = 1000000, decimals = 0, width = 0.6},
				{key = "model", label = "Model", type = "string", width = 3, maxLength = 160},
				{key = "scale", label = "Scale", type = "number", min = 0.05, max = 5, decimals = 2, width = 0.6},
				{key = "material", label = "Material", type = "string", width = 2.4, maxLength = 160},
				{key = "color", label = "Colour", type = "color", width = 0.8},
				{key = "enabled", label = "On", type = "bool", width = 0.5},
			},
			default = DubzScrap.DefaultMaterials,
		},
		{
			id = "trash", label = "Trash", idKey = "id",
			description = "What comes out of the dumpsters. Chance is a weight for being the one picked. Yields is what scrapping it gives: material=least-most, comma separated (least 0 = may give none).",
			columns = {
				{key = "id", label = "ID", type = "string", width = 1, maxLength = 30},
				{key = "name", label = "Name", type = "string", width = 1.3, maxLength = 40},
				{key = "model", label = "Model", type = "string", width = 3, maxLength = 160},
				{key = "scale", label = "Scale", type = "number", min = 0.05, max = 5, decimals = 2, width = 0.6},
				{key = "chance", label = "Chance", type = "number", min = 0, max = 100000, decimals = 1, width = 0.7},
				{key = "yields", label = "Yields", type = "string", width = 2.4, maxLength = 120},
				{key = "enabled", label = "On", type = "bool", width = 0.5},
			},
			default = DubzScrap.DefaultTrash,
		},
	},
})

DFW.Collections.Watch("scrap", "materials", function(rows) DubzScrap.BuildMaterials(rows) end)
DFW.Collections.Watch("scrap", "trash", function(rows) DubzScrap.BuildTrash(rows) end)
