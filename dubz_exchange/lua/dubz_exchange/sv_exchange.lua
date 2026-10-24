-- Exchange, server side: the bank vault (a private item store per character) and the market (listings anyone can buy from).
--
-- Both keep what they hold in the database under the character's key (DubzInv.GetKey), so they follow the character, not the account.
-- Items are the pocket's own records, so they come back out exactly as they went in (a printer keeps what it had, a gem its colour).
util.AddNetworkString("DubzBank_State")    -- server -> client: the vault (JSON)
util.AddNetworkString("DubzBank_Action")   -- client -> server: deposit / withdraw a slot
util.AddNetworkString("DubzEx_State")      -- server -> client: the market (JSON)
util.AddNetworkString("DubzEx_Action")     -- client -> server: sell / buy / cancel / collect
util.AddNetworkString("DubzEx_Close")      -- client -> server: the exchange window was closed

local cfg = DubzExchange.Config

sql.Query("CREATE TABLE IF NOT EXISTS dubz_vault (sid TEXT PRIMARY KEY, data TEXT NOT NULL)")
sql.Query([[CREATE TABLE IF NOT EXISTS dubz_exchange (
	id INTEGER PRIMARY KEY AUTOINCREMENT, seller TEXT NOT NULL, seller_name TEXT NOT NULL, class TEXT NOT NULL, variant TEXT,
	name TEXT NOT NULL, model TEXT, qty INTEGER NOT NULL, price INTEGER NOT NULL, rec TEXT NOT NULL, look TEXT, created INTEGER NOT NULL)]])
sql.Query("CREATE TABLE IF NOT EXISTS dubz_exchange_cash (sid TEXT PRIMARY KEY, amount INTEGER NOT NULL)")

sql.Query("CREATE TABLE IF NOT EXISTS dubz_exchange_rate (k TEXT PRIMARY KEY, avg REAL NOT NULL, sales INTEGER NOT NULL)")

local function say(ply, text, kind)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 5, text) else ply:ChatPrint(text) end
end

local function money(amount)
	return DarkRP and DarkRP.formatMoney and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function key(ply) return DubzInv.GetKey(ply) end

local function premium(ply)
	return DubzChars and DubzChars.PremiumGroups and DubzChars.PremiumGroups[string.lower(ply:GetUserGroup() or "")] == true
end

-- How an item is sent to a window: a name, a model and (for coloured things) its look. Never the saved entity data.
local function look(rec)
	local data = rec.data
	local color, material = data and data.Color, data and data.Material

	local tinted = istable(color) and ((color.r or 255) ~= 255 or (color.g or 255) ~= 255 or (color.b or 255) ~= 255)
	local shiny = isstring(material) and material ~= ""

	if not (tinted or shiny) then return nil end
	return {r = tinted and color.r or 255, g = tinted and color.g or 255, b = tinted and color.b or 255, m = shiny and material or ""}
end

local function compact(rec)
	local l = look(rec)
	return {name = DubzInv.DisplayName(rec), model = rec.model or "", class = rec.class, qty = rec.qty or 1, look = l, value = DubzExchange.Value(rec.class, rec.variant or "")}
end

-- Is there room in the pocket for `qty` of this?
local function hasRoom(ply, rec, qty)
	local slots = DubzInv.GetSlots(ply)
	local limit = DubzInv.GetStackLimit(rec.class, rec.model, rec.variant)
	local space = 0

	for index = 1, DubzInv.GetCapacity(ply) do
		local slot = slots[index]

		if not slot then
			space = space + limit
		elseif limit > 1 and slot.class == rec.class and slot.model == rec.model and (slot.variant or "") == (rec.variant or "") then
			space = space + math.max(limit - (slot.qty or 1), 0)
		end
	end

	return space >= qty
end

-- Going rates ---------------------------------------------------------------------------------------------------------------------
-- What an item is worth: until it has sold here, its base value; after that, what it has been selling for.

local rates = {}   -- "class:variant" -> average price
for _, row in ipairs(sql.Query("SELECT k, avg FROM dubz_exchange_rate") or {}) do rates[row.k] = tonumber(row.avg) end

local function rateKey(class, variant) return class .. ":" .. (variant or "") end

