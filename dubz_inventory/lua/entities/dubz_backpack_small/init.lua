AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- The Small Backpack: the same as the Big one (E opens it, B puts it on) with a smaller case and fewer slots. See dubz_backpack.
function ENT:Initialize()
	if self:GetModel() == "" or self:GetModel() == "models/error.mdl" then
		self:SetModel(DubzInv.Config.smallBagModel)
	end

	if self:GetSlots() <= 0 then self:SetSlots(DubzInv.Config.smallBagSlots) end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end

	self.BagContents = self.BagContents or {}
end
