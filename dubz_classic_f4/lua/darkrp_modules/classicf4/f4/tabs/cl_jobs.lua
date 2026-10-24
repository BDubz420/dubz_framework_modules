-- Jobs tab.
local F4 = DubzF4

-- Jobs keep the player's character: the icon shows YOUR model, in the job's uniform when Cosmetics has one for it (Job Outfits)
local function keepsCharacter()
	local lp = LocalPlayer()
	return F4.Config.KeepCharacterModel ~= false and DubzCosmetics and DubzCosmetics.GetLookId and IsValid(lp) and DubzCosmetics.GetLookId(lp) ~= ""
end

local function characterModel( job )
	local lp = LocalPlayer()
	local look = DubzCosmetics.GetLookId( lp )
	local uniform = DubzCosmetics.Config and DubzCosmetics.Config.jobOutfits and DubzCosmetics.Config.jobOutfits[string.lower( job.name or "" )]

	return ( uniform and DubzCosmetics.GetClothing( uniform ) and DubzCosmetics.ModelFor( look, uniform ) )
		or DubzCosmetics.ModelFor( look, DubzCosmetics.GetClothingId( lp ) )
		or lp:GetModel()
end

function F4.Menu.Tabs.Jobs( parent )

	local frame = F4.Frame
	
	local panel = vgui.Create( "DPanel", parent )
	panel:SetSize( frame:GetWide(), frame:GetTall() - 70 )
	panel.Paint = function( self, w, h ) end

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:SetPos( 0, 0 )
	scroll:SetSize( (panel:GetWide() * 0.5) +32, panel:GetTall() )
	scroll:GetVBar():SetWide( 14 )

	local sbar = scroll:GetVBar()
	function sbar:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, F4.C.surface)
	end
	function sbar.btnGrip:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 150, 150))
	end

	local infopanel = vgui.Create( "DPanelList", panel )
	infopanel:SetPos( scroll:GetWide() + 5, 0 )
	infopanel:SetSize( ( panel:GetWide() - scroll:GetWide() ) - 10, panel:GetTall() )

	infopanel.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
	end
	
	/*
		
		Job Info Panel
		
	*/
	
	local Info = {} // thanks old darkrp
	local getWepName = fn.FOr{fn.FAnd{weapons.Get, fn.Compose{fn.Curry(fn.GetValue, 2)("PrintName"), weapons.Get}}, fn.Id}
	local getWeaponNames = fn.Curry(fn.Map, 2)(getWepName)
	local weaponString = fn.Compose{fn.Curry(fn.Flip(table.concat), 2)("\n"), fn.Curry(fn.Seq, 2)(table.sort), getWeaponNames, table.Copy}
	
	local function updateJobPanel( job )

		if job == false then
			
			infopanel:Clear()
			
			Info = {}
			
			return
		
		end
		
		Info[1] = DarkRP.getPhrase("job_name") .. job.name
		Info[2] = DarkRP.getPhrase("job_description") .. job.description
		
		local weps = weaponString( job.weapons )
		weps = weps != "" && weps or DarkRP.getPhrase( "no_extra_weapons" )
		Info[3] = DarkRP.getPhrase("job_weapons") .. weps	
		
		infopanel:Clear()
		
		if istable( Info ) && #Info > 0 then
		
			for k, v in ipairs( Info ) do
				
				local text = DarkRP.textWrap( DarkRP.deLocalise( v or "" ):gsub( "\t", "" ), "Trebuchet20", infopanel:GetWide() - 20 )	
				
				local label = vgui.Create( "DLabel" )
				label:SetText( text )
				label:SetFont( "Trebuchet20" )
				label:SetTextColor( color_white )
				label:SizeToContents()
				
				if label:IsValid() then infopanel:AddItem( label ) end
			
			end
		
		end
		
	end
	
	/*
		
		Jobs
		
	*/
	
	local categories = F4.Categories().jobs

	for i = 1, #categories do
	
		local category = categories[i]
		
		if #category.members == 0 then continue end
		
		local cat = scroll:Add( "DCollapsibleCategory" )
		cat:SetLabel( category.name )
		cat:Dock( TOP )
		cat:DockMargin( 0, 0, -14, 5 )
		
		cat:GetChildren()[1].Paint = function( self, w, h )
		
			draw.RoundedBox( 6, 0, 0, w, h, category.color )
		
		end
		
		local joblist = vgui.Create( "DPanelList" )
		joblist:SetSpacing( 0 )
		joblist:EnableHorizontal( true )
		joblist:EnableVerticalScrollbar( false )	
		cat:SetContents( joblist )
			
		joblist.Paint = function( s, w, h )
			draw.RoundedBox( 6, 0, 0, w, h, F4.C.background )
		end
		
		local jobs = RPExtraTeams

		for k, v in ipairs( jobs ) do

			if v.category != category.name then continue end
			if F4.IsHidden( "jobs", v ) then continue end
			
			local vip = v.vip or false
			
			if v.customCheck then vip = true end
			
			local size = scroll:GetWide() * F4.Config.JobIconScale

			local jobicon = vgui.Create( "SpawnIcon" )
			
			local iconmodel = v.model
			if keepsCharacter() then iconmodel = characterModel( v ) elseif istable( v.model ) then iconmodel = table.Random( v.model ) end
			jobicon:SetModel( iconmodel )
			
			jobicon:SetSize( size, size )
			
			jobicon:SetToolTip()
			
			jobicon.OnCursorEntered = function( self ) updateJobPanel( v ) end
			
			jobicon.OnCursorExited = function( self ) updateJobPanel( false ) end
			
			jobicon.PaintOver = function( s, w, h )
			
				--draw.RoundedBox( 0, 0, 0, w, h, v.color )
				surface.SetDrawColor(v.color)
				surface.DrawOutlinedRect( 0, 0, w, h, 3 )

				local numteam = team.NumPlayers( v.team )
				local maxteam = v.max == 0 and "∞" or v.max

				local slotX = numteam .."/".. maxteam

				if maxteam == "∞" then
					draw.SimpleTextOutlined("Slots: "..slotX, "DermaDefault", w * 0.5, h * 0.9, F4.C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))					
				elseif numteam >= v.max then
					draw.RoundedBox( 0, 0, 0, w, h, F4.C.surface )
					draw.SimpleTextOutlined("Full", "DermaDefault", w * 0.5, w * 0.5, F4.C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
					draw.SimpleTextOutlined("Slots: "..slotX, "DermaDefault", w * 0.5, h * 0.9, F4.C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
				else
					draw.SimpleTextOutlined("Slots: "..slotX, "DermaDefault", w * 0.5, h * 0.9, F4.C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
				end
			end
			
			local vipicon = Material( "icon16/star.png" )
			local vipiconsize = 16
			local oldpaint = jobicon.PaintOver
			jobicon.PaintOver = function( self, w, h )
				
				if vip then
				
					surface.SetMaterial( vipicon )
					
					surface.DrawTexturedRect( w - vipiconsize - 2, 2, vipiconsize, vipiconsize )
			
				end

				oldpaint( self, w, h )
			
			end
			
			jobicon.DoClick = function() // thanks again old darkrp
			
				local function doChatCommand( panel )	
				
					if v.vote then				
					
						if LocalPlayer():IsAdmin() then	
						
							local menu = DermaMenu()
							menu:AddOption( "Vote", function() RunConsoleCommand( "darkrp", "vote" .. v.command ) panel:Close() end )
							menu:AddOption( "Do not vote", function() RunConsoleCommand( "darkrp", v.command ) panel:Close() end )
							menu:Open()			
							
						else	
							
							RunConsoleCommand( "darkrp", "vote" .. v.command )								
							panel:Close()
							
						end

					else
					
						RunConsoleCommand( "darkrp", v.command )	
						panel:Close()
						
					end
					
				end

				if istable( v.model ) and #v.model > 0 and not keepsCharacter() then   -- (no model to pick when jobs keep your character)
				
					frame:Close()
					
					local modelframe = vgui.Create("DFrame")
					modelframe:SetTitle("Choose model")
					modelframe:SetVisible(true)
					modelframe:MakePopup()

					local levels = 1
					local IconsPerLevel = math.floor(ScrW()/64)

					while #v.model * (64/levels) > ScrW() do
						levels = levels + 1
					end
					modelframe:SetSize(math.Min(#v.model * 64, IconsPerLevel*64), math.Min(90+(64*(levels-1)), ScrH()))
					modelframe:Center()

					local CurLevel = 1
					for k,v in pairs( v.model ) do
						local icon = vgui.Create("SpawnIcon", modelframe)
						if (k-IconsPerLevel*(CurLevel-1)) > IconsPerLevel then
							CurLevel = CurLevel + 1
						end
						icon:SetPos((k-1-(CurLevel-1)*IconsPerLevel) * 64, 25+(64*(CurLevel-1)))
						icon:SetModel(v)
						icon:SetSize(64, 64)
						icon:SetToolTip()
						icon.DoClick = function()
							DarkRP.setPreferredJobModel( k, v )
							doChatCommand( modelframe )
						end
					end
					
				else
				
					doChatCommand( frame )
					
				end
				
			end
			
			if jobicon:IsValid() then joblist:AddItem( jobicon ) end
		
		end

	end
	
	parent:AddSheet( "Jobs", panel, "icon16/user_gray.png" )
	
end
