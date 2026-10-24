-- Registers Cosmetics with the Dubz Framework: the settings in sh_config.lua and the accessory CATALOG appear in the
-- admin config menu (!dubzconfig > Cosmetics). The values in sh_config.lua stay the defaults; the menu overrides them
-- live. New accessories can be added in the Catalog (Browse finds models in the pack folders) or in code
-- (sh_items.lua). Limited editions are stocked from the "Stock the shop" window on the Catalog card.
local cfg = DubzCosmetics.Config

local slotIds = {}
for _, slot in ipairs(cfg.slots) do slotIds[#slotIds + 1] = slot.id end

-- Default catalog rows: every code-defined accessory with its economy fields
local catalogRows = {}
for id, def in SortedPairs(DubzCosmetics.Items) do
	if not def.virtual then
		local econ = DubzCosmetics.Econ[id]
		catalogRows[#catalogRows + 1] = {
			id = id, name = def.name, slot = def.slot, model = def.model, tier = econ.tier, price = econ.price,
			credits = econ.credits, supply = econ.supply, shop = econ.shop, drops = econ.drops, stack = econ.stack,
			hides = econ.hides,
		}
	end
end

DFW.Bind.Module({
	id = "cosmetics",
	name = "Cosmetics",
	version = "3.0.0",
	icon = "players/face",
	description = "Accessories (worn props), the accessory catalog and limited editions, clothing, the store clerks and the placement editor.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "drawDistance", label = "Draw Distance", min = 200, max = 5000, decimals = 0, group = "Display",
		description = "Other players further away than this don't have their accessories drawn."},
	{path = "chatCommands", label = "Wardrobe Commands", list = true, group = "Display"},
	{path = "caseModel", label = "Accessory Case Model", group = "Display",
		description = "The suitcase accessories are carried and dropped as."},

	{path = "backpackPrice", label = "Big Backpack: Cash Price", min = 0, max = 100000000, decimals = 0, group = "Vendor",
		description = "What the accessory vendor charges for the wearable backpack. 0 = not sold for cash."},
	{path = "backpackCredits", label = "Big Backpack: Credit Price", min = 0, max = 100000, decimals = 0, group = "Vendor"},
	{path = "backpackSmallPrice", label = "Small Backpack: Cash Price", min = 0, max = 100000000, decimals = 0, group = "Vendor",
		description = "What the vendor charges for the Small Backpack. 0 = not sold for cash."},
	{path = "backpackSmallCredits", label = "Small Backpack: Credit Price", min = 0, max = 100000, decimals = 0, group = "Vendor"},
	{path = "npcUseDistance", label = "Clerk Use Distance", min = 50, max = 400, decimals = 0, group = "Vendor"},

	{path = "stockMessage", label = "Stocked: Chat Message", group = "Limited Editions", maxLength = 160,
		description = "Said to the whole server when you stock an everyday item. %s = the item's name."},
	{path = "stockLimitedMessage", label = "Stocked Limited: Chat Message", group = "Limited Editions", maxLength = 160,
		description = "Said to the whole server when you stock a limited or seasonal item."},
	{path = "soldOutMessage", label = "Sold Out: Chat Message", group = "Limited Editions", maxLength = 160},
	{path = "revealSupply", label = "Reveal How Many Exist", group = "Limited Editions",
		description = "On: the announcement says how many will ever exist and the vendor shows how many are left. Off keeps it a mystery."},
	{path = "modelFolders", label = "Model Browser Folders", list = true, group = "Limited Editions", maxLength = 240,
		description = "Folders the Catalog's Browse button scans for accessory models, comma separated (the GMod Tower and GTA packs ...)."},

	{path = "hiddenIdentityText", label = "Hidden Identity Text", group = "Display", maxLength = 40,
		description = "Shown over the head of someone wearing an item flagged 'Hides name' (masks ...) instead of their name."},

	{path = "lookPrice", label = "Change Look Price", min = 0, max = 100000, decimals = 0, group = "Clothing Clerk",
		description = "What changing who you are (gender / face) costs at the clothing clerk. 0 = free."},
	{path = "lockClothesOnJob", label = "No Clothes Changes On The Clock", group = "Clothing Clerk",
		description = "While you hold a job with a uniform (Job Outfits) you can not change your clothes at the clerk. Accessories and the backpack stay free."},
	{path = "overrideJobModels", label = "Clothing Overrides Job Model", group = "Clothing Clerk",
		description = "On: the look and clothing you picked at the clothing store are used whatever your job. Off: job models win."},

	{path = "dropBelowPrice", label = "Drop On Death If Cheaper Than", min = 0, max = 100000000, decimals = 0, group = "Death",
		description = "Accessories priced (cash) below this fall off where you die; pricier ones stay on. 0 = price never makes one drop."},
}, {
	ui = true,
	collections = {
		{
			id = "catalog", label = "Catalog", idKey = "id",
			description = "Every accessory: tier (everyday / limited / seasonal), cash and credit price, supply (0 = unlimited, N = only N will ever exist, each with a serial number), whether it is on sale now, whether it drops on death, and its pocket stack size. Use Browse to add models from the pack folders, and 'Stock the shop' to put limited items on sale with a server announcement.",
			picker = {column = "model", provider = "models"},
			actions = {{label = "Stock the shop", primary = true, fn = function() if DubzCosmetics.OpenStockWindow then DubzCosmetics.OpenStockWindow() end end}},
			columns = {
				{key = "id", label = "ID", type = "string", width = 1.3, maxLength = 40},
				{key = "name", label = "Name", type = "string", width = 1.5, maxLength = 40},
				{key = "slot", label = "Slot", type = "choice", choices = slotIds, width = 0.8},
				{key = "model", label = "Model", type = "string", width = 2.2, maxLength = 160},
				{key = "tier", label = "Tier", type = "choice", choices = DubzCosmetics.Tiers, width = 0.9},
				{key = "price", label = "Cash", type = "number", min = 0, max = 100000000, decimals = 0, width = 0.8},
				{key = "credits", label = "Credits", type = "number", min = 0, max = 100000, decimals = 0, width = 0.7},
				{key = "supply", label = "Supply", type = "number", min = 0, max = 100000, decimals = 0, width = 0.7},
				{key = "shop", label = "On sale", type = "bool", width = 0.6},
				{key = "drops", label = "Drops", type = "bool", width = 0.55},
				{key = "stack", label = "Stack", type = "number", min = 1, max = 50, decimals = 0, width = 0.55},
				{key = "hides", label = "Hides name", type = "bool", width = 0.65},
			},
			default = catalogRows,
		},
		{
			id = "quips", label = "Vendor Quips", idKey = "text",
			description = "Funny lines the accessory clerk says when a player hovers an item. Use %s for the item's name.",
			columns = {{key = "text", label = "Line", type = "string", width = 4, maxLength = 160}},
			default = DFW.Collections.RowsFromList(cfg.quips, "text"),
		},
		{
			id = "job_outfits", label = "Job Outfits", idKey = "job",
			description = "The uniform a job wears. The player keeps their own look (model) and only the clothes change. A job without a row keeps whatever the player picked.",
			columns = {
				{key = "job", label = "Job name", type = "string", width = 2, maxLength = 60, suggest = "jobs"},
				{key = "outfit", label = "Clothing set id", type = "string", width = 2, maxLength = 40, suggest = "clothing_sets"},
			},
			default = {{job = "Miner", outfit = "rebel"}},
		},
		{
			id = "job_accessories", label = "Job Accessories",
				description = "A job's costume pieces. Each row puts one accessory in one slot while the player holds the job (a police cap in Hats, say), and the player's own accessory in that slot is hidden and can't be changed until they leave the job. A slot with no row stays the player's own, so a cop can still wear a chain. Leave the accessory empty to keep the slot bare. Slots: hat, face, neck, back.",
				columns = {
					{key = "job", label = "Job name", type = "string", width = 2, maxLength = 60, suggest = "jobs"},
					{key = "slot", label = "Slot", type = "string", width = 1, maxLength = 10},
					{key = "item", label = "Accessory id (empty = bare)", type = "string", width = 2, maxLength = 60},
				},
				default = {},
			},
			{
				id = "clothing_prices", label = "Clothing Prices", idKey = "set",
			description = "What each clothing set costs at the clothing clerk. Bought once, then it is yours. The citizen set is always free.",
			columns = {
				{key = "set", label = "Clothing set", type = "string", width = 2, maxLength = 60, suggest = "clothing_sets"},
				{key = "price", label = "Price", type = "number", min = 0, max = 100000000, decimals = 0, width = 1},
			},
			default = DFW.Collections.RowsFromMap(cfg.clothingPrices, "set", "price"),
		},
	},
})

