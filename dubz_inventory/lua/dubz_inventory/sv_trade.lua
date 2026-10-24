-- /trade: two players put items (from their inventory / backpack) and cash into a shared window. Each
-- side sees what the other offers. Nothing moves until BOTH have accepted; changing an offer clears both
-- accepts. While trading, inventory actions are blocked so the offered slots can't change.
util.AddNetworkString("DubzTrade_Request")   -- server -> target: someone wants to trade
util.AddNetworkString("DubzTrade_Reply")     -- target -> server: accept / decline
util.AddNetworkString("DubzTrade_Open")      -- server -> both: open the window
util.AddNetworkString("DubzTrade_Offer")     -- client -> server: my items + cash
util.AddNetworkString("DubzTrade_Accept")    -- client -> server: accept / un-accept
util.AddNetworkString("DubzTrade_Update")    -- server -> both: both offers + accept states
util.AddNetworkString("DubzTrade_Cancel")    -- client -> server: cancel
util.AddNetworkString("DubzTrade_Close")     -- server -> client: window closes (with a reason)

local cfg = DubzInv.Config

local function say(ply, text)
	local color = Color(110, 190, 120)

	if DarkRP and DarkRP.talkToPerson then
		DarkRP.talkToPerson(ply, color, "[Trade] ", color_white, text)
	else
		ply:ChatPrint("[Trade] " .. text)
	end
end

local function money(ply)
	return ply:getDarkRPVar("money") or 0
end

-- Sessions --------------------------------------------------------------------------------------------

local function partner(session, ply)
	return session.a == ply and session.b or session.a
end

