-- Shared play time API. The server owns the numbers (sv_playtime.lua) and
-- networks them; this file only reads them, so the HUD and ULX-facing shims agree.

-- Total seconds played (saved time + current session). Synced server time via CurTime().
function BHUD.GetPlayTime(ply)
	local base = ply:GetNWInt("bhud_play_base", -1)
	if base < 0 then return nil end

	local joined = ply:GetNWFloat("bhud_play_join", 0)
	return base + math.max(0, CurTime() - joined)
end

function BHUD.GetSessionTime(ply)
	return math.max(0, CurTime() - ply:GetNWFloat("bhud_play_join", 0))
end

-- Stand-in for UTime so ULX/ULib code that calls the UTime player methods keeps working.
-- Only defined when UTime itself isn't installed.
hook.Add("Initialize", "BHUD_UTimeShim", function()
	local PLAYER = FindMetaTable("Player")

	if not PLAYER.GetUTimeTotalTime then
		function PLAYER:GetUTimeTotalTime() return BHUD.GetPlayTime(self) or 0 end
	end

	if not PLAYER.GetUTimeSessionTime then
		function PLAYER:GetUTimeSessionTime() return BHUD.GetSessionTime(self) end
	end
end)
