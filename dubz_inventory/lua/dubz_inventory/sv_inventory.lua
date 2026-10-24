-- The pocket (inventory): slots, backpack, pickup / use / drop, saving, and syncing to the owner.
--
-- A slot holds a record: {class = "spawned_weapon", name = "...", model = "...", data = {serialized entity}}.
-- Slots 1..cfg.slots are the pockets; slots after that belong to the worn backpack.
--
-- Public API for other addons (bank, auction house, jobs ...):
--   DubzInv.GetSlots(ply)               -> the slot table
--   DubzInv.AddItem(ply, rec)           -> true | false, reason   (stacks with matching items, see `stacking`)
--   DubzInv.TakeSlot(ply, slot, qty)    -> the record taken (the whole stack when qty is nil)
--   DubzInv.CanFit(ply, class, model)   -> true when there is a free slot or room in a matching stack
util.AddNetworkString("DubzInv_Sync")
util.AddNetworkString("DubzInv_Action")
util.AddNetworkString("DubzInv_Open")

local cfg = DubzInv.Config

-- Things that can never be pocketed whatever the config says. A cheque is money with a name on it: pocketed, it lost who it was for, and
-- stacked, it took on the amount of whatever was in the stack first.
DubzInv.NeverPocket = {darkrp_cheque = true}

local function say(ply, kind, text)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind, 4, text) else ply:ChatPrint(text) end
end

-- Other addons (logging, quests, ...) can listen: hook.Add("DubzInvEvent", id, function(ply, event, rec) end)
-- Events: "pickup", "drop", "use", "bag_wear", "bag_drop"
local function event(ply, name, rec)
	hook.Run("DubzInvEvent", ply, name, rec)
end

-- Plays the configured sound for "pickup", "take" or "equip" (quietly, near the player)
function DubzInv.PlaySound(ply, kind)
	if not DubzInv.Config.sounds or not IsValid(ply) then return end

	local file = DubzInv.Config[kind .. "Sound"]
	if file and file ~= "" then ply:EmitSound(file, 60, 100) end
end

-- No handling items with your hands up (surrendering) or while otherwise unable to act.
local function canAct(ply)
	if not ply:Alive() or not DubzInv.Enabled() then return false end

	if ply:GetNWBool("handies_surrendered", false) then
		say(ply, 1, "You can't do that with your hands up.")
		return false
	end

	return hook.Run("DubzInvCanAct", ply) ~= false
end

local function state(ply)
	ply.DubzInv = ply.DubzInv or {slots = {}, bag = nil}
	return ply.DubzInv
end

local function capacityOf(st)
	local capacity = cfg.slots
	if st.bag then capacity = capacity + st.bag.slots end
	return math.min(capacity, cfg.maxSlots)
end

-- Sync / save ---------------------------------------------------------------------------------------

-- What an item looks like beyond its model: its colour and material (a tinted gem, a shiny ingot). Read from the saved
-- entity data, so every entity that was coloured shows up coloured in the pocket.
local function writeLook(rec)
	local data = rec.data
	local color = data and data.Color
	local material = hook.Run("DubzInvLookMaterial", rec) or (data and data.Material)   -- (an addon can say what an item is drawn with right now)

	local tinted = istable(color) and ((color.r or 255) ~= 255 or (color.g or 255) ~= 255 or (color.b or 255) ~= 255)
	local shiny = isstring(material) and material ~= ""

	net.WriteBool(tinted or shiny)
	if not (tinted or shiny) then return end

	net.WriteUInt(tinted and math.Clamp(color.r or 255, 0, 255) or 255, 8)
	net.WriteUInt(tinted and math.Clamp(color.g or 255, 0, 255) or 255, 8)
	net.WriteUInt(tinted and math.Clamp(color.b or 255, 0, 255) or 255, 8)
	net.WriteString(shiny and material or "")
end

-- What an item is worth (the exchange says: its going rate), 0 when nothing does. Shown when you hover over the item.
-- The name an item is shown with. Weapons are named after the weapon (older saved ones may still say "Spawned Weapon").
function DubzInv.DisplayName(rec)
	if rec.class == "spawned_weapon" then
		local class = rec.variant
		if not class or class == "" then class = rec.data and rec.data.DT and rec.data.DT.WeaponClass end
		if class and class ~= "" then return DubzInv.WeaponName(class) end
	end

	return rec.name or rec.class
end

local function writeValue(rec)
	-- (hook.Run gives nothing back when no addon values items, and tonumber() with nothing errors)
	local value = hook.Run("DubzInvItemValue", rec)
	value = tonumber(value) or 0
	net.WriteUInt(math.Clamp(math.floor(value), 0, 4294967295), 32)
end

local function sync(ply)
	local st = state(ply)
	local capacity = capacityOf(st)

	net.Start("DubzInv_Sync")
		net.WriteUInt(capacity, 8)

		local count = 0
		for i = 1, capacity do if st.slots[i] then count = count + 1 end end
		net.WriteUInt(count, 8)

		for i = 1, capacity do
			local rec = st.slots[i]
			if rec then
				net.WriteUInt(i, 8)
				net.WriteString(DubzInv.DisplayName(rec))
				net.WriteString(rec.model or "")
				net.WriteString(rec.class or "")
				net.WriteUInt(math.min(rec.qty or 1, 65535), 16)
				writeLook(rec)
				writeValue(rec)
			end
		end
	net.Send(ply)
