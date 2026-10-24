-- Registers the chargers with the Dubz Framework: every setting in sh_config.lua appears in the admin config menu
-- (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
DFW.Bind.Module({
	id = "chargers",
	name = "Health & Armor Chargers",
	version = "1.0.0",
	icon = "darkrp/health_cross",
	description = "Medic-owned chargers: price, owner cut, charge speed and rules.",
	dependencies = {"dubz_core"},
}, DubzChargers.Config, {
	{path = "priceCommand", label = "Price Command", group = "Owner", maxLength = 30,
		description = "What the owner types while looking at their charger, followed by the price."},
	{path = "minPrice", label = "Lowest Price", min = 0, max = 100000, decimals = 0, group = "Owner"},
	{path = "maxPrice", label = "Highest Price", min = 1, max = 1000000, decimals = 0, group = "Owner"},
	{path = "ownerCut", label = "Owner Cut (%)", min = 0, max = 100, decimals = 0, group = "Owner",
		description = "The share of every use the owner earns."},
	{path = "physgunOwnerOnly", label = "Physgun: Owner Only", group = "Owner",
		description = "On: only the owner (and admins) can move a charger with the physgun."},

	{path = "useSeconds", label = "Use Time (Seconds)", min = 5, max = 300, decimals = 0, group = "Use",
		description = "How long one payment lets you use the charger."},
	{path = "stopTimerOnFull", label = "End Early When Full", group = "Use",
		description = "Applies to chargers spawned after the change."},
	{path = "walkAwayDistance", label = "Walk-Away Distance", min = 40, max = 500, decimals = 0, group = "Use"},
	{path = "sounds", label = "Sounds", group = "Use"},

	{path = "health.defaultPrice", label = "Health: Starting Price", min = 0, max = 100000, decimals = 0, group = "Health Charger",
		description = "Applies to chargers spawned after the change."},
	{path = "health.amountPerTick", label = "Health: Per Tick", min = 1, max = 20, decimals = 0, group = "Health Charger"},
	{path = "health.tickSeconds", label = "Health: Tick (Seconds)", min = 0.02, max = 2, decimals = 2, group = "Health Charger"},

	{path = "armor.defaultPrice", label = "Armor: Starting Price", min = 0, max = 100000, decimals = 0, group = "Armor Charger",
		description = "Applies to chargers spawned after the change."},
	{path = "armor.amountPerTick", label = "Armor: Per Tick", min = 1, max = 20, decimals = 0, group = "Armor Charger"},
	{path = "armor.tickSeconds", label = "Armor: Tick (Seconds)", min = 0.02, max = 2, decimals = 2, group = "Armor Charger"},
	{path = "armor.maxArmor", label = "Armor: Maximum", min = 10, max = 255, decimals = 0, group = "Armor Charger"},
}, {
	OnChange = function(path, value)
		-- Switching sounds off: cut a charging hum that is already playing
		if SERVER and path == "sounds" and value == false and DFW.Util.StopAllSounds then DFW.Util.StopAllSounds() end
	end,
})
