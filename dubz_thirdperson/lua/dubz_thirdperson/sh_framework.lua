-- Registers Third Person with the Dubz Framework (!dubzconfig > Third Person).
local cfg = DubzThirdPerson.Config

DFW.Bind.Module({
	id = "thirdperson",
	name = "Third Person",
	version = "2.0.0",
	icon = "players/face",
	description = "The third person camera: F7 switches between first and third person, hold Alt to look around the player.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "toggleKey", label = "Switch Key", keybind = true, group = "Keys", description = "Switches between first and third person. A player can pick their own key in their settings."},
	{path = "shoulderKey", label = "Swap Shoulder Key", keybind = true, group = "Keys", description = "Swaps the camera to the other shoulder. A player can pick their own key in their settings."},
	{path = "shoulderKeyEnabled", label = "Swap Shoulder Key On", group = "Keys", description = "Off: there is no shoulder key by default (players can still pick one in their settings; the settings panel and !shoulder still swap)."},
	{path = "allowToggle", label = "Players Can Switch To First Person", group = "Rules", description = "Off: third person only."},
	{path = "startInThirdPerson", label = "Start In Third Person", group = "Rules", description = "Off (the default): players start in first person and switch with the key. On: the first time a player joins they start in third person."},
	{path = "forceOnSpawn", label = "Third Person On Every Spawn", group = "Rules", description = "Off: players keep the view they chose."},

	{path = "allowFreeLook", label = "Alt Free Look", group = "Features", description = "Hold Alt to lock which way the player faces and walks, and move the camera around them freely."},
	{path = "allowBobbing", label = "Camera Bobbing", group = "Features"},
	{path = "disableOtherCameras", label = "Remove Other Cameras", group = "Features", description = "Takes the ACT3 weapon cameras and the older third person scripts out of the way."},
	{path = "uprightHelper", label = "Upright Helper", group = "Features", description = "Alt + right click with the physgun, tool gun or gravity gun stands the prop you aim at up on the ground."},

	{path = "cameraClearance", label = "Camera Clearance From Walls", min = 2, max = 24, decimals = 0, group = "Limits", description = "The camera never gets closer than this to a wall or prop, and rays from the head make sure it can never see through one. Raise it if you ever see clipping in tight corners."},
	{path = "distanceMin", label = "Closest Camera", min = 20, max = 200, decimals = 0, group = "Limits"},
	{path = "distanceMax", label = "Furthest Camera", min = 40, max = 400, decimals = 0, group = "Limits"},
	{path = "fovMin", label = "Smallest Field Of View", min = 50, max = 110, decimals = 0, group = "Limits"},
	{path = "fovMax", label = "Largest Field Of View", min = 70, max = 140, decimals = 0, group = "Limits"},
}, {})
