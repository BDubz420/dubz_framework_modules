-- Core hooks: hide the stock HUD pieces and run each module's painter.
hook.Add("HUDShouldDraw", "BHUD_HideDefaults", function(name)
	local cfg = BHUD.Config

	-- Master switch off: leave every stock HUD element alone (DarkRP's own HUD comes back)
	if not BHUD.Enabled() then return end

	-- Cinematic mode (F8): hide everything, chat included
	-- (the weapon selection stays, so the weapon wheel still works)
	if BHUD.Cinematic then
		if name == "CHudWeaponSelection" then return end

		return false
	end

	if name == "DarkRP_LocalPlayerHUD" or name == "CHudAmmo" or name == "DarkRP_Agenda"
		or name == "CHudHealth" or name == "CHudBattery"
		or name == "DarkRP_LockdownHUD" or name == "DarkRP_ArrestedHUD"
		or (cfg.hideDefaultHunger and name == "DarkRP_Hungermod")
		or (cfg.replaceEntityDisplay and name == "DarkRP_EntityDisplay") then
		return false
	end
end)

-- If the pre-split HUD files are still installed they would draw a second HUD on top of this one.
-- Their hooks are removed once everything has loaded (deleting the old files is the real fix).
local OLD_HOOKS = {
	{"HUDShouldDraw", "removedarkrpHUD_raychamp"},
	{"HUDShouldDraw", "DisableDefaultSandboxHUD"},
	{"HUDPaint", "darkrp_hud_baby_raychamp"},
	{"PlayerButtonDown", "ToggleLawsHUD"},
}

hook.Add("InitPostEntity", "BHUD_RemoveOldHUD", function()
	for _, old in ipairs(OLD_HOOKS) do hook.Remove(old[1], old[2]) end

	-- DarkRP's arrested text: it starts when "GotArrested" arrives, so that message is taken over and nothing starts
	if BHUD.Config.hideDefaultArrest then usermessage.Hook("GotArrested", function() end) end
end)

hook.Add("HUDPaint", "BHUD_Paint", function()
	-- DarkRP adds its own "You're arrested for N seconds" text as a HUDPaint hook when you're arrested;
	-- the arrest popup + top bar timer replace it, so drop it as soon as it appears.
	hook.Remove("HUDPaint", "DarkRP_Arrested")

	if BHUD.Cinematic or not BHUD.Enabled() then return end

	local lp = LocalPlayer()
	if not IsValid(lp) or not lp.getDarkRPVar then return end

	if not lp:Alive() then
		BHUD.DrawDeath(lp)
		return
	end

	BHUD.ResetDeath()

	BHUD.LayoutBegin()

	BHUD.DrawOverhead(lp)
	BHUD.DrawDoorPrompt(lp)
	BHUD.DrawTopBar(lp)
	-- Placed in this order: the agenda/laws/ammo claim their space first, popups stack after them
	BHUD.DrawAmmo(lp)
	BHUD.DrawAgenda(lp)
	BHUD.DrawLaws()
	BHUD.DrawPrompts()
	BHUD.DrawPopups()
	BHUD.DrawRespawnFade()
end)
