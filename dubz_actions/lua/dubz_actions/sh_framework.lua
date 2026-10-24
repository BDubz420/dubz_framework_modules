-- Registers Actions with the Dubz Framework (!dubzconfig > Actions).
local cfg = DubzActions.Config

DFW.Bind.Module({
	id = "actions",
	name = "Actions",
	version = "1.0.0",
	icon = "economy/inventory_2",
	description = "First person hands at work: animations, sounds and a progress bar for searching, scrapping and crafting.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "lockScrap", label = "Stand Still While Scrapping", group = "Working", description = "Off (the default): you can walk about while you scrap."},
	{path = "lockSearch", label = "Stand Still While Searching", group = "Working"},
	{path = "lockCraft", label = "Stand Still While Crafting", group = "Working"},
	{path = "cancelOnDamage", label = "Being Hurt Stops The Work", group = "Working"},
	{path = "showBar", label = "Progress Bar", group = "Working"},
	{path = "thirdPerson", label = "Others See The Work Gestures", group = "Working"},

	{path = "enableScrap", label = "Scrapping Animation", group = "Actions", description = "Off: scrapping from the pocket still works, but it is instant (no animation or bar)."},
	{path = "enableSearch", label = "Dumpster Search Animation", group = "Actions", description = "Off: searching a dumpster still works, but it is instant."},
	{path = "enableCraft", label = "Crafting Animation", group = "Actions", description = "Off: crafting still works, but it is instant."},
	{path = "enablePickup", label = "Pickup Reach And Grab", group = "Actions", description = "Off: picking things up shows no reach animation."},

	{path = "curlScale", label = "Hand Grip", min = 0, max = 1.5, decimals = 2, group = "Hands", description = "How closed the fingers get while working. 0 = fingers straight out, 1 = the full grip."},
	{path = "itemForward", label = "Item: Forward", min = 0, max = 60, decimals = 1, group = "Hands"},
	{path = "itemRight", label = "Item: Right", min = -30, max = 30, decimals = 1, group = "Hands"},
	{path = "itemUp", label = "Item: Up", min = -30, max = 30, decimals = 1, group = "Hands"},
	{path = "itemSize", label = "Item: Size (Your View)", min = 1, max = 30, decimals = 1, group = "Hands", description = "How big the item looks in your own hands (its longest side)."},
	{path = "itemSizeOthers", label = "Item: Size (Others See)", min = 1, max = 40, decimals = 1, group = "Hands", description = "How big it looks to everyone else. Your own view is drawn with a narrower field of view, so the same size looks bigger to you."},
}, {
	collections = {
		{
			id = "tweaks", label = "Pose Tweaks",
			description = "Extra turns added to a bone while working. Kind: one kind of work or all. View: your own first person arms, other players' models, or both. Bones are R_ or L_ then UpperArm, Forearm, Hand or a finger (Finger0 is the thumb; Finger1 to 4 are the fingers, with 11 and 12 their other joints). Preview with dubz_work_preview <kind> 120 metal 0.5 (the last number holds it at that moment, 0 to 1).",
			columns = {
				{key = "kind", label = "Kind", type = "choice", choices = {"all", "scrap", "search", "craft", "pickup"}, width = 1},
				{key = "view", label = "View", type = "choice", choices = {"both", "first", "third"}, width = 1},
				{key = "bone", label = "Bone", type = "choice", choices = DubzActions.BoneNames, width = 1.6},
				{key = "pitch", label = "Pitch", type = "number", min = -180, max = 180, decimals = 1, width = 0.8},
				{key = "yaw", label = "Yaw", type = "number", min = -180, max = 180, decimals = 1, width = 0.8},
				{key = "roll", label = "Roll", type = "number", min = -180, max = 180, decimals = 1, width = 0.8},
			},
			default = {},
		},
	},
})

DFW.Collections.Watch("actions", "tweaks", function(rows)
	local list = {}

	for _, row in ipairs(rows) do
		if row.bone and row.bone ~= "" then list[#list + 1] = row end
	end

	DubzActions.Tweaks = list
end)
