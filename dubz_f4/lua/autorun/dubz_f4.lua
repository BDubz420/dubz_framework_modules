DubzF4 = DubzF4 or {}

local ROOT = "dubz_f4/"
local LOCAL_FILES = {"sh_config.lua", "sh_diagnostics.lua"}
local PACKAGE_FILES = {
    "sh_theme.lua",
    "sh_framework.lua",
    "sh_net.lua",
    "sh_server.lua",
    "cl_adapter.lua",
    "cl_registry.lua",
    "cl_widgets.lua",
    "cl_sidebar.lua",
    "cl_window.lua",
    "cl_toggle.lua",
    "cl_home_stats.lua",
    "cl_home_panels.lua",
    "cl_tab_home.lua",
    "cl_jobs_state.lua",
    "cl_jobs_list.lua",
    "cl_jobs_detail.lua",
    "cl_tab_jobs.lua",
    "cl_shop_card.lua",
    "cl_shop_sources.lua",
    "cl_tab_shop.lua",
    "cl_tab_commands.lua",
    "cl_tab_rules.lua"
}
local SERVER_FILES = {"sv_models.lua"}
local FILE_GROUPS = SERVER and {LOCAL_FILES, PACKAGE_FILES, SERVER_FILES} or {LOCAL_FILES, PACKAGE_FILES}

DubzF4.ServerFiles = SERVER_FILES

local function missingFiles()
    local missing = {}

    for _, list in ipairs(FILE_GROUPS) do
        for _, name in ipairs(list) do
            if not file.Exists(ROOT .. name, "LUA") then missing[#missing + 1] = name end
        end
    end

    return missing
end

if SERVER then
    concommand.Add("dubz_f4_check", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end

        for _, list in ipairs(FILE_GROUPS) do
            for _, name in ipairs(list) do
                local state = file.Exists(ROOT .. name, "LUA") and "found" or "MISSING"
                local text = "[DubzF4] lua/" .. ROOT .. name .. ": " .. state

                if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text .. "\n") else print(text) end
            end
        end
    end)
end

local missing = missingFiles()

if #missing > 0 then
    MsgC(Color(255, 80, 80), "[DubzF4] ", color_white, "missing files in lua/" .. ROOT .. ": " .. table.concat(missing, ", ") .. ". Upload the whole addon.\n")
    return
end

if SERVER then
    for _, name in ipairs(LOCAL_FILES) do AddCSLuaFile(ROOT .. name) end
end

for _, name in ipairs(LOCAL_FILES) do include(ROOT .. name) end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local files = {}

for _, name in ipairs(PACKAGE_FILES) do files[#files + 1] = ROOT .. name end

local manifest = {
    id = "dubz_f4",
    name = "Dubz F4 Menu",
    version = "1.0.0",
    api = 1,
    dependencies = {"dubz_framework"},
    files = files
}

if DFW.Packages and DFW.Packages.Submit then
    DFW.Packages.Submit(manifest)
else
    DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
