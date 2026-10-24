-- The "Stock the shop" window (admin menu > Cosmetics > Catalog > Stock the shop). Lists every accessory with its
-- tier, how many exist and whether it is on sale; one click puts it on sale (the whole server is told in chat) or
-- pulls it. Limited editions are kept in their own section so they are never mixed up with everyday stock.
local cfg = DubzCosmetics.Config

local frame

local TIER_COLORS = {common = Color(160, 160, 160), limited = Color(235, 180, 60), seasonal = Color(110, 200, 240)}

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function rebuildLater()
	timer.Create("DubzCos.StockRefresh", 0.35, 1, function()
		if IsValid(frame) and frame.Rebuild then frame:Rebuild() end
	end)
end

local function setShop(id, on)
	net.Start("DubzCos_AdminStock")
		net.WriteString(id)
		net.WriteBool(on)
	net.SendToServer()

	rebuildLater()
end

net.Receive("DubzCos_StockInfo", function()
	DubzCosmetics.Minted = util.JSONToTable(net.ReadString()) or {}
	rebuildLater()
end)

function DubzCosmetics.OpenStockWindow()
	if not LocalPlayer():IsAdmin() then return end
	if IsValid(frame) then frame:Remove() end

	frame = DFW.UI.CreateFrame("Stock the Shop", math.min(760, math.floor(ScrW() * 0.5) - 30), 700, nil, {compact = true, module = "cosmetics"})
	if DFW.ConfigMenu and DFW.ConfigMenu.AttachSide then DFW.ConfigMenu.AttachSide(frame) end
	frame:SetSubtitle("Stocking a limited item tells the whole server. Items that sell out are pulled automatically.")

	local scroll = vgui.Create("DFW.ScrollPanel", frame:GetContent())
	scroll:Dock(FILL)

	function frame:Rebuild()
		scroll:Clear()

		local groups = {{label = "Limited and seasonal editions", list = {}}, {label = "Everyday stock", list = {}}}

		for id, def in pairs(DubzCosmetics.Items) do
			if not def.virtual then
				local econ = DubzCosmetics.GetEcon(id)
				table.insert((econ.tier ~= "common" or econ.supply > 0) and groups[1].list or groups[2].list, def)
			end
		end

		for _, group in ipairs(groups) do
			table.sort(group.list, function(a, b) return a.name < b.name end)

			local header = vgui.Create("DFW.SectionHeader", scroll)
			header:Dock(TOP)
			header:SetText(group.label)

			if #group.list == 0 then
				local empty = vgui.Create("DFW.Label", scroll)
				empty:Dock(TOP)
				empty:SetTall(26)
				empty:SetStyle("small")
				empty:SetText("Nothing here yet. Add items in the Catalog table (set Tier to limited or seasonal, and a supply).")
			end

			for _, def in ipairs(group.list) do
				local econ = DubzCosmetics.GetEcon(def.id)
				local minted = DubzCosmetics.Minted[def.id] or 0
				local soldOut = econ.supply > 0 and minted >= econ.supply
				local onSale = DubzCosmetics.IsForSale(def.id)

				local row = vgui.Create("Panel", scroll)
				row:Dock(TOP)
				row:SetTall(48)
				row:DockMargin(0, 0, 6, 4)

				local button = vgui.Create("DFW.Button", row)
				button:Dock(RIGHT)
				button:SetWide(120)
				button:DockMargin(8, 8, 8, 8)

				if soldOut then
					button:SetLabel("Sold out")
					button:SetEnabled(false)
				elseif onSale then
					button:SetLabel("Pull from shop")
					button.DoClick = function() setShop(def.id, false) end
				else
					button:SetLabel("Stock it")
					button:SetVariant("primary")
					button:SetEnabled(econ.price > 0 or econ.credits > 0)
					button.DoClick = function() setShop(def.id, true) end
				end

				row.Paint = function(_, w, h)
					local theme = DFW.UI.GetTheme()
					draw.RoundedBox(6, 0, 0, w, h, theme.slot)

					draw.RoundedBox(3, 8, 8, 8, h - 16, TIER_COLORS[econ.tier] or TIER_COLORS.common)
					DFW.Draw.Text(def.name, "Body", 26, 16, theme.text)

					local prices = {}
					if econ.price > 0 then prices[#prices + 1] = money(econ.price) end
					if econ.credits > 0 then prices[#prices + 1] = econ.credits .. " credits" end
					if #prices == 0 then prices[1] = "no price set" end

					local supply = econ.supply > 0 and (minted .. " / " .. econ.supply .. " minted") or "unlimited"
					DFW.Draw.Text(string.upper(econ.tier) .. "  |  " .. table.concat(prices, " or ") .. "  |  " .. supply, "Tiny", 26, 34, theme.textMuted)

					DFW.Draw.Text(soldOut and "SOLD OUT" or (onSale and "ON SALE" or "off sale"), "Small", w - 140, h / 2,
						onSale and theme.accent or theme.textDim, TEXT_ALIGN_RIGHT)
				end
			end
		end
	end

	frame:Rebuild()
end

concommand.Add("dubz_cosmetic_stock", function() DubzCosmetics.OpenStockWindow() end)
