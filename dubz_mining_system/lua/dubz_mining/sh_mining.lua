-- Shared mining logic: the Mining skill (shown in the skills menu, per character), and the names the pocket and the
-- world give things.

-- The Mining skill. The more you mine, the more efficient a miner you are. Registered again when its numbers
-- change in the admin menu. (Skills register on Initialize because the skills addon loads after this one.)
function DubzMining.RegisterSkill()
	if not (DubzSkills and DubzSkills.Register) then return end

	local cfg = DubzMining.Config

	DubzSkills.Register({
		id = "mining", category = "industry", name = "Mining",
		desc = "Breaking rock makes you a more efficient miner: harder, faster swings and a chance of extra ore.",
		maxLevel = 10, xpBase = cfg.xpBase, xpExponent = cfg.xpExponent,
		effect = function(level)
			local damage = math.floor(cfg.damageBase + level * cfg.damagePerLevel)
			local speed = math.min(level * cfg.swingSpeedPerLevel, cfg.swingSpeedMax)
			local bonus = math.min(level * cfg.bonusChancePerLevel, cfg.bonusChanceMax)
			return damage .. " damage a swing, " .. math.floor(speed) .. "% faster swings, " .. math.floor(bonus) .. "% extra ore"
		end,
	})

	DubzSkills.Register({
		id = "crafting", category = "industry", name = "Crafting",
		desc = "Crafting things teaches you more. The more you make, the bigger the things you can make.",
		maxLevel = 10, xpBase = cfg.craftXpBase, xpExponent = cfg.craftXpExponent,
		effect = function(level)
			local recipes = 0
			for _, recipe in ipairs(DubzMining.Recipes) do
				if recipe.level <= math.max(1, level) then recipes = recipes + 1 end
			end
			return recipes .. " recipes unlocked"
		end,
	})
end

hook.Add("Initialize", "DubzMining_Skill", DubzMining.RegisterSkill)
if DubzSkills then DubzMining.RegisterSkill() end

-- Gems and ingots are props with physics: a model tinted with a material's colour. Ore chunks are the same prop with no material at
-- all (they are anonymous; the forge decides what is in one when it smelts it). Nothing here can be picked up with E: they go in
-- the pocket the way any other prop does. Each entity file calls this with its kind ("gem" or "ingot") and which model setting it
-- uses; `anonymous` is true for ore chunks.
function DubzMining.SetupItem(ENT, kind, modelKey, anonymous, scaleKey)
	ENT.Type = "anim"
	ENT.Base = "base_gmodentity"
	ENT.Category = "Dubz Mining System"
	ENT.Spawnable = true    -- spawns a random material of its kind (ore chunks have none)
	ENT.AdminOnly = true

	function ENT:SetupDataTables()
		self:NetworkVar("String", 0, "Mat")
	end

	function ENT:GetMaterialDef()
		return DubzMining.Material(self:GetMat())
	end

	if SERVER then
		-- A saved copy can say which material it is before it spawns
		function ENT:KeyValue(key, value)
			if key == "mat" and not anonymous then self:SetMat(tostring(value)) end
		end

		function ENT:Initialize()
			local material

			if not anonymous then
				-- Spawned from the spawn menu: a random one. Taken out of the pocket: it already knows what it is.
				material = DubzMining.Material(self:GetMat())
				if not material then
					material = DubzMining.Pick(kind)
					if material then self:SetMat(material.id) end
				end
			end

			self:SetModel((material and material.model ~= "" and material.model) or DubzMining.Config[modelKey])
			DubzMining.Style(self, material)

			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)

			local scale = scaleKey and DubzMining.Config[scaleKey]
			-- (Activate rebuilds the physics for the new scale, so the hitbox matches the model)
			if scale and scale ~= 1 then
				self:SetModelScale(scale, 0)
				self:Activate()
			end

			local phys = self:GetPhysicsObject()
			if IsValid(phys) then phys:Wake() end
		end

		-- Taken out of the pocket: put back what it was (the saved copy says which material), whatever the entity
		-- picked for itself when it was created
		function ENT:OnDuplicated(data)
			if anonymous then return end

			local saved = data and data.DT and data.DT.Mat
			local material = saved and DubzMining.Material(saved)
			if not material then return end

			self:SetMat(material.id)
			self:SetModel((material.model ~= "" and material.model) or DubzMining.Config[modelKey])
			DubzMining.Style(self, material)

			local scale = scaleKey and DubzMining.Config[scaleKey]
			if scale and scale ~= 1 then
				self:SetModelScale(scale, 0)
				self:Activate()
			end
		end
	else
		-- A label over each gem and ingot (they are just coloured blocks); ore chunks have none
		function ENT:Draw()
			self:DrawModel()
			if anonymous then return end

			local distance = LocalPlayer():GetPos():Distance(self:GetPos())
			if distance > 300 then return end

			local material = self:GetMaterialDef()
			if not material then return end

			local alpha = math.Clamp(255 * (1 - distance / 300), 0, 255)

			cam.Start3D2D(self:GetPos() + Vector(0, 0, 12), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.08)
				draw.WordBox(6, 0, 0, DubzMining.ItemName(self:GetClass(), material), "DermaLarge", Color(0, 0, 0, 150 * alpha / 255), ColorAlpha(material.color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			cam.End3D2D()
		end
	end
end
