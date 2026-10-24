-- Accessory registry, economy data and placement lookup.
--
-- DubzCosmetics.Register{
--   id, name, slot,                 -- slot is one of the ids in sh_config.lua
--   model,                          -- the prop that gets attached
--   bone = "ValveBiped.Bip01_Head1",
--   pos = Vector, ang = Angle, scale = 1,   -- default placement, relative to the bone
--   skin = 0,
--   -- Economy (all optional; the admin menu's Catalog table overrides them live):
--   tier = "common" | "limited" | "seasonal",
--   price = 0,      -- cash price (0 = can't be bought with cash)
--   credits = 0,    -- credit price (0 = can't be bought with credits)
--   supply = 0,     -- 0 = unlimited; N = only N will ever be minted (each gets a serial number)
--   shop = false,   -- on sale at the accessory vendor right now
--   drops = false,  -- falls off its wearer on death (cheap / disposable)
--   stack = 1,      -- how many stack in one pocket slot
--   hides = false,  -- covers the wearer's face: others see "<identity hidden>" over their head instead of their name
--   virtual = true  -- not an item you buy or carry; shown on the body because something else says so (the worn
--                      backpack). Placement can still be tuned in the editor.
--   GetModel = function(ply)        -- optional: model to draw for this player instead of `model`
-- }
-- Placement can differ per player model. The in-game editor (dubz_cosmetic_editor) saves offsets per
-- model (or for all models), and those override the defaults.
DubzCosmetics.Items = {}
DubzCosmetics.Econ = DubzCosmetics.Econ or {}         -- econ[id] = {tier, price, credits, supply, shop, drops, stack}
DubzCosmetics.Minted = DubzCosmetics.Minted or {}     -- minted[id] = how many of a limited item exist (server truth)
DubzCosmetics.Offsets = DubzCosmetics.Offsets or {}   -- offsets[modelPath][itemId] = {pos = {x,y,z}, ang = {p,y,r}, scale = n}

DubzCosmetics.Tiers = {"common", "limited", "seasonal"}

-- Where an accessory sits by default on each slot (menu-added items start here; fine tune with the editor)
DubzCosmetics.SlotBones = {
	hat = "ValveBiped.Bip01_Head1",
	face = "ValveBiped.Bip01_Head1",
	neck = "ValveBiped.Bip01_Neck1",
	back = "ValveBiped.Bip01_Spine2",
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzCosmetics.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("cosmetics")
end

-- Item ids can carry a serial number: "neon_halo#7" is copy #7 of a limited item. Base() is the item, Serial() the number.
function DubzCosmetics.Base(id)
	return (string.match(tostring(id or ""), "^[^#]+")) or ""
end

function DubzCosmetics.Serial(id)
	local n = string.match(tostring(id or ""), "#(%d+)$")
	return n and tonumber(n) or nil
end

local function econOf(def)
	return {
		tier = def.tier or "common", price = def.price or 0, credits = def.credits or 0,
		supply = def.supply or 0, shop = def.shop == true, drops = def.drops == true, stack = def.stack or 1,
		hides = def.hides == true,
	}
end

-- fromCatalog = true when the admin menu's Catalog table made the item (code-defined items are marked `code`)
function DubzCosmetics.Register(def, fromCatalog)
	def.bone = def.bone or DubzCosmetics.SlotBones[def.slot] or "ValveBiped.Bip01_Head1"
	def.pos = def.pos or Vector(0, 0, 0)
	def.ang = def.ang or Angle(0, 0, 0)
	def.scale = def.scale or 1

	if fromCatalog then def.menu = true else def.code = true end

	DubzCosmetics.Items[def.id] = def
	if not fromCatalog or not DubzCosmetics.Econ[def.id] then DubzCosmetics.Econ[def.id] = econOf(def) end
end

-- The item behind an id (serial numbers are ignored)
function DubzCosmetics.Get(id)
	return DubzCosmetics.Items[DubzCosmetics.Base(id)]
end

function DubzCosmetics.GetEcon(id)
	return DubzCosmetics.Econ[DubzCosmetics.Base(id)] or econOf({})
end

-- "Neon Halo" or "Neon Halo #7"
function DubzCosmetics.DisplayName(id)
	local def = DubzCosmetics.Get(id)
	local name = def and def.name or tostring(id)
	local serial = DubzCosmetics.Serial(id)
	return serial and (name .. " #" .. serial) or name
end

-- Is the item on sale at the vendor right now (switched on, priced, and not sold out)?
function DubzCosmetics.IsForSale(id)
	local def = DubzCosmetics.Get(id)
	local econ = DubzCosmetics.Econ[DubzCosmetics.Base(id)]
	if not def or def.virtual or not econ or not econ.shop then return false end
	if econ.price <= 0 and econ.credits <= 0 then return false end
	if econ.supply > 0 and (DubzCosmetics.Minted[def.id] or 0) >= econ.supply then return false end

	return true
end

-- Is the player wearing something that hides who they are? (shared, so the HUD can ask)
function DubzCosmetics.HidesIdentity(ply)
	if not DubzCosmetics.Enabled() or not IsValid(ply) then return false end

	for _, slot in ipairs(DubzCosmetics.Config.slots) do
		local id = DubzCosmetics.GetWornItem(ply, slot.id)
		if id ~= "" and DubzCosmetics.GetEcon(id).hides then return true end
	end

	return false
end

function DubzCosmetics.SlotName(slotId)
	for _, slot in ipairs(DubzCosmetics.Config.slots) do
		if slot.id == slotId then return slot.name end
	end
	return slotId
end

-- A job's costume: the accessory the job puts in a slot ("" = the job keeps that slot empty), or nil when the job doesn't touch the slot (the
-- player's own accessory shows). Set in the "Job Accessories" table; the player's own accessories stay saved and come back off the job.
function DubzCosmetics.JobPreset(ply, slotId)
	local map = DubzCosmetics.Config.jobAccessories
	if not map or not IsValid(ply) then return nil end

	local row = map[string.lower(team.GetName(ply:Team()) or "") .. "|" .. slotId]
	if row == nil then return nil end

	return row
end

-- The id of what a player currently wears in a slot ("" when nothing).
function DubzCosmetics.GetWorn(ply, slotId)
	-- A job that puts something in the slot (or empties it) decides it
	local preset = DubzCosmetics.JobPreset(ply, slotId)
	if preset ~= nil then return preset end

	-- Other systems can put something in a slot without it being an owned item (the inventory's backpack)
	local virtual = hook.Run("DubzCosVirtualWorn", ply, slotId)
	if virtual and virtual ~= "" then return virtual end

	return ply:GetNWString("dubz_cos_" .. slotId, "")
end

-- What is really worn in the slot as an owned item (ignores virtual ones). Server and client.
function DubzCosmetics.GetWornItem(ply, slotId)
	return ply:GetNWString("dubz_cos_" .. slotId, "")
end

-- Final placement for an item on a model: the saved offset for that model if there is one, else the defaults.
function DubzCosmetics.GetPlacement(def, model)
	-- A placement saved for this exact player model wins; otherwise the one saved for ALL models ("*"); otherwise
	-- the registry default.
	local saved = DubzCosmetics.Offsets[string.lower(model or "")]
	saved = saved and saved[def.id]

	if not saved then
		saved = DubzCosmetics.Offsets["*"]
		saved = saved and saved[def.id]
	end

	if saved then
		return Vector(saved.pos[1], saved.pos[2], saved.pos[3]), Angle(saved.ang[1], saved.ang[2], saved.ang[3]), saved.scale or def.scale
	end

	return def.pos, def.ang, def.scale
end
