-- Skill storage and XP. Other addons call DubzSkills.AddXP(ply, "lockpicking", 5) when something is done.
-- Overall level comes from ALL skill XP added together (plus an admin "bonus" pool, key "_bonus").
util.AddNetworkString("DubzSkills_Open")

sql.Query("CREATE TABLE IF NOT EXISTS dubz_skills (sid TEXT NOT NULL, skill TEXT NOT NULL, xp REAL NOT NULL DEFAULT 0, PRIMARY KEY (sid, skill))")

local NET_SYNC_INTERVAL = 5   -- seconds between XP network updates (levels sync instantly)
local SAVE_INTERVAL = 60
local BONUS = "_bonus"

-- Skills belong to the character (Steam ID + character; see DubzChars.GetKey)
local function sidOf(ply)
	if DubzChars and DubzChars.GetKey then return DubzChars.GetKey(ply) end
	return ply:SteamID64() or ply:SteamID()
end

local function say(ply, text)
	local color = Color(240, 196, 25)

	if DarkRP and DarkRP.talkToPerson then
		DarkRP.talkToPerson(ply, color, "[Skills] ", color_white, text)
	else
		ply:ChatPrint("[Skills] " .. text)
	end
end

local function save(ply)
	if not ply.DubzSkillXP then return end

	local sid = sql.SQLStr(sidOf(ply))
	for id, xp in pairs(ply.DubzSkillXP) do
		sql.Query("REPLACE INTO dubz_skills (sid, skill, xp) VALUES (" .. sid .. ", " .. sql.SQLStr(id) .. ", " .. xp .. ")")
	end

	ply.DubzSkillsDirty = false
end

local function syncXP(ply)
	for id, xp in pairs(ply.DubzSkillXP or {}) do ply:SetNWInt("dubz_sk_" .. id .. "_xp", math.floor(xp)) end
end

-- Total of everything (precise, server side)
local function totalXP(ply)
	local total = 0
	for _, xp in pairs(ply.DubzSkillXP or {}) do total = total + xp end
	return total
end

local function loadSkills(ply)
	ply.DubzSkillXP = {}

	local rows = sql.Query("SELECT skill, xp FROM dubz_skills WHERE sid = " .. sql.SQLStr(sidOf(ply)))

	-- The first character of an account inherits the account's old skills
	if not rows and DubzChars and DubzChars.LegacyKey then
		local legacy = DubzChars.LegacyKey(ply)
		if legacy then rows = sql.Query("SELECT skill, xp FROM dubz_skills WHERE sid = " .. sql.SQLStr(legacy)) end
	end

	for _, row in ipairs(rows or {}) do
		-- Skills that no longer exist are ignored; their XP stays in the database
		if DubzSkills.Skills[row.skill] or row.skill == BONUS then ply.DubzSkillXP[row.skill] = tonumber(row.xp) or 0 end
	end

	for id, def in pairs(DubzSkills.Skills) do
		local xp = ply.DubzSkillXP[id] or 0
		ply:SetNWInt("dubz_sk_" .. id .. "_lv", DubzSkills.LevelFromXP(def, xp))
		ply:SetNWInt("dubz_sk_" .. id .. "_xp", math.floor(xp))
	end

	ply:SetNWInt("dubz_sk_" .. BONUS .. "_xp", math.floor(ply.DubzSkillXP[BONUS] or 0))
	ply:SetNWInt("dubz_overall_lv", DubzSkills.OverallLevelFromXP(totalXP(ply)))
end

hook.Add("PlayerInitialSpawn", "DubzSkills_Load", loadSkills)

-- A deleted (wiped) character takes its skills with it
hook.Add("DubzCharWipe", "DubzSkills_CharWipe", function(account, charId, keys)
	for _, key in ipairs(keys) do sql.Query("DELETE FROM dubz_skills WHERE sid = " .. sql.SQLStr(key)) end
end)

-- Switching characters: this one's XP is saved, the next one's loaded
hook.Add("DubzCharLeave", "DubzSkills_CharLeave", function(ply) save(ply) end)
hook.Add("DubzCharLoad", "DubzSkills_CharLoad", function(ply) loadSkills(ply) ply.DubzSkillsDirty = true end)

