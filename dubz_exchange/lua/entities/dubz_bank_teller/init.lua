AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(DubzExchange.Config.tellerModel or "models/Humans/Group02/male_03.mdl")
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetSolid(SOLID_BBOX)
	self:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
	self:SetUseType(SIMPLE_USE)
	self:SetMaxYawSpeed(90)
	self:DropToFloor()
end

function ENT:OnTakeDamage() return 0 end

function ENT:AcceptInput(name, activator)
	if name ~= "Use" or not IsValid(activator) or not activator:IsPlayer() then return end

	if (activator.DubzExchangeUse or 0) > CurTime() then return end
	activator.DubzExchangeUse = CurTime() + 1

	if DubzExchange.Enabled() then DubzExchange.OpenBank(activator, self) end
end
