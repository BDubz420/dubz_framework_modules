DubzHands.Config = {
	-- Fists (R to ready them): left click punches, right click shoves a player
	punching = true,
	punchDelay = 0.45,       -- seconds between punches
	punchRange = 75,
	punchDamageMin = 6,
	punchDamageMax = 10,

	pushing = true,
	pushRange = 85,
	pushPower = 280,         -- sideways speed given to the pushed player
	pushLift = 90,
	pushDelay = 1.0,

	toggleDelay = 0.6,       -- seconds between readying / putting away the fists
	lockSound = "doors/door_latch3.wav",

	-- Where the first-person arms sit: units forward / right / up from the default spot. Negative forward pulls
	-- them toward you (so the back of the arms model, which has no texture, stays out of view when you swing).
	viewModelOffset = {x = -2.5, y = 0, z = -1},
}

-- Master kill switch (admin menu > Modules). Off = no punching, shoving or door shortcuts from the hands; the
-- lock / unlock keys part keeps working because the hands replace the default keys weapon.
-- True when the framework isn't installed.
function DubzHands.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("hands")
end