end

local function refresh(ply)
	local st = state(ply)

	ply:SetNWInt("dubz_inv_cap", capacityOf(st))
	ply:SetNWBool("dubz_inv_hasbag", st.bag ~= nil)
	ply:SetNWString("dubz_inv_bagmodel", st.bag and st.bag.model or "")
	ply.DubzInvDirty = true

	sync(ply)
end

local function save(ply)
	if not ply.DubzInv then return end

	DubzInv.SaveRow(ply, {slots = ply.DubzInv.slots, bag = ply.DubzInv.bag})
	ply.DubzInvDirty = false
end

timer.Create("DubzInv_Save", 15, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.DubzInvDirty then save(ply) end
	end
end)

hook.Add("PlayerDisconnected", "DubzInv_SaveOnLeave", save)

hook.Add("ShutDown", "DubzInv_SaveAll", function()
	for _, ply in ipairs(player.GetAll()) do save(ply) end
end)

hook.Add("PlayerInitialSpawn", "DubzInv_Load", function(ply)
	local row = DubzInv.LoadRow(ply)
	ply.DubzInv = {slots = (row and row.slots) or {}, bag = row and row.bag or nil}

	-- The client needs a moment before it can receive net messages
	timer.Simple(3, function() if IsValid(ply) then refresh(ply) end end)
end)

-- A deleted (wiped) character takes its pocket and backpack with it
hook.Add("DubzCharWipe", "DubzInv_CharWipe", function(account, charId, keys)
	for _, key in ipairs(keys) do sql.Query("DELETE FROM dubz_inventory WHERE sid = " .. sql.SQLStr(key)) end
end)

-- Switching characters: the pocket and backpack are saved under the old character and the new one's are loaded
hook.Add("DubzCharLeave", "DubzInv_CharLeave", function(ply) save(ply) end)

-- Cheques that got into a pocket before they were blocked are taken out when the pocket loads, and logged with what they said, so staff can
-- put right anything that was legitimate.
local function scrubForbidden(ply)
	local st = ply.DubzInv
	if not st then return end

	for index, rec in pairs(st.slots) do
		if DubzInv.NeverPocket[string.lower(rec.class or "")] then
			local amount = rec.data and rec.data.DT and rec.data.DT.amount

			MsgC(Color(255, 160, 60), "[DubzInventory] ", color_white, string.format("removed %s x%d from %s's pocket (cheque amount in the saved copy: %s)\n", rec.class, rec.qty or 1, ply:Nick(), tostring(amount)))
			st.slots[index] = nil
		end
	end
end

hook.Add("DubzCharLoad", "DubzInv_Scrub", function(ply) timer.Simple(0.2, function() if IsValid(ply) then scrubForbidden(ply) end end) end)
hook.Add("PlayerInitialSpawn", "DubzInv_ScrubJoin", function(ply) timer.Simple(4, function() if IsValid(ply) then scrubForbidden(ply) end end) end)

hook.Add("DubzCharLoad", "DubzInv_CharLoad", function(ply)
	local row = DubzInv.LoadRow(ply)
	ply.DubzInv = {slots = (row and row.slots) or {}, bag = row and row.bag or nil}
	ply.DubzInvDirty = true

	refresh(ply)
end)

-- Slot operations -----------------------------------------------------------------------------------

function DubzInv.GetSlots(ply)
	return state(ply).slots
end

-- Room for an item of this class/model? (a free slot, or room in a matching stack)
function DubzInv.CanFit(ply, class, model, variant)
	local st = state(ply)

	-- (cash joins the cash already carried)
	if class == "spawned_money" then
		for i = 1, capacityOf(st) do
			if st.slots[i] and st.slots[i].class == "spawned_money" then return true end
		end
	end

	local limit = class and DubzInv.GetStackLimit(class, model, variant) or 1

	for i = 1, capacityOf(st) do
		local slot = st.slots[i]
		if not slot then return true end

		if limit > 1 and slot.class == class and slot.model == model and (slot.variant or "") == (variant or "") and (slot.qty or 1) < limit then return true end
	end

	return false
end

