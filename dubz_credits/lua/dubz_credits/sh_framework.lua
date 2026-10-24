-- Registers Dubz Credits with the Dubz Framework: the store link, HUD, daily credits, boost limits and the prices of
-- every conversion, boost and shop item appear in the admin config menu (!dubzconfig). The values in sh_config.lua
-- stay the defaults; the menu overrides them live.
--
-- The tables here edit what already exists: each row's ID must match an item in sh_config.lua (the reward code lives
-- there). Switch an item off with its "On" box (or delete its row); change its name, price and numbers freely.
-- Storage type and the MySQL login are deliberately NOT in the menu (restart-only and secret): keep them in sh_config.lua.
local cfg = DubzCredits.Config

local function rowsFrom(defs, build)
	local rows = {}
	for id, def in SortedPairs(defs) do rows[#rows + 1] = build(id, def) end
	return rows
end

local function rarityList() return {"common", "uncommon", "rare", "epic", "legendary"} end

-- Applies edited rows onto the existing definitions (keeping their reward functions)
local function apply(defs, rows, fields)
	local byId = {}
	for _, row in ipairs(rows) do byId[row.id] = row end

	for id, def in pairs(defs) do
		local row = byId[id]

		if row then
			def.enabled = row.enabled
			for config, column in pairs(fields) do def[config] = row[column] end
		else
			def.enabled = false   -- a deleted row switches the item off
		end
	end
end

local daily = cfg.Daily.daily_credits

local vipRankRows = {}
for _, rank in ipairs(daily.vip_ranks) do vipRankRows[#vipRankRows + 1] = {rank = rank} end

local nameCol = {key = "name", label = "Name", type = "string", width = 2.4, maxLength = 80}
local idCol = {key = "id", label = "ID (matches sh_config)", type = "string", width = 1.4, maxLength = 40}
local costCol = {key = "cost", label = "Cost (credits)", type = "number", min = 0, max = 1000000, decimals = 0, width = 1}
local onCol = {key = "enabled", label = "On", type = "bool", width = 0.6}

local specs = {
	{path = "Store.Enabled", key = "store_enabled", label = "Store Button", group = "Store"},
	{path = "Store.URL", key = "store_url", label = "Store Link", group = "Store", maxLength = 200,
		description = "Where the Buy Credits button sends players."},
	{path = "Store.ButtonText", key = "store_button", label = "Store Button Text", group = "Store", maxLength = 40},

	{path = "HUD.Enabled", key = "hud_enabled", label = "Active Boosts HUD", group = "HUD"},
	{path = "HUD.Position", key = "hud_position", label = "HUD Corner", choices = {"topleft", "topright", "bottomleft", "bottomright"}, group = "HUD"},
	{path = "HUD.XOffset", key = "hud_x", label = "HUD Distance From Side", min = 0, max = 600, decimals = 0, group = "HUD"},
	{path = "HUD.YOffset", key = "hud_y", label = "HUD Distance From Top/Bottom", min = 0, max = 600, decimals = 0, group = "HUD"},

	{path = "UI.ConversionsEnabled", key = "ui_conversions", label = "Conversions", group = "Systems",
		description = "Credits to cash conversions. Off hides them and refuses the purchase."},
	{path = "UI.BoostsEnabled", key = "ui_boosts", label = "Global Boosts", group = "Systems",
		description = "Boosts everyone benefits from (2x salary for everyone ...)."},
	{path = "UI.PersonalBoostsEnabled", key = "ui_personal_boosts", label = "Personal Boosts", group = "Systems",
		description = "Boosts that only help the buyer (+20 props for a day ...). Boosts already active keep working."},
	{path = "UI.WeeklyShopEnabled", key = "ui_weekly_shop", label = "Weekly Shop", group = "Systems",
		description = "The rotating credit shop of premium items."},
	{path = "UI.EventsEnabled", key = "ui_events", label = "Server Events", group = "Systems"},

	{path = "Daily.daily_credits.mincredits", key = "daily_min", label = "Daily Credits Min", min = 0, max = 1000, decimals = 0, group = "Daily Credits"},
	{path = "Daily.daily_credits.maxcredits", key = "daily_max", label = "Daily Credits Max", min = 0, max = 1000, decimals = 0, group = "Daily Credits"},
	{path = "Daily.daily_credits.vipmultiplier", key = "daily_vip_multiplier", label = "VIP Multiplier", min = 1, max = 20, decimals = 1, group = "Daily Credits"},
}

for category, def in SortedPairs(cfg.BoostCategories) do
	specs[#specs + 1] = {path = "BoostCategories." .. category .. ".maxActive", key = "max_active_" .. category,
		label = "Max Active: " .. category, min = 1, max = 10, decimals = 0, group = "Boost Limits", description = def.description}
end

DFW.Bind.Module({
	id = "credits",
	name = "Credits",
	version = "2.0.0",
	icon = "economy/diamond",
	description = "Donator credits: the store link, daily credits, boosts, conversions and the item shop.",
	dependencies = {"dubz_core"},
}, cfg, specs, {
	collections = {
		{
			id = "vip_ranks", label = "VIP Ranks", idKey = "rank",
			description = "User groups that get the daily-credits VIP multiplier.",
			columns = {{key = "rank", label = "User group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"}},
			default = vipRankRows,
		},
		{
			id = "items", label = "Item Shop", idKey = "id",
			description = "The credit shop's items: name, price, rarity and description. The ID must match an item in sh_config.lua.",
			columns = {
				idCol, nameCol, costCol,
				{key = "rarity", label = "Rarity", type = "choice", choices = rarityList(), width = 1},
				{key = "desc", label = "Description", type = "string", width = 2.4, maxLength = 120},
				onCol,
			},
			default = rowsFrom(cfg.Items, function(id, d)
				return {id = id, name = d.name, cost = d.cost, rarity = d.rarity or "common", desc = d.desc or "", enabled = d.enabled ~= false}
			end),
		},
		{
			id = "boosts", label = "Global Boosts", idKey = "id",
			description = "Boosts everyone benefits from while active.",
			columns = {
				idCol, nameCol, costCol,
				{key = "duration", label = "Seconds", type = "number", min = 60, max = 2592000, decimals = 0, width = 1},
				{key = "multiplier", label = "Multiplier", type = "number", min = 1, max = 20, decimals = 2, width = 1},
				onCol,
			},
			default = rowsFrom(cfg.Boosts, function(id, d)
				return {id = id, name = d.name, cost = d.cost, duration = d.duration, multiplier = d.multiplier, enabled = d.enabled ~= false}
			end),
		},
		{
			id = "personal_boosts", label = "Personal Boosts", idKey = "id",
			description = "Boosts that only help the buyer (extra prop limit ...).",
			columns = {
				idCol, nameCol, costCol,
				{key = "duration", label = "Seconds", type = "number", min = 60, max = 2592000, decimals = 0, width = 1},
				{key = "amount", label = "Amount", type = "number", min = 1, max = 100000, decimals = 0, width = 1},
				onCol,
			},
			default = rowsFrom(cfg.PersonalBoosts, function(id, d)
				return {id = id, name = d.name, cost = d.cost, duration = d.duration, amount = d.amount, enabled = d.enabled ~= false}
			end),
		},
		{
			id = "conversions", label = "Conversions", idKey = "id",
			description = "Credits to money / points conversions.",
			columns = {idCol, nameCol, costCol, onCol},
			default = rowsFrom(cfg.Conversions, function(id, d)
				return {id = id, name = d.name, cost = d.cost, enabled = d.enabled ~= false}
			end),
		},
	},
})

DFW.Collections.Watch("credits", "vip_ranks", function(rows)
	daily.vip_ranks = DFW.Collections.ListFromRows(rows, "rank", true)
end)

DFW.Collections.Watch("credits", "items", function(rows) apply(cfg.Items, rows, {name = "name", cost = "cost", rarity = "rarity", desc = "desc"}) end)
DFW.Collections.Watch("credits", "boosts", function(rows) apply(cfg.Boosts, rows, {name = "name", cost = "cost", duration = "duration", multiplier = "multiplier"}) end)
DFW.Collections.Watch("credits", "personal_boosts", function(rows) apply(cfg.PersonalBoosts, rows, {name = "name", cost = "cost", duration = "duration", amount = "amount"}) end)
DFW.Collections.Watch("credits", "conversions", function(rows) apply(cfg.Conversions, rows, {name = "name", cost = "cost"}) end)
