-- Grant window networking. The server is authoritative: every request is checked for staff access again.
util.AddNetworkString("DubzTempRanks_OpenMenu")      -- server -> staff: open the window (allowed groups, JSON)
util.AddNetworkString("DubzTempRanks_RequestData")   -- staff -> server: send me the active list
util.AddNetworkString("DubzTempRanks_SendData")      -- server -> staff: the active list (JSON)
util.AddNetworkString("DubzTempRanks_AddRank")       -- staff -> server: steamid64, group, seconds
util.AddNetworkString("DubzTempRanks_RemoveRank")    -- staff -> server: steamid64

local function sendData(ply)
	local list = {}

	for sid, info in pairs(DubzTempRanks.Stored) do
		local online = player.GetBySteamID64(sid)
		list[#list + 1] = {
			sid = sid, name = IsValid(online) and online:Nick() or ("Offline (" .. sid .. ")"),
			group = info.group, expires = info.expires,
		}
	end

	net.Start("DubzTempRanks_SendData")
		net.WriteString(util.TableToJSON(list))
	net.Send(ply)
end

local function openMenu(ply)
	if not DubzTempRanks.IsStaff(ply) then return end

	local groups = {}
	for group in pairs(DubzTempRanks.Groups) do groups[#groups + 1] = group end
	table.sort(groups)

	net.Start("DubzTempRanks_OpenMenu")
		net.WriteString(util.TableToJSON(groups))
	net.Send(ply)

	sendData(ply)
end

concommand.Add("dubz_tempranks_menu", function(ply) openMenu(ply) end)

hook.Add("PlayerSay", "DubzTempRanks_MenuChat", function(ply, text)
	if string.lower(string.Trim(text)) ~= string.lower(DubzTempRanks.Config.ChatCommand) then return end
	if not DubzTempRanks.IsStaff(ply) then return end

	openMenu(ply)
	return ""
end)

net.Receive("DubzTempRanks_RequestData", function(_, ply)
	if DubzTempRanks.IsStaff(ply) then sendData(ply) end
end)

net.Receive("DubzTempRanks_AddRank", function(_, ply)
	if not DubzTempRanks.IsStaff(ply) then return end

	local sid, group, seconds = net.ReadString(), net.ReadString(), net.ReadUInt(32)
	local target = player.GetBySteamID64(sid)

	local ok, reason = DubzTempRanks:AddTempRank(target, group, seconds)
	ply:ChatPrint(ok and ("[Temp Rank] Granted '" .. group .. "' to " .. target:Nick() .. ".") or ("[Temp Rank] " .. tostring(reason)))

	sendData(ply)
end)

net.Receive("DubzTempRanks_RemoveRank", function(_, ply)
	if not DubzTempRanks.IsStaff(ply) then return end

	local sid = net.ReadString()
	ply:ChatPrint(DubzTempRanks:RemoveTempRank(sid) and "[Temp Rank] Removed." or "[Temp Rank] Nothing to remove.")

	sendData(ply)
end)
