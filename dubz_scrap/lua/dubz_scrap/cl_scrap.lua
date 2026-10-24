-- Scrap, client side: the Scrap entries in the pocket's right click menu, and the bar that fills while you scrap.

-- Right click in the pocket
hook.Add("DubzInvContextMenu", "DubzScrap_Menu", function(menu, slot, rec)
	if rec.class ~= "dubz_trash" and rec.class ~= "dubz_cosmetic" then return end

	local function start(all)
		net.Start("DubzScrap_Start")
			net.WriteUInt(slot, 8)
			net.WriteBool(all)
		net.SendToServer()
	end

	menu:AddOption("Scrap", function() start(false) end)
	if (rec.qty or 1) > 1 then menu:AddOption("Scrap all (" .. rec.qty .. ")", function() start(true) end) end
end)

-- The bar: plain black card, filling as you scrap. Moving the pocket menu or pressing Escape does not stop it; dying does.
hook.Add("HUDPaint", "DubzScrap_Bar", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	local start = lp:GetNWFloat("dubz_scrap_start", 0)
	if start <= 0 then return end

	local length = math.max(lp:GetNWFloat("dubz_scrap_time", 1), 0.1)
	local fraction = math.Clamp((CurTime() - start) / length, 0, 1)

	if DFW and DFW.Draw and DFW.Draw.ProgressCard then
		DFW.Draw.ProgressCard(ScrW() / 2, ScrH() * 0.62, 220, "Scrapping " .. lp:GetNWString("dubz_scrap_name", ""), fraction)
		return
	end

	local w, h = 300, 46
	local x, y = ScrW() / 2 - w / 2, ScrH() * 0.62

	draw.RoundedBox(6, x, y, w, h, Color(0, 0, 0, 160))
	draw.SimpleText("Scrapping " .. lp:GetNWString("dubz_scrap_name", ""), "DermaDefault", ScrW() / 2, y + 12, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local accent = (DFW and DFW.UI and DFW.UI.GetTheme and DFW.UI.GetTheme().accent) or Color(230, 160, 20)
	draw.RoundedBox(3, x + 10, y + h - 16, w - 20, 8, Color(255, 255, 255, 30))
	draw.RoundedBox(3, x + 10, y + h - 16, (w - 20) * fraction, 8, accent)
end)
