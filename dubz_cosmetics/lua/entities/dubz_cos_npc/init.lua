AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Store clerks. Press E to open the store. Place them with dubz_cosnpc_add (see sv_npc.lua).
local MODELS = {
	clothing = "models/humans/group01/female_02.mdl",
	accessories = "models/humans/group01/male_09.mdl",
}

-- Spawn it from the entities tab (Dubz Cosmetics) and keep it with a perma-props tool; nothing here saves it.
function ENT:Initialize()
	if self.PresetKind then self:SetKind(self.PresetKind) end

	self:SetModel(MODELS[self:GetKind()] or MODELS.clothing)
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetSolid(SOLID_BBOX)
	self:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
	self:SetUseType(SIMPLE_USE)
	self:SetMaxYawSpeed(90)
	self:DropToFloor()
end

-- Called by sv_npc.lua right after SetKind, so the model matches the kind
function ENT:ApplyKind()
	self:SetModel(MODELS[self:GetKind()] or MODELS.clothing)
end

function ENT:OnTakeDamage() return 0 end

function ENT:AcceptInput(name, activator)
	if name ~= "Use" or not IsValid(activator) or not activator:IsPlayer() then return end
	if not DubzCosmetics.Enabled() then return end

	if (activator.DubzCosNpcNext or 0) > CurTime() then return end
	activator.DubzCosNpcNext = CurTime() + 1

	net.Start("DubzCos_OpenStore")
		net.WriteEntity(self)
		net.WriteString(self:GetKind())
		net.WriteString(util.TableToJSON(DubzCosmetics.Minted))
	net.Send(activator)
end
