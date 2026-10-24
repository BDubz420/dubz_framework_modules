-- Karma: killing innocents lowers it, good deeds and commends raise it. Stored in sqlite.
local cfg = DubzKarma.Config

sql.Query("CREATE TABLE IF NOT EXISTS dubz_karma (sid TEXT PRIMARY KEY, karma INTEGER NOT NULL)")

-- Karma belongs to the character (Steam ID + character; see DubzChars.GetKey)
local function sid(ply)
	if DubzChars and DubzChars.GetKey then return sql.SQLStr(DubzChars.GetKey(ply)) end
	return sql.SQLStr(ply:SteamID64() or ply:SteamID())
end

local function save(ply)
	local karma = ply:GetNWInt("dubz_karma", cfg.start)
	sql.Query("REPLACE INTO dubz_karma (sid, karma) VALUES (" .. sid(ply) .. ", " .. karma .. ")")
end

-- Public API: DubzKarma.Add(ply, amount, "reason shown to the player")
function DubzKarma.Add(ply, amount, reason)
	if not DubzKarma.Enabled() then return end
	if not IsValid(ply) or not amount or amount == 0 then return end

	local old = ply:GetNWInt("dubz_karma", cfg.start)
	local new = math.Clamp(old + amount, cfg.min, cfg.max)
	if new == old then return end

	ply:SetNWInt("dubz_karma", new)
	save(ply)

	if reason and DarkRP and DarkRP.notify then
		DarkRP.notify(ply, new > old and 0 or 1, 4, string.format("Karma %+d: %s", new - old, reason))
	end
end

local function loadKarma(ply)
	local saved = sql.QueryValue("SELECT karma FROM dubz_karma WHERE sid = " .. sid(ply))

	-- The first character of an account inherits the account's old karma
	if not saved and DubzChars and DubzChars.LegacyKey then
		local legacy = DubzChars.LegacyKey(ply)
		if legacy then saved = sql.QueryValue("SELECT karma FROM dubz_karma WHERE sid = " .. sql.SQLStr(legacy)) end
	end

	-- Carry over karma saved by the old HUD-bundled system, once.
	if not saved and sql.TableExists("bhud_karma") then
		saved = sql.QueryValue("SELECT karma FROM bhud_karma WHERE sid = " .. sid(ply))
	end

	ply:SetNWInt("dubz_karma", tonumber(saved) or cfg.start)
end

hook.Add("PlayerInitialSpawn", "DubzKarma_Load", loadKarma)

-- A deleted (wiped) character takes its karma with it
hook.Add("DubzCharWipe", "DubzKarma_CharWipe", function(account, charId, keys)
	for _, key in ipairs(keys) do sql.Query("DELETE FROM dubz_karma WHERE sid = " .. sql.SQLStr(key)) end
end)

-- Switching characters: this one's karma is saved, the next one's loaded
hook.Add("DubzCharLeave", "DubzKarma_CharLeave", function(ply) save(ply) end)
hook.Add("DubzCharLoad", "DubzKarma_CharLoad", function(ply) loadKarma(ply) end)

-- DoPlayerDeath runs before PlayerDeath, i.e. before DarkRP clears the wanted state.
hook.Add("DoPlayerDeath", "DubzKarma_WasWanted", function(ply)
	ply.DubzKarma_WasWanted = ply.isWanted and ply:isWanted() or false
end)

hook.Add("PlayerDeath", "DubzKarma_Kill", function(victim, _, attacker)
	local wasWanted = victim.DubzKarma_WasWanted
	victim.DubzKarma_WasWanted = nil

	if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end

	if wasWanted then
		DubzKarma.Add(attacker, cfg.killWanted, "killed a wanted criminal")
	else
		DubzKarma.Add(attacker, cfg.killPlayer, "killed a player")
	end
end)

hook.Add("playerArrested", "DubzKarma_Arrest", function(criminal, _, actor)
	if IsValid(actor) and actor:IsPlayer() and actor ~= criminal then
		DubzKarma.Add(actor, cfg.arrestWanted, "arrested a criminal")
	end
end)

timer.Create("DubzKarma_PlayBonus", cfg.playBonusInterval, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() then DubzKarma.Add(ply, cfg.playBonus) end
	end
end)

hook.Add("PlayerDisconnected", "DubzKarma_Save", save)

-- Everyday karma sources ----------------------------------------------------------------------------------------
-- DubzKarma.Reward(event, class, actor, owner): other addons call this (cooking does, when a donut is cooked).
-- It pays out every row of the Karma Sources table that matches the event and entity class.
local rewardTimes = {}

local function ownerOf(ent)
	if not IsValid(ent) then return nil end

	local owner = ent.Getowning_ent and ent:Getowning_ent()
	if not IsValid(owner) and ent.CPPIGetOwner then owner = ent:CPPIGetOwner() end
	if not IsValid(owner) then owner = ent:GetNWEntity("Owner") end

	return IsValid(owner) and owner or nil
end

function DubzKarma.Reward(event, class, actor, owner)
	if not DubzKarma.Enabled() then return end

	class = string.lower(tostring(class or ""))

	for _, row in ipairs(DubzKarma.Sources) do
		if row.event == event and string.lower(row.class) == class and row.karma ~= 0 then
			local target = row.who == "owner" and owner or actor

			-- Owners can't farm themselves: an "owner" reward needs a different player as the actor
			if IsValid(target) and target:IsPlayer() and not (row.who == "owner" and target == actor) then
				local key = target:SteamID64() .. "|" .. event .. "|" .. class .. "|" .. (IsValid(actor) and actor:SteamID64() or "")
				local readyAt = rewardTimes[key] or 0

				if readyAt <= CurTime() then
					rewardTimes[key] = CurTime() + (row.cooldown or 0)
					DubzKarma.Add(target, row.karma, row.note ~= "" and row.note or event)
				end
			end
		end
	end
end

local function hasSource(event, class)
	class = string.lower(class)

	for _, row in ipairs(DubzKarma.Sources) do
		if row.event == event and string.lower(row.class) == class then return true end
	end

	return false
end

-- Buying an entity from F4
hook.Add("playerBoughtCustomEntity", "DubzKarma_Bought", function(ply, entTable, ent)
	if not IsValid(ply) or not istable(entTable) then return end

	DubzKarma.Reward("bought", entTable.ent or (IsValid(ent) and ent:GetClass()), ply, nil)
end)

-- Using a healing entity while hurt: remember it, and reward once the player reaches full health
hook.Add("PlayerUse", "DubzKarma_HealTrack", function(ply, ent)
	if not DubzKarma.Enabled() or not IsValid(ent) then return end

	local class = ent:GetClass()
	if not hasSource("healed", class) then return end
	if ply:Health() >= ply:GetMaxHealth() then return end

	ply.DubzKarmaHeal = {ent = ent, class = class, started = CurTime()}
end)

timer.Create("DubzKarma_HealWatch", 0.5, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local record = ply.DubzKarmaHeal

		if record then
			if not ply:Alive() or not IsValid(record.ent) or CurTime() - record.started > cfg.healWindow
				or ply:GetPos():Distance(record.ent:GetPos()) > 300 then
				ply.DubzKarmaHeal = nil
			elseif ply:Health() >= ply:GetMaxHealth() then
				ply.DubzKarmaHeal = nil
				DubzKarma.Reward("healed", record.class, ply, ownerOf(record.ent))
			end
		end
	end
end)
