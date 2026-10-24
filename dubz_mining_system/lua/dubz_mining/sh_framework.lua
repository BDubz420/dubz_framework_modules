-- Registers Mining with the Dubz Framework: every number and every list (materials, rocks, recipes) is
-- edited live in the admin config menu (!dubzconfig > Mining). The values in sh_config.lua stay the defaults.
local cfg = DubzMining.Config

local function skillOnChange()
	if DubzMining.RegisterSkill then DubzMining.RegisterSkill() end
end

DFW.Bind.Module({
	id = "mining",
	name = "Mining",
	version = "2.0.0",
	icon = "economy/diamond",
	description = "Rocks to break, gems and ore to find, a forge, a crafting table and a buyer. Gems and ingots show their colour in the pocket.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "gemModel", label = "Gem Model", group = "Models", maxLength = 160},
	{path = "gemScale", label = "Gem Scale", group = "Models", min = 0.05, max = 3, decimals = 2, description = "Size of a gem in the world (1 = the model's own size). Used by newly spawned gems."},
	{path = "ingotModel", label = "Ingot Model", group = "Models", maxLength = 160},
	{path = "stoneModel", label = "Ore Chunk Model", group = "Models", maxLength = 160},
	{path = "forgeModel", label = "Forge Model", group = "Models", maxLength = 160, description = "Used by newly spawned forges."},
	{path = "craftingModel", label = "Crafting Table Model", group = "Models", maxLength = 160},
	{path = "cartModel", label = "Minecart Model", group = "Models", maxLength = 160},
	{path = "shine", label = "Gem / Ingot Material", group = "Models", maxLength = 120,
		description = "Put on gems and ingots so their colour shows as a gem or a metal (empty = the plain model). The pocket draws it too."},

	{path = "rockHealth", label = "Rock Health", min = 10, max = 5000, decimals = 0, group = "Rocks"},
	{path = "rockRespawnTime", label = "Rock Respawn (Seconds)", min = 5, max = 3600, decimals = 0, group = "Rocks"},
	{path = "rockDrawDistance", label = "Health Bar Distance", min = 50, max = 1000, decimals = 0, group = "Rocks"},
	{path = "otherToolDamage", label = "Other Tools' Damage", min = 1, max = 100, decimals = 0, group = "Rocks",
		description = "Rock health taken by a hit from a tool in the list below (the pickaxe uses the damage of the player's Mining level)."},
	{path = "miningTools", label = "Tools That Break Rocks", list = true, group = "Rocks", maxLength = 200, description = "Weapon classes, comma separated."},

	{path = "stoneMin", label = "Ore Chunks: Fewest", min = 0, max = 20, decimals = 0, group = "Drops"},
	{path = "stoneMax", label = "Ore Chunks: Most", min = 0, max = 20, decimals = 0, group = "Drops"},
	{path = "gemMin", label = "Gems: Fewest", min = 0, max = 20, decimals = 0, group = "Drops"},
	{path = "gemMax", label = "Gems: Most", min = 0, max = 20, decimals = 0, group = "Drops"},
	{path = "despawnTime", label = "Loose Drops Vanish After (Seconds)", min = 10, max = 3600, decimals = 0, group = "Drops"},
	{path = "xpMin", label = "XP Per Rock: Least", min = 0, max = 1000, decimals = 0, group = "Drops"},
	{path = "xpMax", label = "XP Per Rock: Most", min = 0, max = 1000, decimals = 0, group = "Drops"},
	{path = "smeltXpMin", label = "XP Per Smelt: Least", min = 0, max = 1000, decimals = 0, group = "Drops"},
	{path = "smeltXpMax", label = "XP Per Smelt: Most", min = 0, max = 1000, decimals = 0, group = "Drops"},

	{path = "damageBase", label = "Swing Damage At Level 0", min = 1, max = 100, decimals = 0, group = "Mining Skill",
		description = "Rock health a pickaxe swing takes off for a player with no Mining levels."},
	{path = "damagePerLevel", label = "Swing Damage Per Mining Level", min = 0, max = 20, decimals = 2, group = "Mining Skill"},
	{path = "swingSpeedPerLevel", label = "Faster Swings Per Mining Level (%)", min = 0, max = 20, decimals = 1, group = "Mining Skill"},
	{path = "swingSpeedMax", label = "Most Faster Swings (%)", min = 0, max = 90, decimals = 0, group = "Mining Skill"},
	{path = "bonusChancePerLevel", label = "Bonus Ore Chance Per Mining Level (%)", min = 0, max = 20, decimals = 2, group = "Mining Skill",
		description = "Each Mining level adds this chance that a rock drops an extra ore chunk."},
	{path = "bonusChanceMax", label = "Most Bonus Ore Chance (%)", min = 0, max = 100, decimals = 0, group = "Mining Skill"},
	{path = "swingDelay", label = "Swing Delay (Seconds)", min = 0.2, max = 5, decimals = 2, group = "Pickaxe"},
	{path = "hitDelay", label = "Hit Lands After (Seconds)", min = 0.05, max = 2, decimals = 2, group = "Pickaxe"},

	{path = "xpBase", label = "Mining XP Base", min = 10, max = 5000, decimals = 0, group = "Mining Skill",
		description = "XP to go from level L-1 to L is base x L ^ exponent."},
	{path = "xpExponent", label = "Mining XP Exponent", min = 1, max = 3, decimals = 2, group = "Mining Skill"},

	{path = "craftXpBase", label = "Crafting XP Base", min = 5, max = 5000, decimals = 0, group = "Crafting Skill"},
	{path = "craftXpExponent", label = "Crafting XP Exponent", min = 1, max = 3, decimals = 2, group = "Crafting Skill"},

	{path = "stackSize", label = "Pocket Stack Size", min = 1, max = 500, decimals = 0, group = "Pocket",
		description = "How many of one gem, ingot or ore chunk fit in a pocket slot."},

	{path = "buyerRefresh", label = "Price Change Every (Seconds)", min = 10, max = 3600, decimals = 0, group = "Foreman"},
	{path = "buyerMinMultiplier", label = "Lowest Price Multiplier", min = 0.1, max = 5, decimals = 2, group = "Foreman"},
	{path = "buyerMaxMultiplier", label = "Highest Price Multiplier", min = 0.1, max = 10, decimals = 2, group = "Foreman"},
	{path = "foremanRate", label = "Foreman Pays (% Of Price)", min = 1, max = 100, decimals = 0, group = "Foreman",
		description = "The mining foreman buys everything in your pocket at this percent of the going price. His name is set in Jobs > Job Sites."},
	{path = "oreValue", label = "Ore Chunk Value (% Of Ingot)", min = 1, max = 100, decimals = 0, group = "Foreman"},
	{path = "cartRentFee", label = "Minecart Rent", min = 0, max = 100000, decimals = 0, group = "Foreman",
		description = "What the foreman charges for each rental period a minecart is out."},
	{path = "cartRentMinutes", label = "Rent Period (Minutes)", min = 1, max = 1440, decimals = 0, group = "Foreman"},
	{path = "craftTime", label = "Craft Takes (Seconds)", min = 0, max = 60, decimals = 1, group = "Crafting", description = "The base time for a craft (the hands-at-work animation). 0 = instant."},
	{path = "craftTimePerLevel", label = "Extra Seconds Per Recipe Level", min = 0, max = 10, decimals = 2, group = "Crafting"},
	{path = "craftingTitle", label = "Crafting Table Title", group = "Crafting", maxLength = 60},
	{path = "useDistance", label = "Window Stays Open Within", min = 80, max = 600, decimals = 0, group = "Crafting"},
}, {
	ui = true,
	OnChange = function(path)
		if path == "xpBase" or path == "xpExponent" or path == "craftXpBase" or path == "craftXpExponent" then skillOnChange() end
	end,
	collections = {
		{
			id = "materials", label = "Materials", idKey = "id",
			description = "Every gem and ingot. kind: gem (found in rocks) or ingot (smelted from ore). Chance is a weight for being picked; price is what the buyer pays; forge is seconds in the forge. The colour is how it looks in the world and in the pocket. Recipes and ore use the name or id.",
			columns = {
				{key = "id", label = "ID", type = "string", width = 1, maxLength = 30},
				{key = "name", label = "Name", type = "string", width = 1.2, maxLength = 40},
				{key = "kind", label = "Kind", type = "choice", choices = {"gem", "ingot"}, width = 0.8},
				{key = "color", label = "Colour", type = "color", width = 0.8},
				{key = "chance", label = "Chance", type = "number", min = 0, max = 100000, decimals = 1, width = 0.8},
				{key = "price", label = "Price", type = "number", min = 0, max = 100000000, decimals = 0, width = 0.8},
				{key = "forge", label = "Forge s", type = "number", min = 0, max = 3600, decimals = 0, width = 0.7},
				{key = "model", label = "Model (optional)", type = "string", width = 1.6, maxLength = 160},
				{key = "enabled", label = "On", type = "bool", width = 0.5},
			},
			default = DubzMining.DefaultMaterials,
		},
		{
			id = "rocks", label = "Rocks",
			description = "The models a placed rock can take, and each one's health (0 = the default Rock Health).",
			columns = {
				{key = "model", label = "Model", type = "string", width = 3, maxLength = 160},
				{key = "health", label = "Health", type = "number", min = 0, max = 100000, decimals = 0, width = 0.8},
			},
			default = DubzMining.DefaultRocks,
		},
		{
			id = "recipes", label = "Recipes", idKey = "id",
			description = "What the crafting table makes. kind: weapon (a pickup on the table), entity (spawned on the table, owned by the player), give, accessory (an accessory id from the Cosmetics catalog, into the pocket), or ammo (class is the ammo type, Makes is the rounds). Items: material=amount, comma separated, taken from the pocket. Craft lvl is the CRAFTING level needed; XP is what crafting it gives (0 = level x 2 + 3).",
			columns = {
				{key = "id", label = "ID", type = "string", width = 1, maxLength = 40},
				{key = "name", label = "Name", type = "string", width = 1.3, maxLength = 50},
				{key = "kind", label = "Kind", type = "choice", choices = {"weapon", "entity", "give", "accessory", "ammo"}, width = 0.8},
				{key = "class", label = "Class", type = "string", width = 1.4, maxLength = 80, suggest = "entities"},
				{key = "model", label = "Model", type = "string", width = 1.6, maxLength = 160},
				{key = "level", label = "Craft lvl", type = "number", min = 0, max = 100, decimals = 0, width = 0.6},
				{key = "xp", label = "XP", type = "number", min = 0, max = 100000, decimals = 0, width = 0.5},
				{key = "amount", label = "Makes", type = "number", min = 1, max = 500, decimals = 0, width = 0.6},
				{key = "items", label = "Items needed", type = "string", width = 2.4, maxLength = 200},
				{key = "enabled", label = "On", type = "bool", width = 0.5},
			},
			default = DubzMining.DefaultRecipes,
		},
	},
})

DFW.Collections.Watch("mining", "materials", function(rows) DubzMining.BuildMaterials(rows) end)
DFW.Collections.Watch("mining", "rocks", function(rows) DubzMining.Rocks = rows end)

DFW.Collections.Watch("mining", "recipes", function(rows)
	local list = {}
	for _, row in ipairs(rows) do
		if row.enabled ~= false and row.id ~= "" then list[#list + 1] = row end
	end

	DubzMining.Recipes = list
end)
