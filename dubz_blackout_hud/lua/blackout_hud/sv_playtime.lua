-- Persistent play time tracking (replaces UTime). Stored in the server sqlite db.
local SAVE_INTERVAL = 300

sql.Query("CREATE TABLE IF NOT EXISTS bhud_playtime (sid TEXT PRIMARY KEY, seconds INTEGER NOT NULL DEFAULT 0)")

local function loadSeconds(ply)
	local sid = sql.SQLStr(ply:SteamID64() or ply:SteamID())
	local saved = sql.QueryValue("SELECT seconds FROM bhud_playtime WHERE sid = " .. sid)

	if saved then return tonumber(saved) or 0 end

	-- First time we see this player: carry over any existing UTime total.
	return math.floor(tonumber(ply:GetPData("UTime", 0)) or 0)
end

local function saveSeconds(ply)
	if not IsValid(ply) or ply:GetNWInt("bhud_play_base", -1) < 0 then return end

	local total = math.floor(BHUD.GetPlayTime(ply) or 0)
	local sid = sql.SQLStr(ply:SteamID64() or ply:SteamID())
	sql.Query("REPLACE INTO bhud_playtime (sid, seconds) VALUES (" .. sid .. ", " .. total .. ")")
end

hook.Add("PlayerInitialSpawn", "BHUD_PlayTimeLoad", function(ply)
	ply:SetNWInt("bhud_play_base", loadSeconds(ply))
	ply:SetNWFloat("bhud_play_join", CurTime())
end)

hook.Add("PlayerDisconnected", "BHUD_PlayTimeSave", saveSeconds)

hook.Add("ShutDown", "BHUD_PlayTimeSaveAll", function()
	for _, ply in ipairs(player.GetAll()) do saveSeconds(ply) end
end)

timer.Create("BHUD_PlayTimeAutosave", SAVE_INTERVAL, 0, function()
	for _, ply in ipairs(player.GetAll()) do saveSeconds(ply) end
end)
