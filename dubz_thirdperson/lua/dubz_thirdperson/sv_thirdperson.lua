-- Third person, server side: switching the view on request (chat commands), the spawn rules, and the upright helper for props.
util.AddNetworkString("DubzTP_SetMode")   -- server -> client: true = third person, false = first person

local cfg = DubzThirdPerson.Config

local function setMode(ply, enabled)
	if not IsValid(ply) then return end

	if enabled == false and not cfg.allowToggle then return end

	net.Start("DubzTP_SetMode")
		net.WriteBool(enabled)
	net.Send(ply)
end

-- Every spawn, if the server wants everyone in third person
hook.Add("PlayerSpawn", "DubzTP_Spawn", function(ply)
	if not DubzThirdPerson.Enabled() or not cfg.forceOnSpawn then return end

	timer.Simple(0, function() setMode(ply, true) end)
end)

hook.Add("PlayerSay", "DubzTP_ChatCommands", function(ply, text)
	if not DubzThirdPerson.Enabled() then return end

	local command = string.lower(string.Trim(text or ""))

	if command == "!firstperson" then
		setMode(ply, false)
		return ""
	end

	if command == "!thirdperson" or command == "!third" then
		setMode(ply, true)
		return ""
	end

	if command == "!shoulder" then
		ply:ConCommand("dtp_shoulder_swap")
		return ""
	end

	if command == "!interactionmouse" then
		ply:ConCommand("dtp_interaction_toggle")
		return ""
	end
end)

-- The upright helper -------------------------------------------------------------------------------------------------------------------------------
-- Alt + right click with the physgun, tool gun or gravity gun: the prop you aim at is stood upright (turned to face the way you look) on the ground.

local deniedClasses = {
	player = true, worldspawn = true, prop_ragdoll = true,
	gmod_sent_vehicle_fphysics_base = true, gmod_sent_vehicle_fphysics_wheel = true,
}

local allowedPrefixes = {"prop_", "sent_", "ent_", "gmod_"}

local function canUpright(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return false end
	if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then return false end
	if ent:GetMoveType() == MOVETYPE_NONE then return false end

	local class = ent:GetClass() or ""
	if deniedClasses[class] then return false end

	for _, prefix in ipairs(allowedPrefixes) do
		if string.StartWith(class, prefix) then return true end
	end

	return ent:GetPhysicsObjectCount() > 0
end

local function groundPosition(ent, desired)
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local height = math.max(maxs.z - mins.z, 1)

	local trace = util.TraceHull({
		start = desired + Vector(0, 0, height + 96),
		endpos = desired - Vector(0, 0, height + 512),
		mins = Vector(mins.x, mins.y, 0),
		maxs = Vector(maxs.x, maxs.y, 4),
		filter = ent,
		mask = MASK_SOLID,
	})

	return (trace.Hit and trace.HitPos or desired) + Vector(0, 0, math.abs(mins.z) + 1)
end

local function upright(ply, ent)
	if not canUpright(ply, ent) then return end

	local physics = {}

	for index = 0, ent:GetPhysicsObjectCount() - 1 do
		local phys = ent:GetPhysicsObjectNum(index)

		if IsValid(phys) then
			physics[#physics + 1] = phys
			phys:EnableMotion(false)
		end
	end

	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	ent:SetPos(groundPosition(ent, ent:GetPos()))
	ent:DropToFloor()

	timer.Simple(0, function()
		if not IsValid(ent) then return end

		ent:SetPos(groundPosition(ent, ent:GetPos()))

		for _, phys in ipairs(physics) do
			if IsValid(phys) then
				phys:SetVelocity(vector_origin)
				phys:AddAngleVelocity(-phys:GetAngleVelocity())
				phys:EnableMotion(true)
				phys:Wake()
			end
		end
	end)
end

local TOOLS = {weapon_physgun = true, gmod_tool = true, weapon_physcannon = true}

hook.Add("StartCommand", "DubzTP_Upright", function(ply, cmd)
	if not cfg.uprightHelper or not IsValid(ply) or not ply:Alive() then return end

	-- (once per click)
	if not (cmd:KeyDown(IN_WALK) and cmd:KeyDown(IN_ATTACK2)) then
		ply.DubzTPWasClick = false
		return
	end

	if ply.DubzTPWasClick then return end
	ply.DubzTPWasClick = true

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) or not TOOLS[string.lower(weapon:GetClass() or "")] then return end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or not IsValid(trace.Entity) or trace.HitPos:DistToSqr(ply:GetShootPos()) > 220 * 220 then return end

	upright(ply, trace.Entity)
end)