function DubzInv.AddItem(ply, rec)
	local st = state(ply)
	local capacity = capacityOf(st)

	-- Cash in the pocket is ONE stack that remembers the total: more cash is added to it
	if rec.class == "spawned_money" and rec.data and rec.data.DT then
		local added = math.max(tonumber(rec.data.DT.amount) or 0, 0)

		for i = 1, capacity do
			local slot = st.slots[i]

			if slot and slot.class == "spawned_money" and slot.data and slot.data.DT then
				slot.data.DT.amount = (tonumber(slot.data.DT.amount) or 0) + added
				slot.name = "Cash ($" .. string.Comma(slot.data.DT.amount) .. ")"
				slot.qty = 1

				refresh(ply)
				return true
			end
		end

		rec.name = "Cash ($" .. string.Comma(added) .. ")"
		rec.qty = 1
	end

	rec.qty = rec.qty or 1
	local limit = DubzInv.GetStackLimit(rec.class, rec.model, rec.variant)

	-- Top up matching stacks first
	if limit > 1 then
		for i = 1, capacity do
			local slot = st.slots[i]

			if slot and slot.class == rec.class and slot.model == rec.model and (slot.variant or "") == (rec.variant or "") and (slot.qty or 1) < limit then
				local add = math.min(limit - (slot.qty or 1), rec.qty)
				slot.qty = (slot.qty or 1) + add
				rec.qty = rec.qty - add

				if rec.qty <= 0 then
					refresh(ply)
					return true
				end
			end
		end
	end

	-- The rest goes in a free slot
	for i = 1, capacity do
		if not st.slots[i] then
			st.slots[i] = rec
			refresh(ply)
			return true
		end
	end

	return false, "Your pocket is full."
end

-- Takes qty items out of a slot (the whole stack when qty is nil). Returns the record taken.
function DubzInv.TakeSlot(ply, slotIndex, qty)
	local st = state(ply)
	local rec = st.slots[slotIndex]
	if slotIndex > capacityOf(st) or not rec then return nil end

	local have = rec.qty or 1
	qty = qty and math.min(qty, have) or have

	if qty >= have then
		st.slots[slotIndex] = nil
		refresh(ply)
		return rec
	end

	rec.qty = have - qty

	local taken = table.Copy(rec)
	taken.qty = qty

	refresh(ply)
	return taken
end

-- Moving onto the same stackable item merges the stacks; otherwise the two slots swap.
function DubzInv.Move(ply, from, to)
	local st = state(ply)
	local capacity = capacityOf(st)
	if from == to or from < 1 or to < 1 or from > capacity or to > capacity then return end

	local a, b = st.slots[from], st.slots[to]
	if not a then return end

	if b and a.class == b.class and a.model == b.model and (a.variant or "") == (b.variant or "") then
		local limit = DubzInv.GetStackLimit(a.class, a.model, a.variant)

		if limit > 1 and (b.qty or 1) < limit then
			local move = math.min(limit - (b.qty or 1), a.qty or 1)
			b.qty = (b.qty or 1) + move
			a.qty = (a.qty or 1) - move
			if a.qty <= 0 then st.slots[from] = nil end

			refresh(ply)
			return
		end
	end

	st.slots[from], st.slots[to] = b, a
	refresh(ply)
end

