-- Third person, client side: the camera, F7 to switch views, Alt free look, and the settings panel.
local cfg = DubzThirdPerson.Config

local cameraAngles = Angle(0, 0, 0)
local initialized = false
local wasPassingMouse = false
local lockedAngles   -- the heading the player is locked to while Alt is held

-- A player's settings (see DubzThirdPerson.Settings in sh_config.lua): one console variable each, kept between sessions
for _, setting in ipairs(DubzThirdPerson.Settings) do
	CreateClientConVar(setting.cvar, setting.default, true, false, setting.label)
end

local function boolCVar(name)
	local cvar = GetConVar(name)
	return cvar and cvar:GetBool() or false
end

local function floatCVar(name, fallback)
	local cvar = GetConVar(name)
	return cvar and cvar:GetFloat() or fallback
end

local function intCVar(name, fallback)
	local cvar = GetConVar(name)
	return cvar and cvar:GetInt() or fallback
end

-- Other cameras (the character screen, the placement editors) take over the view: this one steps aside while they are up
local function blocked()
	if DubzChars and DubzChars.MenuOpen then return true end

	local lp = LocalPlayer()
	if IsValid(lp) and lp:GetNWBool("dubz_char_pending", false) then return true end

	return hook.Run("DubzThirdPersonBlocked") == true
end

local function cameraEnabled()
	local ply = LocalPlayer()

	if not IsValid(ply) or not DubzThirdPerson.Enabled() then return false end
	if not boolCVar("dtp_enable") then return false end
	if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE or ply:InVehicle() then return false end

	return not blocked()
end

local function resetAngles(angles)
	lockedAngles = nil
	cameraAngles = Angle(angles.p, angles.y, 0)
	initialized = true
end

-- The older cameras (ACT3's weapon camera, the first Dubz and Nathan scripts) fight over the view: out of the way
local function removeOtherCameras()
	if not cfg.disableOtherCameras then return end

	hook.Remove("CalcView", "ACT3_CalcView")
	hook.Remove("InputMouseApply", "ACT3_InputMouseApply")

	for _, name in ipairs({"DubzThirdPerson_CalcView", "NathanThirdPerson_CalcView", "DubzThirdPersonGameplay_CalcView"}) do hook.Remove("CalcView", name) end
	for _, name in ipairs({"DubzThirdPerson_InputMouseApply", "NathanThirdPerson_InputMouseApply", "DubzThirdPersonGameplay_InputMouseApply"}) do hook.Remove("InputMouseApply", name) end
	for _, name in ipairs({"DubzThirdPerson_ShouldDrawLocalPlayer", "DubzThirdPersonGameplay_ShouldDrawLocalPlayer"}) do hook.Remove("ShouldDrawLocalPlayer", name) end
end

local function setThirdPerson(enabled)
	if not enabled and not cfg.allowToggle then return end

	RunConsoleCommand("dtp_enable", enabled and "1" or "0")

	if enabled then resetAngles(EyeAngles()) end
end

local function toggle()
	setThirdPerson(not boolCVar("dtp_enable"))
end

-- Bobbing ------------------------------------------------------------------------------------------------------------------------------------------

local function bobAngles(ply)
	if not cfg.allowBobbing or not boolCVar("dtp_bobbing") then return Angle(0, 0, 0) end
	if ply:GetMoveType() == MOVETYPE_NOCLIP then return Angle(0, 0, 0) end

	local speed = math.Clamp(ply:GetVelocity():Length2D() / 280, 0, 1.4)
	if speed <= 0.05 then return Angle(0, 0, 0) end

	local amount = floatCVar("dtp_bob_amount", 1)

	return Angle(math.sin(CurTime() * 9) * speed * amount * 0.55, 0, math.cos(CurTime() * 9) * speed * amount * 0.35)
end

-- Mouse minigames --------------------------------------------------------------------------------------------------------------------------------
-- Lockpicking, keypads and the like need the real mouse: the camera lets go while one is in use

local interactionTokens = {"lockpick", "picklock", "keypad", "cracker", "safecracker", "pickpocket"}

local function weaponNeedsMouse(ply)
	local weapon = IsValid(ply) and ply:GetActiveWeapon()
	if not IsValid(weapon) then return false end

	if weapon.DubzThirdPersonMousePassthrough or weapon.DTPMousePassthrough then return true end

	local printName = weapon.GetPrintName and weapon:GetPrintName() or weapon.PrintName or ""
	local info = string.lower((weapon:GetClass() or "") .. " " .. printName)

	for _, token in ipairs(interactionTokens) do
		if string.find(info, token, 1, true) then return true end
	end

	return false
end

local function passMouse(ply)
	return boolCVar("dtp_interaction_mouse") or gui.IsGameUIVisible() or vgui.CursorVisible() or weaponNeedsMouse(ply)
end

local function freeLook()
	return cfg.allowFreeLook and boolCVar("dtp_freelook") and (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT))
