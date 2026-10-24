-- Weapon Stance, client side: in third person the crosshair stays up while you aim. In first person aiming hides it (you are looking down the
-- sights), and weapons like M9K hide their own crosshair then in third person too, which leaves nothing to aim with. This draws a plain cross
-- in the middle of the screen (where the shots go in third person) while the player aims.
local cfg = DubzStance.Config

local MARGIN = 1   -- the black outline

-- Is the player aiming? The weapon's own state (M9K calls it ironsights), or the right mouse button for the weapons this addon handles
local function aiming(ply, wep)
	if wep.GetIronsights and wep:GetIronsights() == true then return true end
	if wep.GetIronSights and wep:GetIronSights() == true then return true end
	if wep:GetNWBool("Ironsights", false) or wep:GetNWBool("IronSights", false) then return true end

	return false
end

local function handledByStance(wep)
	local class = string.lower(wep:GetClass())

	for _, prefix in ipairs(cfg.prefixes or {}) do
		if prefix ~= "" and string.StartWith(class, string.lower(prefix)) then return true end
	end

	return table.HasValue(cfg.classes or {}, class)
end

local function line(x, y, w, h)
	surface.SetDrawColor(0, 0, 0, 220)
	surface.DrawRect(x - MARGIN, y - MARGIN, w + MARGIN * 2, h + MARGIN * 2)

	surface.SetDrawColor(255, 255, 255, 235)
	surface.DrawRect(x, y, w, h)
end

hook.Add("HUDPaint", "DubzStance_Crosshair", function()
	if not cfg.thirdPersonCrosshair or not DubzStance.Enabled() then return end
	if not (DubzThirdPerson and DubzThirdPerson.IsActive and DubzThirdPerson.IsActive()) then return end

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end

	-- Aiming: the weapon says so, or (for this addon's weapons) the right mouse button is down
	if not (aiming(ply, wep) or (handledByStance(wep) and ply:KeyDown(IN_ATTACK2))) then return end

	-- Running is not aiming: the weapon may call its sprint pose "ironsights", so only the right mouse button counts then
	if ply:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > 160 and not ply:KeyDown(IN_ATTACK2) then return end

	local x, y = ScrW() / 2, ScrH() / 2
	local size, gap, thickness = cfg.crosshairSize, cfg.crosshairGap, cfg.crosshairThickness
	local half = math.floor(thickness / 2)

	line(x - gap - size, y - half, size, thickness)   -- left
	line(x + gap, y - half, size, thickness)          -- right
	line(x - half, y - gap - size, thickness, size)   -- top
	line(x - half, y + gap, thickness, size)          -- bottom
end)
