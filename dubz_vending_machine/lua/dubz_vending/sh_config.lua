-- Vending machine settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Vending Machines) edits them live.
-- A plain soda machine: staff put it in the world (Dubz Vending Machine, in the entities tab), press E to pay and a can drops out.
DubzVending = DubzVending or {}

DubzVending.Config = {
	SodaPrice = 10,            -- what a soda costs
	HungerPerCan = 10,         -- how much hunger one can takes away (energy points, out of 100)
	CanLifetime = 300,         -- seconds a can lies around before it is cleaned up (0 = never)
	MaxCansOut = 6,            -- cans out of one machine at once (the oldest goes first)
	DrinkSound = "npc/barnacle/barnacle_gulp1.wav",
	BuySound = "buttons/button1.wav",
	UseDistance = 130,         -- how close you must be to use the machine
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzVending.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("vending")
end
