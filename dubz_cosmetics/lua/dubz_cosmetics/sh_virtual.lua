-- Things shown on the body that are not owned accessories. Right now: the backpack you wear (from the inventory), in its two sizes. Each look is
-- a normal registry entry, so its placement is tuned per player model with dubz_cosmetic_editor (items: Big Backpack, Small Backpack).
local function register(id, name, modelKey, drawKey, slotsKey)
	local draw = DubzInv.Config[drawKey] or {}

	DubzCosmetics.Register({
		id = id, name = name, slot = "back", virtual = true,
		model = DubzInv.Config[modelKey],
		GetModel = function(ply)
			local model = DubzInv.GetBagModel(ply)
			return model ~= "" and model or DubzInv.Config[modelKey]
		end,
		bone = draw.bone or "ValveBiped.Bip01_Spine2",
		pos = draw.pos and Vector(draw.pos.x, draw.pos.y, draw.pos.z) or Vector(-3, 8, 0),
		ang = draw.ang and Angle(draw.ang.p, draw.ang.y, draw.ang.r) or Angle(0, 90, 90),
		scale = draw.scale or 0.9,
	})
end

local function registerBackpack()
	if not (DubzInv and DubzInv.Config and DubzInv.HasBag) then return end

	if not DubzCosmetics.Items.backpack then register("backpack", "Big Backpack", "bagModel", "bagDraw") end
	if not DubzCosmetics.Items.backpack_small then register("backpack_small", "Small Backpack", "smallBagModel", "smallBagDraw") end
end

-- Both addons are loaded by the time the map starts, whichever autorun ran first
hook.Add("InitPostEntity", "DubzCos_RegisterBackpack", registerBackpack)
registerBackpack()

-- The backpack takes the "back" slot while you wear one (the small one has its own look)
hook.Add("DubzCosVirtualWorn", "DubzCos_Backpack", function(ply, slotId)
	if slotId ~= "back" or not (DubzInv and DubzInv.HasBag and DubzInv.HasBag(ply)) or (DubzInv.Enabled and not DubzInv.Enabled()) then return end

	local id = (DubzInv.BagSize and DubzInv.BagSize(ply) == "small") and "backpack_small" or "backpack"
	if DubzCosmetics.Items[id] then return id end
end)
