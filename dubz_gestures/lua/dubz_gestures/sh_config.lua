-- Gestures settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Gestures) edits them live.
DubzGestures = DubzGestures or {}

DubzGestures.Config = {
	openKey = KEY_G,         -- hold to open the menu, release to close it
	cooldown = 1.5,          -- seconds between two gestures
	closeOnPlay = true,      -- the menu closes when you click a gesture (off: it stays up until you let go of the key)
	allowInVehicle = false,
	lockWhilePlaying = true, -- no moving until the animation has finished
	disabled = {},           -- gesture ids switched off (the Disabled Gestures list in the admin menu)
}

-- The gestures. act = the name of the Garry's Mod animation (looked up when used, so a missing one just does nothing), seq = the animation's
-- name on a player model, used by the preview when the act can't be found. tab = which tab it is on. Anyone can use all of them for now.
-- (Gestures made with the hands-at-work poses can be added here later: they would play through dubz_actions instead of an act.)
DubzGestures.List = {
	{id = "wave",       name = "Wave",          tab = "Gestures", act = "ACT_GMOD_GESTURE_WAVE",       seq = "gesture_wave"},
	{id = "salute",     name = "Salute",        tab = "Gestures", act = "ACT_GMOD_GESTURE_SALUTE",     seq = "gesture_salute"},
	{id = "bow",        name = "Bow",           tab = "Gestures", act = "ACT_GMOD_GESTURE_BOW",        seq = "gesture_bow"},
	{id = "nod",        name = "Nod",           tab = "Gestures", act = "ACT_GMOD_GESTURE_AGREE",      seq = "gesture_agree"},
	{id = "shake",      name = "Shake Head",    tab = "Gestures", act = "ACT_GMOD_GESTURE_DISAGREE",   seq = "gesture_disagree"},
	{id = "beckon",     name = "Come Here",     tab = "Gestures", act = "ACT_GMOD_GESTURE_BECON",      seq = "gesture_becon"},
	{id = "forward",    name = "Move Out",      tab = "Gestures", act = "ACT_SIGNAL_FORWARD",          seq = "gesture_signal_forward"},
	{id = "group",      name = "Group Up",      tab = "Gestures", act = "ACT_SIGNAL_GROUP",            seq = "gesture_signal_group"},
	{id = "halt",       name = "Halt",          tab = "Gestures", act = "ACT_SIGNAL_HALT",             seq = "gesture_signal_halt"},

	{id = "cheer",      name = "Cheer",         tab = "Taunts",   act = "ACT_GMOD_TAUNT_CHEER",        seq = "taunt_cheer"},
	{id = "laugh",      name = "Laugh",         tab = "Taunts",   act = "ACT_GMOD_TAUNT_LAUGH",        seq = "taunt_laugh"},
	{id = "flex",       name = "Flex",          tab = "Taunts",   act = "ACT_GMOD_TAUNT_MUSCLE",       seq = "taunt_muscle"},
	{id = "dance",      name = "Dance",         tab = "Taunts",   act = "ACT_GMOD_TAUNT_DANCE",        seq = "taunt_dance"},
	{id = "persist",    name = "Persistence",   tab = "Taunts",   act = "ACT_GMOD_TAUNT_PERSISTENCE",  seq = "taunt_persistence"},
	{id = "robot",      name = "Robot",         tab = "Taunts",   act = "ACT_GMOD_TAUNT_ROBOT",        seq = "taunt_robot"},
	{id = "zombie",     name = "Zombie",        tab = "Taunts",   act = "ACT_GMOD_GESTURE_TAUNT_ZOMBIE", seq = "taunt_zombie"},
}

DubzGestures.Tabs = {"All", "Gestures", "Taunts"}

DubzGestures.ById = {}
for index, gesture in ipairs(DubzGestures.List) do
	gesture.index = index
	DubzGestures.ById[gesture.id] = gesture
end

function DubzGestures.IsDisabled(id)
	return table.HasValue(DubzGestures.Config.disabled or {}, id)
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzGestures.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("gestures")
end

-- Standing still while a gesture plays: the server sets dubz_gest_until (how long the animation lasts) and every movement command is cleared
-- until then. Done in StartCommand (shared) so the client predicts the same thing: nothing to snap back. Looking around is free.
hook.Add("StartCommand", "DubzGestures_Lock", function(ply, cmd)
	if not DubzGestures.Config.lockWhilePlaying or ply:GetNWFloat("dubz_gest_until", 0) <= CurTime() then return end

	cmd:ClearMovement()
	cmd:RemoveKey(IN_JUMP)
	cmd:RemoveKey(IN_DUCK)
	cmd:RemoveKey(IN_SPEED)
end)
