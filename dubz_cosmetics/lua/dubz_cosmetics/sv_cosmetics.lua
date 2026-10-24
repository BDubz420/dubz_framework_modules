-- Accessories and clothing, server side.
--
-- ACCESSORIES are inventory items: a small suitcase you carry (dubz_cosmetic record) that you can drop, trade or
-- stash in a backpack like anything else. "Wearing" one takes it out of your inventory and puts it in its slot
-- (hat, face, neck, back); taking it off puts it back in your inventory (on the floor if you're full).
-- What is worn is saved per player and networked as dubz_cos_<slot> = item id. Clothing never drops on death;
-- accessories listed in Config.dropOnDeath fall off where you die.
--
-- CLOTHING is the player model you pick at the clothing store (see sh_clothing.lua), saved per player and applied
-- whenever your model is set.
util.AddNetworkString("DubzCos_Open")         -- server -> client: open the equipment window
util.AddNetworkString("DubzCos_Unequip")      -- client -> server: take off the item in a slot
util.AddNetworkString("DubzCos_Offsets")      -- server -> clients: all saved placement offsets (JSON)
util.AddNetworkString("DubzCos_SaveOffset")   -- admin client -> server: save one placement
util.AddNetworkString("DubzCos_ResetOffset")  -- admin client -> server: remove a saved placement
util.AddNetworkString("DubzCos_AdminStock")   -- admin client -> server: put an item on / off sale (id, on)
util.AddNetworkString("DubzCos_StockInfo")    -- server -> admin client: minted counts (JSON)

local cfg = DubzCosmetics.Config

sql.Query("CREATE TABLE IF NOT EXISTS dubz_cos_worn (sid TEXT NOT NULL, slot TEXT NOT NULL, id TEXT NOT NULL, PRIMARY KEY (sid, slot))")
sql.Query("CREATE TABLE IF NOT EXISTS dubz_cos_minted (id TEXT NOT NULL PRIMARY KEY, n INTEGER NOT NULL DEFAULT 0)")
sql.Query("CREATE TABLE IF NOT EXISTS dubz_cos_outfit (sid TEXT NOT NULL PRIMARY KEY, id TEXT NOT NULL)")   -- the look (face id)
sql.Query("CREATE TABLE IF NOT EXISTS dubz_cos_clothes (sid TEXT NOT NULL, id TEXT NOT NULL, worn INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (sid, id))")

local function keyOf(ply)
	if DubzChars and DubzChars.GetKey then return DubzChars.GetKey(ply) end
	return ply:SteamID64() or ply:SteamID()
end

function DubzCosmetics.Say(ply, text)
	local color = Color(190, 140, 220)

	if DarkRP and DarkRP.talkToPerson then
		DarkRP.talkToPerson(ply, color, "[Cosmetics] ", color_white, text)
	else
		ply:ChatPrint("[Cosmetics] " .. text)
	end
end
local say = DubzCosmetics.Say

-- Limited editions: every copy gets a serial number ("neon_halo#7"). Minted counts survive restarts.
for _, row in ipairs(sql.Query("SELECT id, n FROM dubz_cos_minted") or {}) do DubzCosmetics.Minted[row.id] = tonumber(row.n) end

-- Mints the next copy of a supply-limited item and returns its serial id. Unlimited items return the plain id.
-- Returns nil when it is sold out.
function DubzCosmetics.Mint(id)
	local econ = DubzCosmetics.GetEcon(id)
	if econ.supply <= 0 then return id end

	local n = DubzCosmetics.Minted[id] or 0
	if n >= econ.supply then return nil end

	n = n + 1
	DubzCosmetics.Minted[id] = n
	sql.Query("REPLACE INTO dubz_cos_minted (id, n) VALUES (" .. sql.SQLStr(id) .. ", " .. n .. ")")

	-- Last one sold: pull it from the shop and tell everyone
	if n >= econ.supply then
		econ.shop = false
		local def = DubzCosmetics.Get(id)
		if def and cfg.soldOutMessage ~= "" then DubzCosmetics.Announce(string.format(cfg.soldOutMessage, def.name)) end
	end

	return id .. "#" .. n
end

function DubzCosmetics.Announce(text)
	local color = Color(190, 140, 220)

	for _, ply in ipairs(player.GetAll()) do
		if DarkRP and DarkRP.talkToPerson then
			DarkRP.talkToPerson(ply, color, "[Cosmetics] ", color_white, text)
		else
			ply:ChatPrint("[Cosmetics] " .. text)
		end
	end
end

-- Puts an item on or off sale. Putting it on sale announces it to the whole server.
function DubzCosmetics.SetShop(id, on)
	local def, econ = DubzCosmetics.Get(id), DubzCosmetics.Econ[id]
	if not def or not econ or def.virtual then return false end

	if on and not DubzCosmetics.IsForSale(id) then
		econ.shop = true
		if not DubzCosmetics.IsForSale(id) then econ.shop = false return false end
	end

	local was = econ.shop
	econ.shop = on and true or false

	-- Keep the Catalog table's "On sale" column in step so it survives restarts
	if DFW and DFW.Collections and DFW.Collections.Get then
		local rows = table.Copy(DFW.Collections.Get("cosmetics", "catalog") or {})
		for _, row in ipairs(rows) do
			if row.id == id then row.shop = econ.shop end
		end
		DFW.Collections.Set("cosmetics", "catalog", rows, "dubz_cosmetics")
	end

	if on and not was then
		local limited = econ.tier ~= "common" or econ.supply > 0
		local msg = limited and cfg.stockLimitedMessage or cfg.stockMessage
		if limited and cfg.revealSupply and econ.supply > 0 then msg = msg .. " Only " .. econ.supply .. " will ever exist." end
		if msg ~= "" then DubzCosmetics.Announce(string.format(msg, def.name)) end
	end

	return true
end

net.Receive("DubzCos_AdminStock", function(_, ply)
	if not ply:IsAdmin() then return end

	local id, on = net.ReadString(), net.ReadBool()
	if not DubzCosmetics.SetShop(id, on) then say(ply, "That item can't be put on sale (check its price and supply).") end

	net.Start("DubzCos_StockInfo")
		net.WriteString(util.TableToJSON(DubzCosmetics.Minted))
	net.Send(ply)
end)

-- Inventory records -------------------------------------------------------------------------------------------

-- The inventory record for an accessory. `data` is what the inventory uses to put it back in the world as the
-- dubz_cosmetic entity (see lua/entities/dubz_cosmetic).
function DubzCosmetics.MakeRecord(id)
	local def = DubzCosmetics.Get(id)
	if not def or def.virtual then return nil end

	return {
		class = "dubz_cosmetic", name = DubzCosmetics.DisplayName(id), model = cfg.caseModel, qty = 1, variant = id,
		data = {Class = "dubz_cosmetic", Model = cfg.caseModel, DubzCosID = id},
	}
end

-- Items on the floor turn back into records when picked up
hook.Add("DubzInvMakeRecord", "DubzCos_Record", function(ent)
	if ent:GetClass() ~= "dubz_cosmetic" then return end
	return DubzCosmetics.MakeRecord(ent:GetCosID())
end)

-- Using the item from the inventory wears it
hook.Add("DubzInvUseItem", "DubzCos_Use", function(ply, rec)
	if rec.class ~= "dubz_cosmetic" then return end

	local id = rec.data and rec.data.DubzCosID
	if not id or not DubzCosmetics.Get(id) then return false end

	return DubzCosmetics.Equip(ply, id)
end)

-- Puts an accessory on the ground in front of / under a player. Returns the entity (nil if it couldn't be made).
local function dropToFloor(ply, id, inFront)
	local ent = ents.Create("dubz_cosmetic")
	if not IsValid(ent) then
		ErrorNoHalt("[DubzCosmetics] the dubz_cosmetic entity isn't installed (lua/entities/dubz_cosmetic), so accessories can't be put on the ground.\n")
		return nil
	end

	ent:SetCosID(id)
	ent:SetPos(ply:GetPos() + ply:GetForward() * 30 + Vector(0, 0, 20))
	ent:Spawn()
	ent:Activate()

	-- Dropped from the inventory: place it where the player is looking, like any other dropped item
	if inFront and DubzInv and DubzInv.PlaceInFront then DubzInv.PlaceInFront(ent, ply) end

	return ent
end

-- Dropping the item from the inventory puts the suitcase on the ground
hook.Add("DubzInvDropItem", "DubzCos_Drop", function(ply, rec)
	if rec.class ~= "dubz_cosmetic" then return end

	local id = rec.data and rec.data.DubzCosID
	if not id or not DubzCosmetics.Get(id) then return end

	return dropToFloor(ply, id, true)
end)

-- Gives an accessory to a player as an inventory item. Returns true, or false and a reason.
function DubzCosmetics.Give(ply, id)
	local rec = DubzCosmetics.MakeRecord(id)
	if not rec then return false, "That isn't an accessory." end

	if DubzInv and DubzInv.AddItem then return DubzInv.AddItem(ply, rec) end

	-- No inventory installed: just wear it
	return DubzCosmetics.Equip(ply, id)
end

-- Worn state ---------------------------------------------------------------------------------------------------

local function saveWorn(ply, slotId, id)
	if id and id ~= "" then
		sql.Query("REPLACE INTO dubz_cos_worn (sid, slot, id) VALUES (" .. sql.SQLStr(keyOf(ply)) .. ", " .. sql.SQLStr(slotId) .. ", " .. sql.SQLStr(id) .. ")")
	else
		sql.Query("DELETE FROM dubz_cos_worn WHERE sid = " .. sql.SQLStr(keyOf(ply)) .. " AND slot = " .. sql.SQLStr(slotId))
	end
end

local function setSlot(ply, slotId, id)
	ply:SetNWString("dubz_cos_" .. slotId, id or "")
	saveWorn(ply, slotId, id)
end

-- Is this accessory worn, or sitting in the player's inventory?
function DubzCosmetics.Has(ply, id)
	local def = DubzCosmetics.Get(id)
	if not def then return false end
	if DubzCosmetics.GetWornItem(ply, def.slot) == id then return true end

	if DubzInv and DubzInv.GetSlots then
		for _, rec in pairs(DubzInv.GetSlots(ply) or {}) do
			if rec.class == "dubz_cosmetic" and rec.data and rec.data.DubzCosID == id then return true end
		end
	end

	return false
end

-- Takes the accessory in a slot off. It goes back into the inventory, or onto the floor if there's no room.
function DubzCosmetics.Unequip(ply, slotId)
	local id = DubzCosmetics.GetWornItem(ply, slotId)
	if id == "" then return false end

	setSlot(ply, slotId, "")

	local ok = DubzInv and DubzInv.AddItem and DubzCosmetics.Give(ply, id)
	if not ok then
		dropToFloor(ply, id)
		say(ply, "Your pocket is full, so it was put on the ground.")
	end

	return true
end

-- Wears an accessory that is NOT in the inventory any more (the caller already took it). Whatever was in that
-- slot goes back into the inventory. Returns true when worn.
function DubzCosmetics.Equip(ply, id)
	local def = DubzCosmetics.Get(id)
	if not def or def.virtual then return false end

	-- The job's costume covers this slot: nothing is worn (and nothing is lost: the item stays where it was)
	if DubzCosmetics.JobPreset(ply, def.slot) ~= nil then
		say(ply, "Your job's uniform covers that. You can wear it again when you are off the job.")
		return false
	end

	local current = DubzCosmetics.GetWornItem(ply, def.slot)
	if current ~= "" then DubzCosmetics.Unequip(ply, def.slot) end

	setSlot(ply, def.slot, id)
	if DubzInv and DubzInv.PlaySound then DubzInv.PlaySound(ply, "equip") end
	return true
end

-- Removes an accessory from a player entirely (worn, or the first matching item in their inventory)
function DubzCosmetics.Remove(ply, id)
	local def = DubzCosmetics.Get(id)
	if not def then return false end

	if DubzCosmetics.GetWornItem(ply, def.slot) == id then
		setSlot(ply, def.slot, "")
		return true
	end

	if DubzInv and DubzInv.GetSlots and DubzInv.TakeSlot then
		for index, rec in pairs(DubzInv.GetSlots(ply) or {}) do
			if rec.class == "dubz_cosmetic" and rec.data and rec.data.DubzCosID == id then
				DubzInv.TakeSlot(ply, index, 1)
				return true
			end
		end
	end

	return false
end

net.Receive("DubzCos_Unequip", function(_, ply)
	if (ply.DubzCosNext or 0) > CurTime() then return end
	ply.DubzCosNext = CurTime() + 0.3

	local slotId = net.ReadString()
	if DubzCosmetics.GetWornItem(ply, slotId) ~= "" then DubzCosmetics.Unequip(ply, slotId) end
end)

-- Everything cosmetic belongs to the character: what is worn, the look, the clothes owned and worn. Run when the
-- player joins and again whenever they switch character (the previous one's state is cleared first).
local function loadCosmetics(ply)
	for _, slot in ipairs(cfg.slots) do ply:SetNWString("dubz_cos_" .. slot.id, "") end
	ply:SetNWString("dubz_outfit", "")
	ply:SetNWString("dubz_clothes", "")
	ply:SetNWString("dubz_clothes_owned", "")

	-- The first character of an account inherits what the account had before characters existed
	local key = keyOf(ply)
	local legacy = DubzChars and DubzChars.LegacyKey and DubzChars.LegacyKey(ply)

	if legacy and legacy ~= key and not sql.QueryValue("SELECT 1 FROM dubz_cos_worn WHERE sid = " .. sql.SQLStr(key) .. " LIMIT 1")
		and not sql.QueryValue("SELECT 1 FROM dubz_cos_clothes WHERE sid = " .. sql.SQLStr(key) .. " LIMIT 1") then
		local k, l = sql.SQLStr(key), sql.SQLStr(legacy)
		sql.Query("INSERT OR IGNORE INTO dubz_cos_worn (sid, slot, id) SELECT " .. k .. ", slot, id FROM dubz_cos_worn WHERE sid = " .. l)
		sql.Query("INSERT OR IGNORE INTO dubz_cos_outfit (sid, id) SELECT " .. k .. ", id FROM dubz_cos_outfit WHERE sid = " .. l)
		sql.Query("INSERT OR IGNORE INTO dubz_cos_clothes (sid, id, worn) SELECT " .. k .. ", id, worn FROM dubz_cos_clothes WHERE sid = " .. l)
	end

	for _, row in ipairs(sql.Query("SELECT slot, id FROM dubz_cos_worn WHERE sid = " .. sql.SQLStr(keyOf(ply))) or {}) do
		local def = DubzCosmetics.Get(row.id)
		if def and def.slot == row.slot then ply:SetNWString("dubz_cos_" .. row.slot, row.id) end
	end

	local look = sql.QueryValue("SELECT id FROM dubz_cos_outfit WHERE sid = " .. sql.SQLStr(keyOf(ply)))
	if look and DubzCosmetics.GetFace(look) then ply:SetNWString("dubz_outfit", look) end

	local owned = {}
	for _, row in ipairs(sql.Query("SELECT id, worn FROM dubz_cos_clothes WHERE sid = " .. sql.SQLStr(keyOf(ply))) or {}) do
		if DubzCosmetics.GetClothing(row.id) then
			owned[#owned + 1] = row.id
			if tonumber(row.worn) == 1 then ply:SetNWString("dubz_clothes", row.id) end
		end
	end
	ply:SetNWString("dubz_clothes_owned", table.concat(owned, ","))
end

hook.Add("DubzCharLoad", "DubzCos_CharLoad", function(ply) loadCosmetics(ply) end)

-- A deleted (wiped) character takes its look, clothes and accessories with it
hook.Add("DubzCharWipe", "DubzCos_CharWipe", function(account, charId, keys)
	for _, key in ipairs(keys) do
		for _, name in ipairs({"dubz_cos_worn", "dubz_cos_outfit", "dubz_cos_clothes"}) do
			sql.Query("DELETE FROM " .. name .. " WHERE sid = " .. sql.SQLStr(key))
		end
	end
end)

hook.Add("PlayerInitialSpawn", "DubzCos_Load", function(ply)
	loadCosmetics(ply)

	timer.Simple(3, function()
		if not IsValid(ply) then return end

		-- Build the JSON before net.Start so a failure can never leave a half-written net message open
		local json = util.TableToJSON(DubzCosmetics.Offsets or {})
		net.Start("DubzCos_Offsets")
			net.WriteString(json)
		net.Send(ply)
	end)
end)

-- Stackable accessories (cheap spares): the inventory asks how many of one item fit in a slot
hook.Add("DubzInvStackLimit", "DubzCos_Stack", function(class, model, variant)
	if class ~= "dubz_cosmetic" then return end

	-- Serial-numbered copies are one of a kind: never stack
	if not variant or DubzCosmetics.Serial(variant) then return 1 end

	return math.max(1, DubzCosmetics.GetEcon(variant).stack)
end)

hook.Add("DubzInvEntityVariant", "DubzCos_Variant", function(ent)
	if ent:GetClass() == "dubz_cosmetic" then return ent:GetCosID() end
end)

-- Does this accessory fall off when its wearer dies? Numbered limited editions never do; otherwise the Catalog's
-- "Drops" flag, or being cheaper than the configured price.
function DubzCosmetics.DropsOnDeath(id)
	if DubzCosmetics.Serial(id) then return false end

	local econ = DubzCosmetics.GetEcon(id)
	if econ.drops then return true end

	return econ.supply <= 0 and econ.price > 0 and cfg.dropBelowPrice > 0 and econ.price < cfg.dropBelowPrice
end

-- Death: cheap / flagged accessories come off and drop where you died; expensive ones stay on
hook.Add("PlayerDeath", "DubzCos_DeathDrop", function(ply)
	for _, slot in ipairs(cfg.slots) do
		local id = DubzCosmetics.GetWornItem(ply, slot.id)
		if id ~= "" and DubzCosmetics.DropsOnDeath(id) then
			setSlot(ply, slot.id, "")
			dropToFloor(ply, id)
		end
	end
end)

hook.Add("PlayerSay", "DubzCos_Command", function(ply, text)
	if not table.HasValue(cfg.chatCommands, string.lower(string.Trim(text))) then return end

	net.Start("DubzCos_Open")
	net.Send(ply)
	return ""
end)

-- Clothing (player model) ---------------------------------------------------------------------------------------

-- On the clock: holding a job whose uniform is set in Job Outfits. Clothes can't be changed then (accessories and the backpack can).
function DubzCosmetics.OnTheClock(ply)
	if not cfg.lockClothesOnJob then return false end

	local jobSet = cfg.jobOutfits[string.lower(team.GetName(ply:Team()) or "")]
	return jobSet ~= nil and DubzCosmetics.GetClothing(jobSet) ~= nil
end

-- Puts your chosen look in your chosen clothing on you. Returns false when nothing is chosen (the job's model stays).
function DubzCosmetics.ApplyOutfit(ply)
	local look = DubzCosmetics.GetLookId(ply)
	if look == "" or not cfg.overrideJobModels or not DubzCosmetics.Enabled() then return false end

	-- A job's uniform replaces the clothes (not the look) while you hold the job
	local jobSet = cfg.jobOutfits[string.lower(team.GetName(ply:Team()) or "")]
	local uniform = jobSet and DubzCosmetics.GetClothing(jobSet) and DubzCosmetics.ModelFor(look, jobSet)

	-- If the chosen clothing doesn't exist for this look (files missing), fall back to the default set
	local model = uniform or DubzCosmetics.ModelFor(look, DubzCosmetics.GetClothingId(ply)) or DubzCosmetics.ModelFor(look, DubzCosmetics.DefaultClothing)
	if not model then return false end

	-- Models change without respawning anyone; the set's bodygroups and skin go on afterwards
	if ply:GetModel() ~= model then ply:SetModel(model) end

	local setId = (uniform and jobSet) or DubzCosmetics.GetClothingId(ply)
	local set = DubzCosmetics.GetClothing(setId)

	for index = 0, ply:GetNumBodyGroups() - 1 do ply:SetBodygroup(index, 0) end
	ply:SetSkin(set and set.skin or 0)
	for index, value in pairs(set and set.bodygroups or {}) do ply:SetBodygroup(index, value) end

	if ply.SetupHands then ply:SetupHands() end   -- first-person arms must match the new model
	return true
end

function DubzCosmetics.SetLook(ply, faceId)
	if not DubzCosmetics.GetFace(faceId) then return false end

	ply:SetNWString("dubz_outfit", faceId)
	sql.Query("REPLACE INTO dubz_cos_outfit (sid, id) VALUES (" .. sql.SQLStr(keyOf(ply)) .. ", " .. sql.SQLStr(faceId) .. ")")
	return true
end

-- Gives the player ownership of a clothing set (and optionally wears it)
function DubzCosmetics.UnlockClothing(ply, id, wear)
	if not DubzCosmetics.GetClothing(id) then return false end

	if not DubzCosmetics.OwnsClothing(ply, id) then
		local owned = ply:GetNWString("dubz_clothes_owned", "")
		ply:SetNWString("dubz_clothes_owned", owned == "" and id or (owned .. "," .. id))
		sql.Query("REPLACE INTO dubz_cos_clothes (sid, id, worn) VALUES (" .. sql.SQLStr(keyOf(ply)) .. ", " .. sql.SQLStr(id) .. ", 0)")
	end

	if wear then DubzCosmetics.WearClothing(ply, id) end
	return true
end

function DubzCosmetics.WearClothing(ply, id)
	if not DubzCosmetics.GetClothing(id) or not DubzCosmetics.OwnsClothing(ply, id) then return false end

	ply:SetNWString("dubz_clothes", id)
	sql.Query("UPDATE dubz_cos_clothes SET worn = 0 WHERE sid = " .. sql.SQLStr(keyOf(ply)))
	sql.Query("REPLACE INTO dubz_cos_clothes (sid, id, worn) VALUES (" .. sql.SQLStr(keyOf(ply)) .. ", " .. sql.SQLStr(id) .. ", 1)")
	return true
end

-- DarkRP sets the job's model through this hook; if we have clothing to apply, we answer it first
hook.Add("PlayerSetModel", "DubzCos_Outfit", function(ply)
	if DubzCosmetics.ApplyOutfit(ply) then return true end
end)

-- Belt and braces: some job code sets the model right after spawning
hook.Add("PlayerSpawn", "DubzCos_OutfitSpawn", function(ply)
	timer.Simple(0.2, function() if IsValid(ply) and ply:Alive() then DubzCosmetics.ApplyOutfit(ply) end end)
end)

-- Placement offsets (saved per player model, edited in-game by admins) ---------------------------------------

local function loadOffsets()
	local text = file.Exists(cfg.offsetFile, "DATA") and file.Read(cfg.offsetFile, "DATA")
	DubzCosmetics.Offsets = (text and util.JSONToTable(text)) or {}
end

local function saveOffsets()
	if not file.Exists("dubz_cosmetics", "DATA") then file.CreateDir("dubz_cosmetics") end
	file.Write(cfg.offsetFile, util.TableToJSON(DubzCosmetics.Offsets, true))

	local json = util.TableToJSON(DubzCosmetics.Offsets)
	net.Start("DubzCos_Offsets")
		net.WriteString(json)
	net.Broadcast()
end

loadOffsets()

net.Receive("DubzCos_SaveOffset", function(_, ply)
	if not ply:IsAdmin() then return end

	local id = net.ReadString()
	local model = string.lower(net.ReadString())
	local pos = {net.ReadFloat(), net.ReadFloat(), net.ReadFloat()}
	local ang = {net.ReadFloat(), net.ReadFloat(), net.ReadFloat()}
	local scale = net.ReadFloat()

	if not DubzCosmetics.Get(id) or model == "" then return end

	DubzCosmetics.Offsets[model] = DubzCosmetics.Offsets[model] or {}
	DubzCosmetics.Offsets[model][id] = {pos = pos, ang = ang, scale = math.Clamp(scale, 0.05, 5)}

	saveOffsets()
	say(ply, "Saved placement of " .. id .. " for " .. model .. ".")
end)

net.Receive("DubzCos_ResetOffset", function(_, ply)
	if not ply:IsAdmin() then return end

	local id = net.ReadString()
	local model = string.lower(net.ReadString())

	if DubzCosmetics.Offsets[model] then DubzCosmetics.Offsets[model][id] = nil end
	saveOffsets()
	say(ply, "Reset placement of " .. id .. " for " .. model .. ".")
end)
