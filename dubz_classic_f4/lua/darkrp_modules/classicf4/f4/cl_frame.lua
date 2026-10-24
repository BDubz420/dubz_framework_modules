-- The F4 window itself: creates the frame and the tab sheet, then asks each tab file to add its tab.
local F4 = DubzF4

F4.Menu = {}
F4.Menu.Tabs = {}

local scrw, scrh = ScrW(), ScrH()

function F4.Menu.Frame()
	
	F4.Frame = vgui.Create( "DFrame" )
	F4.Frame:SetTitle( F4.Config.Header )
	F4.Frame:SetSize( scrw * 0.55, scrh * 0.65 ) 
	F4.Frame:Center()	
	F4.Frame:ShowCloseButton( true )
	F4.Frame:MakePopup()

	F4.Frame.Paint = function( self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, F4.C.surface)
	end

	-- If F4 is still held when the window appears, ignore it until it is released (no key-repeat flicker)
	F4.WaitRelease = input.IsKeyDown( KEY_F4 )

	F4.Frame.Think = function()
		if F4.WaitRelease and not input.IsKeyDown( KEY_F4 ) then F4.WaitRelease = false end
	end

	F4.Frame.OnKeyCodePressed = function( self, key )

		if key == KEY_F4 and not F4.WaitRelease then
	
			DarkRP.toggleF4Menu()
		end
	end
	
	local sheet = vgui.Create( "DPropertySheet", F4.Frame )
	sheet:Dock( FILL )

	sheet.Paint = function( self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, F4.C.surface)
	end
	
	-- Tabs in the order (and with the switches) set in the admin menu: F4 Menu > Tabs
	local builders = {
		main = function() F4.Menu.Tabs.Main( sheet ) end,
		jobs = function() F4.Menu.Tabs.Jobs( sheet ) end,
		entities = function() F4.Menu.Tabs.Entities( sheet ) end,
		organization = function() F4.Menu.Tabs.Organization( sheet ) end,
		laws = function() F4.Menu.Tabs.Laws( sheet ) end,
		info = function() F4.Menu.Tabs.Info( sheet ) end,
		help = function() F4.Menu.Tabs.Help( sheet ) end,
		rules = function() F4.Menu.Tabs.Rules( sheet ) end,
		donate = function() F4.Menu.Tabs.Donate( sheet ) end,
		gangs = function()
			-- The Gangs tab comes from the gangs addon
			if gangs and gangs.f4menu then
				local gangPanelClass = LocalPlayer():getGang() ~= "" and "DRPGangPanel" or "DRPCreateGangPanel"
				local gangPanel = vgui.Create( gangPanelClass, sheet )
				gangPanel:Dock( FILL )
				gangPanel:Refresh()

				sheet:AddSheet( gangs.tabname, gangPanel, "icon16/group.png" )
			end
		end,
	}

	local built = {}

	for _, row in ipairs( F4.TabRows or {} ) do
		local build = builders[row.tab]

		if build and not built[row.tab] then
			built[row.tab] = true
			if row.enabled then build() end
		end
	end

	-- A tab the table doesn't mention still shows, at the end
	for _, name in ipairs( F4.TabNames ) do
		if not built[name] then builders[name]() end
	end

	-- Tab buttons follow the framework theme
	for _, item in ipairs( sheet:GetItems() ) do
		local tab = item.Tab

		if IsValid( tab ) then
			tab.Paint = function( self, w, h )
				local active = sheet:GetActiveTab() == self
				draw.RoundedBoxEx( 6, 0, 0, w, h, active and F4.C.cat or F4.C.row, true, true, false, false )
			end

			tab.UpdateColours = function( self ) return self:SetTextStyleColor( F4.C.text ) end
		end
	end
end
