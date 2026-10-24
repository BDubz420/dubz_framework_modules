-- The shop engine, server side: opening a shop, stock and prices, buying, selling, "once per character" rows, and shops that travel.
local cfg = DubzShops.Config

util.AddNetworkString("DubzShops_Open")    -- server -> client: the shop window and what is in it
util.AddNetworkString("DubzShops_Trade")   -- client -> server: buy or sell one row
util.AddNetworkString("DubzShops_Close")   -- server -> client: close the window

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function say(ply, text, kind)
	if not IsValid(ply) then print(text) return end

	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 6, text) else ply:ChatPrint(text) end
end

local function wallet(ply)
	if ply.getDarkRPVar then return ply:getDarkRPVar("money") or 0 end

	return 0
end

-- Once-only rows are remembered per character ----------------------------------------------------------------------------------------------------

sql.Query("CREATE TABLE IF NOT EXISTS dubz_shop_once (sid TEXT, shop TEXT, row TEXT, PRIMARY KEY (sid, shop, row))")

local function charKey(ply)
	if DubzChars and DubzChars.GetKey then return DubzChars.GetKey(ply) end

	return ply:SteamID64() or ply:SteamID()
end

local function tookRow(ply, shop, row)
	return sql.QueryValue("SELECT 1 FROM dubz_shop_once WHERE sid = " .. sql.SQLStr(charKey(ply)) .. " AND shop = " .. sql.SQLStr(shop) .. " AND row = " .. sql.SQLStr(row)) ~= nil
end

local function tookAnyInShop(ply, shop)
	return sql.QueryValue("SELECT 1 FROM dubz_shop_once WHERE sid = " .. sql.SQLStr(charKey(ply)) .. " AND shop = " .. sql.SQLStr(shop)) ~= nil
end

local function markTaken(ply, shop, row)
	sql.Query("INSERT OR IGNORE INTO dubz_shop_once (sid, shop, row) VALUES (" .. sql.SQLStr(charKey(ply)) .. ", " .. sql.SQLStr(shop) .. ", " .. sql.SQLStr(row) .. ")")
end

-- Stock and prices ---------------------------------------------------------------------------------------------------------------------------------
-- Stock is shared by everyone for a shop row: it runs out, then is full again after the row's restock minutes. Prices swing (the shop's Swing %).

local left = {}     -- "shop|row" -> {n = how many are left, refill = when it is full again}
local swing = {}    -- "shop|row" -> price factor
local swungAt = 0

local function key(shop, row) return shop .. "|" .. (row.swingKey or row.id) end

-- How many are left (-1 = never runs out)
local function stockLeft(shop, row)
	local max = math.max(math.floor(tonumber(row.stock) or 0), 0)
	if max == 0 then return -1 end

	local entry = left[key(shop, row)]
	if not entry then
		entry = {n = max, refill = 0}
		left[key(shop, row)] = entry
	end

	if entry.n < max and entry.refill > 0 and CurTime() >= entry.refill then
		entry.n = max
		entry.refill = 0
	end

	if entry.n > max then entry.n = max end

	return entry.n
end

local function takeStock(shop, row)
	local n = stockLeft(shop, row)
	if n < 0 then return end

	local entry = left[key(shop, row)]
	entry.n = math.max(n - 1, 0)

	if entry.refill == 0 then entry.refill = CurTime() + math.max(tonumber(row.restock) or 0, 0.1) * 60 end
end

local function swingFactor(shop, row)
	local def = DubzShops.Get(shop)
	local percent = def and tonumber(def.swing) or 0
	if percent <= 0 then return 1 end

	if CurTime() >= swungAt then
		swungAt = CurTime() + math.max(cfg.PriceChangeMinutes, 1) * 60
		swing = {}
	end

	local k = key(shop, row)
	if not swing[k] then swing[k] = 1 + (math.random() * 2 - 1) * percent / 100 end

	return swing[k]
end

local function priceOf(shop, row)
	local base = math.max(tonumber(row.price) or 0, 0)
	if base == 0 then return 0 end

	return math.max(math.floor(base * swingFactor(shop, row) + 0.5), 1)
end

-- Names and models --------------------------------------------------------------------------------------------------------------------------------

local function classLabel(class)
	if weapons.Get(class) or list.Get("Weapon")[class] then return DubzInv and DubzInv.WeaponName and DubzInv.WeaponName(class) or class end

	local ent = scripted_ents.Get(class)
	if ent and isstring(ent.PrintName) and ent.PrintName ~= "" then return ent.PrintName end

	return class
end

