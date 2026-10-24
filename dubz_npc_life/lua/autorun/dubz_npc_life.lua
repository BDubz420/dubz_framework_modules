-- Dubz NPC Life: makes the shop-type NPCs (the drug dealer, the shops) feel alive. They idle with a changing animation, look at you with their
-- head and eyes (and turn to face you when you walk around them), and now and then say something when you walk up or when a sale goes through
-- (only sometimes, so it does not get annoying). Other NPCs can use it too: DubzNPCLife.Think(npc) every tick, DubzNPCLife.Say(npc, "greet" or "sale").
-- Settings: Dubz Framework admin menu (!dubzconfig > NPC Life).
DubzNPCLife = DubzNPCLife or {}

DubzNPCLife.Config = DubzNPCLife.Config or {
	Enabled = true,
	LookDistance = 320,        -- how close you must be for an NPC to look at you (units)
	TurnToFace = true,         -- turn the whole body when you are far to the side or behind
	TurnSpeed = 140,           -- degrees a second
	IdleSequences = {"idle_all_01", "idle_subtle", "idle_all_02", "lineidle01", "lineidle02", "pose_standing_01", "pose_standing_02"},
	IdleSwitchMin = 7,         -- seconds before the idle animation changes
	IdleSwitchMax = 18,

	SoundsOn = true,
	GreetDistance = 170,       -- walking this close can trigger a greeting
	GreetChance = 35,          -- percent: not every time
	SaleChance = 45,           -- percent chance of a line when a sale or purchase goes through
	SoundCooldown = 6,         -- seconds between two lines from one NPC
	SoundLevel = 65,
	GreetSounds = {"vo/npc/male01/hi01.wav", "vo/npc/male01/hi02.wav", "vo/npc/male01/answer01.wav", "vo/npc/male01/answer04.wav", "vo/npc/male01/answer11.wav"},
	SaleSounds = {"vo/npc/male01/nice.wav", "vo/npc/male01/yeah02.wav", "vo/npc/male01/ok01.wav", "vo/npc/male01/ok02.wav", "vo/npc/male01/finally.wav"},
}

local cfg = DubzNPCLife.Config

function DubzNPCLife.Enabled()
	return cfg.Enabled and (not (DFW and DFW.Bind) or DFW.Bind.Enabled("npc_life"))
end

