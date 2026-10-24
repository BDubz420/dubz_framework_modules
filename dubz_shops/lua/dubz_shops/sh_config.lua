-- Shop engine settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Shops) edits them live.
-- What each shop SELLS and BUYS is in the "Stock" table there; the shops themselves (name, model, greeting ...) are in the "Shops" table.
DubzShops = DubzShops or {}

DubzShops.Config = {
	TalkDistance = 120,          -- how close you must be to talk to a shop NPC (and to keep the window open)
	PriceChangeMinutes = 5,      -- prices that swing are picked again this often
	SellMessage = true,          -- tell the player what they bought or sold in a notification
	StayMin = 10,                -- a shop that moves between spots (a traveling merchant) stays this many minutes at least ...
	StayMax = 20,                -- ... and at most
}

-- The shops. `id` is what the NPC entity uses (dubz_shop_store, dubz_shop_furniture, dubz_shop_kits) and what other addons open (the dealer
-- opens "dealer"). Every column can be edited in the admin menu; rows you remove there come back only if you restore the defaults.
DubzShops.DefaultShops = {
	{id = "store", name = "General Store", model = "models/Humans/Group01/male_07.mdl", greeting = "Welcome. Take a look around, nothing here is stolen. Much.",
		buyLabel = "Buy", sellLabel = "Sell", button = "Buy", swing = 10, buyback = 50, exclusive = false, roam = false},
	{id = "furniture", name = "Furniture Salesman", model = "models/Humans/Group01/male_09.mdl", greeting = "Storage, lights, shelves. Everything a growing business needs.",
		buyLabel = "Buy", sellLabel = "Sell", button = "Buy", swing = 0, buyback = 50, exclusive = false, roam = false},
	{id = "dealer", name = "Drug Dealer", model = "models/Humans/Group03/male_08.mdl", greeting = "Looking to start something?",
		buyLabel = "Buy", sellLabel = "Sell", button = "Buy", swing = 15, buyback = 50, exclusive = false, roam = false},
	{id = "kits", name = "Starter Kits", model = "models/Humans/Group02/male_03.mdl", greeting = "Pick a path. I'll set you up with what you need to start. One path each, so choose well.",
		buyLabel = "Paths", sellLabel = "Sell", button = "Take kit", swing = 0, buyback = 0, exclusive = true, roam = false},
}

