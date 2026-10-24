AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Works even if lua/dubz_cooking/ (the config) didn't load: falls back to the original numbers
local DEFAULTS = {cookSeconds = 30, donutEnergy = 10, donutHealth = 10, goldenChance = 1000, goldenClass = "dubnut_gold", goldenEnergy = 10, goldenHealth = 10}
local function cfg() return (DubzCooking and DubzCooking.Config) or DEFAULTS end
local function cookingEnabled() return not (DubzCooking and DubzCooking.Enabled) or DubzCooking.Enabled() end

local function TrySpawnGoldenDonut(ent)
    -- Keep normal donuts working if the golden entity is not installed, or golden donuts are switched off.
    local chance = cfg().goldenChance
    if not cookingEnabled() or chance <= 0 then return false end
    if not scripted_ents.GetStored(cfg().goldenClass) then return false end
    if math.random(1, chance) ~= 1 then return false end

    -- Initialize is still running, so perform the replacement next tick.
    timer.Simple(0, function()
        if not IsValid(ent) then return end

        local golden = ents.Create(cfg().goldenClass)
        if not IsValid(golden) then
            ErrorNoHalt("[Dubz Cooking Mod] Could not create golden donut: " .. cfg().goldenClass .. "\n")
            return
        end

        golden:SetPos(ent:GetPos())
        golden:SetAngles(ent:GetAngles())

        local creator = ent:GetCreator()
        if IsValid(creator) then
            golden:SetCreator(creator)
        end

        golden:Spawn()
        golden:Activate()
        SafeRemoveEntity(ent)
    end)

    return true
end

function ENT:Initialize()
	if TrySpawnGoldenDonut(self) then return end

	self:SetModel("models/noesis/donut.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

end

function ENT:Use(activator, caller)
	if not IsValid(caller) or not caller:IsPlayer() then return end

	local energy = caller:getDarkRPVar("Energy") or 0
	local health = caller:Health()
	local maxHealth = caller:GetMaxHealth()

	if energy >= 100 and health >= maxHealth then return end

	caller:setSelfDarkRPVar("Energy", math.min(energy + cfg().donutEnergy, 100))
	caller:SetHealth(math.min(health + cfg().donutHealth, maxHealth))
	self:Remove()
end
