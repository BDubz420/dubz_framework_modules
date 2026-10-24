-- Registers the Exchange with the Dubz Framework: the bank and exchange settings in the admin config menu (!dubzconfig > Exchange).
local cfg = DubzExchange.Config

DFW.Bind.Module({
	id = "exchange",
	name = "Exchange",
	version = "1.0.0",
	icon = "economy/inventory_2",
	description = "A bank vault for items and a market where any player can list items for any other player to buy.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "tellerName", label = "Bank Teller Name", group = "Bank", maxLength = 40},
	{path = "tellerModel", label = "Bank Teller Model", group = "Bank", maxLength = 160},
	{path = "bankSlots", label = "Vault Slots", min = 1, max = 200, decimals = 0, group = "Bank"},
	{path = "bankSlotsPremium", label = "Vault Slots (Premium)", min = 1, max = 200, decimals = 0, group = "Bank"},

	{path = "clerkName", label = "Exchange Clerk Name", group = "Exchange", maxLength = 40},
	{path = "clerkModel", label = "Exchange Clerk Model", group = "Exchange", maxLength = 160},
	{path = "listingSlots", label = "Listings Per Character", min = 1, max = 50, decimals = 0, group = "Exchange"},
	{path = "listingSlotsPremium", label = "Listings Per Character (Premium)", min = 1, max = 50, decimals = 0, group = "Exchange"},
	{path = "taxPercent", label = "Sale Tax (%)", min = 0, max = 50, decimals = 1, group = "Exchange", description = "The share of every sale the exchange keeps."},
	{path = "maxPrice", label = "Highest Price Each", min = 1, max = 2000000000, decimals = 0, group = "Exchange"},
	{path = "browseLimit", label = "Listings Shown", min = 20, max = 1000, decimals = 0, group = "Exchange"},

	{path = "rateWeight", label = "Going Rate Follows Sales (%)", min = 1, max = 100, decimals = 0, group = "Exchange",
		description = "Each sale moves an item's going rate this percent of the way to the price it sold at."},
	{path = "useDistance", label = "Window Stays Open Within", min = 80, max = 600, decimals = 0, group = "Exchange"},
}, {
	collections = {
		{
			id = "values", label = "Base Values", idKey = "key",
			description = "What an item is worth before it has sold on the exchange: the 'recommended price'. The key is the entity class, or class:variant (dubz_gem:ruby, spawned_weapon:m9k_ak47). Mining and scrap fill in their own; this overrides them.",
			columns = {
				{key = "key", label = "Class or class:variant", type = "string", width = 3, maxLength = 100},
				{key = "value", label = "Value", type = "number", min = 0, max = 2000000000, decimals = 0, width = 1},
			},
			default = {},
		},
	},
})

DFW.Collections.Watch("exchange", "values", function(rows)
	local map = {}
	for _, row in ipairs(rows) do
		if row.key ~= "" then map[row.key] = tonumber(row.value) or 0 end
	end

	DubzExchange.BaseValues = map
end)