-- What each shop sells (side "buy": the player buys) and buys (side "sell").
--   item   a class, or several for one row: "class:amount,class:amount" (a kit). Rows with several items need a Name.
--   kind   pocket: goes in the pocket (on the floor in front of you when it is full).  weapon: handed to you.  ent: put on the floor in front of you.
--   stock  how many can be bought before it runs out (0 = never runs out); restock = minutes until it is full again.
--   job    job names allowed to buy it, comma separated (empty = everyone).   once = each character can take this row only once.
DubzShops.DefaultStock = {
	-- General store
	{shop = "store", id = "frontwoods", side = "buy", kind = "pocket", item = "dubz_weed_frontwoods", name = "Front Woods", model = "models/base/frontwoods.mdl", price = 10, amount = 1, stock = 20, restock = 15, job = "", once = false},
	{shop = "store", id = "skin", side = "buy", kind = "pocket", item = "dubz_weed_skin", name = "Rolling Skin", model = "", price = 4, amount = 1, stock = 30, restock = 15, job = "", once = false},
	{shop = "store", id = "battery", side = "buy", kind = "pocket", item = "dubz_weed_battery", name = "Battery", model = "models/base/battery.mdl", price = 25, amount = 1, stock = 10, restock = 20, job = "", once = false},

	{shop = "store", id = "chess", side = "buy", kind = "pocket", item = "dubz_chess_set", name = "Chess Set", model = "", price = 150, amount = 1, stock = 0, restock = 0, job = "", once = false},
	{shop = "store", id = "checkers", side = "buy", kind = "pocket", item = "dubz_checkers_set", name = "Checkers Set", model = "", price = 100, amount = 1, stock = 0, restock = 0, job = "", once = false},


	-- Furniture salesman
	{shop = "furniture", id = "light", side = "buy", kind = "pocket", item = "dubz_weed_light", name = "Grow Light", model = "models/props_c17/light_decklight01_on.mdl", price = 75, amount = 1, stock = 0, restock = 0, job = "", once = false},
	{shop = "furniture", id = "bag", side = "buy", kind = "pocket", item = "dubz_weed_bag", name = "Weed Bag", model = "models/base/weedbag.mdl", price = 20, amount = 1, stock = 0, restock = 0, job = "", once = false},
	{shop = "furniture", id = "crate", side = "buy", kind = "pocket", item = "dubz_weed_crate", name = "Weed Crate", model = "models/props_junk/wood_crate001a.mdl", price = 50, amount = 1, stock = 0, restock = 0, job = "", once = false},
	{shop = "furniture", id = "scale", side = "buy", kind = "pocket", item = "dubz_weed_scale", name = "Scale", model = "models/base/scale.mdl", price = 50, amount = 1, stock = 0, restock = 0, job = "", once = false},

	-- Dealer
	{shop = "dealer", id = "seedbox", side = "buy", kind = "pocket", item = "dubz_weed_seed_box", name = "Seed Box", model = "models/base/weedbox.mdl", price = 40, amount = 1, stock = 6, restock = 10, job = "", once = false},
	{shop = "dealer", id = "seed", side = "buy", kind = "pocket", item = "dubz_weed_seed", name = "Seed", model = "models/base/weedseed.mdl", price = 5, amount = 1, stock = 20, restock = 10, job = "", once = false},
	{shop = "dealer", id = "plant", side = "buy", kind = "pocket", item = "dubz_weed_plant", name = "Plant Pot", model = "models/base/weedplant.mdl", price = 100, amount = 1, stock = 6, restock = 10, job = "", once = false},

	-- Kits (free, one path per character)
	{shop = "kits", id = "grower", side = "buy", kind = "pocket", item = "dubz_weed_seed_box:1,dubz_weed_plant:2,dubz_weed_light:1,dubz_weed_battery:1", name = "Grower", model = "models/base/weedbox.mdl", price = 0, amount = 1, stock = 0, restock = 0, job = "", once = true},
	{shop = "kits", id = "miner", side = "buy", kind = "weapon", item = "weapon_dubz_pickaxe", name = "Miner", model = "models/weapons/w_crowbar.mdl", price = 0, amount = 1, stock = 0, restock = 0, job = "", once = true},
	{shop = "kits", id = "scavenger", side = "buy", kind = "ent", item = "dubz_backpack_small", name = "Scavenger", model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 0, amount = 1, stock = 0, restock = 0, job = "", once = true},
}

DubzShops.Shops = DubzShops.Shops or {}   -- id -> shop row (kept up to date from the admin menu)
DubzShops.Stock = DubzShops.Stock or {}   -- shop id -> {buy = {rows}, sell = {rows}}
DubzShops.Spots = DubzShops.Spots or {}   -- the spots a traveling shop moves between (rows)

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzShops.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("shops")
end

function DubzShops.Get(id)
	return DubzShops.Shops[id]
end

-- "class:amount,class:amount" -> {{class, amount}, ...}
function DubzShops.ParseItems(text)
	local list = {}

	for part in string.gmatch(tostring(text or ""), "[^,]+") do
		local class, amount = string.match(string.Trim(part), "^([^:]+):?(%d*)$")

		if class and class ~= "" then list[#list + 1] = {class = string.Trim(class), amount = tonumber(amount) or 1} end
	end

	return list
end

-- Sets the shops/stock from the rows (the admin menu's, or the defaults before the framework is there)
function DubzShops.SetShops(rows)
	DubzShops.Shops = {}

	for _, row in ipairs(rows or {}) do
		if row.id and row.id ~= "" then DubzShops.Shops[row.id] = row end
	end
end

function DubzShops.SetStock(rows)
	DubzShops.Stock = {}

	for _, row in ipairs(rows or {}) do
		if row.shop and row.shop ~= "" and row.id and row.id ~= "" then
			local entry = DubzShops.Stock[row.shop] or {buy = {}, sell = {}}
			DubzShops.Stock[row.shop] = entry

			local list = row.side == "sell" and entry.sell or entry.buy
			list[#list + 1] = row
		end
	end
end

DubzShops.SetShops(DubzShops.DefaultShops)
DubzShops.SetStock(DubzShops.DefaultStock)
