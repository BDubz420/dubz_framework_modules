-- F4 settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > F4 Menu) edits them live.
local F4 = DubzF4

F4.Config = {
	-- Gang leader jobs who should be able to set the agenda (the "Gang Leaders" table in the admin menu)
	GangLeaders = {
		"Mob Boss",
		"Cripz Leader",
		"Bloodz Leader",
	},

	Mayor = "Mayor",                        -- the mayor job's name

	Header = "Liminal RP | Sector 18",      -- the window title
	InfoHeading = "Everything you need to know about Liminal RP!",   -- the title above the Info tab buttons

	-- Icon grid in the Shop and Jobs tabs: icon size = window width x scale (never smaller than the minimum)
	ShopIconScale = 0.1,
	ShopIconMin = 64,
	ShopSpacing = 0,
	JobIconScale = 0.25,

	-- Jobs keep the player's character (no model picker; the icons show you in the job's uniform, if it has one)
	KeepCharacterModel = true,
}

-- Tabs from left to right, and whether each shows (the "Tabs" table in the admin menu: reorder with the arrows).
-- "gangs" is the tab the gangs addon adds. A tab not listed here is added at the end.
F4.DefaultTabs = {
	{tab = "main", enabled = true},
	{tab = "jobs", enabled = true},
	{tab = "entities", enabled = true},
	{tab = "organization", enabled = true},
	{tab = "laws", enabled = true},
	{tab = "info", enabled = true},
	{tab = "help", enabled = true},
	{tab = "rules", enabled = true},
	{tab = "donate", enabled = true},
	{tab = "gangs", enabled = true},
}

F4.TabNames = {"main", "jobs", "entities", "organization", "laws", "info", "help", "rules", "donate", "gangs"}

-- What the menu reads (replaced when the table is edited in the admin menu)
F4.TabRows = table.Copy(F4.DefaultTabs)

-- The Rules tab: one rule per row (the "Rules" table in the admin menu)
F4.DefaultRules = {
	"Don't RDM. RDM means random death match or random murder.",
	"Don't RDA. RDA means random arrest.",
	"No advertising anything.",
	"No prop killing.",
	"No prop pushing.",
	"No prop climbing.",
	"No prop surfing.",
	"No spamming in any form or way.",
	"Max mug amount is 3 thousand dollars.",
	"No hacking or glitch exploiting.",
	"Don't scam or blackmail players or staff.",
	"After you raided someone, wait 10 minutes to raid them again.",
	"No RDM/RDA in an admin sit.",
}

F4.Rules = table.Copy(F4.DefaultRules)

-- The How To Play tab: group, key (shown in brackets) and text, one row each. The text may use these tokens, which
-- show the real key from each addon's settings: {laws_key} {skills_key} {pocket_key} {bag_key} {cinematic_key}
-- {surrender_key} {thirdperson_key} {shoulder_key}
F4.DefaultHelp = {
	{group = "Moving around", key = "SHIFT", text = "Run. You walk slowly by default. Running drains stamina, and when you run out of breath you can't sprint until you recover."},
	{group = "Moving around", key = "E", text = "Use things: doors, containers, backpacks lying on the ground."},
	{group = "Moving around", key = "{thirdperson_key}", text = "Switch between first person (the default) and third person. Camera distance, bobbing and your own keys are in the context menu (C) under Third Person."},
	{group = "Moving around", key = "{shoulder_key}", text = "Third person: swap the camera to the other shoulder (or say !shoulder)."},
	{group = "Moving around", key = "Hold ALT", text = "In third person: locks which way your character faces and walks while you hold it, and you move the camera around them freely. Let go and they turn back to the camera."},
	{group = "Moving around", key = "F2", text = "Door options: buy, sell or co-own the door you're looking at."},

	{group = "Menus", key = "{laws_key}", text = "Open or close the laws panel (top right)."},
	{group = "Menus", key = "F4", text = "This menu: jobs, shop, laws, and this guide."},
	{group = "Menus", key = "{skills_key}", text = "Skills. Walking and running level up as you move; your overall level rises with all your skill XP."},
	{group = "Menus", key = "{pocket_key}", text = "Your pocket. Left click an item to use it, right click for more, drag to move items around."},
	{group = "Menus", key = "Hold G", text = "Gestures: wave, salute, laugh, dance. Move the mouse over one to preview it, click to do it, let go of G to close."},
	{group = "Menus", key = "TAB", text = "Scoreboard. Click a player to commend them or open their profile."},
	{group = "Menus", key = "{cinematic_key}", text = "Cinematic mode: hides the whole UI and chat (the weapon wheel still works). Press again to bring it back."},

	{group = "Your hands", key = "R", text = "Ready or put away your fists."},
	{group = "Your hands", key = "Left click", text = "Punch (fists ready) or lock a door (fists away). Left click an item to pick it up."},
	{group = "Your hands", key = "Right click", text = "Push the player in front of you, or unlock a door."},
	{group = "Your hands", key = "{surrender_key}", text = "Surrender: raise your hands. Press again to lower them. You drop the weapon in your hand."},

	{group = "Pocket and backpack", key = "Pocket SWEP", text = "Hold left click on an item to pick it up. Right click or R opens your pocket."},
	{group = "Pocket and backpack", key = "Backpack", text = "Press E on one on the ground to look inside, {bag_key} to put it on. {bag_key} again drops the one you wear."},
	{group = "Pocket and backpack", key = "Stacks", text = "Some items stack in one slot. Right click a stack to drop one or several of them."},

	{group = "Chat commands", key = "/pocket", text = "Open your pocket."},
	{group = "Chat commands", key = "/skills", text = "Open your skills."},
	{group = "Chat commands", key = "/trade", text = "Trade with the player you're looking at (or /trade name). Both of you must accept."},
	{group = "Chat commands", key = "/cosmetics", text = "Your wardrobe of accessories."},
	{group = "Chat commands", key = "/surrender", text = "Same as the surrender key."},
	{group = "Chat commands", key = "//", text = "Out-of-character chat, for example: // brb"},
}

