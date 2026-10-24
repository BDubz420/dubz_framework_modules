AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- A rock: break it with a pickaxe for ore chunks and gems. When it is mined out it disappears and comes back after the
-- respawn time. Spawn it from the entities tab and keep it with a perma-props tool; nothing here saves it.
local function cfg() return DubzMining.Config end

function ENT:Initialize()
	-- One of the models in the Rocks table, with its own health if the row has one
	local rows = DubzMining.Rocks
	local row = rows[math.random(#rows)] or {model = "models/props_wasteland/rockgranite02c.mdl", health = 0}

	self:SetModel(row.model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	self.MaxHealth = (row.health and row.health > 0) and row.health or cfg().rockHealth
	self:SetRockMax(self.MaxHealth)
	self:SetRockHP(self.MaxHealth)
	self:SetMined(false)
end

-- What a mined-out rock leaves behind
local function scatter(rock, class, material, miner)
	local ent = ents.Create(class)
	if not IsValid(ent) then return end

	if material then ent:SetMat(material.id) end
	ent:SetPos(rock:GetPos() + Vector(math.Rand(-24, 24), math.Rand(-24, 24), 30))
	ent:Spawn()
	ent.Miner = miner   -- who gets the Mining XP if this chunk is smelted

	timer.Simple(cfg().despawnTime, function() if IsValid(ent) then ent:Remove() end end)
end

function ENT:Break(miner)
	if self:GetMined() then return end
	self:SetMined(true)

	local c = cfg()

	local stones = math.random(math.min(c.stoneMin, c.stoneMax), math.max(c.stoneMin, c.stoneMax))

	-- A better miner finds more: each Mining level is a chance of one extra ore chunk
	if IsValid(miner) and miner:IsPlayer() and stones > 0 and math.random() * 100 < DubzMining.BonusChance(miner) then stones = stones + 1 end

	for _ = 1, stones do
		scatter(self, "dubz_stone", nil, miner)
	end

	for _ = 1, math.random(math.min(c.gemMin, c.gemMax), math.max(c.gemMin, c.gemMax)) do
		scatter(self, "dubz_gem", DubzMining.Pick("gem"))
	end

	if IsValid(miner) and miner:IsPlayer() then
		local xp = DubzMining.GiveXP(miner)
		if xp > 0 and DarkRP and DarkRP.notify then DarkRP.notify(miner, 0, 3, "+" .. xp .. " mining XP") end
	end

	-- Gone until it respawns (not solid and not drawn, so nothing needs to be moved)
	self:SetNoDraw(true)
	self:SetNotSolid(true)

	timer.Create("DubzMiningRock_" .. self:EntIndex(), c.rockRespawnTime, 1, function()
		if not IsValid(self) then return end

		self:SetRockHP(self:GetRockMax())
		self:SetMined(false)
		self:SetNoDraw(false)
		self:SetNotSolid(false)
	end)
end

-- A hit with damage `amount` (the pickaxe calls this directly with the miner's damage)
function ENT:Mine(miner, amount)
	if self:GetMined() then return end

	local left = self:GetRockHP() - math.max(1, amount)
	self:SetRockHP(math.max(left, 0))

	if left <= 0 then self:Break(miner) end
end

-- Other tools hit it as ordinary damage
function ENT:OnTakeDamage(dmg)
	local attacker, inflictor = dmg:GetAttacker(), dmg:GetInflictor()
	local tools = cfg().miningTools

	local weapon = IsValid(attacker) and attacker:IsPlayer() and attacker:GetActiveWeapon()
	local class = (IsValid(inflictor) and inflictor:GetClass()) or ""
	local held = IsValid(weapon) and weapon:GetClass() or ""

	-- (the pickaxe mines directly, so it is not counted twice here)
	if class == "weapon_dubz_pickaxe" or held == "weapon_dubz_pickaxe" then return end

	if table.HasValue(tools, class) or table.HasValue(tools, held) then self:Mine(attacker, cfg().otherToolDamage) end
end

function ENT:OnRemove()
	timer.Remove("DubzMiningRock_" .. self:EntIndex())
end
