-- Shared scrap logic: the two kinds of entity (scrap, and the trash it comes from) and the link to the Mining crafting table.

-- Scrap and trash are props with physics, like gems and ingots: a model, a scale, a material and a colour from their table. Each entity file
-- calls this with its kind: "scrap" (a piece of plastic, metal ...) or "trash" (a bottle, a shoe ...). Nothing here can be picked up with
-- E: they go in the pocket the way any other prop does.
function DubzScrap.SetupItem(ENT, kind)
	ENT.Type = "anim"
	ENT.Base = "base_gmodentity"
	ENT.Category = "Dubz Scrap"
	ENT.Spawnable = true    -- spawns a random one
	ENT.AdminOnly = true

	function ENT:SetupDataTables()
		self:NetworkVar("String", 0, "Mat")   -- the scrap material's id, or the trash type's id
	end

	-- The table row this is (a scrap material or a trash type)
	function ENT:GetDef()
		if kind == "scrap" then return DubzScrap.Material(self:GetMat()) end
		return DubzScrap.TrashType(self:GetMat())
	end

	if SERVER then
		-- A saved copy can say which one it is before it spawns
		function ENT:KeyValue(key, value)
			if key == "mat" then self:SetMat(tostring(value)) end
		end

		-- Looks: the table's model at its scale, in its material and colour
		function ENT:Look(def)
			self:SetModel((def and def.model ~= "" and def.model) or "models/props_junk/garbage_bag001a.mdl")

			if kind == "scrap" and def then
				self:SetColor(def.color)
				if def.material ~= "" then self:SetMaterial(def.material) end
			end
		end

		function ENT:Initialize()
			local def = self:GetDef()

			if not def then
				def = kind == "scrap" and DubzScrap.PickMaterial() or DubzScrap.PickTrash()
				if def then self:SetMat(def.id) end
			end

			self:Look(def)

			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)

			-- Scaled on the server, and Activate rebuilds the physics to match (otherwise the hitbox stays the model's full size)
			if def and def.scale ~= 1 then
				self:SetModelScale(def.scale, 0)
				self:Activate()
			end

			local phys = self:GetPhysicsObject()
			if IsValid(phys) then phys:Wake() end
		end

		-- Taken out of the pocket: put back what it was (the saved copy says which one)
		function ENT:OnDuplicated(data)
			local saved = data and data.DT and data.DT.Mat
			if not saved then return end

			self:SetMat(saved)

			local def = self:GetDef()
			if not def then return end

			self:Look(def)

			if def.scale ~= 1 then
				self:SetModelScale(def.scale, 0)
				self:Activate()
			end
		end
	elseif kind == "scrap" then
		-- A label over each piece of scrap (they are just small props), like gems and ingots
		function ENT:Draw()
			self:DrawModel()
			if not DubzScrap.Config.labels then return end

			local distance = LocalPlayer():GetPos():Distance(self:GetPos())
			if distance > 300 then return end

			local def = self:GetDef()
			if not def then return end

			local alpha = math.Clamp(255 * (1 - distance / 300), 0, 255)
			local color = def.color
			-- (black plastic would be unreadable as a label colour)
			if color.r + color.g + color.b < 150 then color = Color(190, 190, 190) end

			cam.Start3D2D(self:GetPos() + Vector(0, 0, 12), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.08)
				draw.WordBox(6, 0, 0, DubzScrap.ScrapName(def), "DermaLarge", Color(0, 0, 0, 150 * alpha / 255), ColorAlpha(color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			cam.End3D2D()
		end
	end
end

-- The Scavenging skill. Registered again when its numbers change in the admin menu. (Skills register on Initialize because the skills
-- addon loads after this one.)
function DubzScrap.RegisterSkill()
	if not (DubzSkills and DubzSkills.Register) then return end

	local c = DubzScrap.Config

	DubzSkills.Register({
		id = "scavenging", category = "industry", name = "Scavenging",
		desc = "Searching dumpsters and scrapping what you find makes you a better scavenger: faster scrapping, more scrap and better trash.",
		maxLevel = 10, xpBase = c.scavXpBase, xpExponent = c.scavXpExponent,
		effect = function(level)
			return math.floor(DubzScrap.SpeedBonus(level)) .. "% faster scrapping, " .. math.floor(DubzScrap.BonusChance(level)) .. "% extra scrap, +" .. DubzScrap.ExtraTrash(level) .. " trash a search"
		end,
	})
end

hook.Add("Initialize", "DubzScrap_Skill", DubzScrap.RegisterSkill)
if DubzSkills then DubzScrap.RegisterSkill() end

-- The crafting table (Dubz Mining) can use scrap in recipes: "Plastic=3, Metal=2". These hooks let it find the scrap by name or id.
hook.Add("DubzMiningExtraMaterial", "DubzScrap_Recipes", function(text)
	local material = DubzScrap.FindMaterial(text)
	if not material then return end

	return {id = material.id, name = material.name, color = material.color, kind = "scrap", price = 0, chance = 0, forge = 0, model = ""}
end)