F4.Help = table.Copy(F4.DefaultHelp)

-- Master kill switch (admin menu > Modules). Off = DarkRP's own F4 menu opens instead.
-- The Info tab: one button per row, title and web address (the "Info Buttons" table in the admin menu)
F4.DefaultInfoLinks = {
	{title = "Join our Discord Community!", url = "https://discord.low"},
	{title = "Join our Steam Group!", url = "https://steamcommunity.com/groups/VintageDarkRolePlay"},
	{title = "Missing Textures? Download them here!", url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2872981860"},
}
F4.InfoLinks = table.Copy(F4.DefaultInfoLinks)

-- The Main tab: every section and button can be switched off, and the sections reordered (sec_* rows, top to bottom).
-- Anything not listed is shown. Gang / police / mayor sections still only appear to the people they apply to.
F4.MainNames = {
	"sec_money", "money_give", "money_drop", "money_check",
	"sec_actions", "act_name", "act_job", "act_dropweapon", "act_unowndoors", "act_sleep", "act_letter",
	"sec_gang", "sec_police", "cp_warrant", "cp_wanted", "cp_unwanted", "cp_license",
	"sec_mayor", "mayor_lockdown", "mayor_unlockdown", "mayor_lottery", "mayor_laws",
}

F4.DefaultMain = {}
for _, id in ipairs(F4.MainNames) do F4.DefaultMain[#F4.DefaultMain + 1] = {item = id, enabled = true} end

F4.MainRows = table.Copy(F4.DefaultMain)

function F4.MainShown(id)
	for _, row in ipairs(F4.MainRows) do
		if row.item == id then return row.enabled ~= false end
	end

	return true
end

-- Items the F4 menu doesn't list (the "Hidden Items" table in the admin menu). A hidden job, entity, ammo type, weapon or
-- shipment can still be given by something else (a job NPC); it just isn't in the menu. `match` is the item's name,
-- command or entity class (not case sensitive); kind is jobs, entities, ammo, weapons, shipments or food.
F4.HiddenKinds = {"jobs", "entities", "ammo", "weapons", "shipments", "food"}
F4.DefaultHidden = {
	{kind = "jobs", match = "miner"},   -- hired from the foreman NPC instead
}
F4.HiddenRows = table.Copy(F4.DefaultHidden)

function F4.IsHidden(kind, item)
	if not istable(item) then return false end

	local keys = {item.name, item.cmd, item.command, item.ent, item.entity, item.ammoType}

	for _, row in ipairs(F4.HiddenRows) do
		if row.kind == kind then
			local match = string.lower(row.match or "")

			for _, key in ipairs(keys) do
				if isstring(key) and string.lower(key) == match then return true end
			end
		end
	end

	return false
end

-- DarkRP's categories with the hidden items taken out
function F4.Categories()
	local source = DarkRP.getCategories()
	local out = {}

	for kind, categories in pairs(source) do
		out[kind] = {}

		for _, category in ipairs(categories) do
			local copy = {}
			for key, value in pairs(category) do copy[key] = value end

			copy.members = {}
			for _, item in ipairs(category.members or {}) do
				if not F4.IsHidden(kind, item) then copy.members[#copy.members + 1] = item end
			end

			out[kind][#out[kind] + 1] = copy
		end
	end

	return out
end

-- True when the framework isn't installed, so the F4 menu still works.
function F4.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("f4")
end
