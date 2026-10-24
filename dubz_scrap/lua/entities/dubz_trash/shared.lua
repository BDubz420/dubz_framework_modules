if not (DubzScrap and DubzScrap.SetupItem) then
	if SERVER then AddCSLuaFile("dubz_scrap/sh_config.lua") AddCSLuaFile("dubz_scrap/sh_scrap.lua") end
	include("dubz_scrap/sh_config.lua")
	include("dubz_scrap/sh_scrap.lua")
end

DubzScrap.SetupItem(ENT, "trash")
ENT.PrintName = "Trash"
