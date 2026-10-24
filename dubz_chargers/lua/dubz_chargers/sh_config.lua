DubzChargers.Config = {
	-- Owners (medics) set the price with this chat command while looking at their charger: /setchargerprice 150
	priceCommand = "/setchargerprice",
	minPrice = 0,
	maxPrice = 10000,

	-- The share of every use the owner earns (percent), and how long one payment lets you use the charger
	ownerCut = 25,
	useSeconds = 20,

	stopTimerOnFull = true,   -- the use ends early once you are full (so you aren't charged for time you don't need)
	walkAwayDistance = 100,   -- walk further than this from the charger and the use ends
	sounds = true,

	-- Who may move a charger with the physgun: only its owner (and admins). Off = anyone.
	physgunOwnerOnly = true,

	health = {
		defaultPrice = 100,   -- starting price of a new charger
		amountPerTick = 1,    -- health added each tick while you hold E
		tickSeconds = 0.1,
	},

	armor = {
		defaultPrice = 100,
		amountPerTick = 1,
		tickSeconds = 0.1,
		maxArmor = 100,
	},
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzChargers.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("chargers")
end
