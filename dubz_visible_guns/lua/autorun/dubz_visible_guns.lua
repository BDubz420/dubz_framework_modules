DubzVisibleGuns = DubzVisibleGuns or {}

AddCSLuaFile("dubz_visible_guns/sh_config.lua")
include("dubz_visible_guns/sh_config.lua")

if SERVER then
    AddCSLuaFile("dubz_visible_guns/sh_framework.lua")
    AddCSLuaFile("dubz_visible_guns/cl_core.lua")
    AddCSLuaFile("dubz_visible_guns/cl_editor.lua")
    include("dubz_visible_guns/sv_core.lua")
else
    include("dubz_visible_guns/cl_core.lua")
    include("dubz_visible_guns/cl_editor.lua")
end

-- Dubz Framework: hand the framework a manifest so Visible Weapons shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework installed everything still runs with sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
    id = "dubz_visible_guns",
    name = "Dubz Visible Weapons",
    version = "1.1.0",
    api = 1,
    dependencies = { "dubz_framework" },
    files = { "dubz_visible_guns/sh_framework.lua" },
}

if DFW.Packages and DFW.Packages.Submit then
    DFW.Packages.Submit(manifest)
else
    DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