local function classModel(class)
	local swep = weapons.Get(class)
	if swep and isstring(swep.WorldModel) and swep.WorldModel ~= "" then return swep.WorldModel end

	local ent = scripted_ents.Get(class)
	if ent and isstring(ent.Model) and ent.Model ~= "" then return ent.Model end

	return "models/props_junk/cardboard_box001a.mdl"
end

local function rowName(row)
	if row.name and row.name ~= "" then return row.name end

	local items = DubzShops.ParseItems(row.item)

	return items[1] and classLabel(items[1].class) or row.id
end

local function rowModel(row)
	if row.model and row.model ~= "" then return row.model end

	local items = DubzShops.ParseItems(row.item)

	return items[1] and classModel(items[1].class) or "models/props_junk/cardboard_box001a.mdl"
end

-- How an item LOOKS: its colour, material, scale and skin are set by the entity when it spawns, so one is made out of sight once per class and read
-- (then removed). The window draws the item with it, so a tinted or retextured item shows as it really is.
local looks = {}

local function lookOf(class)
	if looks[class] ~= nil then return looks[class] or nil end

	local look = false

	if class and not weapons.Get(class) and scripted_ents.Get(class) and not string.StartWith(class, "spawned_") and class ~= "dubz_item_stack" then
		pcall(function()
			local ent = ents.Create(class)
			if not IsValid(ent) then return end

			ent:SetPos(Vector(0, 0, -15000))
			ent:Spawn()

			if IsValid(ent) then
				local c = ent:GetColor()

				look = {model = ent:GetModel(), mat = ent:GetMaterial(), r = c.r, g = c.g, b = c.b, a = c.a, scale = ent:GetModelScale(), skin = ent:GetSkin()}

				ent.IsPocketing = true
				ent:Remove()
			end
		end)
	end

	looks[class] = look
	return look or nil
end

-- The look for a row's picture: the real entity's, when it has one (its model comes with it, so the picture is always the real thing)
local function lookFor(row)
	local class = row.exact and row.exact.class

	if not class then
		local items = DubzShops.ParseItems(row.item)
		class = items[1] and items[1].class
	end

	return lookOf(class)
end

-- Rules --------------------------------------------------------------------------------------------------------------------------------------------

-- Why this player cannot buy the row ("" = they can)
local function lockedReason(ply, shop, row)
	local jobs = string.Trim(row.job or "")

	if jobs ~= "" then
		local mine, allowed = string.lower(team.GetName(ply:Team()) or ""), false

		for job in string.gmatch(jobs, "[^,]+") do
			if string.lower(string.Trim(job)) == mine then allowed = true break end
		end

		if not allowed then return "For " .. jobs .. " only" end
	end

	if row.once then
		if tookRow(ply, shop, row.id) then return "You already took this" end

		local def = DubzShops.Get(shop)
		if def and def.exclusive and tookAnyInShop(ply, shop) then return "You already picked a path" end
	end

	return ""
end

