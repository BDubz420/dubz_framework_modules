-- Registers the Hands SWEP with the Dubz Framework: every setting in sh_config.lua appears in the admin config menu
-- (!dubzconfig). The values in sh_config.lua stay the defaults; the menu overrides them live.
DFW.Bind.Module({
	id = "hands",
	name = "Hands",
	version = "2.0.0",
	icon = "misc/handyman",
	description = "The hands weapon: fists, shoving, door keys and the first-person arm position.",
	dependencies = {"dubz_core"},
}, DubzHands.Config, {
	{path = "punching", label = "Punching", group = "Fists"},
	{path = "punchDelay", label = "Punch Delay (Seconds)", min = 0.1, max = 3, decimals = 2, group = "Fists"},
	{path = "punchRange", label = "Punch Range", min = 30, max = 200, decimals = 0, group = "Fists"},
	{path = "punchDamageMin", label = "Punch Damage Min", min = 0, max = 100, decimals = 0, group = "Fists"},
	{path = "punchDamageMax", label = "Punch Damage Max", min = 0, max = 100, decimals = 0, group = "Fists"},
	{path = "toggleDelay", label = "Ready / Put Away Delay (Seconds)", min = 0.1, max = 3, decimals = 2, group = "Fists"},

	{path = "pushing", label = "Shoving", group = "Shove"},
	{path = "pushRange", label = "Shove Range", min = 30, max = 200, decimals = 0, group = "Shove"},
	{path = "pushPower", label = "Shove Power", min = 0, max = 1000, decimals = 0, group = "Shove"},
	{path = "pushLift", label = "Shove Lift", min = 0, max = 500, decimals = 0, group = "Shove"},
	{path = "pushDelay", label = "Shove Delay (Seconds)", min = 0.1, max = 5, decimals = 1, group = "Shove"},

	{path = "lockSound", label = "Lock / Unlock Sound", group = "Keys", maxLength = 100},

	{path = "viewModelOffset.x", label = "Arms: Forward / Back", min = -15, max = 15, decimals = 1, group = "First-Person Arms",
		description = "Negative pulls the arms toward you. Raise it if you see the back of the arms when swinging."},
	{path = "viewModelOffset.y", label = "Arms: Left / Right", min = -15, max = 15, decimals = 1, group = "First-Person Arms"},
	{path = "viewModelOffset.z", label = "Arms: Down / Up", min = -15, max = 15, decimals = 1, group = "First-Person Arms"},
})
