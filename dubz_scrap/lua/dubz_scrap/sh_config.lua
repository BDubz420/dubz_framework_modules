-- Scrap settings and data. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Scrap) edits all of it live:
-- the numbers below, the Scrap Materials (what scrapping gives) and the Trash (what comes out of the dumpsters and what it scraps into).
DubzScrap = DubzScrap or {}

DubzScrap.Config = {
	scrapTime = 3,                   -- seconds to scrap one thing (a bar shows while you do it)
	scrapStack = 50,                 -- how many of one scrap fit in a pocket slot
	trashStack = 10,                 -- how many of one kind of trash fit in a pocket slot

	-- Accessories can be scrapped too (right click one in the pocket). What they give, "material=least-most":
	accessoryYields = "leather=1-2, cloth=1-3",

	-- Metal scrap dropped on the forge melts into bars: this many pieces of `meltScrap` make one `meltBar` (a material id from Mining)
	meltScrap = "metal",
	meltPerBar = 4,
	meltBar = "steel",

	-- Label floating over a piece of scrap (like gems and ingots)
	labels = true,

	-- The Scavenging skill (in the skills menu, 10 levels): searching dumpsters and scrapping things gives XP. Each level:
	scavXpBase = 60,                 -- XP to go from level L-1 to L is base x L ^ exponent
	scavXpExponent = 1.6,
	searchXpMin = 3, searchXpMax = 6,  -- XP for searching a dumpster
	scrapXpMin = 1, scrapXpMax = 2,    -- XP for scrapping one thing
	speedPerLevel = 4,               -- percent faster scrapping
	speedMax = 40,
	bonusPerLevel = 4,               -- percent chance that a scrapped material gives one extra
	bonusMax = 40,
	luckPerLevel = 3,                -- evens out the trash odds, so rarer trash turns up more often
	extraTrashEvery = 3,             -- one more piece of trash from each dumpster search every this many levels
}

-- The scrap you end up with. model + scale + material + colour are how it looks in the world and in the pocket; leave the material
-- empty for the model's own, and colour white to leave it uncoloured.
DubzScrap.DefaultMaterials = {
	{id = "plastic", value = 6, name = "Plastic", model = "models/props_c17/playground_swingset_seat01a.mdl", scale = 0.4, material = "", color = {r = 20, g = 20, b = 20}, enabled = true},
	{id = "plasticscrap", value = 10, name = "Plastic Scrap", model = "models/hunter/plates/plate025x025.mdl", scale = 1, material = "models/props_lab/door_klab01", color = {r = 72, g = 72, b = 72}, enabled = true},
	{id = "electronics", value = 18, name = "Electronics", model = "models/props_lab/harddrive01.mdl", scale = 0.6, material = "", color = {r = 70, g = 130, b = 80}, enabled = true},
	{id = "metal", value = 12, name = "Metal", model = "models/props_debris/metal_panelchunk02d.mdl", scale = 0.5, material = "models/props_canal/canal_bridge_railing_01b", color = {r = 255, g = 255, b = 255}, enabled = true},
	{id = "cloth", value = 8, name = "Cloth", model = "models/props_junk/garbage_newspaper001a.mdl", scale = 1, material = "models/props_lab/door_klab01", color = {r = 255, g = 255, b = 255}, enabled = true},
	{id = "leather", value = 25, name = "Leather", model = "models/props_junk/garbage_newspaper001a.mdl", scale = 1, material = "models/props_pipes/GutterMetal01a", color = {r = 170, g = 100, b = 0}, enabled = true},
	{id = "wood", value = 6, name = "Wood", model = "models/Gibs/wood_gib01b.mdl", scale = 1, material = "models/props_wasteland/wood_fence01a", color = {r = 255, g = 255, b = 255}, enabled = true},
}

