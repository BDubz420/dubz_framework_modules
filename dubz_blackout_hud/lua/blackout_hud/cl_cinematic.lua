-- Cinematic mode: F8 hides the entire UI, including the chat, for screenshots and videos. Press F8 again to
-- bring it back. One second between presses so the key can't spam it.
BHUD.Cinematic = false

local nextToggle = 0

local function toggle()
	if CurTime() < nextToggle then return end
	nextToggle = CurTime() + 1

	BHUD.Cinematic = not BHUD.Cinematic
end

concommand.Add("bhud_cinematic", toggle)

hook.Add("PlayerButtonDown", "BHUD_CinematicKey", function(ply, button)
	if ply ~= LocalPlayer() or button ~= BHUD.Config.cinematicKey or not BHUD.Enabled() then return end

	local focus = vgui.GetKeyboardFocus()
	if IsValid(focus) and focus:GetClassName() == "TextEntry" then return end

	toggle()
end)

-- Hide every stock HUD element (chat, crosshair, target names ...) while it's on
hook.Add("HUDDrawTargetID", "BHUD_CinematicTargetID", function()
	if BHUD.Cinematic then return false end
end)
