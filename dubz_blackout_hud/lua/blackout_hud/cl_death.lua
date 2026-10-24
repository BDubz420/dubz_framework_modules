-- Death screen: fade to black, the cause of death in red (killer name + SteamID for players), the NLR
-- reminder and a respawn prompt. On respawn the screen fades back in from black.
local info, diedAt, respawnedAt

local FADE_TIME = 1.5       -- fade to black
local TEXT_DELAY = 0.8      -- before the text appears
local PROMPT_DELAY = 3      -- before "press any key to respawn" appears
local RESPAWN_FADE = 1.0    -- fade back in after respawning

net.Receive("BHUD_Death", function()
	info = {
		kind = net.ReadUInt(3),
		name = net.ReadString(),
		steamid = net.ReadString(),
	}
	diedAt = CurTime()
end)

-- Called every frame while alive.
function BHUD.ResetDeath()
	if diedAt then respawnedAt = CurTime() end
	info, diedAt = nil, nil
end

local function causeText()
	if not info then return "Cause of death: unknown" end

	if info.kind == 1 then return "You committed suicide." end
	if info.kind == 2 then return string.format("Killed by %s (%s).", info.name, info.steamid) end
	if info.kind == 3 then return string.format("Killed by a %s.", info.name) end

	return "Cause of death: the environment."
end

function BHUD.DrawDeath(lp)
	-- The message can arrive a frame after the player dies, so start the clock on first draw too.
	diedAt = diedAt or CurTime()
	respawnedAt = nil

	local elapsed = CurTime() - diedAt
	local sw, sh = ScrW(), ScrH()
	local red = BHUD.Config.panel.accent

	surface.SetDrawColor(0, 0, 0, 255 * math.Clamp(elapsed / FADE_TIME, 0, 1))
	surface.DrawRect(0, 0, sw, sh)

	local textAlpha = 255 * math.Clamp((elapsed - TEXT_DELAY) / 0.6, 0, 1)
	if textAlpha <= 0 then return end

	local cx, cy = sw / 2, sh / 2
	local gray = Color(160, 160, 160, textAlpha)

	draw.SimpleText(causeText(), "daHUDDeathReason", cx, cy - 20, Color(red.r, red.g, red.b, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Follow New Life Rule (NLR)", "daHUDDeathMed", cx, cy + 30, gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local promptAlpha = textAlpha * math.Clamp((elapsed - PROMPT_DELAY) / 0.6, 0, 1)
	if promptAlpha > 0 then
		draw.SimpleText("Press any key to respawn", BHUD.Config.font, cx, cy + 70, Color(200, 200, 200, promptAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- Black overlay that fades out right after respawning. Drawn last so it covers the whole HUD.
function BHUD.DrawRespawnFade()
	if not respawnedAt then return end

	local t = (CurTime() - respawnedAt) / RESPAWN_FADE
	if t >= 1 then
		respawnedAt = nil
		return
	end

	surface.SetDrawColor(0, 0, 0, 255 * (1 - t))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end