-- What the player carries of a sell row: the pocket slots whose class (or variant: a weapon) is its item, or exactly the class + variant of a row made from the pocket
local function carried(ply, row)
	local total, found = 0, {}

	if not (DubzInv and DubzInv.GetSlots) then return 0, found end

	for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
		local match

		if row.exact then
			match = rec.class == row.exact.class and (rec.variant or "") == row.exact.variant
		else
			match = rec.class == row.item or rec.variant == row.item
		end

		if istable(rec) and match then
			total = total + (rec.qty or 1)
			found[#found + 1] = index
		end
	end

	table.sort(found)
	return total, found
end

-- The price a shop would pay for one of something nobody listed for sale: what the item is worth (the exchange, weed ...), else what any shop sells
-- it for, at the shop's Buyback %
local function shopPrice(class, variant)
	for _, entry in pairs(DubzShops.Stock) do
		for _, row in ipairs(entry.buy) do
			local items = DubzShops.ParseItems(row.item)

			if #items == 1 and (tonumber(row.price) or 0) > 0 and (items[1].class == class or items[1].class == variant) then return tonumber(row.price) end
		end
	end

	return 0
end

-- What the shop buys from players: its Sell rows, plus everything it sells (one item, not free, not a once-only kit) at its Buyback %
local function sellRows(shop, ply)
	local entry = DubzShops.Stock[shop]
	if not entry then return {} end

	local def = DubzShops.Get(shop)
	local percent = math.Clamp(tonumber(def and def.buyback) or 0, 0, 100)
	local rows, have = {}, {}

	for _, row in ipairs(entry.sell) do
		rows[#rows + 1] = row
		have[row.item] = true
	end

	if percent > 0 then
		for _, row in ipairs(entry.buy) do
			local items = DubzShops.ParseItems(row.item)

			if #items == 1 and items[1].amount == 1 and not row.once and (tonumber(row.price) or 0) > 0 and not have[row.item] then
				rows[#rows + 1] = {id = "bb_" .. row.id, swingKey = row.id, item = row.item, name = row.name, model = row.model, price = math.max(math.floor(row.price * percent / 100), 1)}
				have[row.item] = true
			end
		end
	end

	-- Anything else the player carries: the shop buys it too, at what it is worth (or nothing, when it has no value)
	if percent > 0 and IsValid(ply) and DubzInv and DubzInv.GetSlots then
		local groups, order = {}, {}

		for _, rec in pairs(DubzInv.GetSlots(ply) or {}) do
			if istable(rec) and rec.class ~= "spawned_money" and not have[rec.class] and not (rec.variant and have[rec.variant]) then
				local ident = rec.class .. "|" .. tostring(rec.variant or "")

				if not groups[ident] then
					local value = tonumber(hook.Run("DubzInvItemValue", rec)) or 0
					if value <= 0 then value = shopPrice(rec.class, rec.variant) end

					groups[ident] = {id = "inv|" .. ident, exact = {class = rec.class, variant = tostring(rec.variant or "")}, name = DubzInv.DisplayName(rec), model = rec.model,
						price = value > 0 and math.max(math.floor(value * percent / 100), 1) or 0, swingKey = "inv"}
					order[#order + 1] = groups[ident]
				end
			end
		end

		table.sort(order, function(a, b)
			if (a.price > 0) ~= (b.price > 0) then return a.price > 0 end
			return a.name < b.name
		end)

		for _, row in ipairs(order) do rows[#rows + 1] = row end
	end

	return rows
end

-- The window's contents for one player ---------------------------------------------------------------------------------------------------------

local function payload(ply, shop)
	local def = DubzShops.Get(shop) or {id = shop, name = shop}
	local entry = DubzShops.Stock[shop] or {buy = {}, sell = {}}
	local out = {
		shop = shop, name = def.name or shop, buyLabel = def.buyLabel ~= "" and def.buyLabel or "Buy", sellLabel = def.sellLabel ~= "" and def.sellLabel or "Sell",
		button = def.button ~= "" and def.button or "Buy", money = wallet(ply), buy = {}, sell = {},
		canSell = #entry.sell > 0 or (tonumber(def.buyback) or 0) > 0,
	}

	for _, row in ipairs(entry.buy) do
		local reason = lockedReason(ply, shop, row)
		local items = DubzShops.ParseItems(row.item)
		local count = 0

		for _, it in ipairs(items) do count = count + it.amount end

		out.buy[#out.buy + 1] = {
			id = row.id, name = rowName(row), model = (lookFor(row) or {}).model or rowModel(row), look = lookFor(row), price = priceOf(shop, row), left = stockLeft(shop, row),
			amount = #items > 1 and count or math.max(tonumber(row.amount) or 1, 1), bundle = #items > 1, lock = reason, once = row.once and true or false,
		}
	end

	for _, row in ipairs(sellRows(shop, ply)) do
		local have = carried(ply, row)

		out.sell[#out.sell + 1] = {id = row.id, name = rowName(row), model = (lookFor(row) or {}).model or rowModel(row), look = lookFor(row), price = priceOf(shop, row), have = have}
	end

	return out
end

local function send(ply, shop)
	net.Start("DubzShops_Open")
		net.WriteEntity(ply.DubzShopNPC or NULL)
		net.WriteString(util.TableToJSON(payload(ply, shop)))
	net.Send(ply)
end

-- Opens the shop window for a player. `npc` is who they are talking to (they must stay near).
function DubzShops.Open(ply, npc, shop)
	if not IsValid(ply) or not IsValid(npc) then return end
	if not DubzShops.Get(shop) then say(ply, "This shop is closed.", 1) return end

	ply.DubzShopNPC, ply.DubzShopId = npc, shop

	send(ply, shop)
end

-- Handing things over -----------------------------------------------------------------------------------------------------------------------------

local function inFront(ply)
	local forward = ply:GetAngles()
	forward.p = 0

	return ply:GetPos() + forward:Forward() * 50 + Vector(0, 0, 25)
end

-- One item to the player. Returns whether it worked, and "floor" when it was left in front of them instead.
local function give(ply, kind, class)
	if kind == "weapon" then
		if ply:HasWeapon(class) then return false, "You already have that." end

		local wep = ply:Give(class)
		if not IsValid(wep) then return false, "That can't be given." end

		return true
	end

	local ent = ents.Create(class)
	if not IsValid(ent) then return false, "That item isn't available." end

	ent:SetPos(inFront(ply))
	ent:Spawn()
	ent:Activate()

	if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
	if ent.Setowning_ent then ent:Setowning_ent(ply) end
	if DubzInv and DubzInv.Claim then DubzInv.Claim(ent, ply) end   -- (belongs to its buyer: see the inventory's sv_ownership.lua)

	local pockets = kind == "pocket" and DubzInv and DubzInv.RecordFromEntity and not (DubzInv.IsBagClass and DubzInv.IsBagClass(class))

	if pockets then
		local rec = DubzInv.RecordFromEntity(ent)

		if rec and DubzInv.AddItem(ply, rec) then
			ent.IsPocketing = true
			ent:Remove()
			return true
		end
	end

	return true, "floor"
end

local function deliver(ply, row)
	local floor, failed = false, nil

	for _, it in ipairs(DubzShops.ParseItems(row.item)) do
		local count = it.amount

		if #DubzShops.ParseItems(row.item) == 1 then count = math.max(tonumber(row.amount) or 1, 1) end

		for _ = 1, count do
			local ok, extra = give(ply, row.kind, it.class)

			if not ok then failed = extra elseif extra == "floor" then floor = true end
		end
	end

	return floor, failed
end

-- Buying and selling --------------------------------------------------------------------------------------------------------------------------------

local function findRow(shop, side, id, ply)
	local entry = DubzShops.Stock[shop]
	if not entry then return nil end

	for _, row in ipairs(side == "sell" and sellRows(shop, ply) or entry.buy) do
		if row.id == id then return row end
	end
end

local function buy(ply, shop, row)
	local reason = lockedReason(ply, shop, row)
	if reason ~= "" then say(ply, reason .. ".", 1) return end

	if stockLeft(shop, row) == 0 then say(ply, "That's sold out for now.", 1) return end

	local price = priceOf(shop, row)
	if wallet(ply) < price then say(ply, "You can't afford that.", 1) return end

	if price > 0 then ply:addMoney(-price) end

	local floor, failed = deliver(ply, row)

	-- Nothing could be handed over: the money goes back
	if failed and not floor and #DubzShops.ParseItems(row.item) == 1 then
		if price > 0 then ply:addMoney(price) end
		say(ply, failed, 1)
		return
	end

	takeStock(shop, row)

	if row.once then markTaken(ply, shop, row.id) end

	if cfg.SellMessage then
		say(ply, "You got " .. rowName(row) .. (price > 0 and (" for " .. money(price)) or "") .. "." .. (floor and (row.kind == "ent" and " It is on the floor in front of you." or " Your pocket is full: it is on the floor in front of you.") or ""))
	end
end

local function sell(ply, shop, row, qty)
	local have, slots = carried(ply, row)
	qty = math.min(math.max(qty, 1), have)

	if have <= 0 then say(ply, "You don't have any.", 1) return end
	if priceOf(shop, row) <= 0 then say(ply, "I'm not interested in that.", 1) return end

	local remaining = qty

	for _, index in ipairs(slots) do
		if remaining <= 0 then break end

		local rec = DubzInv.GetSlots(ply)[index]
		if rec then
			local take = math.min(rec.qty or 1, remaining)

			DubzInv.TakeSlot(ply, index, take)
			remaining = remaining - take
		end
	end

	local sold = qty - remaining
	local total = sold * priceOf(shop, row)

	if total > 0 then ply:addMoney(total) end

	if cfg.SellMessage then say(ply, "You sold " .. sold .. " x " .. rowName(row) .. " for " .. money(total) .. ".") end
end

net.Receive("DubzShops_Trade", function(_, ply)
	if not DubzShops.Enabled() or not IsValid(ply) then return end

	local side, id, qty = net.ReadString(), net.ReadString(), net.ReadUInt(8)

	if (ply.DubzShopTradeAt or 0) > CurTime() then return end
	ply.DubzShopTradeAt = CurTime() + 0.25

	local npc, shop = ply.DubzShopNPC, ply.DubzShopId
	if not IsValid(npc) or not shop or ply:GetPos():Distance(npc:GetPos()) > cfg.TalkDistance + 120 then return end

	local row = findRow(shop, side, id, ply)
	if not row then return end

	if side == "sell" then sell(ply, shop, row, qty) else buy(ply, shop, row) end

	if DubzNPCLife and DubzNPCLife.Say then DubzNPCLife.Say(npc, "sale") end

	send(ply, shop)
end)

-- Walking away closes the window
timer.Create("DubzShops_Distance", 1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local npc = ply.DubzShopNPC

		if npc and (not IsValid(npc) or ply:GetPos():Distance(npc:GetPos()) > cfg.TalkDistance + 160) then
			ply.DubzShopNPC, ply.DubzShopId = nil, nil

			net.Start("DubzShops_Close")
			net.Send(ply)
		end
	end
end)

-- Talking ------------------------------------------------------------------------------------------------------------------------------------------

function DubzShops.Talk(ply, npc, shop)
	if not DubzShops.Enabled() then return end

	local def = DubzShops.Get(shop)
	if not def then say(ply, "This shop is closed.", 1) return end

	if DubzNPCLife and DubzNPCLife.Say then DubzNPCLife.Say(npc, "greet") end

	if DubzJobs and DubzJobs.Say then
		DubzJobs.Say(ply, npc, def.name, def.greeting ~= "" and def.greeting or "What can I do for you?", {
			{label = "Show me what you have.", run = function(p)
				if IsValid(npc) and p:GetPos():Distance(npc:GetPos()) <= cfg.TalkDistance + 80 then DubzShops.Open(p, npc, shop) end
			end},
			{label = "Never mind.", run = function() end},
		})
		return
	end

	DubzShops.Open(ply, npc, shop)
end

-- Traveling shops ----------------------------------------------------------------------------------------------------------------------------------
-- A shop with Travels switched on: its NPC is moved between the spots set for the map, staying StayMin to StayMax minutes at each.

local function mapSpots(shop)
	local list = {}

	for _, row in ipairs(DubzShops.Spots) do
		if row.map == game.GetMap() and row.shop == shop then list[#list + 1] = row end
	end

	return list
end

local function spotKey(spot) return spot.x .. "|" .. spot.y .. "|" .. spot.z end

timer.Create("DubzShops_Travel", 15, 0, function()
	if not DubzShops.Enabled() then return end

	for _, npc in ipairs(ents.FindByClass("dubz_shop_*")) do
		local shop = npc.GetShopId and npc:GetShopId()
		local def = shop and DubzShops.Get(shop)

		if def and def.roam and CurTime() >= (npc.MoveAt or 0) then
			local spots, options = mapSpots(shop), {}

			for _, spot in ipairs(spots) do
				if npc.SpotKey ~= spotKey(spot) then options[#options + 1] = spot end
			end

			local spot = options[math.random(#options)] or spots[1]

			if spot and (#spots >= 2 or npc.SpotKey ~= spotKey(spot)) then
				npc:SetPos(Vector(spot.x, spot.y, spot.z))
				npc:SetAngles(Angle(0, spot.yaw or 0, 0))
				if DubzNPCLife and DubzNPCLife.Rehome then DubzNPCLife.Rehome(npc) end
				npc.SpotKey = spotKey(spot)
				npc.SpotName = spot.name
			end

			npc.MoveAt = CurTime() + math.random(math.max(cfg.StayMin, 1), math.max(cfg.StayMax, cfg.StayMin)) * 60
		end
	end
end)

local function superOnly(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then
		say(ply, "Only superadmins set the shops' spots.", 1)
		return false
	end

	return true
end

local function addSpot(ply, shop, name)
	if not (DFW and DFW.Collections and DFW.Collections.Set) then say(ply, "The Dubz Framework isn't there to save it.", 1) return end

	if not DubzShops.Get(shop) then say(ply, "There is no shop called '" .. tostring(shop) .. "'.", 1) return end

	local rows = table.Copy(DFW.Collections.Get("shops", "spots") or {})
	local pos = ply:GetPos()

	rows[#rows + 1] = {
		shop = shop, map = game.GetMap(), name = string.sub(string.Trim(name or ""), 1, 40),
		x = math.Round(pos.x, 1), y = math.Round(pos.y, 1), z = math.Round(pos.z, 1), yaw = math.Round(ply:EyeAngles().y),
	}

	if DFW.Collections.Set("shops", "spots", rows, ply) then say(ply, "Spot added for " .. shop .. " where you stand (" .. game.GetMap() .. "). Switch Travels on for the shop in the Shops table.") end
end

concommand.Add("dubz_shop_addspot", function(ply, _, args)
	if IsValid(ply) and superOnly(ply) then addSpot(ply, args[1] or "store", table.concat(args, " ", 2)) end
end)

hook.Add("PlayerSay", "DubzShops_SpotCommand", function(ply, text)
	local command, shop, name = string.match(string.Trim(text), "^(%S+)%s*(%S*)%s*(.*)$")

	if string.lower(command or "") == "!shopspot" then
		if superOnly(ply) then addSpot(ply, shop ~= "" and shop or "store", name) end
		return ""
	end
end)
