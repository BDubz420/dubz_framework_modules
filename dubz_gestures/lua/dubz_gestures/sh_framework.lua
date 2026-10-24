-- Registers Gestures with the Dubz Framework (!dubzconfig > Gestures).
local cfg = DubzGestures.Config

-- One row per gesture, all on to start with
local rows = {}
for _, gesture in ipairs(DubzGestures.List) do rows[#rows + 1] = {id = gesture.id, name = gesture.name, tab = gesture.tab, enabled = true} end

DFW.Bind.Module({
	id = "gestures",
	name = "Gestures",
	version = "1.0.0",
	icon = "players/face",
	description = "Hold G for the gestures menu: wave, salute, laugh, dance and more, with a live preview on your own model.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "openKey", label = "Menu Key", keybind = true, group = "Menu", description = "Hold to open the menu, release to close it."},
	{path = "closeOnPlay", label = "Close When A Gesture Is Picked", group = "Menu", description = "Off: the menu stays up until you let go of the key."},
	{path = "cooldown", label = "Cooldown (Seconds)", min = 0, max = 30, decimals = 1, group = "Rules", description = "How long before the same player can play another gesture."},
	{path = "allowInVehicle", label = "Allow In Vehicles", group = "Rules"},
	{path = "lockWhilePlaying", label = "Stand Still While A Gesture Plays", group = "Rules", description = "The player can't move (or jump) until the animation has finished. They can still look around."},
}, {
	collections = {
		{
			id = "gesture_switches", label = "Gestures",
			description = "Which gestures players can use. Untick one to switch it off: it disappears from the G menu and the server refuses it. (New gestures added by an update appear here after a restart.)",
			idKey = "id",
			columns = {
				{key = "id", label = "Id", type = "string", width = 1, maxLength = 30},
				{key = "name", label = "Name", type = "string", width = 2, maxLength = 40},
				{key = "tab", label = "Tab", type = "string", width = 1, maxLength = 20},
				{key = "enabled", label = "On", type = "bool", width = 0.6},
			},
			default = rows,
		},
	},
})

-- The rest of the addon reads cfg.disabled (the ids switched off), kept in step with the table above
DFW.Collections.Watch("gestures", "gesture_switches", function(rows)
	local off = {}

	for _, row in ipairs(rows) do
		if row.enabled == false and row.id and row.id ~= "" then off[#off + 1] = row.id end
	end

	cfg.disabled = off
end)
