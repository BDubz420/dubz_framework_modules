AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = DubzCW.Config

	self:SetModel(cfg.PlateModel)
	if cfg.PlateMaterial ~= "" then self:SetMaterial(cfg.PlateMaterial) end
	self:SetColor(cfg.PlateColor)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(10)   -- (light enough to be carried with E)
		phys:Wake()
	end
end
