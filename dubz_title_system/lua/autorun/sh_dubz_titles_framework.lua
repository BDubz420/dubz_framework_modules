-- Dubz Titles x Dubz Framework: hands the framework a manifest so Titles shows up in the admin config menu
-- (!dubzconfig). Works whichever autorun runs first; without the framework the titles use the default tables.
DubzTitles = DubzTitles or {}

if SERVER then AddCSLuaFile("dubz_titles/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
    id = "dubz_titles",
    name = "Dubz Titles",
    version = "2.0.0",
    api = 1,
    dependencies = {"dubz_framework"},
    files = {"dubz_titles/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
    DFW.Packages.Submit(manifest)
else
    DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