if SERVER then
	AddCSLuaFile("dubz_npc_life/sh_framework.lua")

	local function pick(list)
		if not istable(list) or #list == 0 then return nil end
		return list[math.random(#list)]
	end

	-- A line from the NPC, only sometimes (kind: "greet" or "sale"; chance overrides the setting)
	function DubzNPCLife.Say(npc, kind, chance)
		if not (IsValid(npc) and DubzNPCLife.Enabled() and cfg.SoundsOn) then return end
		if CurTime() < (npc.LifeQuietUntil or 0) then return end

		if math.random(100) > (chance or (kind == "sale" and cfg.SaleChance or cfg.GreetChance)) then return end

		local sound = pick(kind == "sale" and cfg.SaleSounds or cfg.GreetSounds)
		if not sound then return end

		npc.LifeQuietUntil = CurTime() + cfg.SoundCooldown
		npc:EmitSound(sound, cfg.SoundLevel)
	end

	local function nearest(npc)
		local best, bestDistance = nil, cfg.LookDistance * cfg.LookDistance

		for _, ply in ipairs(player.GetAll()) do
			if ply:Alive() then
				local distance = ply:GetPos():DistToSqr(npc:GetPos())
				if distance < bestDistance then best, bestDistance = ply, distance end
			end
		end

		return best
	end

	local function setPose(npc, name, value)
		if npc:LookupPoseParameter(name) >= 0 then npc:SetPoseParameter(name, value) end
	end

	-- Call from the NPC's Think every tick (the animation only advances when it thinks every tick). Handles idle animation, looking and greeting.
	function DubzNPCLife.Think(npc)
		if not DubzNPCLife.Enabled() then return end

		local now = CurTime()
		local dt = math.Clamp(now - (npc.LifeLast or now), 0, 0.2)
		npc.LifeLast = now

		DubzNPCLife.KeepPose(npc)

		-- Idle animation: one is picked, and changes every so often (an NPC held in a pose by its own settings, LifeFixedPose, keeps it)
		if now >= (npc.LifeNextIdle or 0) and not npc.LifeFixedPose then
			npc.LifeNextIdle = now + math.Rand(cfg.IdleSwitchMin, cfg.IdleSwitchMax)

			local options = {}
			for _, name in ipairs(cfg.IdleSequences) do
				if npc:LookupSequence(name) > 0 then options[#options + 1] = name end
			end

			local name = pick(options)
			if name then npc:ResetSequence(npc:LookupSequence(name)) end
		end

		-- Who to look at (looked for a few times a second)
		if now >= (npc.LifeNextSearch or 0) then
			npc.LifeNextSearch = now + 0.25

			local target = nearest(npc)

			-- Someone just walked up: sometimes a greeting
			if target and target ~= npc.LifeTarget and target:GetPos():DistToSqr(npc:GetPos()) < cfg.GreetDistance * cfg.GreetDistance and now > (npc.LifeGreetAfter or 0) then
				npc.LifeGreetAfter = now + 25
				DubzNPCLife.Say(npc, "greet")
			end

			npc.LifeTarget = target
		end

		npc.LifeHome = npc.LifeHome or npc:GetAngles().y

		local target = npc.LifeTarget
		local yaw, pitch = 0, 0

		if IsValid(target) then
			local eyes = npc:GetPos() + Vector(0, 0, 64)
			local aim = (target:EyePos() - eyes):Angle()
			local facing = npc:GetAngles().y
			local diff = math.AngleDifference(aim.y, facing)

			npc:SetEyeTarget(target:EyePos())

			-- Far to the side or behind: the body turns, then the head takes the rest
			if cfg.TurnToFace and not npc.LifeFixedPose and math.abs(diff) > 50 then
				local turn = math.Clamp(diff, -cfg.TurnSpeed * dt, cfg.TurnSpeed * dt)
				npc:SetAngles(Angle(0, facing + turn, 0))
				diff = math.AngleDifference(aim.y, npc:GetAngles().y)
			end

			yaw = math.Clamp(diff, -50, 50)
			pitch = math.Clamp(math.NormalizeAngle(aim.p), -25, 25)
		elseif cfg.TurnToFace and not npc.LifeFixedPose and math.abs(math.AngleDifference(npc.LifeHome, npc:GetAngles().y)) > 2 then
			-- Nobody about: turn back the way he was put
			local diff = math.AngleDifference(npc.LifeHome, npc:GetAngles().y)
			npc:SetAngles(Angle(0, npc:GetAngles().y + math.Clamp(diff, -cfg.TurnSpeed * dt * 0.5, cfg.TurnSpeed * dt * 0.5), 0))
		end

		-- Ease towards it so the head glides
		npc.LifeYaw = Lerp(math.min(dt * 6, 1), npc.LifeYaw or 0, yaw)
		npc.LifePitch = Lerp(math.min(dt * 6, 1), npc.LifePitch or 0, pitch)

		setPose(npc, "head_yaw", npc.LifeYaw)
		setPose(npc, "head_pitch", npc.LifePitch)
		setPose(npc, "aim_yaw", npc.LifeYaw)
		setPose(npc, "aim_pitch", npc.LifePitch)
	end

	-- The poses an NPC can be held in (a choice list for the admin menus; "auto" = it idles and changes by itself, the NPC Life way)
	DubzNPCLife.Poses = {"auto", "idle_all_01", "idle_subtle", "idle_all_02", "lineidle01", "lineidle02", "lineidle03", "lineidle04",
		"pose_standing_01", "pose_standing_02", "pose_standing_03", "pose_standing_04", "sit_chair", "sit_ground", "idle_all_angry", "cower"}

	-- Holds an NPC in a pose (a sequence name). "auto" or an empty name lets NPC Life animate it again. A pose its model does not have is skipped.
	-- NPC Life's Think keeps it there; an NPC with its own Think can call DubzNPCLife.KeepPose(npc) there instead.
	function DubzNPCLife.SetPose(npc, pose)
		if not IsValid(npc) then return end

		npc.LifePose = pose
		npc.LifeFixedPose = pose ~= nil and pose ~= "" and pose ~= "auto"
		npc.LifePoseSeq = nil

		if npc.LifeFixedPose then
			local seq = npc:LookupSequence(pose)
			if seq <= 0 then seq = npc:LookupSequence("idle_all_01") end

			if seq > 0 then
				npc.LifePoseSeq = seq
				npc:ResetSequence(seq)
				npc:SetPlaybackRate(1)
			end
		end
	end

	-- Puts the NPC back in its pose if something changed the animation (call every tick)
	function DubzNPCLife.KeepPose(npc)
		if npc.LifeFixedPose and npc.LifePoseSeq and npc:GetSequence() ~= npc.LifePoseSeq then
			npc:ResetSequence(npc.LifePoseSeq)
			npc:SetPlaybackRate(1)
		end
	end

	-- When an NPC is moved to a new place (a traveling shop) its "home" direction is the new one
	function DubzNPCLife.Rehome(npc)
		if IsValid(npc) then npc.LifeHome = npc:GetAngles().y end
	end
end

-- Dubz Framework: manifest so NPC Life shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_npc_life",
	name = "Dubz NPC Life",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_npc_life/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
