-- Accessories defined in code. A dev or a bot adds one with DubzCosmetics.Register; the admin menu's Catalog table
-- also lists them (and can add more without code). Economy fields: tier, price (cash), credits, supply (0 =
-- unlimited), shop (on sale now), drops (falls off on death), stack (pocket stack size). See sh_registry.lua.
-- Use the placement editor (dubz_cosmetic_editor) to tune where each one sits on each player model.

-- EVERYDAY STOCK: always on sale ---------------------------------------------------------------------------------

DubzCosmetics.Register({
	id = "top_hat", name = "Top Hat", slot = "hat",
	model = "models/player/items/humans/top_hat.mdl",
	pos = Vector(0, 0, 0), ang = Angle(0, 0, 0), scale = 1,
	tier = "common", price = 400, shop = true,
})

DubzCosmetics.Register({
	id = "traffic_cone", name = "Traffic Cone", slot = "hat",
	model = "models/props_junk/trafficcone001a.mdl",
	pos = Vector(6, 0, 0), ang = Angle(0, 0, 0), scale = 0.55,
	tier = "common", price = 175, shop = true, drops = true, stack = 5,   -- cheap and disposable
})

DubzCosmetics.Register({
	id = "metal_bucket", name = "Metal Bucket", slot = "hat",
	model = "models/props_junk/metalbucket01a.mdl",
	pos = Vector(4, 0, 0), ang = Angle(0, 0, 0), scale = 0.7,
	tier = "common", price = 140, shop = true, drops = true, stack = 5,
})

DubzCosmetics.Register({
	id = "gas_can_back", name = "Fuel Can", slot = "back",
	model = "models/props_junk/gascan001a.mdl",
	bone = "ValveBiped.Bip01_Spine2",
	pos = Vector(-3, 7, 0), ang = Angle(0, 90, 90), scale = 0.7,
	tier = "common", price = 300, shop = true,
})

-- LIMITED / SEASONAL EDITIONS: off sale until you stock them ("Stock the shop" in the Cosmetics page) -----------------
-- Example of the shape (kept as a comment so nothing unfinished ships):
--
-- DubzCosmetics.Register({
--	id = "golden_top_hat", name = "Golden Top Hat", slot = "hat",
--	model = "models/player/items/humans/top_hat.mdl", skin = 0,
--	tier = "limited", supply = 25, price = 25000, credits = 150, shop = false,
-- })
