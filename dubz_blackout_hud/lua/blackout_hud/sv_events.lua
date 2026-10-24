-- Server events that feed the HUD: popups, death info, NLR / wanted / mayor-grace timers.
util.AddNetworkString("BHUD_Popup")
util.AddNetworkString("BHUD_Death")
util.AddNetworkString("BHUD_AgendaEdit")   -- server -> client: open the agenda text box

local cfg = BHUD.Config

-- Popups ------------------------------------------------------------------

-- data: key (replaces/clears a popup with the same key), title, text, color, anchor (default topcenter),
--       duration (seconds, 0 = stays until cleared), countdown (show remaining time), clear (remove key)
-- target: a player/table of players, or nil to broadcast.
function BHUD.Popup(target, data)
	net.Start("BHUD_Popup")
		net.WriteString(data.key or "")
		net.WriteBool(data.clear or false)
		net.WriteString(data.title or "")
		net.WriteString(data.text or "")
		net.WriteColor(data.color or Color(190, 86, 82))
		net.WriteFloat(data.duration or 6)
		net.WriteBool(data.countdown or false)
		net.WriteString(data.anchor or "")
	if target then net.Send(target) else net.Broadcast() end
end

local RED = Color(190, 86, 82)
local GREEN = Color(90, 170, 90)
local AMBER = Color(214, 150, 60)

-- Wanted ------------------------------------------------------------------

local function wantedTimerName(ply) return "BHUD_Wanted_" .. ply:EntIndex() end

hook.Add("playerWanted", "BHUD_Wanted", function(criminal, actor, reason)
	criminal.BHUD_WantedReason = reason -- kept so the arrest popup can say why

	if cfg.wantedDuration > 0 then
		criminal:SetNWFloat("bhud_wanted_end", CurTime() + cfg.wantedDuration)

		if cfg.wantedAutoExpire then
			timer.Create(wantedTimerName(criminal), cfg.wantedDuration, 1, function()
				if IsValid(criminal) and criminal.isWanted and criminal:isWanted() then criminal:unWanted() end
			end)
		end
	end

	BHUD.Popup(nil, {
		key = "wanted_" .. criminal:EntIndex(),
		title = "Wanted",
		text = criminal:Nick() .. " is wanted!\nReason: " .. tostring(reason or "none given"),
		color = RED,
		duration = 8,
	})
end)

hook.Add("playerUnWanted", "BHUD_UnWanted", function(criminal)
	criminal:SetNWFloat("bhud_wanted_end", 0)
	timer.Remove(wantedTimerName(criminal))

	BHUD.Popup(nil, {
		title = "Wanted Lifted",
		text = criminal:Nick() .. " is no longer wanted.",
		color = GREEN,
		duration = 6,
	})
end)

-- Arrests / lockdown ------------------------------------------------------

hook.Add("playerArrested", "BHUD_Arrested", function(criminal, time, actor)
	criminal:SetNWFloat("bhud_arrest_end", (time and time > 0) and (CurTime() + time) or 0)

	local by = (IsValid(actor) and actor:IsPlayer()) and actor:Nick() or "the police"
	local reason = criminal.BHUD_WantedReason or criminal:getDarkRPVar("wantedReason")
	if not reason or reason == "" then reason = "No reason given" end
	criminal.BHUD_WantedReason = nil

	-- Brief notice; the remaining time lives on the top bar afterwards.
	BHUD.Popup(criminal, {
		key = "arrested",
		title = "Arrested",
		text = "You were arrested by " .. by .. ".\nReason: " .. reason,
		color = RED,
		duration = 8,
	})
end)

hook.Add("playerUnArrested", "BHUD_UnArrested", function(criminal)
	criminal:SetNWFloat("bhud_arrest_end", 0)
	BHUD.Popup(criminal, {key = "arrested", clear = true})
end)

hook.Add("lockdownStarted", "BHUD_LockdownStart", function()
	BHUD.Popup(nil, {
		key = "lockdown",
		title = "Lockdown",
		text = "The mayor has ordered a lockdown. Return to your homes.",
		color = RED,
		duration = 0,
	})
end)

hook.Add("lockdownEnded", "BHUD_LockdownEnd", function()
	BHUD.Popup(nil, {key = "lockdown", clear = true})
	BHUD.Popup(nil, {
		title = "Lockdown Ended",
		text = "The lockdown has been lifted.",
		color = GREEN,
		duration = 6,
	})
end)

-- Mayor grace period ------------------------------------------------------

hook.Add("OnPlayerChangedTeam", "BHUD_MayorGrace", function(ply, before, after)
	local mayorTeam = _G[cfg.mayorTeamName]
	if not mayorTeam or cfg.mayorGraceTime <= 0 then return end

	if after == mayorTeam then
		game.GetWorld():SetNWFloat("bhud_mayor_grace_end", CurTime() + cfg.mayorGraceTime)

		BHUD.Popup(nil, {
			title = "New Mayor",
			text = ply:Nick() .. " is now the mayor.",
			color = AMBER,
			duration = 6,
		})
	elseif before == mayorTeam and team.NumPlayers(mayorTeam) == 0 then
		game.GetWorld():SetNWFloat("bhud_mayor_grace_end", 0)
	end
end)

-- Death -------------------------------------------------------------------

local KIND_ENV, KIND_SUICIDE, KIND_PLAYER, KIND_NPC = 0, 1, 2, 3

local function prettyClass(class)
	return (string.gsub(string.gsub(class, "^npc_", ""), "_", " "))
end

hook.Add("PlayerDeath", "BHUD_Death", function(victim, _, attacker)
	local kind, name, steamid = KIND_ENV, "", ""

	if attacker == victim then
		kind = KIND_SUICIDE
	elseif IsValid(attacker) and attacker:IsPlayer() then
		kind, name, steamid = KIND_PLAYER, attacker:Nick(), attacker:SteamID()
	elseif IsValid(attacker) and attacker:IsNPC() then
		kind, name = KIND_NPC, prettyClass(attacker:GetClass())
	end

	net.Start("BHUD_Death")
		net.WriteUInt(kind, 3)
		net.WriteString(name)
		net.WriteString(steamid)
	net.Send(victim)
end)

-- /editagenda: the boss of an agenda gets a text box (the agenda itself is still set by DarkRP's /agenda)
hook.Add("InitPostEntity", "BHUD_EditAgendaCommand", function()
	timer.Simple(1, function()
		if not (DarkRP and DarkRP.defineChatCommand) then return end

		DarkRP.defineChatCommand("editagenda", function(ply)
			local agenda = ply.getAgendaTable and ply:getAgendaTable()

			if not agenda or agenda.Manager ~= ply:Team() then
				DarkRP.notify(ply, 1, 4, "You are not in charge of an agenda.")
				return ""
			end

			net.Start("BHUD_AgendaEdit")
			net.Send(ply)

			return ""
		end)
	end)
end)