-- The value before any sale: the table, then the addon the item belongs to, then the F4 shop price
function DubzExchange.BaseValue(class, variant)
	local set = DubzExchange.BaseValues
	local exact = set[rateKey(class, variant)] or set[class]
	if exact and exact > 0 then return exact end

	local hooked = hook.Run("DubzExchangeBaseValue", class, variant)
	hooked = tonumber(hooked)
	if hooked and hooked > 0 then return hooked end

	local entry = DubzInv.ShopEntry and DubzInv.ShopEntry(class)
	if entry and tonumber(entry.price) then return tonumber(entry.price) end

	-- A weapon lying on the ground is a "spawned weapon" whose variant is the weapon
	if class == "spawned_weapon" and variant and variant ~= "" and CustomShipments then
		for _, shipment in pairs(CustomShipments) do
			if shipment.entity == variant then return tonumber(shipment.pricesep) or tonumber(shipment.price) end
		end
	end
end

-- The going rate: 0 when nothing says what the item is worth
function DubzExchange.Value(class, variant)
	local rate = rates[rateKey(class, variant)]
	if rate then return math.max(1, math.Round(rate)) end

	local base = DubzExchange.BaseValue(class, variant)
	return base and math.max(1, math.Round(base)) or 0
end

-- A sale at `price` moves the going rate toward it
local function recordSale(class, variant, price)
	local k = rateKey(class, variant)
	local weight = math.Clamp(cfg.rateWeight, 1, 100) / 100
	local old = rates[k] or DubzExchange.BaseValue(class, variant)

	-- (a first sale is balanced against the base value so one odd price doesn't set the rate)
	local new = old and (old * (1 - weight) + price * weight) or price
	rates[k] = new

	local sales = (tonumber(sql.QueryValue("SELECT sales FROM dubz_exchange_rate WHERE k = " .. sql.SQLStr(k))) or 0) + 1
	sql.Query("REPLACE INTO dubz_exchange_rate (k, avg, sales) VALUES (" .. sql.SQLStr(k) .. ", " .. new .. ", " .. sales .. ")")
end

-- Every pocket and backpack shows it when you hover over an item
hook.Add("DubzInvItemValue", "DubzExchange_Value", function(rec)
	return DubzExchange.Value(rec.class, rec.variant or "")
end)

-- Close enough to the NPC the window belongs to?
local function near(ply, field)
	local npc = ply[field]
	return IsValid(npc) and ply:GetPos():Distance(npc:GetPos()) <= cfg.useDistance * 1.5
end

-- The bank vault -------------------------------------------------------------------------------------------------------------

local function vaultSize(ply) return premium(ply) and cfg.bankSlotsPremium or cfg.bankSlots end

local function loadVault(ply)
	local current = key(ply)

	if ply.DubzVault and ply.DubzVaultKey == current then return ply.DubzVault end

	local text = sql.QueryValue("SELECT data FROM dubz_vault WHERE sid = " .. sql.SQLStr(current))
	local data = text and DubzInv.FromJSON(text)

	ply.DubzVault = data and data.slots or {}
	ply.DubzVaultKey = current
	return ply.DubzVault
end

local function saveVault(ply)
	if not ply.DubzVault then return end
	sql.Query("REPLACE INTO dubz_vault (sid, data) VALUES (" .. sql.SQLStr(ply.DubzVaultKey or key(ply)) .. ", " .. sql.SQLStr(DubzInv.ToJSON({slots = ply.DubzVault})) .. ")")
end

-- Put a record in the vault (stacking where it can). False when there is no room; rec.qty is then what is left over.
local function vaultAdd(ply, rec)
	local slots, size = loadVault(ply), vaultSize(ply)
	rec.qty = rec.qty or 1

	-- Cash in the vault is one stack with the total: more is added to it (so the vault holds money like an ATM)
	if rec.class == "spawned_money" and rec.data and rec.data.DT then
		local added = math.max(tonumber(rec.data.DT.amount) or 0, 0)

		for index = 1, size do
			local slot = slots[index]

			if slot and slot.class == "spawned_money" and slot.data and slot.data.DT then
				slot.data.DT.amount = (tonumber(slot.data.DT.amount) or 0) + added
				slot.name = "Cash ($" .. string.Comma(slot.data.DT.amount) .. ")"
				slot.qty = 1
				return true
			end
		end

		rec.name = "Cash ($" .. string.Comma(added) .. ")"
		rec.qty = 1
	end

	local limit = DubzInv.GetStackLimit(rec.class, rec.model, rec.variant)

	if limit > 1 then
		for index = 1, size do
			local slot = slots[index]

			if slot and slot.class == rec.class and slot.model == rec.model and (slot.variant or "") == (rec.variant or "") and (slot.qty or 1) < limit then
				local add = math.min(limit - (slot.qty or 1), rec.qty)
				slot.qty = (slot.qty or 1) + add
				rec.qty = rec.qty - add

				if rec.qty <= 0 then return true end
			end
		end
	end

	for index = 1, size do
		if not slots[index] then
			slots[index] = rec
			return true
		end
	end

	return false
end

local function sendVault(ply)
	local slots = loadVault(ply)
	local items = {}

	for index = 1, vaultSize(ply) do
		if slots[index] then
			local item = compact(slots[index])
			item.slot = index
			items[#items + 1] = item
		end
	end

	net.Start("DubzBank_State")
		net.WriteString(util.TableToJSON({size = vaultSize(ply), items = items, title = cfg.tellerName}))
	net.Send(ply)
end

function DubzExchange.OpenBank(ply, npc)
	ply.DubzBankNpc = npc
	sendVault(ply)
end

net.Receive("DubzBank_Action", function(_, ply)
	local action, slot, second = net.ReadString(), net.ReadUInt(8), net.ReadUInt(8)

	if not DubzExchange.Enabled() or not near(ply, "DubzBankNpc") then return end
	if (ply.DubzBankNext or 0) > CurTime() then return end
	ply.DubzBankNext = CurTime() + 0.2

	if action == "deposit" or action == "deposit1" then
		local peek = DubzInv.GetSlots(ply)[slot]
		if peek and DubzInv.NeverPocket[string.lower(peek.class or "")] then return end

		local rec = DubzInv.TakeSlot(ply, slot, action == "deposit1" and 1 or nil)
		if not rec then return end

		if not vaultAdd(ply, rec) then
			DubzInv.AddItem(ply, rec)   -- what did not fit goes back
			say(ply, "Your vault is full.", 1)
		end

		saveVault(ply)
	elseif action == "vmove" then
		-- Rearranging the vault: onto the same stackable thing merges, otherwise the two slots swap
		local slots, size = loadVault(ply), vaultSize(ply)
		if slot == second or slot < 1 or second < 1 or slot > size or second > size then return end

		local a, b = slots[slot], slots[second]
		if not a then return end

		local merged = false

		if b and a.class == b.class and a.model == b.model and (a.variant or "") == (b.variant or "") then
			local limit = DubzInv.GetStackLimit(a.class, a.model, a.variant)

			if limit > 1 and (b.qty or 1) < limit then
				local move = math.min(limit - (b.qty or 1), a.qty or 1)
				b.qty = (b.qty or 1) + move
				a.qty = (a.qty or 1) - move
				if a.qty <= 0 then slots[slot] = nil end

				merged = true
			end
		end

		if not merged then slots[slot], slots[second] = b, a end

		saveVault(ply)
	elseif action == "withdraw" or action == "withdraw1" then
		local slots = loadVault(ply)
		local rec = slots[slot]
		if not rec or slot > vaultSize(ply) then return end

		local give = table.Copy(rec)
		give.qty = action == "withdraw1" and 1 or (rec.qty or 1)

		local before = give.qty
		local added = DubzInv.AddItem(ply, give)
		local moved = added and before or (before - give.qty)

		if moved <= 0 then say(ply, "Your pocket is full.", 1) return end

		rec.qty = (rec.qty or 1) - moved
		if rec.qty <= 0 then slots[slot] = nil end

		saveVault(ply)
	end

	sendVault(ply)
end)

hook.Add("DubzCharLeave", "DubzExchange_Leave", function(ply)
	saveVault(ply)
	ply.DubzVault = nil
end)

hook.Add("DubzCharLoad", "DubzExchange_Load", function(ply) ply.DubzVault = nil end)
hook.Add("PlayerDisconnected", "DubzExchange_Disconnect", saveVault)

-- A wiped character takes its vault, listings and waiting cash with it
hook.Add("DubzCharWipe", "DubzExchange_Wipe", function(account, charId, keys)
	for _, k in ipairs(keys) do
		sql.Query("DELETE FROM dubz_vault WHERE sid = " .. sql.SQLStr(k))
		sql.Query("DELETE FROM dubz_exchange WHERE seller = " .. sql.SQLStr(k))
		sql.Query("DELETE FROM dubz_exchange_cash WHERE sid = " .. sql.SQLStr(k))
	end
end)

-- The market -------------------------------------------------------------------------------------------------------------------

local function listingSlots(ply) return premium(ply) and cfg.listingSlotsPremium or cfg.listingSlots end

local function waitingCash(sid)
	return tonumber(sql.QueryValue("SELECT amount FROM dubz_exchange_cash WHERE sid = " .. sql.SQLStr(sid))) or 0
end

local function addCash(sid, amount)
	sql.Query("REPLACE INTO dubz_exchange_cash (sid, amount) VALUES (" .. sql.SQLStr(sid) .. ", " .. (waitingCash(sid) + amount) .. ")")
end

local function rowToListing(row, mine)
	return {
		id = tonumber(row.id), seller = row.seller_name, mine = mine,
		-- (listings made before weapons were named properly still say "Spawned Weapon": name them from the weapon)
		name = (row.class == "spawned_weapon" and row.variant and row.variant ~= "") and DubzInv.WeaponName(row.variant) or row.name, class = row.class, model = row.model or "", value = DubzExchange.Value(row.class, row.variant or ""),
		qty = tonumber(row.qty), price = tonumber(row.price), look = row.look and row.look ~= "" and util.JSONToTable(row.look) or nil,
	}
end

local function sendMarket(ply)
	local me = key(ply)

	local listings = {}
	for _, row in ipairs(sql.Query("SELECT id, seller, seller_name, class, variant, name, model, qty, price, look FROM dubz_exchange ORDER BY id DESC LIMIT " .. math.floor(cfg.browseLimit)) or {}) do
		listings[#listings + 1] = rowToListing(row, row.seller == me)
	end

	-- Everything this character has listed, even what is older than the browse list reaches
	local mine = {}
	for _, row in ipairs(sql.Query("SELECT id, seller, seller_name, class, variant, name, model, qty, price, look FROM dubz_exchange WHERE seller = " .. sql.SQLStr(me) .. " ORDER BY id DESC") or {}) do
		mine[#mine + 1] = rowToListing(row, true)
	end

	net.Start("DubzEx_State")
		net.WriteString(util.TableToJSON({
			title = cfg.clerkName, listings = listings, mine = mine, cash = waitingCash(me), slots = listingSlots(ply),
			tax = cfg.taxPercent, maxPrice = cfg.maxPrice,
		}))
	net.Send(ply)
end

-- Everyone with the exchange window open sees changes as they happen: a sale, a new listing, a listing taken down
local viewers = {}

local function refreshViewers()
	for viewer in pairs(viewers) do
		if IsValid(viewer) and near(viewer, "DubzExNpc") then sendMarket(viewer) else viewers[viewer] = nil end
	end
end

function DubzExchange.OpenExchange(ply, npc)
	ply.DubzExNpc = npc
	viewers[ply] = true
	sendMarket(ply)
end

net.Receive("DubzEx_Close", function(_, ply) viewers[ply] = nil end)
hook.Add("PlayerDisconnected", "DubzExchange_Viewers", function(ply) viewers[ply] = nil end)

local function tell(sid, text)
	for _, other in ipairs(player.GetAll()) do
		if key(other) == sid then say(other, text) return end
	end
end

local actions = {}

-- List items from the pocket: slot, how many, the price of each
actions.sell = function(ply, slot, qty, price)
	local rec = DubzInv.GetSlots(ply)[slot]
	if not rec then return end

	if table.HasValue(DubzExchange.Blocked, string.lower(rec.class)) then say(ply, "That can't be sold here.", 1) return end
	if qty < 1 or qty > (rec.qty or 1) then say(ply, "You don't have that many.", 1) return end
	if price < 1 or price > cfg.maxPrice then say(ply, "Pick a price between $1 and " .. money(cfg.maxPrice) .. ".", 1) return end

	local mine = tonumber(sql.QueryValue("SELECT COUNT(*) FROM dubz_exchange WHERE seller = " .. sql.SQLStr(key(ply)))) or 0
	if mine >= listingSlots(ply) then say(ply, "You already have " .. mine .. " listings. Cancel or sell one first.", 1) return end

	local taken = DubzInv.TakeSlot(ply, slot, qty)
	if not taken then return end

	-- (an older saved weapon has no variant: take it from the weapon so it lists, stacks and prices as that weapon)
	if taken.class == "spawned_weapon" and (not taken.variant or taken.variant == "") then
		taken.variant = taken.data and taken.data.DT and taken.data.DT.WeaponClass or ""
	end

	local l = look(taken)

	sql.Query(string.format(
		"INSERT INTO dubz_exchange (seller, seller_name, class, variant, name, model, qty, price, rec, look, created) VALUES (%s, %s, %s, %s, %s, %s, %d, %d, %s, %s, %d)",
		sql.SQLStr(key(ply)), sql.SQLStr(ply:Nick()), sql.SQLStr(taken.class), sql.SQLStr(taken.variant or ""), sql.SQLStr(DubzInv.DisplayName(taken)),
		sql.SQLStr(taken.model or ""), taken.qty or qty, price, sql.SQLStr(DubzInv.ToJSON(taken)), sql.SQLStr(l and util.TableToJSON(l) or ""), os.time()))

	say(ply, "Listed " .. (taken.qty or qty) .. " x " .. (taken.name or taken.class) .. " for " .. money(price) .. " each.")
end

-- Buy from a listing: its id, how many
actions.buy = function(ply, id, qty)
	local row = sql.Query("SELECT * FROM dubz_exchange WHERE id = " .. math.floor(id))
	row = row and row[1]
	if not row then say(ply, "That listing is gone.", 1) return end

	if row.seller == key(ply) then say(ply, "That is your own listing. Cancel it instead.", 1) return end

	local have = tonumber(row.qty)
	if qty < 1 or qty > have then say(ply, "There aren't that many left.", 1) return end

	local rec = DubzInv.FromJSON(row.rec)
	if not rec then say(ply, "That listing is broken.", 1) return end

	rec.qty = qty

	local cost = tonumber(row.price) * qty
	if not ply:canAfford(cost) then say(ply, "That costs " .. money(cost) .. ". You can't afford it.", 1) return end
	if not hasRoom(ply, rec, qty) then say(ply, "Your pocket is full.", 1) return end

	-- The listing shrinks (or goes) first, so two buyers can't have the same item
	if qty >= have then
		sql.Query("DELETE FROM dubz_exchange WHERE id = " .. math.floor(id))
	else
		local left = DubzInv.FromJSON(row.rec)
		left.qty = have - qty
		sql.Query("UPDATE dubz_exchange SET qty = " .. (have - qty) .. ", rec = " .. sql.SQLStr(DubzInv.ToJSON(left)) .. " WHERE id = " .. math.floor(id))
	end

	ply:addMoney(-cost)
	DubzInv.AddItem(ply, rec)
	DubzInv.PlaySound(ply, "pickup")

	local net_ = cost - math.floor(cost * cfg.taxPercent / 100)
	addCash(row.seller, net_)
	recordSale(row.class, row.variant or "", tonumber(row.price))

	say(ply, "Bought " .. qty .. " x " .. row.name .. " for " .. money(cost) .. ".")
	tell(row.seller, "Sold " .. qty .. " x " .. row.name .. " on the exchange: " .. money(net_) .. " is waiting for you at the " .. cfg.clerkName .. ".")
end

-- Take a listing down: the items come back to the pocket
actions.cancel = function(ply, id)
	local row = sql.Query("SELECT * FROM dubz_exchange WHERE id = " .. math.floor(id))
	row = row and row[1]
	if not row or row.seller ~= key(ply) then return end

	local rec = DubzInv.FromJSON(row.rec)
	if not rec then return end

	if not hasRoom(ply, rec, rec.qty or 1) then say(ply, "Your pocket is full.", 1) return end

	sql.Query("DELETE FROM dubz_exchange WHERE id = " .. math.floor(id))
	DubzInv.AddItem(ply, rec)

	say(ply, "Took your listing down.")
end

-- Pick up what sales have earned
actions.collect = function(ply)
	local amount = waitingCash(key(ply))
	if amount <= 0 then say(ply, "Nothing is waiting for you.", 1) return end

	sql.Query("DELETE FROM dubz_exchange_cash WHERE sid = " .. sql.SQLStr(key(ply)))
	ply:addMoney(amount)

	say(ply, "You collected " .. money(amount) .. " from your sales.")
end

net.Receive("DubzEx_Action", function(_, ply)
	local action, a, b, c = net.ReadString(), net.ReadUInt(32), net.ReadUInt(32), net.ReadUInt(32)

	if not DubzExchange.Enabled() or not near(ply, "DubzExNpc") or not actions[action] then return end
	if (ply.DubzExNext or 0) > CurTime() then return end
	ply.DubzExNext = CurTime() + 0.3

	actions[action](ply, a, b, c)

	viewers[ply] = true
	refreshViewers()
end)
