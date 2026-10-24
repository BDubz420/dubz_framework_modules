DubzCosmetics.Config = {
	-- Where accessories can be worn. A player wears at most one item per slot.
	slots = {
		{id = "hat",  name = "Hats"},
		{id = "face", name = "Face"},
		{id = "neck", name = "Neck"},
		{id = "back", name = "Back"},
	},

	-- Other players further away than this don't have their accessories drawn
	drawDistance = 1500,

	-- Equipment window: chat commands / console command
	chatCommands = {"/cosmetics", "!cosmetics", "/wardrobe", "!wardrobe"},

	-- Where per-model placement offsets are saved (inside the server's data folder)
	offsetFile = "dubz_cosmetics/offsets.json",

	-- Accessories you carry are inventory items shown as this suitcase (the dropped item is the same box with text
	-- over it saying what it really is).
	caseModel = "models/props_c17/SuitCase_Passenger_Physics.mdl",

	-- Store NPCs: how close you must stand to use one.
	npcUseDistance = 130,

	-- A job changes what you WEAR, never who you are: your character's look (model) stays, and the job puts you in a
	-- clothing set (a uniform). Leaving the job puts your own clothes back. Which set a job wears is the "Job Outfits"
	-- table in the admin menu (job name -> clothing set id); a job with no row just keeps what you are wearing.
	jobOutfits = {miner = "rebel"},

	-- While you hold a job that has a uniform (the table above) you can't change your clothes. Accessories and the backpack stay free.
	lockClothesOnJob = true,

	-- The wearable backpack is sold by the accessory vendor too (it is not part of the Catalog table). 0 = not sold
	-- for that currency.
	backpackPrice = 1800,
	backpackCredits = 0,
	backpackSmallPrice = 900,       -- the Small Backpack (the one above is the Big Backpack)
	backpackSmallCredits = 0,

	-- What the clerk says when you hover an item (random each time; the admin menu's Vendor Quips table edits them).
	-- "%s" in a line is replaced with the item's name.
	quips = {
		"That's a snazzy look, dude!",
		"Oh, that one? Customers faint when they see it. In a good way.",
		"Honestly? Bold. I respect it.",
		"My cousin bought one of those. Never took it off. Weird guy.",
		"%s, huh. Finally, someone with taste.",
		"Looks great on you. Looks great on literally anyone.",
		"No refunds if it makes you too cool.",
		"That'll turn some heads. Hopefully not violently.",
		"I'd wear it, but I have a reputation to ruin.",
		"Fresh in. Okay, it's been here a while. Still fresh.",
		"Wear that and nobody will take you seriously. Perfect.",
		"Ooh, that one's my favourite. Don't tell the others.",
		"You will look incredible, or at least memorable.",
		"Pairs well with questionable life choices.",
	},

	-- Every other accessory's tier, prices, supply and shop status live in the admin menu's Catalog table.
	-- Folders the Catalog's model browser scans for accessory models (the GMod Tower / GTA packs ...), one per line
	-- in the admin menu.
	modelFolders = {"models/gmod_tower", "models/captainbigbutt/skeyler", "models/lordvipes", "models/sal", "models/modified"},

	-- Announcements when you stock a limited item (%s = the item's name). revealSupply adds "only N will ever exist"
	-- and shows "x left" in the vendor; leave it off to keep the scarcity a mystery.
	stockMessage = "The accessory shop was just stocked with %s!",
	stockLimitedMessage = "LIMITED EDITION: the accessory shop was just stocked with %s!",
	soldOutMessage = "%s has SOLD OUT at the accessory shop.",
	revealSupply = false,

	-- Shown over the head of a player wearing something that hides their identity (a mask ...)
	hiddenIdentityText = "<identity hidden>",

	-- Clothing store. Changing who you are (gender / face) costs lookPrice; each clothing set (id = price) is bought
	-- once and then yours. The default set (citizen) is free. 0 = free.
	lookPrice = 200,
	clothingPrices = {
		citizen = 0,
		rebel = 350,
		medic = 450,
	},

	-- On = your chosen clothing (player model) replaces your job's model. Off = job models win.
	overrideJobModels = true,

	-- Dying: accessories priced (cash) BELOW this drop on the ground where you die (cheap, disposable ones); anything
	-- at or above it stays on you. 0 = nothing drops because of its price. In the Catalog table an item can also be
	-- flagged "Drops on death" whatever it costs, and given a stack size so you can carry spares to put on after you
	-- die. Limited / serial-numbered items never drop. Clothing never drops.
	dropBelowPrice = 0,
}
