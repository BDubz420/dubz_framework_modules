-- Gestures, server side: checks a request to play a gesture and tells everyone who can see the player. The animation itself plays on each client.
util.AddNetworkString("DubzGest_Play")   -- client -> server: gesture number. server -> clients: player, gesture number

local cfg = DubzGestures.Config

local function say(ply, text)
	if DarkRP and DarkRP.notify then DarkRP.notify(ply, 1, 3, text) else ply:ChatPrint(text) end
end

function DubzGestures.Play(ply, gesture)
	if not IsValid(ply) or not gesture then return false end
	if not DubzGestures.Enabled() or DubzGestures.IsDisabled(gesture.id) then return false end

	if not ply:Alive() then return false end
	if ply:GetNWBool("dubz_char_pending", false) then return false end                 -- still at the character screen
	if ply:GetNWString("dubz_act_kind", "") ~= "" then say(ply, "You are busy.") return false end   -- working (searching, scrapping, crafting)
	if ply:InVehicle() and not cfg.allowInVehicle then return false end

	if (ply.DubzGestNext or 0) > CurTime() then return false end
	ply.DubzGestNext = CurTime() + math.max(cfg.cooldown, 0.2)

	-- How long the animation lasts: the player stands still for that long (see the StartCommand hook in sh_config.lua)
	local act = _G[gesture.act]
	local sequence = act and ply:SelectWeightedSequence(act) or -1
	local length = sequence > 0 and ply:SequenceDuration(sequence) or 0

	ply:SetNWFloat("dubz_gest_until", CurTime() + (length > 0 and length or 2.5))

	net.Start("DubzGest_Play")
		net.WriteEntity(ply)
		net.WriteUInt(gesture.index, 8)
	net.SendPVS(ply:GetPos())

	return true
end

net.Receive("DubzGest_Play", function(_, ply)
	DubzGestures.Play(ply, DubzGestures.List[net.ReadUInt(8)])
end)

-- dubz_gesture <id>: the same from the console, so a gesture can be put on a key (bind x "dubz_gesture wave")
concommand.Add("dubz_gesture", function(ply, _, args)
	if not IsValid(ply) then return end

	DubzGestures.Play(ply, DubzGestures.ById[string.lower(args[1] or "")])
end)

-- Dying (or respawning) ends the stand-still
hook.Add("PlayerDeath", "DubzGestures_ClearLock", function(ply) ply:SetNWFloat("dubz_gest_until", 0) end)
hook.Add("PlayerSpawn", "DubzGestures_ClearLockSpawn", function(ply) ply:SetNWFloat("dubz_gest_until", 0) end)