-- Pocketing rules (DarkRP's canPocket, minus the old capacity check) --------------------------------

function DubzInv.CanPocket(ply, ent)
	if not IsValid(ent) then return false end

	-- Another addon can refuse (a wagered chess game in progress ...): return false and a reason
	local allowed, why = hook.Run("DubzInvCanPocket", ply, ent)
	if allowed == false then return false, why or "You can't put that in your pocket." end

	local class = ent:GetClass()
	local failed = "You can't put that in your pocket."

	if ent.Removed then return false, failed end
	if ent.CPPICanPickup and not ent:CPPICanPickup(ply) then return false, failed end
	if ent.jailWall then return false, failed end
	if GAMEMODE.Config and GAMEMODE.Config.PocketBlacklist and GAMEMODE.Config.PocketBlacklist[class] then return false, failed end
	if string.find(class, "func_", 1, true) then return false, failed end
	if ent.DubzStack then return true end   -- a dropped stack: it holds the whole stack, whatever it weighs
	if ent:IsRagdoll() or ent:IsNPC() or ent:IsPlayer() or ent:IsVehicle() then return false, failed end
	if DubzInv.IsBagClass(class) then return false, "Press E on a backpack to put it on." end
	if DubzInv.NeverPocket[string.lower(class)] then return false, "That can't go in your pocket. Cash a cheque with E." end
	if cfg.pocketBlacklist[string.lower(class)] then return false, failed end
	if class == "spawned_money" and cfg.cashToWallet then return false end
	if not duplicator.IsAllowed(class) then return false, failed end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return false end

	local mass = ent.RPOriginalMass or phys:GetMass()
	if mass > 100 then return false, "That is too heavy to carry in your pocket." end

	return true
end

-- Entities <-> records ------------------------------------------------------------------------------

-- Different weapons lying as DarkRP's "spawned weapon" must not stack with each other
hook.Add("DubzInvEntityVariant", "DubzInv_WeaponVariant", function(ent)
	if ent:GetClass() == "spawned_weapon" then return ent.weaponclass or (ent.GetWeaponClass and ent:GetWeaponClass()) end
end)

-- A weapon's name for the pocket: its own PrintName, the weapon list's, a DarkRP shipment's, or a tidied-up class name
-- ("weapon_crowbar" -> "Crowbar"). Never "Spawned Weapon".
function DubzInv.WeaponName(class)
	class = tostring(class or "")

	local swep = weapons.Get(class)
	if swep and isstring(swep.PrintName) and swep.PrintName ~= "" and string.sub(swep.PrintName, 1, 1) ~= "#" then return swep.PrintName end

	local listed = list.Get("Weapon")[class]
	if listed and isstring(listed.PrintName) and listed.PrintName ~= "" and string.sub(listed.PrintName, 1, 1) ~= "#" then return listed.PrintName end

	for _, shipment in pairs(CustomShipments or {}) do
		if shipment.entity == class and shipment.name then return shipment.name end
	end

	local text = string.gsub(string.gsub(class, "^weapon_", ""), "^m9k_", "M9K ")
	text = string.gsub(text, "_", " ")
	return string.gsub(text, "(%a)([%w]*)", function(first, rest) return string.upper(first) .. rest end)
end

-- What makes two of the same class different for stacking: another addon's answer, else everything networked on the entity
function DubzInv.VariantOf(ent)
	local custom = hook.Run("DubzInvEntityVariant", ent)
	if custom ~= nil then return custom end

	return DubzInv.StateSignature(ent)
end

local function recordFromEntity(ent)
	-- A dropped stack goes back as the stack it was
	if ent.DubzStack then return table.Copy(ent.DubzStack) end

	-- Other addons can turn their own entities into records (accessories do, see dubz_cosmetics)
	local custom = hook.Run("DubzInvMakeRecord", ent)
	if custom then return custom end

	-- A weapon lying on the ground is DarkRP's "spawned weapon", and a stack of them is one with an amount: it goes in as that many of the
	-- weapon, named after the weapon (Crowbar, not "Spawned Weapon"). The saved copy is ONE weapon, so each comes out as one.
	if ent:GetClass() == "spawned_weapon" then
		local weaponClass = ent:GetWeaponClass()
		local rec = {
			class = "spawned_weapon", name = DubzInv.WeaponName(weaponClass), model = ent:GetModel(), qty = math.max(ent:Getamount(), 1),
			variant = weaponClass, data = DubzInv.SerializeEntity(ent),
		}

		if rec.data.DT then rec.data.DT.amount = 1 end
		return rec
	end

	-- A shipment is a crate of weapons: in the pocket it is that many of the weapon (the crate itself is not kept)
	if ent:GetClass() == "spawned_shipment" then
		local shipment = CustomShipments and CustomShipments[ent:Getcontents()]

		if shipment then
			local weapon = ents.Create("spawned_weapon")

			if IsValid(weapon) then
				weapon:SetModel(shipment.model)
				weapon:SetWeaponClass(shipment.entity)
				weapon:Setamount(1)
				weapon:Spawn()

				local data = DubzInv.SerializeEntity(weapon)
				weapon.IsPocketing = true
				weapon:Remove()

				if data.DT then data.DT.amount = 1 end

				return {class = "spawned_weapon", name = DubzInv.WeaponName(shipment.entity), model = shipment.model, qty = math.max(ent:Getcount(), 1), variant = shipment.entity, data = data}
			end
		end
	end

	return {class = ent:GetClass(), name = ent.PrintName or ent:GetClass(), model = ent:GetModel(), qty = 1, variant = DubzInv.VariantOf(ent), data = DubzInv.SerializeEntity(ent)}
end

DubzInv.RecordFromEntity = recordFromEntity   -- (other addons: shops turn a bought entity into the record that goes in the pocket)

-- Pickup (hold left click with the pocket SWEP) -------------------------------------------------------

local function pickupTarget(ply)
	-- Bodies don't block the aim: items lying on or under a corpse can still be picked up
	local tr = util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * (cfg.pickupDistance + 40),
		filter = function(e) return e ~= ply and not e:IsPlayer() and not e:IsRagdoll() end,
		mask = MASK_SHOT,
	})
	local ent = tr.Entity

	if not IsValid(ent) or ply:EyePos():Distance(tr.HitPos) > cfg.pickupDistance then return nil end
	return ent
end

-- Weapons whose left click picks things up
local pickupWeapons = {dubz_pocket = true, dubz_hands = true}

local function stopPickup(ply)
	if ply.DubzPickup and DubzActions and DubzActions.EndPose then DubzActions.EndPose(ply) end

	ply.DubzPickup = nil
	ply:SetNWFloat("dubz_pick_start", 0)
end

