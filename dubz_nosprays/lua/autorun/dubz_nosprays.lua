-- Dubz No Sprays: players can't spray their image (the T key / impulse 201) on this server. Returning true from PlayerSpray stops the spray.
-- On or off in the Dubz Framework admin menu (!dubzconfig > No Sprays); on by default.
DubzNoSprays = DubzNoSprays or {}
DubzNoSprays.Config = DubzNoSprays.Config or {blockSprays = true}

function DubzNoSprays.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("no_sprays")
end

if SERVER then
	AddCSLuaFile("dubz_nosprays/sh_framework.lua")

	hook.Add("PlayerSpray", "DubzNoSprays_Block", function(ply)
		if DubzNoSprays.Enabled() and DubzNoSprays.Config.blockSprays ~= false then return true end
	end)
end

-- Dubz Framework: hand the framework a manifest so No Sprays shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_nosprays",
	name = "Dubz No Sprays",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_nosprays/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
