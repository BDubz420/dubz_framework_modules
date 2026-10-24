-- Registers the shop engine with the Dubz Framework: the settings, the Shops table, the Stock table (what each shop sells and buys) and the
-- spots a traveling shop moves between.
local cfg = DubzShops.Config

-- The stock columns (the shop column is only in the table for other shops)
local function stockColumns(withShop)
	local columns = {}

	if withShop then columns[#columns + 1] = {key = "shop", label = "Shop", type = "string", width = 1.2, maxLength = 30} end

	for _, column in ipairs({
		{key = "id", label = "Id", type = "string", width = 1.2, maxLength = 30},
		{key = "side", label = "Side", type = "choice", choices = {"buy", "sell"}, width = 0.8},
		{key = "kind", label = "Kind", type = "choice", choices = {"pocket", "weapon", "ent"}, width = 1},
		{key = "item", label = "Item", type = "string", width = 3, maxLength = 200},
		{key = "name", label = "Name", type = "string", width = 1.6, maxLength = 40},
		{key = "model", label = "Model", type = "string", width = 2.2, maxLength = 120},
		{key = "price", label = "Price", type = "number", min = 0, max = 10000000, decimals = 0, width = 1},
		{key = "amount", label = "Amount", type = "number", min = 1, max = 50, decimals = 0, width = 0.8},
		{key = "stock", label = "Stock", type = "number", min = 0, max = 10000, decimals = 0, width = 0.8},
		{key = "restock", label = "Restock (min)", type = "number", min = 0, max = 1440, decimals = 0, width = 1},
		{key = "job", label = "Jobs", type = "string", width = 1.6, maxLength = 120},
		{key = "once", label = "Once", type = "bool", width = 0.6},
	}) do columns[#columns + 1] = column end

	return columns
end

local STOCK_HELP = "Side buy = the shop sells it, sell = the shop buys it from players (everything it sells is also bought back at the shop's Buyback %). Item is an entity or weapon class, or several for one row: class:amount,class:amount (then give it a Name). Kind: pocket goes in the pocket (floor when full), weapon is handed over, ent is put on the floor. Stock 0 = never runs out; Restock = minutes until full again. Jobs = job names that may buy it (comma separated). Once = each character can take it only once."

-- One stock table for each shop that ships with the addon
local FIXED = {
	{id = "store", label = "Stock: General Store"},
	{id = "furniture", label = "Stock: Furniture Salesman"},
	{id = "dealer", label = "Stock: Drug Dealer"},
	{id = "kits", label = "Stock: Starter Kits"},
}

local function defaultsFor(shop)
	local list = {}

	for _, row in ipairs(DubzShops.DefaultStock) do
		if row.shop == shop then list[#list + 1] = row end
	end

	return list
end

local collections = {}

collections[#collections + 1] = {
	id = "shops", label = "Shops", idKey = "id",
	description = "One row per shop. The Id is what the NPC uses (Dubz Shops entities: General Store = store, Furniture Salesman = furniture, Starter Kits = kits; the dealer opens dealer). Swing: prices move up to this many percent. Buyback: players can sell back what the shop sells for this percent of its price (0 = off). Exclusive: a character can take only ONE once-only row of the shop (the starter kits). Travels: the NPC moves between the spots below. What each shop sells is in its own Stock table.",
	columns = {
		{key = "id", label = "Id", type = "string", width = 1.2, maxLength = 30},
		{key = "name", label = "Name", type = "string", width = 1.6, maxLength = 40},
		{key = "model", label = "Model", type = "string", width = 2.4, maxLength = 120},
		{key = "greeting", label = "Greeting", type = "string", width = 3, maxLength = 200},
		{key = "buyLabel", label = "Buy Tab", type = "string", width = 1, maxLength = 20},
		{key = "sellLabel", label = "Sell Tab", type = "string", width = 1, maxLength = 20},
		{key = "button", label = "Button", type = "string", width = 1, maxLength = 20},
		{key = "swing", label = "Swing %", type = "number", min = 0, max = 90, decimals = 0, width = 0.8},
		{key = "buyback", label = "Buyback %", type = "number", min = 0, max = 100, decimals = 0, width = 0.8},
		{key = "exclusive", label = "Exclusive", type = "bool", width = 0.8},
		{key = "roam", label = "Travels", type = "bool", width = 0.8},
	},
	default = DubzShops.DefaultShops,
}

for _, fixed in ipairs(FIXED) do
	collections[#collections + 1] = {
		id = "stock_" .. fixed.id, label = fixed.label, idKey = "id",
		description = "What this shop sells and buys. " .. STOCK_HELP,
		columns = stockColumns(false),
		default = defaultsFor(fixed.id),
	}
end

collections[#collections + 1] = {
	id = "stock", label = "Stock: Other Shops", idKey = "id",
	description = "For a shop you add yourself in the Shops table (give each row its Shop id). " .. STOCK_HELP,
	columns = stockColumns(true),
	default = {},
}

collections[#collections + 1] = {
	id = "spots", label = "Traveling Spots",
	description = "Where a shop with Travels switched on stands, for each map: stand where you want the NPC, looking the way he should face, and press Add My Position (or say !shopspot store Docks). With two or more spots he is moved between them.",
	columns = {
		{key = "shop", label = "Shop", type = "string", width = 1.2, maxLength = 30},
		{key = "map", label = "Map", type = "string", width = 2, maxLength = 80},
		{key = "name", label = "Name", type = "string", width = 2, maxLength = 40},
		{key = "x", label = "X", type = "number", min = -100000, max = 100000, decimals = 1, width = 1},
		{key = "y", label = "Y", type = "number", min = -100000, max = 100000, decimals = 1, width = 1},
		{key = "z", label = "Z", type = "number", min = -100000, max = 100000, decimals = 1, width = 1},
		{key = "yaw", label = "Facing", type = "number", min = -360, max = 360, decimals = 0, width = 1},
	},
	default = {},
	actions = {
		{label = "Add my position (General Store)", primary = true, fn = function() RunConsoleCommand("dubz_shop_addspot", "store") end},
	},
}

DFW.Bind.Module({
	id = "shops",
	name = "Shops",
	version = "1.0.0",
	icon = "action/shopping_cart",
	description = "NPC shops with a Buy and a Sell tab: the general store, the furniture salesman, the dealer's wares and the starter kits. Each shop has its own Stock table here.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "TalkDistance", label = "Talk Distance", min = 60, max = 400, decimals = 0, group = "General", description = "How close you must be to talk to a shop NPC (and to keep the window open)."},
	{path = "SellMessage", label = "Tell The Player What Happened", group = "General", description = "A notification for every purchase and sale."},
	{path = "PriceChangeMinutes", label = "Prices Change Every (Minutes)", min = 1, max = 120, decimals = 0, group = "Prices", description = "Shops with a price swing pick their prices again this often."},
	{path = "StayMin", label = "Traveling Shop Stays At Least (Minutes)", min = 1, max = 240, decimals = 0, group = "Traveling", description = "A shop with Travels switched on moves between its spots."},
	{path = "StayMax", label = "Traveling Shop Stays At Most (Minutes)", min = 1, max = 240, decimals = 0, group = "Traveling"},
}, {
	collections = collections,
})

DFW.Collections.Watch("shops", "shops", function(rows) DubzShops.SetShops(rows) end)
DFW.Collections.Watch("shops", "spots", function(rows) DubzShops.Spots = rows or {} end)

-- Every stock table feeds the one list the engine uses (a row in a shop's own table belongs to that shop; the same Id twice: the shop's own table wins)
local parts = {}

local function rebuildStock()
	local all, seen = {}, {}

	local function add(rows, shop)
		for _, row in ipairs(rows or {}) do
			local copy = shop and table.Merge(table.Copy(row), {shop = shop}) or row
			local k = tostring(copy.shop) .. "|" .. tostring(copy.id)

			if not seen[k] then
				seen[k] = true
				all[#all + 1] = copy
			end
		end
	end

	for _, fixed in ipairs(FIXED) do add(parts[fixed.id], fixed.id) end
	add(parts.other)

	DubzShops.SetStock(all)
end

for _, fixed in ipairs(FIXED) do
	DFW.Collections.Watch("shops", "stock_" .. fixed.id, function(rows) parts[fixed.id] = rows rebuildStock() end)
end

DFW.Collections.Watch("shops", "stock", function(rows) parts.other = rows rebuildStock() end)
