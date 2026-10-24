-- Exchange settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Exchange) edits them live.
DubzExchange = DubzExchange or {}

DubzExchange.Config = {
	-- The Bank Teller: a private vault for each character (items only; cash stays in the ATM account)
	tellerName = "Bank Teller",
	tellerModel = "models/Humans/Group02/male_03.mdl",
	bankSlots = 30,
	bankSlotsPremium = 60,           -- for the premium groups of the Characters addon

	-- The Exchange Clerk: players list items for sale; anyone can buy them, even after the seller has logged off
	clerkName = "Exchange Clerk",
	clerkModel = "models/Humans/Group02/female_04.mdl",
	listingSlots = 6,                -- listings one character can have at a time
	listingSlotsPremium = 12,
	taxPercent = 5,                  -- percent of a sale the exchange keeps (a money sink)
	maxPrice = 100000000,            -- the highest price for one item
	browseLimit = 300,               -- how many listings the browse list shows (newest first)

	useDistance = 200,               -- how close you must stay to either NPC while its window is open

	-- The going rate of an item: until it has sold on the exchange it is the item's base value (the Base Values table, or what the
	-- addon that owns the item says, or the F4 shop price). After that it follows what it sells for: each sale moves the rate this
	-- percent of the way to the price it sold at.
	rateWeight = 30,
}

DubzExchange.BaseValues = {}   -- "class" or "class:variant" -> value (the Base Values table)

-- Things that can't be listed (lower case entity classes). Cash is not an item anyway.
DubzExchange.Blocked = {"spawned_money", "darkrp_cheque"}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzExchange.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("exchange")
end