end

-- The camera ---------------------------------------------------------------------------------------------------------------------------------------

-- Walls must never be seen through. The camera is kept inside open space in three steps:
--   1. a box (Camera Clearance units on every side) is swept from the player's eyes to where the camera wants to be, so it stops before any
--      surface and stays that far from it (nothing can poke in through the near plane at corners or beside a wall);
--   2. rays from the head, and from points around it (above, below, to both sides), must reach the camera: if one hits something, the camera
--      is pulled in along that ray, which stops a thin wall or a corner from being peeked past from the side;
--   3. if the eyes themselves are inside something, the camera stays at the eyes.
-- Players and NPCs don't block it; everything else solid (the map, props, doors, glass) does.
local function blocks(ent)
	return not (ent:IsPlayer() or ent:IsNPC() or ent:IsWeapon())
end

local function safeOrigin(ply, from, wanted, angles)
	local clearance = math.Clamp(cfg.cameraClearance or 8, 2, 24)
	local box = Vector(clearance, clearance, clearance)

	local trace = util.TraceHull({
		start = from, endpos = wanted, filter = blocks,
		mins = -box, maxs = box, mask = MASK_SOLID,
	})

	if trace.StartSolid then return from end

	local at = trace.HitPos

	-- Rays from around the head: the camera must be visible from all of them
	local right, up = angles:Right() * 6, angles:Up() * 6
	local starts = {from, from + right, from - right, from + up, from - up}

	for _, start in ipairs(starts) do
		local line = util.TraceLine({start = start, endpos = at, filter = blocks, mask = MASK_SOLID})

		if line.Hit and not line.StartSolid then
			at = start + (at - start) * math.Clamp(line.Fraction * 0.85, 0, 1)
		end
	end

	return at
end

local function calcView(ply, pos, angles, fov)
	removeOtherCameras()

	if not cameraEnabled() then
		resetAngles(angles)
		return
	end

	if not initialized then resetAngles(angles) end

	local viewAngles = Angle(cameraAngles.p, cameraAngles.y, 0)
	local origin = pos
	local eyes = ply:LookupAttachment("eyes")

	if eyes and eyes > 0 then
		local attachment = ply:GetAttachment(eyes)
		if attachment then origin = attachment.Pos end
	end

	local shoulder = intCVar("dtp_shoulder", 1) < 0 and -1 or 1
	local distance = math.Clamp(floatCVar("dtp_distance", 88), cfg.distanceMin, cfg.distanceMax)

	local wanted = origin
		+ viewAngles:Up() * floatCVar("dtp_up", -2)
		+ viewAngles:Right() * floatCVar("dtp_right", 12) * shoulder
		- viewAngles:Forward() * distance

	local znear = 2
	local at = safeOrigin(ply, pos, wanted, viewAngles)

	return {
		origin = at,
		angles = viewAngles + ply:GetViewPunchAngles() + bobAngles(ply),
		fov = math.Clamp(floatCVar("dtp_fov", 90), cfg.fovMin, cfg.fovMax),
		znear = znear,
		drawviewer = true,
		viewmodelfov = 90,
	}
end

