-- Refund, server side. The idea: remember what each player bought and still has; if the server restarts or crashes
-- those items are lost, so the next time the character joins they are offered back (respawn or cash).
--
--   live      what a player currently owns from the F4 shop. Saved to the database a moment after every change and
--             when the server shuts down. Deleted when the player leaves normally (the items go with them).
--   pending   what a player is owed after a restart/crash: moved here from `live` when they join, until claimed.
--
-- Other addons can keep extra data with an item:
--   hook.Add("DubzRefundSave", id, function(ent, rec) rec.data = {...} end)
--   hook.Add("DubzRefundRestore", id, function(ent, rec, ply) ... end)
util.AddNetworkString("DubzRefund_Menu")    -- server -> client: the list (JSON)
util.AddNetworkString("DubzRefund_Claim")   -- client -> server: action, index
util.AddNetworkString("DubzRefund_Close")   -- server -> client: nothing left, close the menu

local cfg = DubzRefund.Config

sql.Query("CREATE TABLE IF NOT EXISTS dubz_refund_live (key TEXT PRIMARY KEY, json TEXT NOT NULL, updated INTEGER NOT NULL)")
sql.Query("CREATE TABLE IF NOT EXISTS dubz_refund_pending (key TEXT PRIMARY KEY, json TEXT NOT NULL, updated INTEGER NOT NULL)")

local live = {}          -- ply -> {[ent] = rec}
local pending = {}      -- ply -> {rec, rec, ...}
local shuttingDown = false

local function keyOf(ply)
	local char = DubzChars and DubzChars.Active and DubzChars.Active(ply)
	if char and char.id then return "c" .. char.id end

	return "s" .. (ply:SteamID64() or ply:SteamID())
end

local function say(ply, text, kind)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 6, text) else ply:ChatPrint("[Refund] " .. text) end
end

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

-- Storage ---------------------------------------------------------------------------------------------------------

local function store(tableName, key, list)
	if #list == 0 then
		sql.Query("DELETE FROM " .. tableName .. " WHERE key = " .. sql.SQLStr(key))
	else
		sql.Query(string.format("REPLACE INTO %s (key, json, updated) VALUES (%s, %s, %d)", tableName, sql.SQLStr(key), sql.SQLStr(util.TableToJSON(list)), os.time()))
	end
end

local function fetch(tableName, key)
	local json = sql.QueryValue("SELECT json FROM " .. tableName .. " WHERE key = " .. sql.SQLStr(key))
	return (json and util.JSONToTable(json)) or {}
end

