-- Registers Temp Ranks with the Dubz Framework: how groups are changed, which groups can be handed out and who may
-- open the grant window appear in the admin config menu (!dubzconfig). The values in sh_config.lua stay the defaults.
local cfg = DubzTempRanks.Config

DFW.Bind.Module({
	id = "temp_ranks",
	name = "Temp Ranks",
	version = "2.0.0",
	icon = "players/face",
	description = "Time-limited user groups (VIP ...) handed out by staff or bought with credits; they revert when the time is up.",
	dependencies = {"dubz_core"},
}, cfg, {
	{path = "AdminSystem", key = "admin_system", label = "Admin System", choices = {"ulx", "darkrp"}, group = "Groups",
		description = "ulx: groups are changed with ulx adduserid (they survive restarts). darkrp: SetUserGroup, re-applied each time the player joins."},
	{path = "DefaultGroup", key = "default_group", label = "Fallback Group", group = "Groups", maxLength = 40,
		description = "Where a player goes when their time runs out and no earlier group was recorded."},
	{path = "ThinkInterval", key = "think_interval", label = "Expiry Check (Seconds)", min = 5, max = 600, decimals = 0, group = "Groups"},
	{path = "ChatCommand", key = "chat_command", label = "Grant Window Command", group = "Groups", maxLength = 30},
}, {
	collections = {
		{
			id = "groups", label = "Temporary Groups", idKey = "group",
			description = "Groups that can be handed out temporarily (by staff or the credits shop). The group has to exist in your admin mod.",
			columns = {{key = "group", label = "Group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"}},
			default = DubzTempRanks.DefaultGroups,
		},
		{
			id = "staff", label = "Staff Groups", idKey = "group",
			description = "Groups (besides superadmins) allowed to open the grant window.",
			columns = {{key = "group", label = "Group", type = "string", width = 1, maxLength = 40, suggest = "usergroups"}},
			default = DubzTempRanks.DefaultStaff,
		},
	},
	OnChange = function(path)
		if SERVER and path == "ThinkInterval" and DubzTempRanks.StartTimer then DubzTempRanks.StartTimer() end
	end,
})

local function toSet(rows)
	local set = {}
	for _, row in ipairs(rows) do set[string.lower(row.group)] = true end
	return set
end

DFW.Collections.Watch("temp_ranks", "groups", function(rows) DubzTempRanks.Groups = toSet(rows) end)
DFW.Collections.Watch("temp_ranks", "staff", function(rows) DubzTempRanks.Staff = toSet(rows) end)
