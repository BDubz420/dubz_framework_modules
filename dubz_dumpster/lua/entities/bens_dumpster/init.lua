AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("Bens_DumpsterSendTime")

-- Settings come from DubzDumpster.Config / .Props / .Drops (lua/dubz_dumpster), which the Dubz Framework admin
-- menu edits live.

function ENT:Initialize()
	self:SetModel("models/props_junk/TrashDumpster01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetTrigger(true)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(100)
		phys:Wake()
	end
end

local function canSearch(ply)
	local jobs = DubzDumpster.Config.jobs
	if not next(jobs) then return true end

	local job = ply.getJobTable and ply:getJobTable()
	return job ~= nil and jobs[string.lower(job.name or "")] == true
end

local function spawnPos(self, spreadX, spreadY, zMin, zMax)
	return self:GetPos() + Vector(math.random(-spreadX, spreadX), math.random(-spreadY, spreadY), math.random(zMin, zMax))
end

-- Press E: with the hands-at-work addon the player searches for a few seconds (arms in the dumpster, rummaging sounds) and gets the
-- loot at the end; without it the loot is instant.
function ENT:Use(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if self.CanUse == false or self.Searching then return end
	if not DubzDumpster.Enabled() then return end
	if not canSearch(ply) then return end

	local time = DubzDumpster.Config.searchTime or 0

	if time > 0 and DubzActions and DubzActions.Start and DubzActions.Allowed and DubzActions.Allowed("search") then
		self.Searching = true

		local started = DubzActions.Start(ply, "search", time, {
			label = "Searching the dumpster", hint = "dumpster",
			onFinish = function()
				if not IsValid(self) then return end

				self.Searching = false
				if IsValid(ply) and ply:Alive() and ply:GetPos():Distance(self:GetPos()) < 200 then self:Search(ply) end
			end,
			onCancel = function() if IsValid(self) then self.Searching = false end end,
		})

		if not started then self.Searching = false end
		return
	end

	-- The search animation is switched off (Actions > Dumpster Search Animation) but the hands-at-work addon is there: still take the time and
	-- show the progress bar (the bar reads the same player values the animation sets), just with no arms or sounds.
	if time > 0 and DubzActions and DubzActions.Config and DubzActions.Config.showBar ~= false then
		self.Searching = true

		ply:SetNWFloat("dubz_act_start", CurTime())
		ply:SetNWFloat("dubz_act_time", time)
		ply:SetNWString("dubz_act_label", "Searching the dumpster")

		local token = CurTime()
		ply.DubzBarOnly = token

		local function clear()
			if ply.DubzBarOnly ~= token then return end

			ply.DubzBarOnly = nil
			ply:SetNWFloat("dubz_act_start", 0)
			ply:SetNWString("dubz_act_label", "")
		end

		-- The rummaging sounds, on the same beat the animation would use (everyone nearby hears them), or a simple set if that isn't available
		local beat = DubzActions.BeatFor and DubzActions.BeatFor("search")
		beat = beat or {{0, "physics/metal/metal_barrel_impact_hard1.wav", 90, 100, 65}, {0.45, "physics/cardboard/cardboard_box_impact_soft1.wav", 90, 110, 58}, {0.9, "physics/cardboard/cardboard_box_impact_hard1.wav", 90, 105, 62}}

		for _, step in ipairs(beat) do
			timer.Simple(step[1] * time, function()
				if IsValid(ply) and ply.DubzBarOnly == token then ply:EmitSound(step[2], step[5] or 60, math.random(step[3] or 100, step[4] or 100), 0.8) end
			end)
		end

		timer.Simple(time, function()
			if IsValid(self) then self.Searching = false end
			if not IsValid(ply) then return end

			local stillThere = ply.DubzBarOnly == token and ply:Alive() and IsValid(self) and ply:GetPos():Distance(self:GetPos()) < 200
			clear()

			if stillThere then self:Search(ply) end
		end)

		return
	end

	self:Search(ply)
end

-- The search itself: junk, cash and items
function ENT:Search(ply)
	if self.CanUse == false then return end

	local cfg = DubzDumpster.Config

	net.Start("Bens_DumpsterSendTime")
	net.WriteEntity(self)
	net.WriteInt(cfg.cooldown, 32)
	net.Broadcast()

	-- Random junk. With the scrap addon it is trash that can be picked up, scrapped for resources and sold (see Dubz Scrap);
	-- without it, plain props from the Junk Props table.
	local useTrash = scripted_ents.Get("dubz_trash") ~= nil and DubzScrap and DubzScrap.Enabled and DubzScrap.Enabled()
	local props = DubzDumpster.Props

	-- A better scavenger (the Scavenging skill) finds more, and better, trash, and earns XP for looking
	local level = useTrash and DubzScrap.Level(ply) or 0
	if useTrash then DubzScrap.OnSearch(ply) end

	-- Sometimes there is nothing in it at all (a better scavenger gets fewer of these)
	local empty = math.max((cfg.emptyChance or 0) - level * (cfg.emptyChancePerLevel or 0), 0)

	if empty > 0 and math.random() * 100 < empty then
		local lines = {"Nothing but rot and wet cardboard.", "Somebody got here first.", "Empty. Not even a good smell.", "Just soggy paper. Nothing worth taking."}

		if DarkRP and DarkRP.notify then DarkRP.notify(ply, 1, 4, table.Random(lines)) else ply:ChatPrint(table.Random(lines)) end

		self.CanUse = false
		timer.Simple(cfg.cooldown, function()
			if IsValid(self) then self.CanUse = true end
		end)

		return
	end

	-- How much junk is different every time (from propsMin up to propsAmount), and a good scavenger finds more
	local low = math.Clamp(cfg.propsMin or cfg.propsAmount, 0, cfg.propsAmount)
	local amount = math.random(low, cfg.propsAmount) + (useTrash and DubzScrap.ExtraTrash(level) or 0)

	if useTrash or #props > 0 then
		for _ = 1, amount do
			local junk = ents.Create(useTrash and "dubz_trash" or "prop_physics")

			if IsValid(junk) then
				if useTrash then
					local def = DubzScrap.PickTrash(level)
					if def then junk:SetMat(def.id) end
				else
					junk:SetModel(table.Random(props))
				end
				junk:SetPos(spawnPos(self, 15, 40, 30, 50))
				junk:Spawn()

				timer.Simple(cfg.propLifetime, function()
					if IsValid(junk) then junk:Remove() end
				end)
			end
		end
	end

	-- Random cash
	if cfg.moneyChance >= math.random(1, 100) and GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.MoneyClass then
		local money = ents.Create(GAMEMODE.Config.MoneyClass)
		if IsValid(money) then
			money:SetPos(spawnPos(self, 5, 10, 30, 50))
			money:Setamount(math.random(cfg.moneyMin, math.max(cfg.moneyMin, cfg.moneyMax)))
			money:Spawn()
		end
	end

	-- Random entities / weapons
	local drops = DubzDumpster.Drops
	if #drops > 0 then
		for _ = 1, cfg.entityRolls do
			local drop = table.Random(drops)

			if drop.chance >= math.random(1, 100) then
				local ent = ents.Create(drop.class)

				if IsValid(ent) then
					ent:SetPos(spawnPos(self, 5, 10, 30, 50))
					ent:Spawn()

					-- Loot: hold E to pick it up
					ent.DubzLoot = true
					ent:SetNWBool("DubzHoldE", true)
				end
			end
		end
	end

	self.CanUse = false
	timer.Simple(cfg.cooldown, function()
		if IsValid(self) then self.CanUse = true end
	end)
end