local function liveList(ply)
	local list = {}

	for ent, rec in pairs(live[ply] or {}) do
		if IsValid(ent) then
			local copy = table.Copy(rec)
			hook.Run("DubzRefundSave", ent, copy)
			list[#list + 1] = copy
		end
	end

	return list
end

local function saveLive(ply)
	if IsValid(ply) then store("dubz_refund_live", keyOf(ply), liveList(ply)) end
end

-- Saves a moment after the last change (buying five things in a row writes once)
local function queueSave(ply)
	timer.Create("DubzRefund_Save_" .. ply:UserID(), 3, 1, function() saveLive(ply) end)
end

local function savePending(ply) store("dubz_refund_pending", keyOf(ply), pending[ply] or {}) end

-- Tracking what players buy ---------------------------------------------------------------------------------------

local function track(ply, ent, rec)
	live[ply] = live[ply] or {}
	live[ply][ent] = rec

	-- Gone for any reason (used up, sold, destroyed): no longer owed. A shutdown removes everything; ignore that.
	ent:CallOnRemove("DubzRefund", function()
		if shuttingDown then return end

		if live[ply] then live[ply][ent] = nil end
		if IsValid(ply) then queueSave(ply) end
	end)

	queueSave(ply)
end

local function sizeOf(ent)
	local mins, maxs = ent:GetCollisionBounds()
	if not mins or not maxs then return 0 end

	return math.abs(maxs.x - mins.x) * math.abs(maxs.y - mins.y) * math.abs(maxs.z - mins.z)
end

hook.Add("playerBoughtCustomEntity", "DubzRefund_Track", function(ply, entTable, ent, price)
	if not DubzRefund.Enabled() or not IsValid(ent) then return end

	track(ply, ent, {
		cls = ent:GetClass(), name = entTable.name or ent:GetClass(), cmd = entTable.cmd or "", price = price or entTable.price or 0,
		model = ent:GetModel() or "", vol = math.floor(sizeOf(ent)), bought = os.time(),
	})
end)

hook.Add("ShutDown", "DubzRefund_Shutdown", function()
	shuttingDown = true

	for ply in pairs(live) do saveLive(ply) end
end)

-- A normal leave: the items go with the player and nothing is owed (a restart or crash is what is covered)
hook.Add("PlayerDisconnected", "DubzRefund_Leave", function(ply)
	if shuttingDown then return end

	timer.Remove("DubzRefund_Save_" .. ply:UserID())
	store("dubz_refund_live", keyOf(ply), {})

	live[ply], pending[ply] = nil, nil
end)

-- Joining -----------------------------------------------------------------------------------------------------------

local function modeOf(rec) return DubzRefund.ModeFor(rec) end

local function menuJson(ply)
	local list = {}

	for index, rec in ipairs(pending[ply] or {}) do
		list[#list + 1] = {
			index = index, name = rec.name, model = rec.model, price = rec.price, mode = modeOf(rec),
			cash = math.floor(rec.price * cfg.cashRate / 100),
		}
	end

	return util.TableToJSON({items = list, rate = cfg.cashRate, maxRespawn = cfg.maxRespawn})
end

local function sendMenu(ply)
	if not pending[ply] or #pending[ply] == 0 then
		net.Start("DubzRefund_Close")
		net.Send(ply)
		return
	end

	local json = menuJson(ply)

	net.Start("DubzRefund_Menu")
		net.WriteString(json)
	net.Send(ply)
end

-- Called when a character (or, without characters, the player) is in the world
local function onJoin(ply)
	if not DubzRefund.Enabled() or not IsValid(ply) then return end

	local key = keyOf(ply)

	-- What was saved while they were online last time is owed now; the live record starts over empty
	local owed = fetch("dubz_refund_live", key)
	store("dubz_refund_live", key, {})

	pending[ply] = fetch("dubz_refund_pending", key)

	for _, rec in ipairs(owed) do pending[ply][#pending[ply] + 1] = rec end

	-- Forget old ones
	if cfg.expireDays > 0 then
		local cutoff = os.time() - cfg.expireDays * 86400
		for i = #pending[ply], 1, -1 do
			if (pending[ply][i].bought or os.time()) < cutoff then table.remove(pending[ply], i) end
		end
	end

	savePending(ply)
	live[ply] = {}

	if #pending[ply] > 0 then
		timer.Simple(3, function() if IsValid(ply) then sendMenu(ply) end end)
	end
end

-- A deleted (wiped) character takes what it was owed with it
hook.Add("DubzCharWipe", "DubzRefund_CharWipe", function(account, charId)
	local key = sql.SQLStr("c" .. charId)
	sql.Query("DELETE FROM dubz_refund_live WHERE key = " .. key)
	sql.Query("DELETE FROM dubz_refund_pending WHERE key = " .. key)
end)

hook.Add("DubzCharSelected", "DubzRefund_CharJoin", function(ply) onJoin(ply) end)

-- Switching character: what the old one has deployed is saved as owed to them (their next login offers it back) and
-- taken out of the world, so it can't be used by the next character
hook.Add("DubzCharLeave", "DubzRefund_CharLeave", function(ply)
	if not DubzRefund.Enabled() then return end

	saveLive(ply)
	timer.Remove("DubzRefund_Save_" .. ply:UserID())

	local gone = live[ply] or {}
	live[ply] = {}
	pending[ply] = nil

	local silent = shuttingDown
	shuttingDown = true   -- the removals below must not rewrite the saved list
	for ent in pairs(gone) do if IsValid(ent) then ent:Remove() end end
	shuttingDown = silent
end)

hook.Add("PlayerInitialSpawn", "DubzRefund_Join", function(ply)
	-- With the Characters addon the join waits for the character to be chosen
	if DubzChars and DubzChars.Enabled and DubzChars.Enabled() and not ply:IsBot() then return end

	timer.Simple(4, function() onJoin(ply) end)
end)

hook.Add("PlayerSay", "DubzRefund_Command", function(ply, text)
	if string.lower(string.Trim(text)) ~= string.lower(cfg.chatCommand) then return end

	if not pending[ply] or #pending[ply] == 0 then say(ply, "You have nothing to claim.", 1) return "" end

	sendMenu(ply)
	return ""
end)

-- Claiming ---------------------------------------------------------------------------------------------------------

local function findShopEntry(rec)
	for _, entry in ipairs(DarkRPEntities or {}) do
		if entry.cmd == rec.cmd or entry.ent == rec.cls then return entry end
	end
end

local function atLimit(ply, entry)
	if cfg.surpassLimit or not entry or not entry.max or entry.max <= 0 then return false end
	if not ply.customEntityCount then return false end

	local ok, count = pcall(ply.customEntityCount, ply, entry)
	return ok and (count or 0) >= entry.max
end

-- Puts one item back next to the player, owned by them again. Returns true when it was spawned.
local function respawn(ply, rec, index)
	local entry = findShopEntry(rec)
	if atLimit(ply, entry) then return false, "limit" end

	local ent = ents.Create(rec.cls)
	if not IsValid(ent) then return false, "missing" end

	-- A fan in front of the player so they don't land on top of each other
	local yaw = ply:EyeAngles().y + ((index - 1) % 5 - 2) * 28
	local dir = Angle(0, yaw, 0):Forward()
	local radius = 70 + math.floor((index - 1) / 5) * 45

	local start = ply:GetPos() + Vector(0, 0, 40)
	local trace = util.TraceLine({start = start, endpos = start + dir * radius, filter = ply})
	local pos = trace.Hit and (trace.HitPos - dir * 12) or (start + dir * radius)

	ent:SetPos(pos)
	ent:Spawn()
	ent:Activate()
	ent:DropToFloor()

	-- Ownership, the way the F4 shop does it, so the player can use and own it again
	if ent.Setowning_ent then ent:Setowning_ent(ply) end
	ent.SID = ply.SID
	ent.DarkRPItem = entry
	if ent.CPPISetOwner then pcall(ent.CPPISetOwner, ent, ply) end

	-- The shop's count for this item (limit tracking)
	if entry and ply.addCustomEntity then
		pcall(ply.addCustomEntity, ply, entry)
		ent:CallOnRemove("DubzRefundCount", function() if IsValid(ply) and ply.removeCustomEntity then pcall(ply.removeCustomEntity, ply, entry) end end)
	end

	hook.Run("DubzRefundRestore", ent, rec, ply)

	local fresh = table.Copy(rec)
	fresh.bought = os.time()
	track(ply, ent, fresh)

	return true
end

local function giveCash(ply, rec)
	local amount = math.floor(rec.price * cfg.cashRate / 100)
	if amount > 0 then ply:addMoney(amount) end
	return amount
end

net.Receive("DubzRefund_Claim", function(_, ply)
	local action, index = net.ReadString(), net.ReadUInt(16)

	if not DubzRefund.Enabled() or not ply:Alive() or not pending[ply] or #pending[ply] == 0 then return end
	if (ply.DubzRefundNext or 0) > CurTime() then return end
	ply.DubzRefundNext = CurTime() + 0.6

	local list = pending[ply]
	local cashTotal, spawned = 0, 0

	if action == "cash" then
		local rec = list[index]
		if not rec then return end

		cashTotal = giveCash(ply, rec)
		table.remove(list, index)

	elseif action == "respawn" then
		local rec = list[index]
		if not rec then return end

		if modeOf(rec) ~= "respawn" then say(ply, rec.name .. " can only be taken as cash.", 1) return end

		local ok, why = respawn(ply, rec, 1)
		if not ok then
			say(ply, why == "limit" and ("You already have the most " .. rec.name .. " allowed. Take the cash instead.") or "That item can't be respawned right now.", 1)
			return
		end

		table.remove(list, index)
		spawned = 1

	elseif action == "cashall" then
		for _, rec in ipairs(list) do cashTotal = cashTotal + giveCash(ply, rec) end
		pending[ply] = {}
		list = pending[ply]

	elseif action == "respawnall" then
		-- Everything that may respawn comes back (up to the limit); the rest becomes cash
		local keep = {}

		for _, rec in ipairs(list) do
			local done = false

			if modeOf(rec) == "respawn" and spawned < cfg.maxRespawn then
				local ok = respawn(ply, rec, spawned + 1)
				if ok then spawned, done = spawned + 1, true end
			end

			if not done then
				if modeOf(rec) == "cash" or cfg.overflowToCash then cashTotal = cashTotal + giveCash(ply, rec)
				else keep[#keep + 1] = rec end
			end
		end

		pending[ply] = keep
		list = keep
	else
		return
	end

	savePending(ply)

	local parts = {}
	if spawned > 0 then parts[#parts + 1] = spawned .. " item(s) respawned next to you" end
	if cashTotal > 0 then parts[#parts + 1] = money(cashTotal) .. " refunded" end
	if #parts > 0 then say(ply, table.concat(parts, ", ") .. ".") end

	sendMenu(ply)
end)
