AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- The crafting table: turns gems and ingots from the pocket into the things in the Recipes table. Spawn it from the
-- entities tab and keep it with a perma-props tool.
function ENT:Initialize()
	self:SetModel(DubzMining.Config.craftingModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or not DubzMining.Enabled() then return end

	if (activator.DubzMiningUse or 0) > CurTime() then return end
	activator.DubzMiningUse = CurTime() + 0.8

	DubzMining.OpenCrafting(activator, self)
end
