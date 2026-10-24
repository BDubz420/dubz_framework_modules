AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- The backpack. Press E to open it, B to put it on; the wearer presses B to drop it again. A dropped backpack keeps
-- whatever it was carrying (BagContents), so nothing is lost when it changes hands.
function ENT:Initialize()
	if self:GetModel() == "" or self:GetModel() == "models/error.mdl" then
		self:SetModel(DubzInv.Config.bagModel)
	end

	if self:GetSlots() <= 0 then self:SetSlots(DubzInv.Config.bagSlots) end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end

	self.BagContents = self.BagContents or {}
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or self.IsWorn then return end

	-- E opens it (move things in and out); B while looking at it puts it on
	DubzInv.OpenBag(activator, self)
end