-- Recomputes a skill's level and the overall level after its XP changed. announce = chat + sounds.
local function applyChange(ply, id, oldSkillLevel, oldOverall, announce)
	local def = DubzSkills.Skills[id]
	local xp = ply.DubzSkillXP[id] or 0

	if def then
		local newLevel = DubzSkills.LevelFromXP(def, xp)
		ply:SetNWInt("dubz_sk_" .. id .. "_lv", newLevel)
		ply:SetNWInt("dubz_sk_" .. id .. "_xp", math.floor(xp))

		if announce and newLevel > oldSkillLevel then
			say(ply, "Your " .. def.name .. " skill increased to level " .. newLevel .. ".")
			if DubzSkills.Config.levelUpSounds then ply:EmitSound(DubzSkills.Config.levelUpSound, DubzSkills.Config.soundLevel, 100) end
		end
	else
		ply:SetNWInt("dubz_sk_" .. id .. "_xp", math.floor(xp))
	end

	local newOverall = DubzSkills.OverallLevelFromXP(totalXP(ply))
	ply:SetNWInt("dubz_overall_lv", newOverall)

	if announce and newOverall > oldOverall then
		say(ply, "You are now level " .. newOverall .. ".")

		-- A second, higher ding for an overall level
		timer.Simple(0.3, function()
			if IsValid(ply) and DubzSkills.Config.levelUpSounds then ply:EmitSound(DubzSkills.Config.overallLevelUpSound, DubzSkills.Config.soundLevel, 130) end
		end)
	end

	ply.DubzSkillsDirty = true
end

-- Public API: give XP (positive amounts only; the leveling messages and sounds play).
function DubzSkills.AddXP(ply, id, amount)
	local def = DubzSkills.Skills[id]
	if not DubzSkills.Enabled() then return end
	if not IsValid(ply) or not def or not amount or amount <= 0 or not ply.DubzSkillXP then return end

	local maxXP = DubzSkills.XPForLevel(def, def.maxLevel)
	local old = ply.DubzSkillXP[id] or 0
	if old >= maxXP then return end

	local oldLevel = DubzSkills.LevelFromXP(def, old)
	local oldOverall = DubzSkills.GetOverallLevel(ply)

	ply.DubzSkillXP[id] = math.min(old + amount, maxXP)

	-- Only level-ups are applied immediately; plain XP is networked on the sync timer
	local newLevel = DubzSkills.LevelFromXP(def, ply.DubzSkillXP[id])
	local newOverall = DubzSkills.OverallLevelFromXP(totalXP(ply))

	if newLevel ~= oldLevel or newOverall ~= oldOverall then
		applyChange(ply, id, oldLevel, oldOverall, true)
		save(ply)
	else
		ply.DubzSkillsDirty = true
	end
end

-- Admin: set a skill's XP exactly (id may be "_bonus"). Silent, saves right away.
function DubzSkills.SetXP(ply, id, xp)
	if not IsValid(ply) or not ply.DubzSkillXP then return end

	local def = DubzSkills.Skills[id]
	if not def and id ~= BONUS then return end

	local oldLevel = def and DubzSkills.LevelFromXP(def, ply.DubzSkillXP[id] or 0) or 0
	local oldOverall = DubzSkills.GetOverallLevel(ply)

	xp = math.max(0, xp)
	if def then xp = math.min(xp, DubzSkills.XPForLevel(def, def.maxLevel)) end

	ply.DubzSkillXP[id] = xp
	applyChange(ply, id, oldLevel, oldOverall, false)
	save(ply)
end

function DubzSkills.GetServerXP(ply, id)
	return (ply.DubzSkillXP or {})[id] or 0
end

function DubzSkills.GetServerTotalXP(ply)
	return totalXP(ply)
end

timer.Create("DubzSkills_Sync", NET_SYNC_INTERVAL, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.DubzSkillsDirty then syncXP(ply) end
	end
end)

timer.Create("DubzSkills_Save", SAVE_INTERVAL, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.DubzSkillsDirty then save(ply) end
	end
end)

hook.Add("PlayerDisconnected", "DubzSkills_SaveOnLeave", save)

hook.Add("ShutDown", "DubzSkills_SaveAll", function()
	for _, ply in ipairs(player.GetAll()) do save(ply) end
end)

-- /skills opens the menu
hook.Add("PlayerSay", "DubzSkills_ChatCommand", function(ply, text)
	if not DubzSkills.Enabled() then return end
	if not table.HasValue(DubzSkills.Config.chatCommands, string.lower(string.Trim(text))) then return end

	net.Start("DubzSkills_Open")
	net.Send(ply)

	return ""
end)
