-- Dubz Dumpsters (based on Ben's Dumpsters Remade): searchable dumpsters that hand out junk, cash and the odd item.
-- Settings live in lua/dubz_dumpster/sh_config.lua and appear in the Dubz Framework admin menu (!dubzconfig),
-- including editable tables for the junk props and the item drops.
-- (The original addon's usage tracker, which phoned home to the author's website, has been removed.)
DubzDumpster = DubzDumpster or {}

if SERVER then
	resource.AddFile("resource/fonts/Simpleness.ttf")
	AddCSLuaFile("dubz_dumpster/sh_config.lua")
	AddCSLuaFile("dubz_dumpster/sh_framework.lua")
end

include("dubz_dumpster/sh_config.lua")

-- Dubz Framework: hand the framework a manifest so the dumpsters show up in the admin config menu.
-- Works whichever autorun runs first; without the framework they run with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_dumpster",
	name = "Dubz Dumpsters",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_dumpster/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end

if SERVER then
	hook.Add("InitPostEntity", "DubzDumpster_CheckEntity", function()
		if not scripted_ents.Get("bens_dumpster") then
			MsgC(Color(255, 80, 80), "[DubzDumpster] ", color_white, "entity bens_dumpster is NOT registered. Check that lua/entities/bens_dumpster/ is uploaded and has no Lua errors above.\n")
		end
	end)
end
