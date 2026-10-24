-- Laws, server side: the two lists, the mayor's commands, and telling every player. This replaces DarkRP's /addlaw, /removelaw, /resetlaws and its
-- list of laws (DarkRP.getLaws), so the billboards (/placelaws), the F1 panel and the F4 tab all read these lists.
util.AddNetworkString("DubzLaws_Sync")   -- server -> client: both lists

local cfg = DubzLaws.Config

local fixedLegal, fixedIllegal = {}, {}   -- what is always there
local legal, illegal = {}, {}             -- everything shown: the fixed laws first, then the mayor's

local function say(ply, kind, text)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind, 4, text) else ply:ChatPrint(text) end
end

-- The fixed laws: the tables in the admin menu, and DarkRP's own default laws when the illegal table is empty
local function loadFixed()
	fixedLegal = table.Copy(DubzLaws.FixedLegalRows or DubzLaws.DefaultFixedLegal)

	fixedIllegal = table.Copy(DubzLaws.FixedIllegalRows or {})
	if #fixedIllegal == 0 then fixedIllegal = DubzLaws.DefaultFixedIllegal() end
end

local function rebuild(keepCustom)
	local customLegal, customIllegal = {}, {}

	if keepCustom then
		for index = DubzLaws.FixedLegal + 1, #legal do customLegal[#customLegal + 1] = legal[index] end
		for index = DubzLaws.FixedIllegal + 1, #illegal do customIllegal[#customIllegal + 1] = illegal[index] end
	end

	loadFixed()

	legal, illegal = table.Copy(fixedLegal), table.Copy(fixedIllegal)
	DubzLaws.FixedLegal, DubzLaws.FixedIllegal = #legal, #illegal

	for _, law in ipairs(customLegal) do legal[#legal + 1] = law end
	for _, law in ipairs(customIllegal) do illegal[#illegal + 1] = law end

	DubzLaws.Legal, DubzLaws.Illegal = legal, illegal
end

local function send(target)
	net.Start("DubzLaws_Sync")
		net.WriteString(util.TableToJSON({legal = legal, illegal = illegal, fixedLegal = DubzLaws.FixedLegal, fixedIllegal = DubzLaws.FixedIllegal}))

	if target then net.Send(target) else net.Broadcast() end
end

-- Other addons read the laws as one list: the illegal ones first, then the legal ones, each marked
local function combined()
	local list = {}

	for _, law in ipairs(illegal) do list[#list + 1] = "Illegal: " .. law end
	for _, law in ipairs(legal) do list[#list + 1] = "Legal: " .. law end

	return list
end

-- Who may change the laws: the mayor (and superadmins when that is on)
local function canEdit(ply)
	if not IsValid(ply) then return true end
	if cfg.adminsCanEdit and ply:IsSuperAdmin() then return true end

	return ply.isMayor and ply:isMayor() or false
end

local function add(ply, text, list, max, fixedCount, name)
	if not canEdit(ply) then say(ply, 1, "Only the mayor can change the laws.") return "" end

	text = string.Trim(text or "")

	if string.len(text) < 3 then say(ply, 1, "That law is too short.") return "" end
	if string.len(text) > cfg.maxLength then say(ply, 1, "That law is too long (" .. cfg.maxLength .. " letters at most).") return "" end
	if #list - fixedCount >= max then say(ply, 1, "The " .. name .. " list is full (" .. max .. " laws). Remove one first.") return "" end

	list[#list + 1] = text
	send()

	hook.Run("addLaw", #list, text, ply)
	say(ply, 0, "Added to the " .. name .. " laws.")

	return ""
end

local function remove(ply, args, list, fixedCount, name)
	if not canEdit(ply) then say(ply, 1, "Only the mayor can change the laws.") return "" end

	local index = tonumber(string.Trim(args or ""))

	if not index or not list[index] then say(ply, 1, "Say which " .. name .. " law, by its number.") return "" end
	if index <= fixedCount then say(ply, 1, "That law is fixed. It can't be removed.") return "" end

	local law = table.remove(list, index)
	send()

	hook.Run("removeLaw", index, law, ply)
	say(ply, 0, "Removed from the " .. name .. " laws.")

	return ""
end

-- The commands. DarkRP's entity file defines its own /addlaw and friends when it loads, so ours go in after everything is up.
local function define()
	rebuild(true)

	-- DarkRP's own functions now answer from these lists (DarkRP is not there yet when this file loads, so this waits for the game)
	DarkRP.getLaws = function() return combined() end

	DarkRP.resetLaws = function()
		rebuild(false)
		send()
	end

	DarkRP.defineChatCommand("addlegal", function(ply, args) return add(ply, args, legal, cfg.maxLegal, DubzLaws.FixedLegal, "legal") end)
	DarkRP.defineChatCommand("addillegal", function(ply, args) return add(ply, args, illegal, cfg.maxIllegal, DubzLaws.FixedIllegal, "illegal") end)
	DarkRP.defineChatCommand("removelegal", function(ply, args) return remove(ply, args, legal, DubzLaws.FixedLegal, "legal") end)
	DarkRP.defineChatCommand("removeillegal", function(ply, args) return remove(ply, args, illegal, DubzLaws.FixedIllegal, "illegal") end)

	-- The old commands say where things moved
	local function moved(ply)
		say(ply, 1, "Laws are legal or illegal now: use /addlegal or /addillegal, /removelegal or /removeillegal.")
		return ""
	end

	DarkRP.defineChatCommand("addlaw", moved)
	DarkRP.defineChatCommand("removelaw", moved)

	DarkRP.defineChatCommand("resetlaws", function(ply)
		if not canEdit(ply) then say(ply, 1, "Only the mayor can change the laws.") return "" end

		hook.Run("resetLaws", ply)
		DarkRP.resetLaws()
		say(ply, 0, "The laws were reset.")

		return ""
	end)

	send()
end

hook.Add("InitPostEntity", "DubzLaws_Define", function() timer.Simple(1, define) end)

-- The fixed tables arrive from the framework after load; a change there rebuilds the lists (the mayor's laws stay)
DubzLaws.OnFixedChanged = function()
	if not DubzLaws.Defined then return end

	rebuild(true)
	send()
end

hook.Add("InitPostEntity", "DubzLaws_Mark", function() timer.Simple(2, function() DubzLaws.Defined = true end) end)

hook.Add("PlayerInitialSpawn", "DubzLaws_Join", function(ply)
	timer.Simple(5, function() if IsValid(ply) then send(ply) end end)
end)
