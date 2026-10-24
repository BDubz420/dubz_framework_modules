-- Shop tab (F4.Menu.Tabs.Entities): entities, ammo, weapons, shipments, food.
local F4 = DubzF4

function F4.Menu.Tabs.Entities( parent )

	local frame = F4.Frame
	
	local panel = vgui.Create( "DPanel", parent )
	panel:SetSize( frame:GetWide(), frame:GetTall() - 70 )
	panel.Paint = function( self, w, h ) end

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:SetPos( 0, 0 )
	scroll:SetSize( panel:GetWide(), panel:GetTall() )
	scroll:GetVBar():SetWide( 0 )
	
	local entities = F4.Categories().entities
	
	for i = 1, #entities do
	
		local category = entities[i]
		local members = {}

		for k, v in ipairs( category.members ) do
		
			if v.allowed && istable( v.allowed ) && !table.HasValue( v.allowed, LocalPlayer():Team() ) then continue end
			if v.customCheck then
			    if not v.customCheck(LocalPlayer()) then continue end
			    v.vip = true
			end			
			table.insert(members, v)
			
		end
		
		if #members == 0 then continue end
		
		local cat = scroll:Add( "DCollapsibleCategory" )
		cat:SetLabel( category.name )
		cat:Dock( TOP )
		cat:DockMargin( 0, 0, 0, 5 )
		
		cat:GetChildren()[1].Paint = function( self, w, h )
		
			draw.RoundedBox( 6, 0, 0, w, h, category.color )
		
		end
				
		local entlist = vgui.Create("DIconLayout")
		entlist:Dock(FILL)
		entlist:SetSpaceX(F4.Config.ShopSpacing)
		entlist:SetSpaceY(F4.Config.ShopSpacing)
		cat:SetContents(entlist)
		
		local function AddIcon( v )

			local size = math.max(scroll:GetWide() * F4.Config.ShopIconScale, F4.Config.ShopIconMin)
			local icon = vgui.Create( "SpawnIcon" )
			
			icon:SetModel( v.model )			
			icon:SetSize( size, size )			
			icon:SetToolTip( v.name .. " " .. DarkRP.formatMoney( v.price ) )

			icon.Paint = function( s, w, h )
			
				draw.RoundedBox( 0, 0, 0, w, h, v.color or F4.C.row2 )

			end

			local vipicon = Material( "icon16/star.png" )
			local vipiconsize = 16
			local oldpaint = icon.PaintOver
			icon.PaintOver = function( self, w, h )

				if v.vip then
				
					surface.SetMaterial( vipicon )
					
					surface.DrawTexturedRect( w - vipiconsize - 2, 2, vipiconsize, vipiconsize )
			
				end
			
				surface.SetDrawColor( category.color )
				
				surface.DrawOutlinedRect( 0, 0, w, h )
			
				return oldpaint( self, w, h )
			
			end

			icon.DoClick = function( self )
			
				RunConsoleCommand( "darkrp", v.cmd )
			
			end
			
			if icon:IsValid() then entlist:Add( icon ) end
			
		end

		for k, v in ipairs( members ) do

			AddIcon( v )
			
		end
		
	end
	
	local ammo = F4.Categories().ammo

	for i = 1, #ammo do
	
		local category = ammo[i]
		local members = {}
		
		for k, v in ipairs( category.members ) do
		
			if v.allowed && istable( v.allowed ) && !table.HasValue( v.allowed, LocalPlayer():Team() ) then continue end
			if v.customCheck && !v.customCheck( LocalPlayer() ) then continue end
			
			table.insert(members, v)
			
		end
		
		if #members == 0 then continue end
		
		local cat = scroll:Add( "DCollapsibleCategory" )
		cat:SetLabel( "Ammo" )
		cat:Dock( TOP )
		cat:DockMargin( 0, 0, 0, 5 )
		
		cat:GetChildren()[1].Paint = function( self, w, h )
		
			draw.RoundedBox( 6, 0, 0, w, h, category.color )
		
		end
		
		local entlist = vgui.Create("DIconLayout")
		entlist:Dock(FILL)
		entlist:SetSpaceX(F4.Config.ShopSpacing)
		entlist:SetSpaceY(F4.Config.ShopSpacing)
		cat:SetContents(entlist)
		
		local function AddIcon( v )

			local size = math.max(scroll:GetWide() * F4.Config.ShopIconScale, F4.Config.ShopIconMin)
			local icon = vgui.Create( "SpawnIcon" )
			
			icon:SetModel( v.model )			
			icon:SetSize( size, size )			
			icon:SetToolTip( v.name .. " " .. DarkRP.formatMoney( v.price ) )

			icon.Paint = function( s, w, h )
			
				draw.RoundedBox( 0, 0, 0, w, h, v.color or F4.C.row2 )

			end
			
			local oldpaint = icon.PaintOver
			icon.PaintOver = function( self, w, h )
			
				surface.SetDrawColor( category.color )
				
				surface.DrawOutlinedRect( 0, 0, w, h )
			
				return oldpaint( self, w, h )
			
			end
			
			icon.DoClick = function( self )
			
				RunConsoleCommand( "darkrp", "buyammo", v.ammoType )
			
			end
			
			if icon:IsValid() then entlist:Add( icon ) end
			
		end

		for k, v in ipairs( members ) do

			AddIcon( v )
			
		end
		
	end
		
	
	local weps = F4.Categories().weapons
	
	for i = 1, #weps do
	
		local category = weps[i]
		local members = {}
		
		for k, v in ipairs( category.members ) do
		
			if v.allowed && istable( v.allowed ) && !table.HasValue( v.allowed, LocalPlayer():Team() ) then continue end
			if v.customCheck && !v.customCheck( LocalPlayer() ) then continue end
			
			table.insert(members, v)
			
		end
		
		if #members == 0 then continue end
		
		local cat = scroll:Add( "DCollapsibleCategory" )
		cat:SetLabel( category.name )
		cat:Dock( TOP )
		cat:DockMargin( 0, 0, 0, 5 )
		
		cat:GetChildren()[1].Paint = function( self, w, h )
		
			draw.RoundedBox( 6, 0, 0, w, h, category.color )
		
		end
		
		local entlist = vgui.Create("DIconLayout")
		entlist:Dock(FILL)
		entlist:SetSpaceX(F4.Config.ShopSpacing)
		entlist:SetSpaceY(F4.Config.ShopSpacing)
		cat:SetContents(entlist)
		
		local function AddIcon( v )

			local size = math.max(scroll:GetWide() * F4.Config.ShopIconScale, F4.Config.ShopIconMin)
			local icon = vgui.Create( "SpawnIcon" )
			
			icon:SetModel( v.model )			
			icon:SetSize( size, size )			
			icon:SetToolTip( v.name .. " single " .. DarkRP.formatMoney( v.pricesep ) )

			icon.Paint = function( s, w, h )
			
				draw.RoundedBox( 0, 0, 0, w, h, v.color or F4.C.row2 )

			end
			
			local oldpaint = icon.PaintOver
			icon.PaintOver = function( self, w, h )
			
				surface.SetDrawColor( category.color )
				
				surface.DrawOutlinedRect( 0, 0, w, h )
			
				return oldpaint( self, w, h )
			
			end
			
			icon.DoClick = function( self )
			
				RunConsoleCommand( "darkrp", "buy", v.name )
			
			end
			
			if icon:IsValid() then entlist:Add( icon ) end
			
		end

		for k, v in ipairs( members ) do

			AddIcon( v )
			
		end
		
	end
	
	local shipments = F4.Categories().shipments
	
	for i = 1, #shipments do
	
		local category = shipments[i]
		local members = {}
		
		for k, v in ipairs( category.members ) do
		
			if v.allowed && istable( v.allowed ) && !table.HasValue( v.allowed, LocalPlayer():Team() ) then continue end
			if v.customCheck && !v.customCheck( LocalPlayer() ) then continue end
			
			table.insert(members, v)
		end
		
		if #members == 0 then continue end
		
		local cat = scroll:Add( "DCollapsibleCategory" )
		cat:SetLabel( category.name .. " Shipments" )
		cat:Dock( TOP )
		cat:DockMargin( 0, 0, 0, 5 )
		
		cat:GetChildren()[1].Paint = function( self, w, h )
		
			draw.RoundedBox( 6, 0, 0, w, h, category.color )
		end
		
		local entlist = vgui.Create("DIconLayout")
		entlist:Dock(FILL)
		entlist:SetSpaceX(F4.Config.ShopSpacing)
		entlist:SetSpaceY(F4.Config.ShopSpacing)
		cat:SetContents(entlist)
		
		local function AddIcon( v )

			local size = math.max(scroll:GetWide() * F4.Config.ShopIconScale, F4.Config.ShopIconMin)
			local icon = vgui.Create( "SpawnIcon" )
			
			icon:SetModel( v.model )			
			icon:SetSize( size, size )			
			icon:SetToolTip( v.name .. " shipment " .. DarkRP.formatMoney( v.price ) )

			icon.Paint = function( s, w, h )
			
				draw.RoundedBox( 0, 0, 0, w, h, v.color or F4.C.row2 )
			end
			
			local oldpaint = icon.PaintOver
			icon.PaintOver = function( self, w, h )
			
				surface.SetDrawColor( category.color )
				
				surface.DrawOutlinedRect( 0, 0, w, h )
			
				return oldpaint( self, w, h )
			end
			
			icon.DoClick = function( self )
			
				RunConsoleCommand( "darkrp", "buyshipment", v.name )
			end
			
			if icon:IsValid() then entlist:Add( icon ) end
		end

		for k, v in ipairs( members ) do

			AddIcon( v )
		end
	end

	---------------------------------------------------
	-- FOOD SHOP (WORKS ON OLD + NEW DARKRP)
	---------------------------------------------------

	local FOOD_ALLOWED_TEAMS = {
	    [TEAM_COOK] = true
	}

	local function GetFoodTable()
	    -- Newer forks (some use this)
	    if DarkRP.getFoodItems and isfunction(DarkRP.getFoodItems) then
	        local t = DarkRP.getFoodItems()
	        if istable(t) then return t end
	    end

	    -- Some forks expose it here
	    if DarkRP.getFood and isfunction(DarkRP.getFood) then
	        local t = DarkRP.getFood()
	        if istable(t) then return t end
	    end

	    -- Categories-based fallback (your earlier attempt)
	    if DarkRP.getCategories and isfunction(DarkRP.getCategories) then
	        local cats = F4.Categories()
	        if istable(cats) and istable(cats.food) then
	            -- Flatten categories.members into one list
	            local out = {}
	            for _, cat in ipairs(cats.food) do
	                for _, v in ipairs(cat.members or {}) do
	                    table.insert(out, v)
	                end
	            end
	            if #out > 0 then return out end
	        end
	    end

	    -- Classic DarkRP global table
	    if istable(FoodItems) then
	        return FoodItems
	    end

	    return nil
	end

	-- Only build for allowed jobs
	if FOOD_ALLOWED_TEAMS[LocalPlayer():Team()] then
	    local foods = GetFoodTable()

	    if istable(foods) and table.Count(foods) > 0 then
	        local cat = scroll:Add("DCollapsibleCategory")
	        cat:SetLabel("Food")
	        cat:Dock(TOP)
	        cat:DockMargin(0, 0, 0, 5)

	        cat:GetChildren()[1].Paint = function(self, w, h)
	            draw.RoundedBox(6, 0, 0, w, h, Color(120, 90, 60))
	        end

			local entlist = vgui.Create("DIconLayout")
			entlist:Dock(FILL)
			entlist:SetSpaceX(F4.Config.ShopSpacing)
			entlist:SetSpaceY(F4.Config.ShopSpacing)
			cat:SetContents(entlist)

	        -- Sort by price if it exists
	        local sorted = {}
	        for _, v in pairs(foods) do
	            table.insert(sorted, v)
	        end
	        table.sort(sorted, function(a, b)
	            return (tonumber(a.price) or 0) < (tonumber(b.price) or 0)
	        end)

	        for _, v in ipairs(sorted) do
	            if not v or not v.name then continue end

	            -- DarkRP permission checks
	            if v.allowed and istable(v.allowed) and not table.HasValue(v.allowed, LocalPlayer():Team()) then continue end
	            if v.customCheck and not v.customCheck(LocalPlayer()) then continue end

	            local size = math.max(scroll:GetWide() * F4.Config.ShopIconScale, F4.Config.ShopIconMin)
	            local icon = vgui.Create("SpawnIcon")

	            icon:SetModel(v.model or "models/props_junk/watermelon01.mdl")
	            icon:SetSize(size, size)
	            icon:SetToolTip(v.name .. " " .. DarkRP.formatMoney(tonumber(v.price) or 0))

	            icon.Paint = function(s, w, h)
	                draw.RoundedBox(0, 0, 0, w, h, Color(60, 45, 30))
	            end

	            icon.PaintOver = function(self, w, h)
	                surface.SetDrawColor(Color(160, 120, 80))
	                surface.DrawOutlinedRect(0, 0, w, h)
	            end

	            icon.DoClick = function()
	                -- This is correct for DarkRP food
	                RunConsoleCommand("darkrp", "buyfood", v.name)
	            end

	            entlist:Add(icon)
	        end
	    end
	end

	parent:AddSheet( "Shop", panel, "icon16/cart.png" )
end
