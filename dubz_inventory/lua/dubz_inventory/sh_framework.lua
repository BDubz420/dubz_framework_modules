-- Registers the Pocket / Inventory with the Dubz Framework: every setting in sh_config.lua appears in the admin
-- config menu (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
-- Loaded by the framework (see the manifest at the bottom of lua/autorun/dubz_inventory.lua).
DFW.Bind.Module({
	id = "inventory",
	name = "Pocket & Backpack",
	version = "1.0.0",
	icon = "economy/inventory_2",
	description = "Pocket inventory, worn and ground backpacks, stacking, pickup, trading and weapon drops on death.",
	dependencies = {"dubz_core"},
}, DubzInv.Config, {
	-- Pocket
	{path = "slots", label = "Pocket Slots", min = 1, max = 30, decimals = 0, group = "Pocket",
		description = "Slots everyone has. A worn backpack adds more."},
	{path = "perRow", label = "Slots Per Row", min = 3, max = 10, decimals = 0, group = "Pocket"},
	{path = "maxSlots", label = "Max Total Slots", min = 10, max = 120, decimals = 0, group = "Pocket"},
	{path = "openKey", label = "Open Key", keybind = true, group = "Pocket"},
	{path = "chatCommands", label = "Chat Commands", list = true, group = "Pocket", description = "Comma separated."},

	-- Picking up
	{path = "pickupDistance", label = "Pickup Distance", min = 40, max = 300, decimals = 0, group = "Picking Up"},
	{path = "pickupTime", label = "Pickup Time (Seconds)", min = 0.1, max = 10, decimals = 1, group = "Picking Up"},

	-- Stacking
	{path = "stacking.default", label = "Default Stack Size", min = 1, max = 100, decimals = 0, group = "Stacking",
		description = "How many of the same item fit in one slot. 1 = does not stack."},

	{path = "deployLimits", label = "Deploy Limits", group = "Limits",
		description = "Limit how many of an entity a player can have put down (printers, stoves ...). Items in the pocket don't count; only deployed ones."},
	{path = "useShopLimits", label = "Use Shop Limits", group = "Limits",
		description = "Entities without a row in the Deploy Limits table use their max from the F4 shop."},
	{path = "holdE", label = "Hold E To Pick Up", group = "Picking Up",
		description = "Look at a loose item and hold E to pocket it (as well as holding left click with the pocket)."},
	{path = "holdEClasses", label = "Hold E: Item Classes", list = true, group = "Picking Up", maxLength = 300,
		description = "Entity classes that can be picked up with E, comma separated. Dropped stacks and dumpster loot always can."},
	{path = "abandonMinutes", label = "Remove Their Things After (Minutes)", min = 0, max = 1440, decimals = 0, group = "Ownership",
		description = "What a player took out of the pocket, bought or dropped is theirs. When they leave it is removed after this long (0 = it stays); back in time, it is theirs again. DarkRP's removal delay is set to the same time at startup."},
	{path = "abandonKeep", label = "Never Removed (Classes)", list = true, group = "Ownership", maxLength = 300,
		description = "Entity classes that stay when their owner leaves, comma separated (a dropped backpack, cash)."},
	{path = "holdEWeapons", label = "Hold E Pockets Weapons", group = "Picking Up", description = "Off (the default): E on a weapon on the ground equips it, so it is on your weapon wheel. On: E puts it in the pocket. Holding left click with the pocket always pockets it."},
	{path = "persistHeld", label = "Remember What They Hold", group = "Death",
		description = "Weapons a character owns that no job gives (with their rounds and ammo) are saved and given back when they rejoin or switch back."},
	{path = "jobWeaponsBound", label = "Job Weapons Are Bound", group = "Death",
		description = "Weapons a job hands out (a lockpick, a baton ...) never drop on death and can't be dropped or pocketed. The job gives them back on respawn."},

	{path = "sounds", label = "Pocket Sounds", group = "Sounds", description = "The pickup sound when you take, pick up or equip an item."},
	{path = "pickupSound", label = "Pickup Sound", group = "Sounds", maxLength = 100},
	{path = "takeSound", label = "Take Out Of Backpack Sound", group = "Sounds", maxLength = 100},
	{path = "equipSound", label = "Equip Accessory Sound", group = "Sounds", maxLength = 100},

	{path = "cashToWallet", label = "Cash Goes To Wallet", group = "Picking Up",
		description = "Off (the default): picking money up with the pocket puts it in the pocket as one stack that keeps the total (the bank vault keeps one too). On: the pocket pickup goes to the wallet. Pressing E on cash always goes to the wallet."},

	-- Backpack
	{path = "bagSlots", label = "Big Backpack Slots", min = 1, max = 40, decimals = 0, group = "Backpack"},
	{path = "smallBagSlots", label = "Small Backpack Slots", min = 1, max = 40, decimals = 0, group = "Backpack",
		description = "The Small Backpack adds this many slots (the Big one adds the number above)."},
	{path = "smallBagModel", label = "Small Backpack Model", group = "Backpack",
		description = "The model that makes a backpack a Small one (also what the visible weapons use to place guns on the back)."},
	{path = "bagModel", label = "Big Backpack Model", group = "Backpack",
		description = "Where it sits on the body is set with the placement editor: dubz_cosmetic_editor (item: Backpack)."},
	{path = "dropBagKey", label = "Wear / Drop Key", keybind = true, group = "Backpack"},
	{path = "bagOpenDistance", label = "Open Distance", min = 40, max = 400, decimals = 0, group = "Backpack"},
	{path = "dropBagOnDeath", label = "Drop Backpack On Death", group = "Backpack",
		description = "Off: you keep your backpack. On: it drops where you died, with its contents."},
	-- Trading
	{path = "tradeCommands", label = "Trade Commands", list = true, group = "Trading"},
	{path = "tradeDistance", label = "Trade Distance", min = 50, max = 1000, decimals = 0, group = "Trading"},
	{path = "tradeMaxItems", label = "Max Items Per Side", min = 1, max = 10, decimals = 0, group = "Trading",
		description = "The trade window shows up to 10 slots per side."},
	{path = "tradeRequestTimeout", label = "Request Timeout (Seconds)", min = 5, max = 120, decimals = 0, group = "Trading"},

	-- Death
	{path = "dropWeaponsOnDeath", label = "Drop Weapons On Death", group = "Death",
		description = "Dying drops every weapon you carry except the blacklisted ones below."},
}, {
	ui = true,
	OnChange = function(path, value)
		-- Switching the sounds off: cut anything still playing
		if SERVER and path == "sounds" and value == false and DFW.Util.StopAllSounds then DFW.Util.StopAllSounds() end
	end,
	collections = {
		{
			id = "stacks", label = "Stack Sizes", idKey = "item",
			description = "How many of an item fit in one slot. Item is an entity class, or model:<path> for one specific model. Anything not listed uses the default stack size above.",
			columns = {
				{key = "item", label = "Item (class or model:path)", type = "string", width = 2.4, maxLength = 120, suggest = "entities"},
				{key = "size", label = "Stack size", type = "number", min = 1, max = 1000, decimals = 0, width = 1},
			},
			default = DFW.Collections.RowsFromMap(DubzInv.Config.stacking.limits, "item", "size"),
		},
		{
			id = "deploy_limits", label = "Deploy Limits", idKey = "class",
			description = "The most of an entity a player can have deployed at once (0 = no limit). Also applies to buying it in the F4 shop, so both agree. Anything not listed uses its F4 shop max.",
			columns = {
				{key = "class", label = "Entity class", type = "string", width = 2.4, maxLength = 120, suggest = "entities"},
				{key = "max", label = "Most deployed", type = "number", min = 0, max = 100, decimals = 0, width = 1},
			},
			default = {},
		},
		{
			id = "pickup_times", label = "Pickup Times", idKey = "item",
			description = "How long picking an item up takes (hold left click). Anything not listed uses the default pickup time.",
			columns = {
				{key = "item", label = "Item (class)", type = "string", width = 2.4, maxLength = 120, suggest = "entities"},
				{key = "seconds", label = "Seconds", type = "number", min = 0.1, max = 60, decimals = 1, width = 1},
			},
			default = DFW.Collections.RowsFromMap(DubzInv.Config.pickupTimes, "item", "seconds"),
		},
		{
			id = "use_labels", label = "Left Click Labels", idKey = "item",
			description = "The text on an item's first menu entry (Eat, Equip, Take ...). Anything not listed says Use.",
			columns = {
				{key = "item", label = "Item (class)", type = "string", width = 2, maxLength = 120, suggest = "entities"},
				{key = "label", label = "Label", type = "string", width = 1.4, maxLength = 24},
			},
			default = DFW.Collections.RowsFromMap(DubzInv.Config.useLabels, "item", "label"),
		},
		{
			id = "pocket_blacklist", label = "Can't Be Pocketed", idKey = "class",
			description = "Entities and weapons that can never be put in the pocket (the dumpster, vendors, fixtures ...). Use Browse to search everything installed and click to add or remove.",
			picker = {column = "class", provider = "entities"},
			columns = {
				{key = "class", label = "Entity / weapon class", type = "string", width = 1, maxLength = 80, suggest = "entities"},
			},
			default = DFW.Collections.RowsFromSet(DubzInv.Config.pocketBlacklist, "class"),
		},
		{
			id = "keep_weapons", label = "Weapons You Keep On Death", idKey = "weapon",
			description = "Weapons that never drop when you die (the tool gun, physgun, hands ...). Everything else you carry drops.",
			columns = {
				{key = "weapon", label = "Weapon class", type = "string", width = 1, maxLength = 80, suggest = "weapons"},
			},
			default = DFW.Collections.RowsFromList(DubzInv.Config.weaponBlacklist, "weapon"),
		},
	},
})

-- The rest of the addon reads these config tables, so keep them in step with the editable tables
DFW.Collections.Watch("inventory", "stacks", function(rows)
	local limits = {}
	for _, row in ipairs(rows) do
		local key = row.item
		if string.StartWith(string.lower(key), "model:") then key = string.lower(key) end
		limits[key] = row.size
	end
	DubzInv.Config.stacking.limits = limits
end)

DFW.Collections.Watch("inventory", "deploy_limits", function(rows)
	DubzInv.DeployRules = DFW.Collections.MapFromRows(rows, "class", "max")
	if SERVER and DubzInv.ApplyShopLimits then DubzInv.ApplyShopLimits() end
end)

DFW.Collections.Watch("inventory", "pickup_times", function(rows)
	DubzInv.Config.pickupTimes = DFW.Collections.MapFromRows(rows, "item", "seconds")
end)

DFW.Collections.Watch("inventory", "use_labels", function(rows)
	DubzInv.Config.useLabels = DFW.Collections.MapFromRows(rows, "item", "label")
end)

DFW.Collections.Watch("inventory", "pocket_blacklist", function(rows)
	DubzInv.Config.pocketBlacklist = DFW.Collections.SetFromRows(rows, "class")
end)

DFW.Collections.Watch("inventory", "keep_weapons", function(rows)
	DubzInv.Config.weaponBlacklist = DFW.Collections.ListFromRows(rows, "weapon", true)
end)