-- Turns the catalog rows into live registry items and economy data (both realms)
DFW.Collections.Watch("cosmetics", "catalog", function(rows)
	local seen = {}

	for _, row in ipairs(rows) do
		if string.match(row.id, "^[%w_]+$") then
			seen[row.id] = true

			local def = DubzCosmetics.Items[row.id]

			if def and def.code then
				def.name = row.name   -- code items keep their model, slot and placement
			elseif row.model ~= "" and table.HasValue({"hat", "face", "neck", "back"}, row.slot) then
				local old = def
				DubzCosmetics.Register({
					id = row.id, name = row.name, slot = row.slot, model = row.model,
					pos = old and old.pos, ang = old and old.ang, scale = old and old.scale,
				}, true)
			end

			DubzCosmetics.Econ[row.id] = {
				tier = row.tier, price = row.price, credits = row.credits, supply = row.supply,
				shop = row.shop, drops = row.drops, stack = row.stack, hides = row.hides,
			}
		end
	end

	-- Menu-added items whose row was removed disappear
	local missing = {}

	for id, def in pairs(DubzCosmetics.Items) do
		if not seen[id] and not def.virtual then
			if def.menu then
				DubzCosmetics.Items[id] = nil
				DubzCosmetics.Econ[id] = nil
			else
				missing[#missing + 1] = id
			end
		end
	end

	-- Items added in code after the table was first saved (new packs, new releases) get their own rows, so they
	-- show up in the Catalog without wiping what you changed. Server only; the change replicates to clients.
	if SERVER and #missing > 0 then
		table.sort(missing)
		local all = table.Copy(rows)

		for _, id in ipairs(missing) do
			local def, econ = DubzCosmetics.Items[id], DubzCosmetics.Econ[id]
			if def and econ then
				all[#all + 1] = {
					id = id, name = def.name, slot = def.slot, model = def.model, tier = econ.tier, price = econ.price,
					credits = econ.credits, supply = econ.supply, shop = econ.shop, drops = econ.drops, stack = econ.stack,
					hides = econ.hides,
				}
			end
		end

		timer.Simple(0, function() DFW.Collections.Set("cosmetics", "catalog", all, "dubz_cosmetics") end)
	end
end)

DFW.Collections.Watch("cosmetics", "quips", function(rows)
	cfg.quips = DFW.Collections.ListFromRows(rows, "text")
end)

DFW.Collections.Watch("cosmetics", "job_outfits", function(rows)
	local map = {}
	for _, row in ipairs(rows) do map[string.lower(row.job)] = row.outfit end
	cfg.jobOutfits = map
end)

DFW.Collections.Watch("cosmetics", "job_accessories", function(rows)
	local map = {}
	for _, row in ipairs(rows) do
		if (row.job or "") ~= "" and (row.slot or "") ~= "" then map[string.lower(row.job) .. "|" .. string.lower(row.slot)] = row.item or "" end
	end
	cfg.jobAccessories = map
end)

DFW.Collections.Watch("cosmetics", "clothing_prices", function(rows)
	cfg.clothingPrices = DFW.Collections.MapFromRows(rows, "set", "price")
end)

if CLIENT then
	DFW.Collections.Suggest = DFW.Collections.Suggest or {}
	DFW.Collections.Browse = DFW.Collections.Browse or {}

	DFW.Collections.Suggest.accessories = function()
		local list = {}
		for id, def in pairs(DubzCosmetics.Items) do
			if not def.virtual then list[#list + 1] = id end
		end
		table.sort(list)
		return list
	end

	DFW.Collections.Suggest.clothing_sets = function()
		return table.Copy(DubzCosmetics.ClothingOrder)
	end

	-- The Catalog's model browser: every .mdl under the folders in the "Model Browser Folders" setting
	DFW.Collections.Browse.models = function()
		local list, count = {}, 0

		local function scan(folder, depth)
			if count > 8000 or depth > 6 then return end

			local files, folders = file.Find(folder .. "/*", "GAME")

			for _, name in ipairs(files or {}) do
				if string.EndsWith(string.lower(name), ".mdl") then
					list[#list + 1] = {id = folder .. "/" .. name, label = string.StripExtension(name), kind = "model"}
					count = count + 1
				end
			end

			for _, name in ipairs(folders or {}) do scan(folder .. "/" .. name, depth + 1) end
		end

		for _, folder in ipairs(cfg.modelFolders) do scan(string.TrimRight(folder, "/"), 0) end

		table.sort(list, function(a, b) return a.id < b.id end)
		return list
	end

	-- A model picked in the browser becomes a new row: id and name come from the file name, off sale until you
	-- decide (so nothing goes on sale by accident)
	local picker = DFW.Collections.GetDefinition("cosmetics", "catalog").picker
	picker.fill = function(row, item, taken)
		local base = string.lower(string.gsub(string.StripExtension(string.GetFileFromFilename(item.id)), "[^%w]+", "_"))
		base = string.sub("acc_" .. base, 1, 38)

		local id, n = base, 1
		while taken[id] do n = n + 1 id = base .. "_" .. n end

		local words = {}
		for word in string.gmatch(string.gsub(string.StripExtension(string.GetFileFromFilename(item.id)), "[_%-]+", " "), "%S+") do
			words[#words + 1] = string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2)
		end

		row.id = id
		row.name = table.concat(words, " ")
		row.slot = "hat"
		row.tier = "common"
		row.price = 0
		row.shop = false
		taken[id] = true
	end
end
