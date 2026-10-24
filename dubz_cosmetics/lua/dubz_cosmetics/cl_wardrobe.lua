-- Equipment window: what you are wearing in each slot, with a Take off button. Accessories you own but aren't
-- wearing are inventory items (use one from your pocket to wear it; or visit the accessory store to browse).
-- Open with /cosmetics (or !cosmetics, /wardrobe) or the dubz_cosmetics console command.
-- Built from Dubz Framework controls, so it follows the framework theme.
local cfg = DubzCosmetics.Config

local frame
local nextOpen = 0

local function slotRow(parent, slot)
	local row = vgui.Create("Panel", parent)
	row:Dock(TOP)
	row:SetTall(34)
	row:DockMargin(0, 0, 0, 2)

	local button = vgui.Create("DFW.Button", row)
	button:Dock(RIGHT)
	button:SetWide(90)
	button:DockMargin(0, 4, 4, 4)
	button:SetLabel("Take off")
	button.Think = function(self) self:SetEnabled(DubzCosmetics.GetWornItem(LocalPlayer(), slot.id) ~= "") end
	button.DoClick = function()
		net.Start("DubzCos_Unequip")
			net.WriteString(slot.id)
		net.SendToServer()
	end

	row.Paint = function(_, w, h)
		local theme = DFW.UI.GetTheme()
		draw.RoundedBox(4, 0, 0, w, h, theme.slot)

		local def = DubzCosmetics.Get(DubzCosmetics.GetWornItem(LocalPlayer(), slot.id))
		DFW.Draw.Text(slot.name, "Small", 10, h / 2, theme.textMuted)
		DFW.Draw.Text(def and DubzCosmetics.DisplayName(DubzCosmetics.GetWorn(LocalPlayer(), slot.id)) or "Nothing", "Body", 90, h / 2, def and theme.accent or theme.textDim)
	end

end

-- A panel listing every slot with what is worn in it and a Take off button (the stores show it too)
function DubzCosmetics.WornList(parent)
	local list = vgui.Create("Panel", parent)
	list:SetTall(#cfg.slots * 36)

	for _, slot in ipairs(cfg.slots) do slotRow(list, slot) end

	return list
end

local function open()
	if not DubzCosmetics.Enabled() then return end
	if CurTime() < nextOpen then return end
	nextOpen = CurTime() + 1

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then
		chat.AddText(Color(255, 80, 80), "[Cosmetics] ", color_white, "The Dubz Framework addon isn't installed, so the window can't open.")
		return
	end

	if IsValid(frame) then frame:Remove() end

	frame = DFW.UI.CreateFrame("Wardrobe", 340, 250, nil, {compact = true, module = "cosmetics"})

	local list = DubzCosmetics.WornList(frame:GetContent())
	list:Dock(FILL)
	list:DockMargin(4, 4, 4, 4)

	local hint = vgui.Create("DFW.Label", frame:GetContent())
	hint:Dock(BOTTOM)
	hint:SetTall(22)
	hint:SetStyle("small")
	hint:SetAlign(TEXT_ALIGN_CENTER)
	hint:SetText("Use an accessory from your pocket to wear it.")
end

concommand.Add("dubz_cosmetics", open)
net.Receive("DubzCos_Open", open)
