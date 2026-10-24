-- Draws everyone's worn accessories on their bones. Placement comes from the registry defaults or the saved
-- per-model offsets (see sh_registry.lua); the editor can override one slot on you as a live preview.
-- DubzCosmetics.DrawAttachment works on any entity with a skeleton, so the stores reuse it for their try-on view.
local cfg = DubzCosmetics.Config

-- Set by the editor while it is open: {slot = "hat", id = "top_hat", pos = Vector, ang = Angle, scale = 1}
DubzCosmetics.Preview = nil

net.Receive("DubzCos_Offsets", function()
	DubzCosmetics.Offsets = util.JSONToTable(net.ReadString()) or {}
end)

local cache = {}   -- "<key>" -> {ent = clientside model, model = path}

local function drop(key)
	local entry = cache[key]
	if entry and IsValid(entry.ent) then entry.ent:Remove() end
	cache[key] = nil
end

local function dropPlayer(index)
	for _, slot in ipairs(cfg.slots) do drop(index .. "_" .. slot.id) end
end

-- Draws `def` on `target` (a player or any model entity). `key` keeps one cached prop per place it is drawn.
-- `owner` (optional) is the player the item belongs to, for items whose model depends on them (the backpack).
function DubzCosmetics.DrawAttachment(target, def, pos, ang, scale, key, owner)
	local model = (def.GetModel and def.GetModel(owner or target)) or def.model

	local entry = cache[key]
	if not entry or entry.model ~= model or not IsValid(entry.ent) then
		drop(key)

		local ent = ClientsideModel(model, RENDERGROUP_OPAQUE)
		if not IsValid(ent) then return end

		ent:SetNoDraw(true)
		entry = {ent = ent, model = model}
		cache[key] = entry
	end

	local bone = target:LookupBone(def.bone)
	if not bone then return end

	local bonePos, boneAng = target:GetBonePosition(bone)
	if not bonePos then return end

	local ent = entry.ent
	ent:SetModelScale(scale, 0)
	if def.skin then ent:SetSkin(def.skin) end

	ent:SetPos(bonePos + boneAng:Forward() * pos.x + boneAng:Right() * pos.y + boneAng:Up() * pos.z)

	local final = Angle(boneAng.p, boneAng.y, boneAng.r)
	final:RotateAroundAxis(final:Forward(), ang.r)
	final:RotateAroundAxis(final:Right(), ang.p)
	final:RotateAroundAxis(final:Up(), ang.y)
	ent:SetAngles(final)

	ent:DrawModel()
end

function DubzCosmetics.ClearAttachment(key)
	drop(key)
end

hook.Add("PostPlayerDraw", "DubzCos_Draw", function(ply)
	-- Master switch off: nothing is drawn (accessories and the worn backpack disappear)
	if not DubzCosmetics.Enabled() or not ply:Alive() then
		dropPlayer(ply:EntIndex())
		return
	end

	local lp = LocalPlayer()
	if ply ~= lp and ply:GetPos():DistToSqr(EyePos()) > cfg.drawDistance * cfg.drawDistance then return end

	local model = ply:GetModel()

	for _, slot in ipairs(cfg.slots) do
		local def = DubzCosmetics.Get(DubzCosmetics.GetWorn(ply, slot.id))
		local pos, ang, scale

		-- The editor's live preview replaces whatever is worn in that slot on the local player
		local preview = DubzCosmetics.Preview
		if ply == lp and preview and preview.slot == slot.id then
			def, pos, ang, scale = DubzCosmetics.Get(preview.id), preview.pos, preview.ang, preview.scale
		elseif def then
			pos, ang, scale = DubzCosmetics.GetPlacement(def, model)
		end

		local key = ply:EntIndex() .. "_" .. slot.id
		if def then DubzCosmetics.DrawAttachment(ply, def, pos, ang, scale, key, ply) else drop(key) end
	end
end)

hook.Add("EntityRemoved", "DubzCos_Cleanup", function(ent)
	if ent:IsPlayer() then dropPlayer(ent:EntIndex()) end
end)
