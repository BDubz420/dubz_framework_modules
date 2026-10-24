-- Main tab: money, actions, and the gang leader / police / mayor sections.
local F4 = DubzF4

function F4.Menu.Tabs.Main( parent )

	local frame = F4.Frame
	
	local panel = vgui.Create( "DPanel", parent )
	panel:SetSize( frame:GetWide(), frame:GetTall() - 70 )
	panel.Paint = function( self, w, h ) end

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:SetPos( 0, 0 )
	scroll:SetSize( panel:GetWide(), panel:GetTall() )
	scroll:GetVBar():SetWide( 0 )
	
	-- Takes disabled buttons out of a list (admin menu > F4 Menu > Main Tab)
	local function prune( list, items )
		for id, elements in pairs( items ) do
			if not F4.MainShown( id ) then
				for _, element in ipairs( elements ) do
					if IsValid( element ) then list:RemoveItem( element ) element:Remove() end
				end
			end
		end
	end

	// Money Commands
	local money = vgui.Create( "DCollapsibleCategory" )
	money:SetLabel( "Money" )
	money:Dock( TOP )
	money:DockMargin( 0, 5, 0, 5 )
	money.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, Color( 0, 150, 0 ) ) end
	
	local moneypanel = vgui.Create( "DPanelList" )
	moneypanel:SetSpacing( 0 )
	moneypanel:EnableHorizontal( false )
	moneypanel:EnableVerticalScrollbar( true )	

	local give = moneypanel:Add( "DButton" )
	give:SetText( DarkRP.getPhrase( "give_money" ) )
	give.DoClick = function() Derma_StringRequest( "Amount of money", "How much money do you want to give?", "", function( a ) RunConsoleCommand( "darkrp", "give", a ) end ) end
	give:Dock( TOP )
	
	local drop = moneypanel:Add( "DButton" )
	drop:SetText( DarkRP.getPhrase( "drop_money" ) )
	drop.DoClick = function() Derma_StringRequest( "Amount of money", "How much money do you want to drop?", "", function( a ) RunConsoleCommand( "darkrp", "dropmoney", a ) end ) end
	drop:Dock( TOP )
	
	local check = moneypanel:Add( "DButton" )
	check:SetText( "Write a check" )
	check.DoClick = function() 
		Derma_StringRequest( "Recipient", "Who are you writing the check out to?", "", 
		function( value ) 
			Derma_StringRequest( "Amount of money", "How much money do you want to write the check for?", "", 
			function( a ) 
				RunConsoleCommand( "darkrp", "check", value, a ) 
			end ) 			
		end ) 
	end
	check:Dock( TOP )
	
	prune( moneypanel, { money_give = { give }, money_drop = { drop }, money_check = { check } } )

	money:SetContents( moneypanel )
	
	// Other Commands
	local commands = vgui.Create( "DCollapsibleCategory" )
	commands:SetLabel( "Actions" )
	commands:Dock( TOP )
	commands:DockMargin( 0, 5, 0, 5 )
	commands.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, F4.C.cat ) end
	
	local cmdpanel = vgui.Create( "DPanelList" )
	cmdpanel:SetSpacing( 0 )
	cmdpanel:EnableHorizontal( false )
	cmdpanel:EnableVerticalScrollbar( true )	
	
	local rpnamelabel = cmdpanel:Add( "DLabel" )
	rpnamelabel:SetText( DarkRP.getPhrase( "change_name" ) )
	rpnamelabel.paint = function( self, w, h )
		draw.RoundedBox( 1, 0, 0, w, h, F4.C.dark2 )
	end	
	rpnamelabel:Dock( TOP )
	
	local rpname = cmdpanel:Add( "DTextEntry" )
	rpname:SetText( LocalPlayer():Nick() )
	rpname.OnEnter = function( self ) RunConsoleCommand( "darkrp", "rpname", tostring( self:GetValue() ) ) end
	rpname:Dock( TOP )

	local joblabel = cmdpanel:Add( "DLabel" )
	joblabel:SetText( DarkRP.getPhrase( "set_custom_job" ) )
	joblabel.paint = function( self, w, h )
		draw.RoundedBox( 1, 0, 0, w, h, F4.C.dark2 )
	end	
	joblabel:Dock( TOP )
	
	local customjob = cmdpanel:Add( "DTextEntry" )
	customjob:SetText( LocalPlayer():getDarkRPVar( "job" ) or "" )
	customjob.OnEnter = function( self ) RunConsoleCommand( "darkrp", "job", tostring( self:GetValue() ) ) end
	customjob:Dock( TOP )
	
	local dropwep = cmdpanel:Add( "DButton" )
	dropwep:SetText( DarkRP.getPhrase( "drop_weapon" ) )
	dropwep.DoClick = function() RunConsoleCommand( "darkrp", "drop" ) end
	dropwep:Dock( TOP )
	
	local unowndoors = cmdpanel:Add( "DButton" )
	unowndoors:SetText( "Sell all of your doors" )
	unowndoors.DoClick = function() RunConsoleCommand( "darkrp", "unownalldoors" ) end
	unowndoors:Dock( TOP )
	
	local sleep = cmdpanel:Add( "DButton" )
	sleep:SetText( "Go to sleep/wake up" )
	sleep.DoClick = function() RunConsoleCommand( "darkrp", "sleep" ) end
	sleep:Dock( TOP )
	
	local write = cmdpanel:Add("DTextEntry")
	write:SetText("Write a letter")
	write:Dock(TOP)

	write.OnGetFocus = function(entry)
	    if entry:GetValue() == "Write a letter" then
	        entry:SetText("")
	    end
	end

	write.OnEnter = function(entry)
	    local txt = string.Trim(entry:GetValue())
	    if txt == "" then return end

	    RunConsoleCommand("darkrp", "write", txt)
	    entry:SetText("")
	end
	
	prune( cmdpanel, {
		act_name = { rpnamelabel, rpname }, act_job = { joblabel, customjob }, act_dropweapon = { dropwep },
		act_unowndoors = { unowndoors }, act_sleep = { sleep }, act_letter = { write },
	} )

	commands:SetContents( cmdpanel )
	
	// Gang Commands
	local function gangCommands()
	
		local gang = vgui.Create( "DCollapsibleCategory" )
		gang:SetLabel( "Gang leader options" )
		gang:Dock( TOP )
		gang:DockMargin( 0, 5, 0, 5 )
		gang.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, team.GetColor( LocalPlayer():Team() ) ) end
		
		local gangpanel = vgui.Create( "DPanelList" )
		gangpanel:SetSpacing( 0 )
		gangpanel:EnableHorizontal( false )
		gangpanel:EnableVerticalScrollbar( true )		

		local agendalabel = gangpanel:Add( "DLabel" )
		agendalabel:SetText( DarkRP.getPhrase( "set_agenda" ) )
		agendalabel.paint = function( self, w, h )
			draw.RoundedBox( 1, 0, 0, w, h, F4.C.dark2 )
		end	
		agendalabel:Dock( TOP )
		
		local agenda = gangpanel:Add( "DTextEntry" )
		agenda:SetText( LocalPlayer():getDarkRPVar( "agenda" ) or "" )
		agenda.OnEnter = function( self ) RunConsoleCommand( "darkrp", "agenda", tostring( self:GetValue() ) ) end
		agenda:Dock( TOP )		
		
		gang:SetContents( gangpanel )
		
		return gang
		
	end
	
	// CP Commands
	local function cpCommands()
		
		local cp = vgui.Create( "DCollapsibleCategory" )
		cp:SetLabel( "Police options" )
		cp:Dock( TOP )
		cp:DockMargin( 0, 5, 0, 5 )
		cp.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, team.GetColor( LocalPlayer():Team() ) ) end
		
		local cppanel = vgui.Create( "DPanelList" )
		cppanel:SetSpacing( 0 )
		cppanel:EnableHorizontal( false )
		cppanel:EnableVerticalScrollbar( true )	
		
		local search = cppanel:Add("DButton")
		search:SetText( DarkRP.getPhrase("request_warrant") )
		search.DoClick = function()			
			local menu = DermaMenu()
			for k, v in next, player.GetAll() do			
				if !v:getDarkRPVar( "warrant" ) and v != LocalPlayer() then				
					menu:AddOption( v:Nick(), function()
						Derma_StringRequest( "Warrant", "Why do you want to search warrant " .. v:Nick() .. "?", nil,
							function( a )
								RunConsoleCommand( "darkrp", "warrant", v:Nick(), a )
							end,
						function() end )
					end )
				end
			end
			menu:Open()
		end
		search:Dock( TOP )
		
		local wanted = cppanel:Add("DButton")
		wanted:SetText( DarkRP.getPhrase( "searchwarrantbutton" ) )
		wanted.DoClick = function()			
			local menu = DermaMenu()
			for k, v in next, player.GetAll() do			
				if !v:getDarkRPVar( "wanted" ) and v != LocalPlayer() then				
					menu:AddOption( v:Nick(), function()
						Derma_StringRequest( "Wanted", "Why do you want to make " .. v:Nick() .. " wanted?", nil,
							function( a )
								RunConsoleCommand( "darkrp", "wanted", v:Nick(), a )
							end,
						function() end )
					end )
				end
			end
			menu:Open()
		end
		wanted:Dock( TOP )
		
		local unwanted = cppanel:Add("DButton")
		unwanted:SetText( DarkRP.getPhrase( "unwarrantbutton" ) )
		unwanted.DoClick = function()			
			local menu = DermaMenu()
			for k, v in next, player.GetAll() do			
				if v:getDarkRPVar( "wanted" ) and v != LocalPlayer() then				
					menu:AddOption( v:Nick(), function() RunConsoleCommand( "darkrp", "unwanted", v:Nick() ) end )
				end
			end
			menu:Open()
		end
		unwanted:Dock( TOP )
		
		local givelicense = cppanel:Add( "DButton" )
		givelicense:SetText( DarkRP.getPhrase( "give_license_lookingat" ) )
		givelicense.DoClick = function() RunConsoleCommand( "darkrp", "givelicense" ) end
		givelicense:Dock( TOP )
		
		prune( cppanel, { cp_warrant = { search }, cp_wanted = { wanted }, cp_unwanted = { unwanted }, cp_license = { givelicense } } )

		cp:SetContents( cppanel )
		
		return cp
	
	end
	
	local function mayorOptions()
		
		local mayor = vgui.Create( "DCollapsibleCategory" )
		mayor:SetLabel( "Mayor options" )
		mayor:Dock( TOP )
		mayor:DockMargin( 0, 5, 0, 5 )
		mayor.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, team.GetColor( LocalPlayer():Team() ) ) end
		
		local mayorpanel = vgui.Create( "DPanelList" )
		mayorpanel:SetSpacing( 0 )
		mayorpanel:EnableHorizontal( false )
		mayorpanel:EnableVerticalScrollbar( true )	
	
		local lockdown = mayorpanel:Add( "DButton" )
		lockdown:SetText( DarkRP.getPhrase( "initiate_lockdown" ) )
		lockdown.DoClick = function() RunConsoleCommand( "darkrp", "lockdown" ) end
		lockdown:Dock( TOP )	
	
		local unlockdown = mayorpanel:Add( "DButton" )
		unlockdown:SetText( DarkRP.getPhrase( "stop_lockdown" ) )
		unlockdown.DoClick = function() RunConsoleCommand( "darkrp", "unlockdown" ) end
		unlockdown:Dock( TOP )		
	
		local lottery = mayorpanel:Add( "DButton" )
		lottery:SetText( DarkRP.getPhrase( "start_lottery" ) )
		lottery.DoClick = function() Derma_StringRequest( "Lottery", "Enter lottery joining price", nil, function( a ) RunConsoleCommand( "darkrp", "lottery", a ) end ) end
		lottery:Dock( TOP )	
		
		local placelaws = mayorpanel:Add( "DButton" )
		placelaws:SetText( "Place a screen containing the laws" )
		placelaws.DoClick = function() RunConsoleCommand( "darkrp", "placelaws" ) end
		placelaws:Dock( TOP )
		
		prune( mayorpanel, { mayor_lockdown = { lockdown }, mayor_unlockdown = { unlockdown }, mayor_lottery = { lottery }, mayor_laws = { placelaws } } )

		mayor:SetContents( mayorpanel )
		
		return mayor
	
	end

	-- Sections in the order of the "Main Tab" table (anything not listed goes last), skipping the ones switched off
	local jobname = LocalPlayer():getDarkRPVar("job") or ""

	local builders = {
		sec_money = function() return money end,
		sec_actions = function() return commands end,
		sec_gang = function()
			if istable(F4.Config.GangLeaders) and table.HasValue(F4.Config.GangLeaders, jobname) then return gangCommands() end
		end,
		sec_police = function()
			if LocalPlayer().isCP and LocalPlayer():isCP() then return cpCommands() end
		end,
		sec_mayor = function()
			if jobname == (F4.Config.Mayor or "") or (LocalPlayer().isMayor and LocalPlayer():isMayor()) then return mayorOptions() end
		end,
	}

	local order, listed = {}, {}
	for _, row in ipairs( F4.MainRows or {} ) do
		if builders[row.item] and not listed[row.item] then order[#order + 1] = row.item listed[row.item] = true end
	end
	for _, id in ipairs( { "sec_money", "sec_actions", "sec_gang", "sec_police", "sec_mayor" } ) do
		if not listed[id] then order[#order + 1] = id end
	end

	for _, id in ipairs( order ) do
		if F4.MainShown( id ) then
			local section = builders[id]()
			if IsValid( section ) then scroll:AddItem( section ) end
		end
	end

	parent:AddSheet( "Main", panel, "icon16/house.png" )
end
