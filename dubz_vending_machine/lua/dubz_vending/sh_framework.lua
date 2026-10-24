-- Registers the vending machines with the Dubz Framework: the soda price and how much a soda feeds.
local cfg = DubzVending.Config

DFW.Bind.Module({
	id = "vending",
	name = "Vending Machines",
	version = "2.0.0",
	icon = "action/store",
	description = "Soda machines: press E, pay, and a can drops out. A can takes away hunger.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "SodaPrice", label = "Soda Price", min = 1, max = 10000, decimals = 0, group = "Soda"},
	{path = "HungerPerCan", label = "Hunger Taken Away Per Can", min = 1, max = 100, decimals = 0, group = "Soda", description = "Energy points out of 100 (the hunger system's energy)."},
	{path = "CanLifetime", label = "Can Cleanup (Seconds)", min = 0, max = 3600, decimals = 0, group = "Soda", description = "A can nobody picked up goes away after this long. 0 = never."},
	{path = "MaxCansOut", label = "Cans Out Of One Machine At Once", min = 1, max = 50, decimals = 0, group = "Soda"},
	{path = "DrinkSound", label = "Drink Sound", group = "Soda", maxLength = 120},
	{path = "BuySound", label = "Buy Sound", group = "Soda", maxLength = 120},
	{path = "UseDistance", label = "Use Distance", min = 60, max = 400, decimals = 0, group = "Soda"},
})
