AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/noesis/donut.mdl")
    self:SetMaterial("models/shiny")
    self:SetColor(Color(255, 190, 25))
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self:EmitSound("ambient/levels/labs/coinslot1.wav", 75, 110, 1)
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end

    local energy = caller:getDarkRPVar("Energy") or 0
    local health = caller:Health()
    local maxHealth = caller:GetMaxHealth()

    if energy >= 100 and health >= maxHealth then return end

    local cfg = (DubzCooking and DubzCooking.Config) or {goldenEnergy = 10, goldenHealth = 10}
    caller:setSelfDarkRPVar("Energy", math.min(energy + cfg.goldenEnergy, 100))
    caller:SetHealth(math.min(health + cfg.goldenHealth, maxHealth))
    self:Remove()
end