-- The mouse turns the camera. The player turns with it (the default: aim is where the camera looks) - or, holding Alt, stays where they are
-- so the camera can swing round them, until you move: then they turn the way you walk.
local function mouseApply(cmd, x, y)
	removeOtherCameras()

	if not cameraEnabled() then
		resetAngles(cmd:GetViewAngles())
		return
	end

	if not initialized then resetAngles(cmd:GetViewAngles()) end

	if passMouse(LocalPlayer()) then
		wasPassingMouse = true
		return
	end

	if wasPassingMouse then
		resetAngles(cmd:GetViewAngles())
		wasPassingMouse = false
	end

	local scale = floatCVar("dtp_sensitivity", 1) * 25 * GetConVar("sensitivity"):GetFloat()
	local deltaX, deltaY = x * scale / ScrW(), y * scale / ScrH()

	if GetConVar("m_yaw"):GetFloat() < 0 then deltaX = -deltaX end
	if GetConVar("m_pitch"):GetFloat() < 0 then deltaY = -deltaY end

	cameraAngles.p = math.Clamp(cameraAngles.p + deltaY, -85, 85)
	cameraAngles.y = cameraAngles.y - deltaX
	cameraAngles.r = 0

	local viewAngles = cmd:GetViewAngles()

	-- Holding Alt locks which way the player faces (the way they were facing when Alt went down): they keep walking straight along it and the
	-- camera swings round them freely. Let go and they turn back to where the camera points.
	if freeLook() then
		if not lockedAngles then lockedAngles = Angle(viewAngles.p, viewAngles.y, 0) end

		cmd:SetViewAngles(lockedAngles)
		return true
	end

	lockedAngles = nil

	local rate = 720

	viewAngles.p = math.ApproachAngle(viewAngles.p, cameraAngles.p, FrameTime() * rate)
	viewAngles.y = math.ApproachAngle(viewAngles.y, cameraAngles.y, FrameTime() * rate)
	viewAngles.r = 0

	cmd:SetViewAngles(viewAngles)

	return true
end

hook.Add("CalcView", "DubzTP_CalcView", calcView)
hook.Add("InputMouseApply", "DubzTP_Mouse", mouseApply)

hook.Add("ShouldDrawLocalPlayer", "DubzTP_Draw", function(ply)
	if ply == LocalPlayer() and cameraEnabled() then return true end
end)

-- The switch key (the server's, unless the player picked their own) ---------------------------------------------------------------------------

-- The key for something: the player's own (-1 = they turned it off), else the server's (nil when the server has it off)
local function keyFor(cvarName, serverField)
	local own = intCVar(cvarName, 0)

	if own < 0 then return nil end
	if own > 0 then return own end
	if serverField == "shoulderKey" and not cfg.shoulderKeyEnabled then return nil end

	return cfg[serverField]
end

local function swapShoulder()
	RunConsoleCommand("dtp_shoulder", intCVar("dtp_shoulder", 1) < 0 and "1" or "-1")
end

hook.Add("PlayerButtonDown", "DubzTP_Key", function(ply, button)
	if ply ~= LocalPlayer() or not IsFirstTimePredicted() then return end

	local isSwitch = button == keyFor("dtp_key", "toggleKey")
	local isShoulder = button == keyFor("dtp_shoulder_key", "shoulderKey")
	if not isSwitch and not isShoulder then return end
	if not DubzThirdPerson.Enabled() or DubzThirdPerson.CapturingKey then return end

	-- Not while typing, in a menu, or in a screen that has its own camera
	if ply:IsTyping() or gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) or blocked() then return end

	if isShoulder then swapShoulder() else toggle() end
end)

concommand.Add("dtp_toggle", toggle)
concommand.Add("dtp_firstperson", function() setThirdPerson(false) end)
concommand.Add("dtp_thirdperson", function() setThirdPerson(true) end)
concommand.Add("dtp_shoulder_swap", function() swapShoulder() end)
concommand.Add("dtp_interaction_toggle", function() RunConsoleCommand("dtp_interaction_mouse", boolCVar("dtp_interaction_mouse") and "0" or "1") end)
concommand.Add("dtp_bobbing_toggle", function() RunConsoleCommand("dtp_bobbing", boolCVar("dtp_bobbing") and "0" or "1") end)

net.Receive("DubzTP_SetMode", function() setThirdPerson(net.ReadBool()) end)

