-- Temp Ranks settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig > Temp Ranks) edits them live.
DubzTempRanks = DubzTempRanks or {}

DubzTempRanks.Config = {
	-- How groups are changed: "ulx" (runs ulx adduserid, keeps the group across restarts) or "darkrp" (SetUserGroup)
	AdminSystem = "ulx",

	-- The group a player goes back to when their time is up and they had no other group before
	DefaultGroup = "user",

	-- How often (seconds) expired ranks are looked for
	ThinkInterval = 30,

	-- Chat command that opens the grant window for staff
	ChatCommand = "!tempranks",
}

-- Groups that can be handed out temporarily (the "Temporary Groups" table in the admin menu)
DubzTempRanks.DefaultGroups = {
	{group = "vip"},
	{group = "vip+"},
	{group = "elite"},
}
DubzTempRanks.Groups = {}
for _, row in ipairs(DubzTempRanks.DefaultGroups) do DubzTempRanks.Groups[row.group] = true end

-- Besides superadmins, these groups may open the grant window (the "Staff Groups" table)
DubzTempRanks.DefaultStaff = {
	{group = "owner"},
}
DubzTempRanks.Staff = {}
for _, row in ipairs(DubzTempRanks.DefaultStaff) do DubzTempRanks.Staff[row.group] = true end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed.
function DubzTempRanks.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("temp_ranks")
end

-- "7d", "12h", "30m", "2w", "perma" -> seconds (0 = permanent). Returns nil when it can't be read.
function DubzTempRanks.ParseTime(text)
	text = string.Trim(string.lower(text or ""))
	if text == "perma" or text == "perm" or text == "permanent" or text == "0" then return 0 end

	local n, unit = string.match(text, "^(%d+)%s*([mhdw])$")
	n = tonumber(n)
	if not n or n <= 0 then return nil end

	return n * ({m = 60, h = 3600, d = 86400, w = 604800})[unit]
end

function DubzTempRanks.FormatTime(seconds)
	if seconds <= 0 then return "Permanent" end

	local d = math.floor(seconds / 86400)
	seconds = seconds % 86400
	local h = math.floor(seconds / 3600)
	seconds = seconds % 3600
	local m = math.floor(seconds / 60)

	local parts = {}
	if d > 0 then parts[#parts + 1] = d .. "d" end
	if h > 0 then parts[#parts + 1] = h .. "h" end
	if m > 0 or #parts == 0 then parts[#parts + 1] = m .. "m" end

	return table.concat(parts, " ")
end
