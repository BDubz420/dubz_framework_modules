if not (DubzMining and DubzMining.SetupItem) then
	if SERVER then AddCSLuaFile("dubz_mining/sh_config.lua") AddCSLuaFile("dubz_mining/sh_mining.lua") end
	include("dubz_mining/sh_config.lua")
	include("dubz_mining/sh_mining.lua")
end

DubzMining.SetupItem(ENT, "ingot", "ingotModel")
ENT.PrintName = "Ingot"