-- Can this loose thing be picked up by holding E? Dropped stacks and dumpster loot always can; otherwise it is the Hold E classes.
function DubzInv.IsHoldE(ent)
	if not (IsValid(ent) and cfg.holdE) then return false end
	if ent:GetClass() == "spawned_money" then return false end   -- (E on cash is the game's own: it goes straight in the wallet)

	-- E on a weapon on the ground puts it in your hands like normal (the game's own use: it goes on your weapon wheel), not in the pocket. Holding
	-- left click with the pocket still pockets it. (Hold E Picks Up Weapons switches this back.)
	if ent:GetClass() == "spawned_weapon" and not cfg.holdEWeapons then return false end
	if ent.DubzStack or ent.DubzLoot then return true end

	return table.HasValue(cfg.holdEClasses, string.lower(ent:GetClass()))
end

-- `quiet`: used by the hands, which also open/lock doors, so they stay silent when the target isn't pickable.
-- Returns true when the player was looking at something that can be picked up (so the hands know not to lock).
function DubzInv.TryPickup(ply, quiet, key)
	if not DubzInv.Enabled() then return false end
	if ply.DubzPickup or not canAct(ply) then return false end

	local ent = pickupTarget(ply)
	if not ent then return false end

	-- Holding E only takes loose items (E still opens doors, uses printers ...)
	if key == IN_USE and not DubzInv.IsHoldE(ent) then return false end

	-- Cash goes straight into the wallet (it is not an inventory item) and tells you what it was worth
	if cfg.cashToWallet and ent:GetClass() == "spawned_money" then
		-- Cash is simply used, as if you had pressed E on it: DarkRP puts it in the wallet and tells you what it was (no message of ours)
		local amount = (ent.Getamount and ent:Getamount()) or 0

		if amount > 0 and ent.Use then
			ent:Use(ply, ply, USE_ON, 1)
			event(ply, "cash", {class = "spawned_money", name = "Cash", qty = amount})
			return true
		end
	end

	-- A backpack on the ground is put on with a click
	if DubzInv.IsBagClass(ent:GetClass()) then
		if (ply.DubzNextBag or 0) > CurTime() then return true end
		ply.DubzNextBag = CurTime() + 1
		DubzInv.WearBag(ply, ent)
		return true
	end

	local ok, message = DubzInv.CanPocket(ply, ent)
	if not ok then
		if message and not quiet then say(ply, 1, message) end
		return false
	end

	local stack = ent.DubzStack
	local fits = stack and DubzInv.CanFit(ply, stack.class, stack.model, stack.variant) or (not stack and DubzInv.CanFit(ply, ent:GetClass(), ent:GetModel(), DubzInv.VariantOf(ent)))

	if not fits then
		say(ply, 1, "Your pocket is full.")
		return true
	end

	local time = cfg.pickupTimes[stack and stack.class or ent:GetClass()] or cfg.pickupTime
	ply.DubzPickup = {ent = ent, finish = CurTime() + time, key = key or IN_ATTACK}
	ply:SetNWFloat("dubz_pick_start", CurTime())
	ply:SetNWFloat("dubz_pick_time", time)

	-- Everyone sees the reach down and the grab (the hands-at-work addon)
	if DubzActions and DubzActions.Pose then DubzActions.Pose(ply, "pickup", time, {model = stack and stack.model or ent:GetModel()}) end

	return true
end

hook.Add("Think", "DubzInv_Pickup", function()
	for _, ply in ipairs(player.GetAll()) do
		local pickup = ply.DubzPickup
		if not pickup then continue end

		local weapon = ply:GetActiveWeapon()
		local byUse = pickup.key == IN_USE
		local stillValid = IsValid(pickup.ent) and ply:Alive() and ply:KeyDown(pickup.key or IN_ATTACK)
			and (byUse or (IsValid(weapon) and pickupWeapons[weapon:GetClass()])) and pickupTarget(ply) == pickup.ent

		if not stillValid then
			stopPickup(ply)
		elseif CurTime() >= pickup.finish then
			local ent = pickup.ent
			stopPickup(ply)

			-- Some entities can't be copied; fail cleanly instead of erroring every tick
			local ok, rec = pcall(recordFromEntity, ent)
			if not ok then
				ErrorNoHalt("[DubzInventory] couldn't pocket " .. ent:GetClass() .. ": " .. tostring(rec) .. "\n")
				say(ply, 1, "You can't put that in your pocket.")
				continue
			end

			local added, reason = DubzInv.AddItem(ply, rec)

			if added then
				-- It leaves the world, so it stops counting toward its owner's deployed limit
				if not ent.DubzStack then
					local owner = ent.Getowning_ent and ent:Getowning_ent() or (ent.CPPIGetOwner and ent:CPPIGetOwner())
					hook.Run("DubzInvPocketed", owner, ent)
				end

				ent.IsPocketing = true
				ent:Remove()
				event(ply, "pickup", rec)
				DubzInv.PlaySound(ply, "pickup")
			elseif ent.DubzStack and (rec.qty or 1) < (ent.DubzStack.qty or 1) then
				-- Only part of the stack fit: the rest stays on the ground
				ent:SetStackQty(rec.qty)
				say(ply, 1, "Your pocket is full. The rest stays on the ground.")
			elseif reason then
				say(ply, 1, reason)
			end
		end
	end
end)

-- Pressing E on a loose item starts the pickup (holding it finishes it)
hook.Add("KeyPress", "DubzInv_HoldE", function(ply, key)
	if key == IN_USE and cfg.holdE and DubzInv.Enabled() then DubzInv.TryPickup(ply, true, IN_USE) end
end)

-- ...and E must not also "use" the thing (DarkRP would put a spawned weapon straight in your hands)
hook.Add("PlayerUse", "DubzInv_HoldEBlock", function(ply, ent)
	if cfg.holdE and DubzInv.Enabled() and DubzInv.IsHoldE(ent) then return false end
end)

-- Drop / use ---------------------------------------------------------------------------------------------

-- Puts real, working entities down: one from the slot, or up to the drop-all limit when `all` is true (each item becomes its own entity).
local function deploySingles(ply, slotIndex, all)
	-- "Drop all" is capped so nobody can spawn a hundred entities with one click
	local want = (not all) and 1 or math.max(1, DubzInv.Config.dropAllMax or 8)

	-- Deploy limits: never more of an entity down than the limit allows (see sv_limits.lua)
	local peek = state(ply).slots[slotIndex]
	if peek and DubzInv.CanDeploy then
		local allowed, message = DubzInv.CanDeploy(ply, peek, math.min(want, peek.qty or 1))

		if allowed <= 0 then say(ply, 1, message) return end
		if message then say(ply, 1, message) end
		want = math.min(want, allowed)
	end

	local rec = DubzInv.TakeSlot(ply, slotIndex, want)
	if not rec then return end

	local count = rec.qty or 1
	local dropped = 0

	for _ = 1, count do
		-- Other addons can put their own items in the world (accessories do); otherwise it is rebuilt from its data
		local ent = hook.Run("DubzInvDropItem", ply, rec) or DubzInv.DeserializeEntity(ply, table.Copy(rec.data))
		if not IsValid(ent) then
			ErrorNoHalt("[DubzInventory] couldn't put a " .. tostring(rec.class) .. " back in the world (is its entity installed?)\n")
			say(ply, 1, "That item couldn't be dropped.")
			break
		end
		dropped = dropped + 1
	end

	-- Anything that could not be put in the world goes back into the pocket
	if dropped < count then
		local rest = table.Copy(rec)
		rest.qty = count - dropped
		DubzInv.AddItem(ply, rest)
	end

	if dropped > 0 then
		local logged = table.Copy(rec)
		logged.qty = dropped
		event(ply, "drop", logged)
	end
end

-- Deploy: puts ONE of the item down, live (a printer starts printing, a stove cooks)
function DubzInv.DeploySlot(ply, slotIndex)
	return deploySingles(ply, slotIndex, false)
end

-- Drop: one of the item, or the whole stack, goes on the ground as a single inert prop that stands for all of them (so a stack of a
-- hundred is one prop, not a pile). It does nothing until it is picked up and deployed from the pocket.
function DubzInv.DropSlot(ply, slotIndex, all)
	local peek = state(ply).slots[slotIndex]
	if not peek then return end

	-- Accessories drop as their own suitcase (see the cosmetics addon)
	if peek.class == "dubz_cosmetic" then return deploySingles(ply, slotIndex, all) end

	-- Other addons can ask for their items to be dropped as the real thing (weed buds and bags: they have to touch each other to be packed)
	if hook.Run("DubzInvDropsLive", peek) then return deploySingles(ply, slotIndex, all) end

	local rec = DubzInv.TakeSlot(ply, slotIndex, (not all) and 1 or nil)
	if not rec then return end

	local stack = ents.Create("dubz_item_stack")
	if not IsValid(stack) then
		DubzInv.AddItem(ply, rec)
		say(ply, 1, "That item couldn't be dropped.")
		return
	end

	stack:SetRecord(rec)
	stack:Spawn()
	DubzInv.PlaceInFront(stack, ply)
	DubzInv.Claim(stack, ply)   -- (it belongs to whoever dropped it: see sv_ownership.lua)

	event(ply, "drop", rec)
end

-- Right click with the pocket SWEP: drop the last item
function DubzInv.DropLast(ply)
	if not canAct(ply) then return end

	local st = state(ply)

	for i = capacityOf(st), 1, -1 do
		if st.slots[i] then return DubzInv.DropSlot(ply, i) end
	end

	say(ply, 1, "You have nothing to drop.")
end

-- "Use" puts the item in front of you and uses it (eats food, equips a weapon, ...)
function DubzInv.UseSlot(ply, slotIndex)
	-- Using an item puts it down first, so the deploy limit applies here too
	local peek = state(ply).slots[slotIndex]
	if peek and DubzInv.CanDeploy and peek.class ~= "dubz_cosmetic" then
		local allowed, message = DubzInv.CanDeploy(ply, peek, 1)
		if allowed <= 0 then say(ply, 1, message) return end
	end

	local rec = DubzInv.TakeSlot(ply, slotIndex, 1)
	if not rec then return end

	-- Other addons can handle using their own items (accessories wear themselves): return true = used up,
	-- false = couldn't be used, so it goes back; nil = carry on with the normal use below.
	local handled = hook.Run("DubzInvUseItem", ply, rec, slotIndex)
	if handled == true then event(ply, "use", rec) return end
	if handled == false then DubzInv.AddItem(ply, rec) return end

	local ent = DubzInv.DeserializeEntity(ply, rec.data)
	if not IsValid(ent) then
		DubzInv.AddItem(ply, rec)
		return
	end

	event(ply, "use", rec)
	if ent.Use then ent:Use(ply, ply, USE_ON, 1) end
end

-- Backpack --------------------------------------------------------------------------------------------------

-- Press E on a dubz_backpack: wear it. Anything it was carrying comes with it.
function DubzInv.WearBag(ply, bagEnt)
	local st = state(ply)

	if st.bag then
		say(ply, 1, "You are already wearing a backpack. Press B to drop it first.")
		return
	end

	st.bag = {slots = bagEnt:GetSlots(), model = bagEnt:GetModel()}

	for i, rec in pairs(bagEnt.BagContents or {}) do
		local index = cfg.slots + i
		if index <= capacityOf(st) then st.slots[index] = rec end
	end

	bagEnt.IsWorn = true
	if DubzInv.CloseBagViews then DubzInv.CloseBagViews(bagEnt) end
	bagEnt:Remove()
	refresh(ply)
	event(ply, "bag_wear", {class = DubzInv.BagClassForModel(st.bag.model), name = DubzInv.IsSmallModel(st.bag.model) and "Small Backpack" or "Big Backpack"})
end

-- B: take the backpack off and put it on the ground (or where `pos` is) with its contents inside.
function DubzInv.DropBag(ply, pos)
	local st = state(ply)
	if not st.bag then return end

	local bagEnt = ents.Create(DubzInv.BagClassForModel(st.bag.model))
	if not IsValid(bagEnt) then return end

	bagEnt:SetModel(st.bag.model)
	bagEnt:SetSlots(st.bag.slots)
	bagEnt:Spawn()

	-- Move everything in the backpack's slots into the entity
	local contents = {}
	for i = 1, st.bag.slots do
		local index = cfg.slots + i
		if st.slots[index] then
			contents[i] = st.slots[index]
			st.slots[index] = nil
		end
	end
	bagEnt.BagContents = contents

	st.bag = nil
	DubzInv.PlaceInFront(bagEnt, ply, pos)
	refresh(ply)
	event(ply, "bag_drop", {class = bagEnt:GetClass(), name = DubzInv.IsSmallModel(bagEnt:GetModel()) and "Small Backpack" or "Big Backpack"})
end

concommand.Add("dubz_dropbag", function(ply)
	if not IsValid(ply) or not canAct(ply) then return end
	if (ply.DubzNextBag or 0) > CurTime() then return end

	ply.DubzNextBag = CurTime() + 1
	DubzInv.DropBag(ply)
end)

-- A backpack on the ground: E opens it (a container window), B puts it on ----------------------------------

util.AddNetworkString("DubzInv_BagView")     -- server -> client: contents of the opened backpack (or closes the window)
util.AddNetworkString("DubzInv_BagAction")   -- client -> server: "take" a slot out / "put" a pocket slot in / "close"

local function sendBagView(ply, bagEnt)
	if not IsValid(bagEnt) then
		net.Start("DubzInv_BagView")
			net.WriteBool(false)
		net.Send(ply)
		return
	end

	local contents = bagEnt.BagContents or {}
	local count = 0
	for i = 1, bagEnt:GetSlots() do if contents[i] then count = count + 1 end end

	net.Start("DubzInv_BagView")
		net.WriteBool(true)
		net.WriteUInt(bagEnt:GetSlots(), 8)
		net.WriteUInt(count, 8)

		for i = 1, bagEnt:GetSlots() do
			local rec = contents[i]
			if rec then
				net.WriteUInt(i, 8)
				net.WriteString(DubzInv.DisplayName(rec))
				net.WriteString(rec.model or "")
				net.WriteString(rec.class or "")
				net.WriteUInt(math.min(rec.qty or 1, 65535), 16)
				writeLook(rec)
				writeValue(rec)
			end
		end
	net.Send(ply)
end

local function refreshBagViewers(bagEnt)
	for viewer in pairs(bagEnt.Viewers or {}) do
		if IsValid(viewer) and viewer.DubzOpenBag == bagEnt then sendBagView(viewer, bagEnt) end
	end
end

local function closeBagView(ply)
	local bagEnt = ply.DubzOpenBag
	ply.DubzOpenBag = nil

	if IsValid(bagEnt) and bagEnt.Viewers then bagEnt.Viewers[ply] = nil end
	if IsValid(ply) then sendBagView(ply, nil) end
end

function DubzInv.CloseBagViews(bagEnt)
	for viewer in pairs(bagEnt.Viewers or {}) do
		if IsValid(viewer) then closeBagView(viewer) end
	end
end

function DubzInv.OpenBag(ply, bagEnt)
	if not canAct(ply) or not IsValid(bagEnt) or bagEnt.IsWorn then return end

	if DubzInv.HasBag and ply.DubzOpenBag and ply.DubzOpenBag ~= bagEnt then closeBagView(ply) end

	bagEnt.BagContents = bagEnt.BagContents or {}
	bagEnt.Viewers = bagEnt.Viewers or {}
	bagEnt.Viewers[ply] = true
	ply.DubzOpenBag = bagEnt

	sendBagView(ply, bagEnt)
end

net.Receive("DubzInv_BagAction", function(_, ply)
	local action = net.ReadString()
	local slot = net.ReadUInt(8)
	local second = net.ReadUInt(8)

	if action == "close" then closeBagView(ply) return end

	local bagEnt = ply.DubzOpenBag
	if not IsValid(bagEnt) or bagEnt.IsWorn or ply:GetPos():Distance(bagEnt:GetPos()) > cfg.bagOpenDistance * 1.5 then
		closeBagView(ply)
		return
	end

	if (ply.DubzBagNext or 0) > CurTime() then return end
	ply.DubzBagNext = CurTime() + 0.15

	if not canAct(ply) then return end

	bagEnt.BagContents = bagEnt.BagContents or {}

	if action == "take" then
		local rec = bagEnt.BagContents[slot]
		if not rec then return end

		local added, reason = DubzInv.AddItem(ply, rec)
		if added then
			bagEnt.BagContents[slot] = nil
			refreshBagViewers(bagEnt)
			DubzInv.PlaySound(ply, "take")
		elseif reason then
			say(ply, 1, reason)
		end
	elseif action == "move" then
		-- Rearranging inside the container: onto the same stackable thing merges, otherwise the two slots swap
		local total = bagEnt:GetSlots()
		if slot == second or slot < 1 or second < 1 or slot > total or second > total then return end

		local a, b = bagEnt.BagContents[slot], bagEnt.BagContents[second]
		if not a then return end

		if b and a.class == b.class and a.model == b.model and (a.variant or "") == (b.variant or "") then
			local limit = DubzInv.GetStackLimit(a.class, a.model, a.variant)

			if limit > 1 and (b.qty or 1) < limit then
				local move = math.min(limit - (b.qty or 1), a.qty or 1)
				b.qty = (b.qty or 1) + move
				a.qty = (a.qty or 1) - move
				if a.qty <= 0 then bagEnt.BagContents[slot] = nil end

				refreshBagViewers(bagEnt)
				return
			end
		end

		bagEnt.BagContents[slot], bagEnt.BagContents[second] = b, a
		refreshBagViewers(bagEnt)
	elseif action == "put" then
		-- Pocket slots and worn-backpack slots can both be put in
		if slot < 1 or slot > DubzInv.GetCapacity(ply) then return end

		local free
		for i = 1, bagEnt:GetSlots() do
			if not bagEnt.BagContents[i] then free = i break end
		end

		if not free then say(ply, 1, "That backpack is full.") return end

		local rec = DubzInv.TakeSlot(ply, slot)
		if rec then
			bagEnt.BagContents[free] = rec
			refreshBagViewers(bagEnt)
		end
	end
end)

-- Walk away from an open backpack and it closes by itself
timer.Create("DubzInv_BagDistance", 1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local bagEnt = ply.DubzOpenBag
		if bagEnt and (not IsValid(bagEnt) or bagEnt.IsWorn or ply:GetPos():Distance(bagEnt:GetPos()) > cfg.bagOpenDistance * 1.5) then
			closeBagView(ply)
		end
	end
end)

-- B while looking at a backpack on the ground: put it on (B with one already on drops it, see below)
concommand.Add("dubz_wearbag", function(ply)
	if not IsValid(ply) or not canAct(ply) then return end
	if (ply.DubzNextBag or 0) > CurTime() then return end

	local tr = ply:GetEyeTrace()
	local ent = tr.Entity

	if not IsValid(ent) or not DubzInv.IsBagClass(ent:GetClass()) or ply:EyePos():Distance(tr.HitPos) > cfg.bagOpenDistance then return end

	ply.DubzNextBag = CurTime() + 1
	DubzInv.WearBag(ply, ent)
end)

-- Client requests -------------------------------------------------------------------------------------

net.Receive("DubzInv_Action", function(_, ply)
	local action = net.ReadString()
	local a = net.ReadUInt(8)
	local b = net.ReadUInt(8)

	if (ply.DubzInvNextAction or 0) > CurTime() then return end
	ply.DubzInvNextAction = CurTime() + 0.15

	if not canAct(ply) then return end

	if action == "use" then DubzInv.UseSlot(ply, a)
	elseif action == "drop" then DubzInv.DropSlot(ply, a)
	elseif action == "dropall" then DubzInv.DropSlot(ply, a, true)
	elseif action == "deploy" then DubzInv.DeploySlot(ply, a)
	elseif action == "move" then DubzInv.Move(ply, a, b)
	end
end)

hook.Add("PlayerSay", "DubzInv_ChatCommand", function(ply, text)
	if not table.HasValue(cfg.chatCommands, string.lower(string.Trim(text))) then return end

	net.Start("DubzInv_Open")
	net.Send(ply)
	return ""
end)

-- Death does NOT drop the inventory: items stay with the player. The backpack only drops if configured to.
hook.Add("PlayerDeath", "DubzInv_Death", function(ply)
	stopPickup(ply)

	if cfg.dropBagOnDeath then DubzInv.DropBag(ply, ply:GetPos() + Vector(0, 0, 20)) end
end)