-- Starting in third person the first time (after that it is the player's choice, kept in their console variables)
hook.Add("InitPostEntity", "DubzTP_First", function()
	timer.Simple(0, function()
		if cfg.startInThirdPerson and cookie.GetNumber("dubz_tp_seen", 0) == 0 then
			cookie.Set("dubz_tp_seen", "1")
			setThirdPerson(true)
		end
	end)
end)

-- The settings panel ---------------------------------------------------------------------------------------------------------------------------
-- DubzThirdPerson.BuildSettings(parent) fills any panel with the player's camera settings in the framework's controls: the context menu icon
-- uses it, and so can the F4 settings tab.

local function keyName(code, serverField)
	if code < 0 then return "off" end
	if code == 0 then return "server default (" .. string.upper(input.GetKeyName(cfg[serverField or "toggleKey"] or 0) or "?") .. ")" end

	return string.upper(input.GetKeyName(code) or "?")
end

function DubzThirdPerson.BuildSettings(parent)
	if not (DFW and DFW.UI) then return end

	parent:Clear()

	local scroll = vgui.Create("DFW.ScrollPanel", parent)
	scroll:Dock(FILL)

	for _, setting in ipairs(DubzThirdPerson.Settings) do
		local hidden = (setting.id == "bobbing" or setting.id == "bob_amount") and not cfg.allowBobbing
			or (setting.id == "freelook" and not cfg.allowFreeLook)
			or (setting.id == "key" and not cfg.allowToggle)
			or (setting.id == "enable" and not cfg.allowToggle)

		if not hidden then
			local cvar = setting.cvar

			if setting.type == "bool" or setting.type == "shoulder" then
				local box = vgui.Create("DFW.Checkbox", scroll)
				box:Dock(TOP)
				box:SetTall(28)
				box:DockMargin(8, 4, 8, 0)
				box:SetLabel(setting.label)

				if setting.type == "shoulder" then
					box:SetChecked(intCVar(cvar, 1) < 0, true)
					box.OnChange = function(_, value) RunConsoleCommand(cvar, value and "-1" or "1") end
				else
					box:SetChecked(boolCVar(cvar), true)
					box.OnChange = function(_, value) RunConsoleCommand(cvar, value and "1" or "0") end
				end

				box:SetTooltip(setting.help)
			elseif setting.type == "number" then
				local caption = vgui.Create("DFW.Label", scroll)
				caption:Dock(TOP)
				caption:SetTall(18)
				caption:DockMargin(8, 8, 8, 0)
				caption:SetStyle("small")
				caption:SetText(setting.label)

				local slider = vgui.Create("DFW.Slider", scroll)
				slider:Dock(TOP)
				slider:SetTall(24)
				slider:DockMargin(8, 0, 8, 0)
				slider:SetRange(setting.min, setting.max)
				slider:SetDecimals(setting.decimals or 0)
				slider:SetValue(floatCVar(cvar, tonumber(setting.default)), true)
				slider.OnValueChanged = function(_, value) RunConsoleCommand(cvar, tostring(value)) end
			elseif setting.type == "key" then
				local button = vgui.Create("DFW.Button", scroll)
				button:Dock(TOP)
				button:SetTall(34)
				button:DockMargin(8, 10, 8, 4)
				button:SetLabel(setting.label .. ": " .. keyName(intCVar(cvar, 0), setting.serverKey))
				button:SetTooltip(setting.help)

				button.DoClick = function()
					button:SetLabel("Press a key...")
					DubzThirdPerson.CapturingKey = true

					hook.Add("PlayerButtonDown", "DubzTP_Capture", function(ply, code)
						if ply ~= LocalPlayer() or not IsFirstTimePredicted() then return end
						if code == MOUSE_LEFT or code == MOUSE_RIGHT then return end   -- (the click that started this)

						hook.Remove("PlayerButtonDown", "DubzTP_Capture")
						timer.Simple(0.2, function() DubzThirdPerson.CapturingKey = false end)

						-- Escape cancels, Backspace goes back to the server's key, Delete turns the key off
						if code ~= KEY_ESCAPE then RunConsoleCommand(cvar, code == KEY_BACKSPACE and "0" or (code == KEY_DELETE and "-1" or tostring(code))) end

						if IsValid(button) then button:SetLabel(setting.label .. ": " .. keyName(intCVar(cvar, 0), setting.serverKey)) end
					end)
				end
			end
		end
	end
end

-- A window for it (console: dtp_menu) and the icon in the context menu (hold Q... C)
-- For other addons: is the player in the third person camera right now?
function DubzThirdPerson.IsActive()
	return cameraEnabled()
end

function DubzThirdPerson.OpenMenu()
	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end

	local frame = DFW.UI.CreateFrame("Third Person", 380, 520, nil, {compact = true, module = "thirdperson"})
	DubzThirdPerson.BuildSettings(frame:GetContent())
end

concommand.Add("dtp_menu", function() DubzThirdPerson.OpenMenu() end)

list.Set("DesktopWindows", "DubzThirdPerson", {
	title = "Third Person", icon = "icon32/zoom_extend.png", width = 380, height = 520, onewindow = true,
	init = function(icon, panel) DubzThirdPerson.BuildSettings(panel) end,
})
