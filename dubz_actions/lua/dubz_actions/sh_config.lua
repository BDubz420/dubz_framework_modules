-- Actions settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Actions) edits them live.
DubzActions = DubzActions or {}

DubzActions.Config = {
	-- Standing still while working, for each kind (off: they can walk about while it plays)
	lockScrap = false,          -- scrapping from the pocket: you can walk while you scrap
	lockSearch = true,          -- searching a dumpster
	lockCraft = true,           -- crafting at the table
	cancelOnDamage = true,      -- being hurt stops the work
	showBar = true,             -- the progress bar
	thirdPerson = true,         -- other players see the work gestures

	-- Each action's animation can be switched off. Off, the thing still works; it just happens at once with no animation or bar.
	enableScrap = true,         -- scrapping an item from the pocket
	enableSearch = true,        -- searching a dumpster
	enableCraft = true,         -- crafting at the crafting table
	enablePickup = true,        -- the reach and grab when picking something up

	-- The hands: how closed they are while working (1 = the full grip the animations ask for, 0 = fingers straight out)
	curlScale = 0.3,

	-- The item being worked on, in front of the eyes: forward, to the right, up (negative = down), and how big it is (its longest side)
	itemForward = 22,
	itemRight = 0,
	itemUp = -3,
	itemSize = 4.5,
	itemSizeOthers = 9,         -- how big it looks to everyone else (the first person view is drawn with a narrower field of view, so it looks bigger to you)
}

-- Pose tweaks (the Pose Tweaks table in the admin menu): extra turns added to a bone, for one kind of work or all of them, in your own first
-- person arms, on other players' models, or both. This is how the poses are dialed in without touching the code.
DubzActions.Tweaks = {}

DubzActions.BoneNames = {}
for _, side in ipairs({"R", "L"}) do
	for _, name in ipairs({"UpperArm", "Forearm", "Hand", "Finger0", "Finger01", "Finger02", "Finger1", "Finger11", "Finger12", "Finger2", "Finger21", "Finger22", "Finger3", "Finger31", "Finger32", "Finger4", "Finger41", "Finger42"}) do
		DubzActions.BoneNames[#DubzActions.BoneNames + 1] = side .. "_" .. name
	end
end

function DubzActions.ApplyTweaks(kind, set, view)
	for _, row in ipairs(DubzActions.Tweaks) do
		if (row.kind == "all" or row.kind == kind) and (row.view == "both" or row.view == view) then
			local current = set[row.bone] or Angle(0, 0, 0)
			set[row.bone] = Angle(current.p + (row.pitch or 0), current.y + (row.yaw or 0), current.r + (row.roll or 0))
		end
	end
end

-- Is this kind of action switched on? (the callers fall back to doing it instantly when it isn't)
function DubzActions.Allowed(kind)
	if not DubzActions.Enabled() then return false end

	local key = "enable" .. string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2)
	return DubzActions.Config[key] ~= false
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzActions.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("actions")
end
