AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- An accessory lying on the ground: a small suitcase. Press E to wear it, or pick it up into your inventory
-- (hold left click with your hands or pocket). The item itself is set with SetCosID.
function ENT:Initialize()
	self:SetModel(DubzCosmetics.Config.caseModel)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end

-- Used by the inventory when it puts a saved record back in the world
function ENT:OnDuplicated(data)
	if data and data.DubzCosID then self:SetCosID(data.DubzCosID) end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	local id = self:GetCosID()
	if not DubzCosmetics.Get(id) then self:Remove() return end

	if DubzCosmetics.Equip(activator, id) then
		self.IsPocketing = true
		self:Remove()
	end
end
