-- Third person settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Third Person) edits them live.
-- (A player's own camera settings are console variables, see Settings below.)
DubzThirdPerson = DubzThirdPerson or {}

DubzThirdPerson.Config = {
	toggleKey = KEY_F7,          -- switches between first and third person (a player can pick their own key in their settings)
	shoulderKey = KEY_V,         -- swaps the camera to the other shoulder (a player can pick their own key in their settings)
	shoulderKeyEnabled = true,   -- off: no shoulder key unless a player picks their own (the chat command and the settings still swap)
	allowToggle = true,          -- players can switch to first person at all (off: third person only)
	startInThirdPerson = false,  -- players start in third person the first time they join (off: they start in first person)
	forceOnSpawn = false,        -- put everyone back in third person every time they spawn (off: they keep what they chose)

	allowFreeLook = true,        -- hold Alt to look around the player without turning them
	allowBobbing = true,         -- the camera bobs a little when moving
	disableOtherCameras = true,  -- takes the ACT3 weapon cameras (and the older third person scripts) out of the way

	distanceMin = 40,            -- how far behind the player the camera can be put (units)
	distanceMax = 160,
	cameraClearance = 8,         -- how far the camera is kept from any wall or prop (units): bigger is safer in corners, smaller lets it get closer
	fovMin = 70,                 -- the field of view a player can pick
	fovMax = 110,

	uprightHelper = true,        -- Alt + right click with the physgun / tool gun / gravity gun sets the prop you aim at upright on the ground
}

-- A player's own settings. Each one is a console variable (kept between sessions); `type` is what control to draw for it. The settings panel
-- (DubzThirdPerson.BuildSettings, in cl_thirdperson.lua) draws all of these, and so can the F4 settings tab.
DubzThirdPerson.Settings = {
	{id = "enable",      cvar = "dtp_enable",           type = "bool",   default = "0",  label = "Third person",                   help = "Off is first person (the default). F7 switches."},
	{id = "shoulder",    cvar = "dtp_shoulder",         type = "shoulder", default = "1", label = "Camera on the left shoulder"},
	{id = "distance",    cvar = "dtp_distance",         type = "number", default = "88", min = 40, max = 160, decimals = 0, label = "Camera distance"},
	{id = "right",       cvar = "dtp_right",            type = "number", default = "12", min = 0, max = 40, decimals = 0, label = "Camera to the side"},
	{id = "up",          cvar = "dtp_up",               type = "number", default = "-2", min = -20, max = 30, decimals = 0, label = "Camera height"},
	{id = "fov",         cvar = "dtp_fov",              type = "number", default = "90", min = 70, max = 110, decimals = 0, label = "Field of view"},
	{id = "sensitivity", cvar = "dtp_sensitivity",      type = "number", default = "1",  min = 0.2, max = 2, decimals = 2, label = "Mouse sensitivity"},
	{id = "bobbing",     cvar = "dtp_bobbing",          type = "bool",   default = "1",  label = "Camera bobbing"},
	{id = "bob_amount",  cvar = "dtp_bob_amount",       type = "number", default = "1",  min = 0, max = 2, decimals = 2, label = "Bobbing amount"},
	{id = "freelook",    cvar = "dtp_freelook",         type = "bool",   default = "1",  label = "Hold Alt to look around", help = "Locks which way your character faces and walks while you hold it, and the camera moves around them freely."},
	{id = "mouse",       cvar = "dtp_interaction_mouse", type = "bool",  default = "0",  label = "Interaction mouse mode", help = "Releases the camera for mouse minigames (lockpicking, keypads)."},
	{id = "key",         cvar = "dtp_key",              type = "key",    default = "0",  serverKey = "toggleKey",   label = "Switch key (first / third person)", help = "Click, then press the key you want. Backspace puts the server's key back, Delete turns the key off."},
	{id = "shoulderkey", cvar = "dtp_shoulder_key",      type = "key",    default = "0",  serverKey = "shoulderKey", label = "Swap shoulder key", help = "Click, then press the key you want. Backspace puts the server's key back, Delete turns the key off."},
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzThirdPerson.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("thirdperson")
end
