-- Open / close / toggle entry points DarkRP calls for the F4 key.
local F4 = DubzF4

function F4.Open()

	F4.Menu.Frame()
	
end

function F4.Close()

	if IsValid( F4.Frame ) then
		
		F4.Frame:SetVisible( false )
		
	end

end

local nextOpen = 0 -- one second between opens so the key can't spam the menu

-- DarkRP's own F4 menu, kept so the master switch (admin menu > Modules > F4 Menu) can fall back to it
F4.OriginalToggle = F4.OriginalToggle or DarkRP.toggleF4Menu   -- only the first load: a Lua refresh must not capture our own function
local darkrpToggle = F4.OriginalToggle

function DarkRP.toggleF4Menu()

	if not F4.Enabled() then

		if IsValid( F4.Frame ) and F4.Frame:IsVisible() then F4.Close() end

		if darkrpToggle then return darkrpToggle() end

		return

	end


	if !IsValid( F4.Frame ) then

		if CurTime() < nextOpen then return end
		nextOpen = CurTime() + 1

		F4.Open()

	elseif !F4.Frame:IsVisible() then

		if CurTime() < nextOpen then return end
		nextOpen = CurTime() + 1

		F4.WaitRelease = input.IsKeyDown( KEY_F4 )
		F4.Frame:SetVisible( true )

	else

		if CurTime() < nextOpen then return end
		nextOpen = CurTime() + 1

		F4.Close()
		
	end
	
end

function DarkRP.getF4MenuPanel()

	return F4.Frame
	
end
