-- Mining settings and data. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Mining) edits all of it
-- live: the numbers below, and the Materials (gems and ingots), Rocks and Recipes tables.
DubzMining = DubzMining or {}

DubzMining.Config = {
	-- Models (any model works; materials can have their own in the Materials table)
	gemModel = "models/props_junk/rock001a.mdl",   -- gems are small rocks, tinted by their colour
	gemScale = 0.15,                 -- how big (1 = the model's own size)
	ingotModel = "models/hunter/plates/plate025.mdl",
	stoneModel = "models/props_junk/rock001a.mdl",
	forgeModel = "models/props_forest/furnace01.mdl",
	craftingModel = "models/props_c17/FurnitureTable002a.mdl",
	cartModel = "models/props_wasteland/laundry_cart002.mdl",

	-- How gems and ingots look. This material is put on them (so the colour shows as a gem or a metal); empty = plain.
	shine = "models/props_canal/rock_riverbed01a",

	-- Rocks
	rockHealth = 100,           -- default health of a rock (a row in the Rocks table can set its own)
	rockRespawnTime = 30,       -- seconds before a mined rock is back
	rockDrawDistance = 200,     -- how close you must be to see its health bar
	otherToolDamage = 2,        -- health a hit from any other tool (below) takes off a rock
	miningTools = {"weapon_dubz_pickaxe"},   -- weapons that break rocks by damaging them (the pickaxe also does it directly)

	-- What a rock gives
	stoneMin = 0, stoneMax = 3,      -- ore chunks (smelted into ingots in the forge)
	gemMin = 0, gemMax = 3,          -- gems

	despawnTime = 120,               -- seconds before loose stones and gems left on the ground disappear
	xpMin = 4, xpMax = 8,            -- Mining XP for breaking a rock
	smeltXpMin = 1, smeltXpMax = 3,  -- Mining XP for smelting an ore chunk into an ingot

	-- Swinging
	swingDelay = 1.0,                -- seconds between swings at Mining level 0 (levels make it shorter)
	hitDelay = 0.5,                  -- seconds from the swing to the hit landing

	-- The Mining skill (in the skills menu, 10 levels like Movement). There are no pickaxe tiers: each Mining level makes you a
	-- more efficient miner. It levels up by breaking rocks.
	xpBase = 70,                     -- XP to go from level L-1 to L is base x L ^ exponent (about 12,000 XP for all 10 levels)
	xpExponent = 1.6,
	damageBase = 2,                  -- rock health a swing takes off at Mining level 0
	damagePerLevel = 1,              -- more per Mining level
	swingSpeedPerLevel = 5,          -- percent faster swings per Mining level
	swingSpeedMax = 50,              -- the most that can reach (percent)
	bonusChancePerLevel = 5,         -- percent chance per Mining level that a rock drops an extra ore chunk
	bonusChanceMax = 50,             -- the most that chance can reach (percent)

	-- The Crafting skill (in the skills menu, also 10 levels): crafting things levels it up, and its level decides which recipes you can
	-- make (so small things unlock the big ones). A recipe's XP is in the Recipes table (0 = its level x 2 + 3).
	craftXpBase = 25,
	craftXpExponent = 1.4,

	-- The pocket: how many of one gem / ingot / ore fit in a slot
	stackSize = 50,

	-- The mining foreman buys gems, ingots and ore chunks. He pays the going price (a percent of it, below) times a multiplier that
	-- changes every refresh, so prices go up and down. Ore chunks are worth this percent of an average ingot.
	buyerRefresh = 60,               -- seconds between price changes
	buyerMinMultiplier = 0.7,
	buyerMaxMultiplier = 1.3,
	foremanRate = 75,                -- percent of the going price he pays
	oreValue = 40,

	-- Minecart rental from the foreman: this much for each period it is out. It is paid when it is returned or when selling.
	cartRentFee = 200,
	cartRentMinutes = 60,

	craftingTitle = "Crafting Table",
	craftTime = 3,                   -- seconds a craft takes (the hands-at-work animation), plus the next number for each recipe level
	craftTimePerLevel = 0.6,
	useDistance = 200,               -- how close you must stay to the buyer / crafting table while its window is open
}

-- Gems and ingots. kind: gem (found in rocks, sold or crafted with) or ingot (smelted from ore chunks in the forge).
-- chance = how likely it is to be picked (weights); price = what the buyer pays; forge = seconds in the forge (ingots).
-- color is what the item looks like in the world and in the pocket. model = leave empty for the default model.
DubzMining.DefaultMaterials = {
	{id = "topaz", name = "Topaz", kind = "gem", color = {r = 255, g = 200, b = 0}, chance = 40, price = 200, forge = 0, model = "", enabled = true},
	{id = "amethyst", name = "Amethyst", kind = "gem", color = {r = 153, g = 102, b = 204}, chance = 25, price = 350, forge = 0, model = "", enabled = true},
	{id = "emerald", name = "Emerald", kind = "gem", color = {r = 0, g = 255, b = 0}, chance = 20, price = 500, forge = 0, model = "", enabled = true},
	{id = "ruby", name = "Ruby", kind = "gem", color = {r = 255, g = 0, b = 0}, chance = 10, price = 700, forge = 0, model = "", enabled = true},
	{id = "sapphire", name = "Sapphire", kind = "gem", color = {r = 0, g = 0, b = 255}, chance = 4, price = 900, forge = 0, model = "", enabled = true},
	{id = "diamond", name = "Diamond", kind = "gem", color = {r = 200, g = 255, b = 255}, chance = 1, price = 1500, forge = 0, model = "", enabled = true},

	{id = "copper", name = "Copper", kind = "ingot", color = {r = 184, g = 115, b = 51}, chance = 30, price = 100, forge = 10, model = "", enabled = true},
	{id = "iron", name = "Iron", kind = "ingot", color = {r = 192, g = 192, b = 192}, chance = 25, price = 200, forge = 15, model = "", enabled = true},
	{id = "steel", name = "Steel", kind = "ingot", color = {r = 70, g = 70, b = 70}, chance = 20, price = 300, forge = 20, model = "", enabled = true},
	{id = "silver", name = "Silver", kind = "ingot", color = {r = 220, g = 220, b = 220}, chance = 15, price = 450, forge = 30, model = "", enabled = true},
	{id = "gold", name = "Gold", kind = "ingot", color = {r = 255, g = 215, b = 0}, chance = 7, price = 650, forge = 45, model = "", enabled = true},
	{id = "titanium", name = "Titanium", kind = "ingot", color = {r = 176, g = 224, b = 230}, chance = 3, price = 1000, forge = 60, model = "", enabled = true},
}

-- Rock models (the placed rock picks one); health 0 = the default above.
DubzMining.DefaultRocks = {
	{model = "models/props_wasteland/rockgranite02c.mdl", health = 0},
	{model = "models/props_wasteland/rockgranite03a.mdl", health = 0},
	{model = "models/props_wasteland/rockgranite03b.mdl", health = 0},
	{model = "models/props_wasteland/rockgranite03c.mdl", health = 0},
}

-- Crafting recipes (a starter set: default sweps and M9K guns; add your own in the admin menu). `level` is the CRAFTING level needed (crafting small things raises it); xp is what a craft gives (0 = level x 2 + 3).
-- kind: ammo (class = the ammo type, Makes = how many rounds), weapon (a weapon pickup is placed on the table), entity (the entity is spawned on the table, owned by
-- the player) or give (put straight into the player's hands). `items` lists what it costs from the pocket: "Copper=2, Topaz=1"
-- (material names or ids). level = the mining level needed.
DubzMining.DefaultRecipes = {
	{id = "crowbar", name = "Crowbar", kind = "weapon", class = "weapon_crowbar", model = "models/weapons/w_crowbar.mdl", level = 0, amount = 1, items = "Metal=12, Wood=2", enabled = true},
	{id = "colt1911", name = "Colt 1911", kind = "weapon", class = "m9k_colt1911", model = "models/weapons/s_dmgf_co1911.mdl", level = 3, amount = 1, items = "Steel=4, Topaz=3, Silver=2", enabled = true},
	{id = "grenade", name = "Grenade", kind = "weapon", class = "m9k_m61_frag", model = "models/weapons/w_grenade.mdl", level = 6, amount = 1, items = "Copper=5, Iron=3, Topaz=1", enabled = true},
	{id = "c4", name = "C4 Explosive", kind = "weapon", class = "m9k_suicide_bomb", model = "models/weapons/w_c4.mdl", level = 8, amount = 1, items = "Steel=15, Silver=10, Gold=5, Emerald=3, Ruby=2", enabled = true},
	{id = "lockpick", name = "Lockpick", kind = "weapon", class = "lockpick", model = "models/weapons/w_crowbar.mdl", level = 2, amount = 1, items = "Metal=8, Plastic=4, Copper=2", enabled = true},
	{id = "keypad_cracker", name = "Keypad Cracker", kind = "weapon", class = "keypad_cracker", model = "models/weapons/w_c4.mdl", level = 3, amount = 1, items = "Plastic=8, Metal=8, Electronics=6, Copper=4", enabled = true},
	{id = "medkit", name = "Med Kit", kind = "weapon", class = "med_kit", model = "models/items/healthkit.mdl", level = 0, amount = 1, items = "Cloth=8, Plastic=4, Silver=1", enabled = true},
	{id = "rpg7", name = "RPG-7", kind = "weapon", class = "m9k_rpg7", model = "models/weapons/w_rocket_launcher.mdl", level = 9, amount = 1, items = "Steel=20, Gold=10, Titanium=8, Sapphire=3, Diamond=1", enabled = true},
	{id = "minigun", name = "Minigun", kind = "weapon", class = "m9k_minigun", model = "models/weapons/w_m134_minigun.mdl", level = 10, amount = 1, items = "Steel=50, Titanium=15, Sapphire=5, Diamond=2", enabled = true},
	{id = "pistol_ammo", name = "Pistol Ammo (30)", kind = "ammo", class = "pistol", model = "models/items/boxsrounds.mdl", level = 2, amount = 30, items = "Metal=3, Plastic=1", enabled = true},
	{id = "rifle_ammo", name = "Rifle Ammo (30)", kind = "ammo", class = "ar2", model = "models/items/boxmrounds.mdl", level = 3, amount = 30, items = "Metal=5, Plastic=2, Plastic Scrap=1", enabled = true},
	{id = "glock", name = "Glock 18", kind = "weapon", class = "m9k_glock", model = "", level = 4, amount = 1, items = "Metal=10, Plastic Scrap=4, Plastic=4, Steel=2", enabled = true},
	{id = "ak47", name = "AK-47", kind = "weapon", class = "m9k_ak47", model = "", level = 6, amount = 1, items = "Steel=6, Metal=14, Wood=8, Plastic Scrap=4", enabled = true},
	{id = "m4a1", name = "M4A1", kind = "weapon", class = "m9k_m4a1", model = "", level = 7, amount = 1, items = "Steel=8, Metal=16, Plastic Scrap=8, Plastic=4, Silver=1", enabled = true},
	{id = "pickaxe", name = "Pickaxe", kind = "weapon", class = "weapon_dubz_pickaxe", model = "models/dubz_mining/w_pickaxe.mdl", level = 0, amount = 1, items = "Metal=15, Wood=8, Copper=4", enabled = true},
}

for _, row in ipairs(DubzMining.DefaultRecipes) do row.xp = row.xp or 0 end

-- Sounds (Lua only: these are lists of files)
DubzMining.Sounds = {
	swing = {"weapons/slam/throw.wav"},
	hitWorld = {"weapons/crossbow/hitbod2.wav"},
	hitRock = {
		"physics/concrete/rock_impact_soft1.wav", "physics/concrete/rock_impact_soft2.wav", "physics/concrete/rock_impact_soft3.wav",
		"physics/concrete/rock_impact_hard1.wav", "physics/concrete/rock_impact_hard2.wav", "physics/concrete/rock_impact_hard3.wav",
		"physics/concrete/rock_impact_hard4.wav", "physics/concrete/rock_impact_hard5.wav", "physics/concrete/rock_impact_hard6.wav",
	},
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so mining still works.
function DubzMining.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("mining")
end

-- The live data (rebuilt from the tables by sh_framework.lua; built once from the defaults for a standalone install) -------

DubzMining.Materials = {}   -- id -> {id, name, kind, color, chance, price, forge, model}
DubzMining.Order = {}       -- material ids, in table order
DubzMining.Rocks = {}
DubzMining.Recipes = {}     -- ordered list

local function toColor(value)
	if istable(value) then return Color(value.r or 255, value.g or 255, value.b or 255, value.a or 255) end
	return Color(255, 255, 255)
end

function DubzMining.BuildMaterials(rows)
	DubzMining.Materials, DubzMining.Order = {}, {}

	for _, row in ipairs(rows) do
		if row.enabled ~= false and row.id ~= "" then
			DubzMining.Materials[row.id] = {
				id = row.id, name = row.name, kind = row.kind, color = toColor(row.color), chance = math.max(row.chance or 1, 0),
				price = row.price or 0, forge = row.forge or 0, model = row.model or "",
			}
			DubzMining.Order[#DubzMining.Order + 1] = row.id
		end
	end
end

DubzMining.BuildMaterials(DubzMining.DefaultMaterials)
DubzMining.Rocks = table.Copy(DubzMining.DefaultRocks)

-- Lookups ----------------------------------------------------------------------------------------------------------------

function DubzMining.Material(id) return DubzMining.Materials[id or ""] end

-- A material from its id or its name (recipes may use either)
function DubzMining.FindMaterial(text)
	text = string.lower(string.Trim(tostring(text or "")))
	if DubzMining.Materials[text] then return DubzMining.Materials[text] end

	for _, material in pairs(DubzMining.Materials) do
		if string.lower(material.name) == text then return material end
	end

	-- Other addons can offer materials of their own for recipes (the scrap addon: plastic, metal, cloth ...)
	return hook.Run("DubzMiningExtraMaterial", text)
end

function DubzMining.OfKind(kind)
	local list = {}
	for _, id in ipairs(DubzMining.Order) do
		local material = DubzMining.Materials[id]
		if material.kind == kind then list[#list + 1] = material end
	end
	return list
end

-- A random material of a kind by its chance weights
function DubzMining.Pick(kind)
	local list = DubzMining.OfKind(kind)
	local total = 0
	for _, material in ipairs(list) do total = total + material.chance end
	if total <= 0 then return list[1] end

	local roll, running = math.Rand(0, total), 0
	for _, material in ipairs(list) do
		running = running + material.chance
		if roll <= running then return material end
	end

	return list[#list]
end

-- "Copper=2, Topaz=1" -> {{material = <copper>, amount = 2}, ...}; materials that don't exist are listed with material = nil
function DubzMining.ParseItems(text)
	local list = {}

	for part in string.gmatch(tostring(text or ""), "[^,]+") do
		local name, amount = string.match(string.Trim(part), "^(.-)%s*=%s*(%d+)$")
		if name and name ~= "" then list[#list + 1] = {name = name, material = DubzMining.FindMaterial(name), amount = tonumber(amount)} end
	end

	return list
end

-- The player's Mining level (the Mining skill, 0 to 10): how efficient a miner they are
function DubzMining.Level(ply)
	if DubzSkills and DubzSkills.GetLevel then return math.max(0, DubzSkills.GetLevel(ply, "mining")) end
	return 0
end

-- Rock health a swing takes off, the swing delay in seconds, and the chance of an extra ore chunk, for a player's Mining level
function DubzMining.Damage(ply)
	return math.max(1, math.floor(DubzMining.Config.damageBase + DubzMining.Level(ply) * DubzMining.Config.damagePerLevel))
end

function DubzMining.SwingDelay(ply)
	local cfg = DubzMining.Config
	return cfg.swingDelay * (1 - math.min(DubzMining.Level(ply) * cfg.swingSpeedPerLevel, cfg.swingSpeedMax) / 100)
end

function DubzMining.BonusChance(ply)
	return math.min(DubzMining.Level(ply) * DubzMining.Config.bonusChancePerLevel, DubzMining.Config.bonusChanceMax)
end

-- The player's Crafting level (the Crafting skill; everyone starts at 0): which recipes they can make
function DubzMining.CraftLevel(ply)
	if DubzSkills and DubzSkills.GetLevel then return math.max(0, DubzSkills.GetLevel(ply, "crafting")) end
	return 0
end

-- XP a recipe gives for crafting it
function DubzMining.RecipeXP(recipe)
	return (recipe.xp and recipe.xp > 0) and recipe.xp or ((recipe.level or 1) * 2 + 3)
end

-- The words used for each kind of thing in the world and the pocket
function DubzMining.ItemName(class, material)
	-- Ore chunks are anonymous: nobody knows what is in one until it is smelted
	if class == "dubz_stone" then return "Ore Chunk" end
	if not material then return "Unknown" end

	if class == "dubz_ingot" then return material.name .. " Ingot" end
	return material.name
end

-- What an ore chunk is worth on average: the ingots' prices weighted by how likely each is to come out of the forge
function DubzMining.AverageIngotPrice()
	local total, weight = 0, 0

	for _, material in ipairs(DubzMining.OfKind("ingot")) do
		total = total + material.price * material.chance
		weight = weight + material.chance
	end

	return weight > 0 and (total / weight) or 0
end

-- Looks: gems and ingots get their colour and the shine material (ore chunks are plain rock)
function DubzMining.Style(ent, material)
	if not material then return end

	ent:SetColor(material.color)
	if DubzMining.Config.shine ~= "" then ent:SetMaterial(DubzMining.Config.shine) end
end

DubzMining.Recipes = {}
for _, row in ipairs(DubzMining.DefaultRecipes) do
	if row.enabled ~= false then DubzMining.Recipes[#DubzMining.Recipes + 1] = row end
end
