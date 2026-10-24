-- Temp ranks, server side: storage, changing groups, expiry. Data file format is unchanged from the old addon
-- (dubz_temp_ranks_data.txt: steamid64 -> {group, expires, prev}), so existing temp ranks carry over.
local cfg = DubzTempRanks.Config

local DATA_FILE = "dubz_temp_ranks_data.txt"
DubzTempRanks.Stored = DubzTempRanks.Stored or {}

function DubzTempRanks:Load()
	local text = file.Exists(DATA_FILE, "DATA") and file.Read(DATA_FILE, "DATA")
	local data = text and util.JSONToTable(text)
	self.Stored = istable(data) and data or {}
end

function DubzTempRanks:Save()
	file.Write(DATA_FILE, util.TableToJSON(self.Stored, true))
end

-- Group changes ---------------------------------------------------------------------------------------------------

local function setGroupBySid64(sid64, group)
	local ply = player.GetBySteamID64(sid64)

	if cfg.AdminSystem == "ulx" then
		RunConsoleCommand("ulx", "adduserid", util.SteamIDFrom64(sid64), group)
		-- ulx applies it on its own; the in-memory group changes at once for online players
		if IsValid(ply) then ply:SetUserGroup(group) end
		return true
	end

	if IsValid(ply) then
		ply:SetUserGroup(group)
		return true
	end

	return false   -- darkrp mode can't change an offline player; it is fixed when they join
end

function DubzTempRanks:SetGroup(ply, group)
	if not IsValid(ply) then return false end
	return setGroupBySid64(ply:SteamID64(), group)
end

function DubzTempRanks:GroupExists(group)
	if cfg.AdminSystem ~= "ulx" then return true end   -- DarkRP groups don't need predefining

	-- ULX keeps its groups in ULib's user control list (the names are case sensitive)
	if istable(ULib) and istable(ULib.ucl) and istable(ULib.ucl.groups) then return ULib.ucl.groups[group] ~= nil end

	return istable(ulx) and istable(ulx.groups) and ulx.groups[group] ~= nil
end

function DubzTempRanks:IsAllowedGroup(group)
	return self.Groups[string.lower(group or "")] == true
end

-- Granting -------------------------------------------------------------------------------------------------------

-- Gives a player a group for `seconds` (0 = permanent). Granting the group they already have on a temp rank adds
-- the time on top. Returns true, or false and a reason.
function DubzTempRanks:AddTempRank(ply, group, seconds, silent)
	if not IsValid(ply) then return false, "That player isn't online." end
	if not self.Enabled() then return false, "Temp ranks are switched off." end

	group = string.lower(group or "")
	seconds = math.floor(tonumber(seconds) or 0)

	if not self:IsAllowedGroup(group) then return false, "'" .. group .. "' can't be handed out as a temporary rank." end
	if not self:GroupExists(group) then return false, "The group '" .. group .. "' doesn't exist in " .. string.upper(cfg.AdminSystem) .. "." end

	local sid = ply:SteamID64()
	local current = self.Stored[sid]
	local expires

	if seconds == 0 then
		expires = 0
	elseif current and current.group == group and current.expires ~= 0 then
		expires = math.max(current.expires, os.time()) + seconds
	else
		expires = os.time() + seconds
	end

	-- Remember where they came from so the rank can be taken off cleanly
	local prev = current and current.prev
	if not prev then
		local before = string.lower(ply:GetUserGroup() or "")
		prev = (before ~= group and before ~= "") and before or cfg.DefaultGroup
	end

	self.Stored[sid] = {group = group, expires = expires, prev = prev}
	self:SetGroup(ply, group)
	self:Save()

	if not silent then
		local left = expires == 0 and "permanently" or ("for " .. self.FormatTime(expires - os.time()))
		ply:ChatPrint("[Rank] You have been granted '" .. group .. "' " .. left .. ".")
	end

	return true, expires
end

function DubzTempRanks:RemoveTempRank(sid64)
	local info = self.Stored[sid64]
	if not info then return false end

	self.Stored[sid64] = nil
	self:Save()

	local ply = player.GetBySteamID64(sid64)
	local fallback = info.prev or cfg.DefaultGroup

	if not setGroupBySid64(sid64, fallback) then
		-- darkrp mode, offline: remembered so it is reset when they join
		self.PendingReset = self.PendingReset or {}
		self.PendingReset[sid64] = fallback
	end

	if IsValid(ply) then ply:ChatPrint("[Rank] Your temporary rank has ended.") end
	return true
end

-- Expiry ---------------------------------------------------------------------------------------------------------

function DubzTempRanks:Think()
	local now = os.time()
	local expired = {}

	for sid, info in pairs(self.Stored) do
		if info.expires ~= 0 and now >= info.expires then expired[#expired + 1] = sid end
	end

	for _, sid in ipairs(expired) do self:RemoveTempRank(sid) end
end

function DubzTempRanks.StartTimer()
	timer.Create("DubzTempRanks_Think", math.max(5, tonumber(cfg.ThinkInterval) or 30), 0, function() DubzTempRanks:Think() end)
end

-- When a player joins: still ranked -> make sure the group is on them; run out while away -> take it off
hook.Add("PlayerInitialSpawn", "DubzTempRanks_Reapply", function(ply)
	timer.Simple(1, function()
		if not IsValid(ply) or not DubzTempRanks.Enabled() then return end

		local sid = ply:SteamID64()
		local info = DubzTempRanks.Stored[sid]

		if info then
			if info.expires ~= 0 and os.time() >= info.expires then
				DubzTempRanks:RemoveTempRank(sid)
			else
				DubzTempRanks:SetGroup(ply, info.group)
			end
		elseif DubzTempRanks.PendingReset and DubzTempRanks.PendingReset[sid] then
			DubzTempRanks:SetGroup(ply, DubzTempRanks.PendingReset[sid])
			DubzTempRanks.PendingReset[sid] = nil
		end
	end)
end)

-- Console / rcon: dubz_tempranks_give <name part or steamid64> <group> <time like 7d | perma>
concommand.Add("dubz_tempranks_give", function(caller, _, args)
	if IsValid(caller) and not DubzTempRanks.IsStaff(caller) then return end

	local who, group, duration = args[1], args[2], DubzTempRanks.ParseTime(args[3])
	local function reply(text) if IsValid(caller) then caller:ChatPrint(text) else print(text) end end

	if not who or not group or not duration then reply("Usage: dubz_tempranks_give <name or steamid64> <group> <7d|12h|30m|perma>") return end

	local target = player.GetBySteamID64(who)
	if not IsValid(target) then
		for _, ply in ipairs(player.GetAll()) do
			if string.find(string.lower(ply:Nick()), string.lower(who), 1, true) then target = ply break end
		end
	end

	local ok, reason = DubzTempRanks:AddTempRank(target, group, duration)
	reply(ok and ("Granted " .. group .. " to " .. target:Nick() .. ".") or ("Temp rank failed: " .. tostring(reason)))
end)

-- Staff: superadmins, or any group in the Staff Groups table
function DubzTempRanks.IsStaff(ply)
	if not IsValid(ply) then return false end
	return ply:IsSuperAdmin() or DubzTempRanks.Staff[string.lower(ply:GetUserGroup() or "")] == true
end

DubzTempRanks:Load()
DubzTempRanks.StartTimer()
