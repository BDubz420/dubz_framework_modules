DubzInv.Config = {
	-- Slots everyone has. A worn backpack adds bagSlots more.
	slots = 10,
	perRow = 5,
	maxSlots = 60,

	-- Opening your pocket: this key, the chat commands, or Reload with the pocket SWEP
	openKey = KEY_I,
	chatCommands = {"/pocket", "!pocket", "/inventory", "!inventory", "/inv", "!inv"},

	-- Picking things up with the pocket SWEP: hold left click on the item.
	pickupDistance = 120,
	pickupTime = 1.5,           -- seconds, default
	pickupTimes = {             -- per entity class, in seconds
		spawned_weapon = 5,
	},

	-- /trade: opens a trade window with the player you're looking at (or /trade <name>)
	tradeCommands = {"/trade", "!trade"},
	tradeDistance = 300,       -- how close you must be to start, and to keep trading
	tradeMaxItems = 10,        -- items each side can offer
	tradeRequestTimeout = 30,  -- seconds the other player has to answer

	-- Stacking: how many of the same item fit in ONE slot. Items stack when they have the same entity class
	-- AND the same model. Anything not listed uses `default` (1 = does not stack).
	-- A limit is looked up by "model:<path>" first (one specific item), then by entity class.
	-- Only stack things that are identical: a stack shares one saved copy of its state, so do not stack items
	-- that carry their own data, like weapons with different ammo.
	stacking = {
		-- Most things stack (drugs, pots, misc). Set a class to 1 to make it never stack.
		default = 10,
		limits = {
			spawned_food = 8,
			spawned_weapon = 20,      -- guns stack (the same weapon), and a stack or shipment picked up counts all of its guns
			spawned_shipment = 3,     -- (a shipment picked up becomes its guns, so this is only for oddities)
			dubz_backpack = 1,        -- unique items: never stack
			dubz_backpack_small = 1,
			dubz_cosmetic = 1,        -- accessories (planned)
			spawned_money = 1,
			-- ["model:models/props_junk/popcan01a.mdl"] = 12,
			-- spawned_money = 5,
		},
	},

	-- Things that can never be put in the pocket (world props, vendors, fixtures). Manage it in the admin menu:
	-- Pocket & Backpack > "Can't Be Pocketed" > Browse, which searches every installed entity and weapon.
	pocketBlacklist = {
		bens_dumpster = true,
		npc_title = true,
		dubz_cos_npc = true,
		dubz_cos_npc_clothing = true,
		dubz_cos_npc_accessories = true,
		dubz_atm = true,
	},

	-- Sounds: the ammo pickup sound when you pick something up into your pocket, take it out of a backpack, or put an
	-- accessory on. Switch them off with `sounds`, or change the files.
	sounds = true,
	pickupSound = "items/ammo_pickup.wav",
	takeSound = "items/ammo_pickup.wav",
	equipSound = "items/ammo_pickup.wav",

	-- Deploy limits: only deployed entities count toward a limit (see sv_limits.lua). The limits themselves are the
	-- shop's max for the entity (useShopLimits) unless the "Deploy Limits" table in the admin menu gives it one.
	deployLimits = true,
	useShopLimits = true,

	-- Weapons a job (or the default loadout) hands out are the job's tools, not loot: they never drop on death (the job
	-- gives them again on respawn), can't be dropped and so can't end up in a pocket. A lockpick from the thief job is
	-- the example. Weapons a player bought or found are not affected.
	jobWeaponsBound = true,

	-- Weapons a character owns that no job hands out (a vape, a bought gun), with their rounds and ammo, are remembered and given back
	-- when they come back (a rejoin, a restart, switching character). Job weapons come from the job as usual.
	persistHeld = true,

	-- Hold E while looking at a loose item to pick it up (a bar fills, like holding left click with the pocket). It works on dropped stacks,
	-- loot from dumpsters, and these classes. E never "uses" them any more, so a weapon on the ground goes in the pocket instead of your hands.
	holdE = true,
	holdEClasses = {"dubz_item_stack", "dubz_trash", "dubz_scrap", "dubz_gem", "dubz_ingot", "dubz_stone", "spawned_weapon", "spawned_money"},
	holdEWeapons = false,      -- false: E on a weapon on the ground equips it (your weapon wheel); true: it goes in the pocket like the other classes above

	-- Cash picked up with the pocket goes in the POCKET as one stack that remembers the total (more cash is added to it, and the bank
	-- vault keeps one too, so the bank works like an ATM). Pressing E on cash is always the game's own: it goes straight in the wallet.
	-- Set true to make the pocket pickup go to the wallet as well.
	cashToWallet = false,

	-- Left-click / first menu entry text per entity class (anything not listed says "Use")
	useLabels = {
		spawned_food = "Eat",
		spawned_weapon = "Equip",
		spawned_money = "Take",
		dubz_cosmetic = "Wear",
	},

	-- Backpack (the dubz_backpack entity): press E on it to put it on, B to drop it.
	bagSlots = 10,                 -- the Big Backpack
	bagModel = "models/props_c17/suitcase001a.mdl",

	-- The Small Backpack (the dubz_backpack_small entity): half the slots, a smaller case on the back
	smallBagSlots = 5,
	smallBagModel = "models/props_c17/SuitCase_Passenger_Physics.mdl",
	dropBagKey = KEY_B,         -- B: drop the backpack you wear, or put on the one you're looking at
	bagOpenDistance = 150,      -- how close you must be to open / put on a backpack on the ground
	-- Keep this false so dying doesn't drop the backpack; set true to drop it (with its contents) where you died.
	dropBagOnDeath = false,

	-- Default placement of the worn backpack (the cosmetics system draws it; fine tune per player model with
	-- the dubz_cosmetic_editor placement editor, item: Backpack).
	bagDraw = {
		bone = "ValveBiped.Bip01_Spine2",
		pos = Vector(-3, 8, 0),
		ang = Angle(0, 90, 90),
		scale = 0.9,
	},

	-- Same for the small one (its own item in the placement editor: Small Backpack)
	smallBagDraw = {
		bone = "ValveBiped.Bip01_Spine2",
		pos = Vector(-3, 8, 0),
		ang = Angle(0, 90, 90),
		scale = 0.9,
	},

	-- Ownership: everything a player takes out of the pocket, buys (the F4 menu or a shop) or drops belongs to them. When they leave the server it stays
	-- this many minutes, then it is gone (back in time: it is theirs again). 0 = it stays forever. DarkRP's own removal delay for bought things is
	-- set to the same time. Classes in the list are never removed (a dropped backpack holds a player's things; cash is cash).
	abandonMinutes = 5,
	abandonKeep = {"dubz_backpack", "dubz_backpack_small", "spawned_money"},

	-- Dying drops every weapon the player has except these (they keep them). Dropped weapons become
	-- normal DarkRP weapon pickups with their ammo.
	dropWeaponsOnDeath = true,
	weaponBlacklist = {
		"keys",
		"dubz_work",
		"weapon_physcannon",
		"gmod_camera",
		"gmod_tool",
		"weapon_physgun",
		"pocket",
		"dubz_pocket",
		"dubz_hands",
		"weapon_fists",
		"handies_universal",
	},
}
