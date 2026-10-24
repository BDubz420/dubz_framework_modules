AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_junk/PopCan01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end

-- E: drink it. It takes away hunger (the hunger system's energy, out of 100); a player who is not hungry keeps the can.
function ENT:Use(activator)
	if not (IsValid(activator) and activator:IsPlayer()) then return end

	local cfg = DubzVending and DubzVending.Config or {HungerPerCan = 10, DrinkSound = "npc/barnacle/barnacle_gulp1.wav"}
	local energy = activator.getDarkRPVar and activator:getDarkRPVar("Energy")

	if energy and energy >= 100 then
		if DarkRP and DarkRP.notify then DarkRP.notify(activator, 1, 4, "You are not hungry.") end
		return
	end

	if energy and activator.setSelfDarkRPVar then
		activator:setSelfDarkRPVar("Energy", math.min(energy + cfg.HungerPerCan, 100))
	end

	self:EmitSound(cfg.DrinkSound or "npc/barnacle/barnacle_gulp1.wav", 60)
	self:Remove()
end
