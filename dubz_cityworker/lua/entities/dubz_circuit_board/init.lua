AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = DubzCW.Config

	self:SetModel(cfg.BoardModel)

	-- Scaled so its longest side is the board size from the settings
	local size = self:OBBMaxs() - self:OBBMins()
	local longest = math.max(size.x, size.y, size.z, 1)
	self:SetModelScale(cfg.BoardSize / longest, 0)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(3)
		phys:Wake()
	end
end