-- The trash the dumpsters give out. chance = how likely it is to be the one picked (a weight); yields = what scrapping it gives,
-- "material=least-most" separated by commas (a least of 0 means it may give none of that).
DubzScrap.DefaultTrash = {
	{id = "bottle", name = "Plastic Bottle", model = "models/props_junk/garbage_plasticbottle001a.mdl", scale = 1, chance = 20, yields = "plastic=1-2", enabled = true},
	{id = "milk", name = "Milk Carton", model = "models/props_junk/garbage_milkcarton001a.mdl", scale = 1, chance = 14, yields = "plastic=1-2", enabled = true},
	{id = "tincan", name = "Tin Can", model = "models/props_junk/garbage_metalcan001a.mdl", scale = 1, chance = 20, yields = "metal=1-2", enabled = true},
	{id = "paintcan", name = "Paint Can", model = "models/props_junk/metal_paintcan001b.mdl", scale = 1, chance = 8, yields = "metal=1-3", enabled = true},
	{id = "metalbucket", name = "Dented Bucket", model = "models/props_junk/MetalBucket01a.mdl", scale = 1, chance = 5, yields = "metal=2-4", enabled = true},
	{id = "plasticbucket", name = "Cracked Bucket", model = "models/props_junk/plasticbucket001a.mdl", scale = 1, chance = 6, yields = "plastic=2-4", enabled = true},
	{id = "pipe", name = "Rusty Pipe", model = "models/props_canal/mattpipe.mdl", scale = 1, chance = 8, yields = "metal=1-3", enabled = true},
	{id = "sawblade", name = "Old Sawblade", model = "models/props_junk/sawblade001a.mdl", scale = 1, chance = 4, yields = "metal=2-3", enabled = true},
	{id = "harddrive", name = "Dead Hard Drive", model = "models/props_lab/harddrive01.mdl", scale = 1, chance = 6, yields = "electronics=1-3, metal=0-1", enabled = true},
	{id = "receiver", name = "Old Receiver", model = "models/props_lab/reciever01c.mdl", scale = 1, chance = 8, yields = "electronics=1-3, metal=0-1", enabled = true},
	{id = "phone", name = "Cracked Payphone Handset", model = "models/props_trainstation/payphone_reciever001a.mdl", scale = 1, chance = 5, yields = "electronics=1-2, plastic=1-2", enabled = true},
	{id = "keyboard", name = "Dead Keyboard", model = "models/props_c17/computer01_keyboard.mdl", scale = 1, chance = 7, yields = "electronics=1-2, plastic=1-2", enabled = true},
	{id = "monitor", name = "Busted Monitor", model = "models/props_lab/monitor01a.mdl", scale = 0.8, chance = 4, yields = "electronics=2-4, plastic=1-2, metal=0-1", enabled = true},
	{id = "rags", name = "Bag Of Rags", model = "models/props_junk/garbage_bag001a.mdl", scale = 1, chance = 14, yields = "cloth=1-3", enabled = true},
	{id = "doll", name = "Ragged Doll", model = "models/props_c17/doll01.mdl", scale = 1, chance = 5, yields = "cloth=1-2, plastic=0-1", enabled = true},
	{id = "shoe", name = "Worn Shoe", model = "models/props_junk/Shoe001a.mdl", scale = 1, chance = 10, yields = "leather=1-2, cloth=0-1", enabled = true},
	{id = "crate", name = "Broken Crate", model = "models/props_junk/wood_crate001a.mdl", scale = 0.5, chance = 6, yields = "wood=2-4", enabled = true},
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so scrap still works.
function DubzScrap.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("scrap")
end

-- The live data (rebuilt from the tables by sh_framework.lua; built once from the defaults for a standalone install) -----------

DubzScrap.Materials = {}   -- id -> {id, name, model, scale, material, color}
DubzScrap.Order = {}
DubzScrap.Trash = {}       -- id -> {id, name, model, scale, chance, yields}
DubzScrap.TrashOrder = {}

local function toColor(value)
	if istable(value) then return Color(value.r or 255, value.g or 255, value.b or 255, value.a or 255) end
	return Color(255, 255, 255)
end

function DubzScrap.BuildMaterials(rows)
	DubzScrap.Materials, DubzScrap.Order = {}, {}

	for _, row in ipairs(rows) do
		if row.enabled ~= false and row.id ~= "" then
			DubzScrap.Materials[row.id] = {
				id = row.id, name = row.name, value = tonumber(row.value) or 0, model = row.model or "", scale = tonumber(row.scale) or 1, material = row.material or "", color = toColor(row.color),
			}
			DubzScrap.Order[#DubzScrap.Order + 1] = row.id
		end
	end
end

function DubzScrap.BuildTrash(rows)
	DubzScrap.Trash, DubzScrap.TrashOrder = {}, {}

	for _, row in ipairs(rows) do
		if row.enabled ~= false and row.id ~= "" then
			DubzScrap.Trash[row.id] = {
				id = row.id, name = row.name, model = row.model or "", scale = tonumber(row.scale) or 1, chance = math.max(tonumber(row.chance) or 1, 0), yields = row.yields or "",
			}
			DubzScrap.TrashOrder[#DubzScrap.TrashOrder + 1] = row.id
		end
	end
end

DubzScrap.BuildMaterials(DubzScrap.DefaultMaterials)
DubzScrap.BuildTrash(DubzScrap.DefaultTrash)

-- Lookups ---------------------------------------------------------------------------------------------------------------------

function DubzScrap.Material(id) return DubzScrap.Materials[id or ""] end
function DubzScrap.TrashType(id) return DubzScrap.Trash[id or ""] end

-- A material from its id or its name
function DubzScrap.FindMaterial(text)
	text = string.lower(string.Trim(tostring(text or "")))
	if DubzScrap.Materials[text] then return DubzScrap.Materials[text] end

	for _, material in pairs(DubzScrap.Materials) do
		if string.lower(material.name) == text then return material end
	end
end

-- The name of a piece of scrap ("Metal Scrap"; a material already called "... Scrap" keeps its name)
function DubzScrap.ScrapName(def)
	if string.lower(string.sub(def.name, -5)) == "scrap" then return def.name end
	return def.name .. " Scrap"
end

-- The player's Scavenging level (the skill, 0 to 10)
function DubzScrap.Level(ply)
	if IsValid(ply) and DubzSkills and DubzSkills.GetLevel then return math.max(0, DubzSkills.GetLevel(ply, "scavenging")) end
	return 0
end

function DubzScrap.SpeedBonus(level) return math.min(level * DubzScrap.Config.speedPerLevel, DubzScrap.Config.speedMax) end
function DubzScrap.BonusChance(level) return math.min(level * DubzScrap.Config.bonusPerLevel, DubzScrap.Config.bonusMax) end
function DubzScrap.ExtraTrash(level) return math.floor(level / math.max(1, DubzScrap.Config.extraTrashEvery)) end

-- A random kind of trash by its chance weights. A higher Scavenging level raises every weight to a smaller power, which
-- narrows the gap between common and rare trash.
function DubzScrap.PickTrash(level)
	local power = math.max(0.5, 1 - (level or 0) * DubzScrap.Config.luckPerLevel / 100)
	local weights, total = {}, 0

	for _, id in ipairs(DubzScrap.TrashOrder) do
		local chance = DubzScrap.Trash[id].chance
		weights[id] = chance > 0 and chance ^ power or 0
		total = total + weights[id]
	end

	if total <= 0 then return DubzScrap.Trash[DubzScrap.TrashOrder[1] or ""] end

	local roll, running = math.Rand(0, total), 0
	for _, id in ipairs(DubzScrap.TrashOrder) do
		running = running + weights[id]
		if roll <= running then return DubzScrap.Trash[id] end
	end

	return DubzScrap.Trash[DubzScrap.TrashOrder[#DubzScrap.TrashOrder]]
end

function DubzScrap.PickMaterial()
	local id = DubzScrap.Order[math.random(#DubzScrap.Order)]
	return id and DubzScrap.Materials[id]
end

-- "plastic=1-2, metal=0-1" -> {{id = "plastic", min = 1, max = 2}, ...} (materials that don't exist are skipped)
function DubzScrap.ParseYield(text)
	local list = {}

	for part in string.gmatch(tostring(text or ""), "[^,]+") do
		local name, low, high = string.match(string.Trim(part), "^(.-)%s*=%s*(%d+)%s*%-%s*(%d+)$")

		if not name then
			name, low = string.match(string.Trim(part), "^(.-)%s*=%s*(%d+)$")
			high = low
		end

		local material = name and DubzScrap.FindMaterial(name)
		if material then list[#list + 1] = {id = material.id, min = tonumber(low), max = math.max(tonumber(low), tonumber(high))} end
	end

	return list
end

-- What scrapping gives this time: {{id, amount}, ...} (only what came out above zero)
function DubzScrap.RollYield(text)
	local out = {}

	for _, part in ipairs(DubzScrap.ParseYield(text)) do
		local amount = math.random(part.min, part.max)
		if amount > 0 then out[#out + 1] = {id = part.id, amount = amount} end
	end

	return out
end
