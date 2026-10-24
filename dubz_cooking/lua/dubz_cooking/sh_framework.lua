-- Registers Cooking with the Dubz Framework: every setting in sh_config.lua appears in the admin config menu
-- (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
-- Karma for cooking is set in the Karma module's "Karma Sources" table (event: cooked).
DFW.Bind.Module({
	id = "cooking",
	name = "Cooking",
	version = "2.0.0",
	icon = "economy/storefront",
	description = "The cook's stove, donuts and golden donuts.",
	dependencies = {"dubz_core"},
}, DubzCooking.Config, {
	{path = "cookSeconds", label = "Cook Time (Seconds)", min = 3, max = 600, decimals = 0, group = "Stove",
		description = "How long a batch takes once the milk and ingredients are in."},

	{path = "donutEnergy", label = "Donut: Energy", min = 0, max = 100, decimals = 0, group = "Donuts"},
	{path = "donutHealth", label = "Donut: Health", min = 0, max = 100, decimals = 0, group = "Donuts"},

	{path = "goldenChance", label = "Golden Donut Odds (1 in N)", min = 0, max = 100000, decimals = 0, group = "Golden Donuts",
		description = "0 turns golden donuts off."},
	{path = "goldenClass", label = "Golden Donut Entity", group = "Golden Donuts", maxLength = 60},
	{path = "goldenEnergy", label = "Golden: Energy", min = 0, max = 100, decimals = 0, group = "Golden Donuts"},
	{path = "goldenHealth", label = "Golden: Health", min = 0, max = 100, decimals = 0, group = "Golden Donuts"},
})