local function sendUpdate(session)
	for _, ply in ipairs({session.a, session.b}) do
		if IsValid(ply) then
			local other = partner(session, ply)

			net.Start("DubzTrade_Update")
				for _, side in ipairs({ply, other}) do
					local offer = session.offer[side]

					net.WriteUInt(#offer.slots, 8)
					local slots = DubzInv.GetSlots(side)
					for _, index in ipairs(offer.slots) do
						local rec = slots[index]
						local label = rec and (rec.name or rec.class) or "?"
						local amount = offer.qty[index] or (rec and rec.qty) or 1
						if amount > 1 then label = label .. " x" .. amount end
						net.WriteString(label)
						net.WriteString(rec and rec.model or "")
					end

					net.WriteUInt(offer.cash, 32)
					net.WriteBool(session.accepted[side])
				end
			net.Send(ply)
		end
	end
end

local function closeSession(session, reason)
	if session.closed then return end
	session.closed = true

	for _, ply in ipairs({session.a, session.b}) do
		if IsValid(ply) then
			ply.DubzTrade = nil

			net.Start("DubzTrade_Close")
				net.WriteString(reason or "")
			net.Send(ply)
		end
	end
end

local function startSession(a, b)
	local session = {
		a = a, b = b,
		offer = {[a] = {slots = {}, qty = {}, cash = 0}, [b] = {slots = {}, qty = {}, cash = 0}},
		accepted = {[a] = false, [b] = false},
	}

	a.DubzTrade, b.DubzTrade = session, session

	for _, ply in ipairs({a, b}) do
		net.Start("DubzTrade_Open")
			net.WriteEntity(partner(session, ply))
		net.Send(ply)
	end

	sendUpdate(session)
end

-- While trading, inventory actions are blocked so the offered slots stay put.
hook.Add("DubzInvCanAct", "DubzTrade_Block", function(ply)
	if ply.DubzTrade then
		say(ply, "Finish or cancel your trade first.")
		return false
	end
end)

-- Requests --------------------------------------------------------------------------------------------

local function findTarget(ply, query)
	if query and query ~= "" then
		local matches = {}
		for _, other in ipairs(player.GetAll()) do
			if other ~= ply and string.find(string.lower(other:Nick()), string.lower(query), 1, true) then matches[#matches + 1] = other end
		end

		if #matches ~= 1 then
			say(ply, #matches == 0 and "No player matches that name." or "More than one player matches; be more specific.")
			return
		end

		return matches[1]
	end

	local ent = ply:GetEyeTrace().Entity
	if IsValid(ent) and ent:IsPlayer() then return ent end

	say(ply, "Look at a player to trade with them, or use /trade <name>.")
end

local function tooFar(a, b)
	return a:GetPos():Distance(b:GetPos()) > cfg.tradeDistance
end

local function requestTrade(ply, query)
	if ply.DubzTrade then say(ply, "You are already trading.") return end
	if ply:GetNWBool("handies_surrendered", false) then say(ply, "You can't trade with your hands up.") return end

	local target = findTarget(ply, query)
	if not target then return end

	if target == ply then say(ply, "You can't trade with yourself.") return end
	if target.DubzTrade then say(ply, target:Nick() .. " is already trading.") return end
	if tooFar(ply, target) then say(ply, "You are too far away from " .. target:Nick() .. ".") return end

	target.DubzTradeRequest = {from = ply, expires = CurTime() + cfg.tradeRequestTimeout}

	net.Start("DubzTrade_Request")
		net.WriteEntity(ply)
	net.Send(target)

	say(ply, "Trade request sent to " .. target:Nick() .. ".")
end

net.Receive("DubzTrade_Reply", function(_, target)
	local accepted = net.ReadBool()
	local request = target.DubzTradeRequest
	target.DubzTradeRequest = nil

	if not request or request.expires < CurTime() or not IsValid(request.from) then return end

	local from = request.from

	if not accepted then
		say(from, target:Nick() .. " declined the trade.")
		return
	end

	if from.DubzTrade or target.DubzTrade then return end
	if tooFar(from, target) then say(from, "You are too far apart to trade.") say(target, "You are too far apart to trade.") return end

	startSession(from, target)
end)

hook.Add("PlayerSay", "DubzTrade_Command", function(ply, text)
	local lowered = string.lower(string.Trim(text))

	for _, command in ipairs(cfg.tradeCommands) do
		if lowered == command or string.StartWith(lowered, command .. " ") then
			requestTrade(ply, string.Trim(string.sub(text, #command + 1)))
			return ""
		end
	end
end)

-- Offers ------------------------------------------------------------------------------------------------

net.Receive("DubzTrade_Offer", function(_, ply)
	local session = ply.DubzTrade
	if not session or session.closed then return end

	local slots = DubzInv.GetSlots(ply)
	local chosen, seen, amounts = {}, {}, {}

	for _ = 1, math.min(net.ReadUInt(8), cfg.tradeMaxItems) do
		local index = net.ReadUInt(8)
		local qty = net.ReadUInt(16)

		-- Only slots that hold something, each at most once, never more than the stack holds
		if slots[index] and not seen[index] then
			seen[index] = true
			chosen[#chosen + 1] = index
			amounts[index] = math.Clamp(qty, 1, slots[index].qty or 1)
		end
	end

	local cash = math.floor(math.max(0, net.ReadUInt(32)))
	cash = math.min(cash, math.max(0, math.floor(money(ply))))

	-- The Accept button re-sends your offer first; if nothing changed, that must not undo anybody's accept
	local old = session.offer[ply]
	local unchanged = old and old.cash == cash and #old.slots == #chosen
	if unchanged then
		for i, index in ipairs(chosen) do
			if old.slots[i] ~= index or old.qty[index] ~= amounts[index] then unchanged = false break end
		end
	end

	if unchanged then return end

	session.offer[ply] = {slots = chosen, qty = amounts, cash = cash}

	-- Any real change clears both accepts
	session.accepted[session.a], session.accepted[session.b] = false, false
	sendUpdate(session)
end)

-- Completing the trade -------------------------------------------------------------------------------------

local function freeSlots(ply)
	local count = 0
	for i = 1, DubzInv.GetCapacity(ply) do
		if not DubzInv.GetSlots(ply)[i] then count = count + 1 end
	end
	return count
end

local function execute(session)
	local a, b = session.a, session.b
	local offerA, offerB = session.offer[a], session.offer[b]

	-- Re-check everything right before it happens
	for _, side in ipairs({a, b}) do
		if not IsValid(side) or not side:Alive() then closeSession(session, "The trade was cancelled.") return end

		for _, index in ipairs(session.offer[side].slots) do
			local rec = DubzInv.GetSlots(side)[index]
			if not rec or (rec.qty or 1) < session.offer[side].qty[index] then closeSession(session, "The trade was cancelled (items changed).") return end
		end

		if session.offer[side].cash > money(side) then
			session.accepted[a], session.accepted[b] = false, false
			say(side, "You don't have enough money for that offer.")
			sendUpdate(session)
			return
		end
	end

	-- Each side needs room for what they receive (their own offered items free up slots too)
	-- (a slot is only freed when the whole stack in it is offered)
	local function freed(ply, offer)
		local count = 0
		for _, index in ipairs(offer.slots) do
			if offer.qty[index] >= (DubzInv.GetSlots(ply)[index].qty or 1) then count = count + 1 end
		end
		return count
	end

	if #offerB.slots > freeSlots(a) + freed(a, offerA) then
		session.accepted[a], session.accepted[b] = false, false
		say(a, "You don't have enough pocket space for that trade.")
		say(b, a:Nick() .. " doesn't have enough pocket space.")
		sendUpdate(session)
		return
	end

	if #offerA.slots > freeSlots(b) + freed(b, offerB) then
		session.accepted[a], session.accepted[b] = false, false
		say(b, "You don't have enough pocket space for that trade.")
		say(a, b:Nick() .. " doesn't have enough pocket space.")
		sendUpdate(session)
		return
	end

	-- Take everything out first, then hand it over
	local fromA, fromB = {}, {}
	for _, index in ipairs(offerA.slots) do fromA[#fromA + 1] = DubzInv.TakeSlot(a, index, offerA.qty[index]) end
	for _, index in ipairs(offerB.slots) do fromB[#fromB + 1] = DubzInv.TakeSlot(b, index, offerB.qty[index]) end

	for _, rec in ipairs(fromA) do DubzInv.AddItem(b, rec) end
	for _, rec in ipairs(fromB) do DubzInv.AddItem(a, rec) end

	if offerA.cash > 0 then a:addMoney(-offerA.cash) b:addMoney(offerA.cash) end
	if offerB.cash > 0 then b:addMoney(-offerB.cash) a:addMoney(offerB.cash) end

	hook.Run("DubzTradeCompleted", a, b, fromA, offerA.cash, fromB, offerB.cash)

	say(a, "Trade with " .. b:Nick() .. " complete.")
	say(b, "Trade with " .. a:Nick() .. " complete.")
	closeSession(session, "")
end

net.Receive("DubzTrade_Accept", function(_, ply)
	local session = ply.DubzTrade
	if not session or session.closed then return end

	session.accepted[ply] = net.ReadBool()
	sendUpdate(session)

	if session.accepted[session.a] and session.accepted[session.b] then execute(session) end
end)

net.Receive("DubzTrade_Cancel", function(_, ply)
	local session = ply.DubzTrade
	if not session then return end

	say(partner(session, ply), ply:Nick() .. " cancelled the trade.")
	closeSession(session, "")
end)

-- Safety: end the trade if anyone leaves, dies, raises their hands or walks away ------------------------

hook.Add("PlayerDisconnected", "DubzTrade_Disconnect", function(ply)
	local session = ply.DubzTrade
	if not session then return end

	local other = partner(session, ply)
	if IsValid(other) then say(other, ply:Nick() .. " left the trade.") end
	closeSession(session, "")
end)

hook.Add("PlayerDeath", "DubzTrade_Death", function(ply)
	if ply.DubzTrade then closeSession(ply.DubzTrade, "The trade was cancelled.") end
end)

timer.Create("DubzTrade_Watch", 1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local session = ply.DubzTrade

		if session and not session.closed and ply == session.a then
			local b = session.b

			if not IsValid(b) or ply:GetPos():Distance(b:GetPos()) > cfg.tradeDistance * 1.5
				or ply:GetNWBool("handies_surrendered", false) or b:GetNWBool("handies_surrendered", false) then
				closeSession(session, "The trade was cancelled.")
			end
		end
	end
end)
