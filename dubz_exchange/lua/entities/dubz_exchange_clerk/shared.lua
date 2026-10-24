-- Exchange Clerk: talk to it (E) to open its window. Spawn it from the entities tab (Dubz Exchange) and keep it with a perma-props tool.
-- (if the entity loads before the addon's autorun has run, load the settings itself)
if not (DubzExchange and DubzExchange.Config) then
	DubzExchange = DubzExchange or {}
	if SERVER then AddCSLuaFile("dubz_exchange/sh_config.lua") end
	include("dubz_exchange/sh_config.lua")
end

ENT.Type = "ai"
ENT.Base = "base_ai"

ENT.PrintName = "Exchange Clerk"
ENT.Author = "BDubz420"
ENT.Category = "Dubz Exchange"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true
