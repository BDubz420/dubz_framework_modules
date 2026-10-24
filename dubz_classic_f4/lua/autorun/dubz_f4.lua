-- Dubz F4: the classic F4 menu lives in lua/darkrp_modules/classicf4/ (DarkRP loads it). This autorun adds its
-- settings to the Dubz Framework admin menu (!dubzconfig). The settings load here, early, so they exist before the
-- menu code and before the framework builds its pages.
DubzF4 = DubzF4 or {}

for _, name in ipairs({"sh_config.lua", "sh_framework.lua"}) do
	if not file.Exists("dubz_f4/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzF4] ", color_white, "lua/dubz_f4/" .. name .. " is missing. Upload the whole lua/dubz_f4/ folder. The F4 menu will not load.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_f4/sh_config.lua")
	AddCSLuaFile("dubz_f4/sh_framework.lua")
end

include("dubz_f4/sh_config.lua")

-- Dubz Framework: hand the framework a manifest so the F4 menu shows up in the admin config menu.
-- Works whichever autorun runs first; without the framework the F4 menu runs with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_f4",
	name = "Dubz F4",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_f4/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
