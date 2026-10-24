DubzCredits = DubzCredits or {}

if SERVER then
    -- Shared files
    AddCSLuaFile("dubz_credits/sh_config.lua")
    AddCSLuaFile("dubz_credits/sh_api.lua")
    AddCSLuaFile("dubz_credits/sh_framework.lua")

    -- Client files
    AddCSLuaFile("dubz_credits/cl_state.lua")
    AddCSLuaFile("dubz_credits/cl_notify.lua")
    AddCSLuaFile("dubz_credits/cl_api.lua")
    AddCSLuaFile("dubz_credits/cl_hud.lua")
    AddCSLuaFile("dubz_credits/cl_weekly.lua")

    -- Server includes
    include("dubz_credits/sh_config.lua")
    include("dubz_credits/sv_log.lua")
    include("dubz_credits/sv_storage_file.lua")
    include("dubz_credits/sv_storage_mysql.lua")
    include("dubz_credits/sv_boosts.lua")
    include("dubz_credits/sv_core.lua")
    include("dubz_credits/sv_salary.lua")
    include("dubz_credits/sv_net.lua")
    include("dubz_credits/sv_admin.lua")
    include("dubz_credits/sv_boot.lua")
    include("dubz_credits/sv_personal_boosts.lua")
    include("dubz_credits/sv_weekly.lua")
else
    include("dubz_credits/sh_config.lua")
    include("dubz_credits/sh_api.lua")
    include("dubz_credits/cl_state.lua")
    include("dubz_credits/cl_notify.lua")
    include("dubz_credits/cl_api.lua")
    include("dubz_credits/cl_hud.lua")
    include("dubz_credits/cl_weekly.lua")
end

-- Dubz Framework: hand the framework a manifest so Credits shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework credits run with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
    id = "dubz_credits",
    name = "Dubz Credits",
    version = "2.0.0",
    api = 1,
    dependencies = {"dubz_framework"},
    files = {"dubz_credits/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
    DFW.Packages.Submit(manifest)
else
    DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
