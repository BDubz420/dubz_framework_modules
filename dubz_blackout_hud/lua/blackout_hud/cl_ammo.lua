-- Ammo box, bottom-right: "Ammo: clip/reserve". Hidden for weapons that use no ammo (melee, tools).
function BHUD.DrawAmmo(lp)
	local wep = lp:GetActiveWeapon()
	if not IsValid(wep) then return end

	local clip = wep:Clip1()
	local ammoType = wep:GetPrimaryAmmoType()
	local reserve = ammoType >= 0 and lp:GetAmmoCount(ammoType) or 0

	local text
	if clip >= 0 then
		text = clip .. "/" .. reserve
	elseif ammoType >= 0 and reserve > 0 then
		text = tostring(reserve) -- clip-less weapons such as grenades
	else
		return
	end

	local p = BHUD.Config.panel
	local label = "Ammo: " .. text

	surface.SetFont("daHUDAmmo")
	local tw, th = surface.GetTextSize(label)
	local w, h = tw + 28, th + 14
	local x, y = BHUD.Place("bottomright", w, h)

	draw.RoundedBox(8, x, y, w, h, p.bg)
	draw.SimpleText(label, "daHUDAmmo", x + 14, y + h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end
