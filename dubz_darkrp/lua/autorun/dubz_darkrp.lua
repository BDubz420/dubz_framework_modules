DubzDarkRP = DubzDarkRP or {}

local ROOT = "dubz_darkrp/"
local LOCAL_FILES = {"sh_config.lua", "sh_diagnostics.lua"}
local PACKAGE_FILES = {
    "sh_net.lua",
    "sh_settings_info.lua",
    "sh_fields.lua",
    "sh_kinds.lua",
    "sh_framework.lua",
    "sh_adapter.lua",
    "sh_engine.lua",
    "sh_jobs.lua",
    "sh_shop.lua",
    "sh_categories.lua",
    "sh_doors.lua",
    "sh_server.lua",
    "cl_sync.lua",
    "cl_tags.lua",
    "cl_pickers.lua",
    "cl_form.lua",
    "cl_weapons.lua",
    "cl_props.lua",
    "cl_defaults.lua",
    "cl_settings.lua",
    "cl_board_card.lua",
    "cl_board_column.lua",
    "cl_board_scrollbar.lua",
    "cl_board.lua",
    "cl_workflow.lua"
}
local SERVER_FILES = {
    "sv_store.lua",
    "sv_audit.lua",
    "sv_edit.lua",
    "sv_sync.lua",
    "sv_requests.lua",
    "sv_settings.lua",
    "sv_boot.lua",
    "sv_commands.lua"
}
local FILE_GROUPS = SERVER and {LOCAL_FILES, PACKAGE_FILES, SERVER_FILES} or {LOCAL_FILES, PACKAGE_FILES}

DubzDarkRP.ServerFiles = SERVER_FILES

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
    concommand.Add("dubz_darkrp_check", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end

        for _, list in ipairs(FILE_GROUPS) do
            for _, name in ipairs(list) do
                local state = file.Exists(ROOT .. name, "LUA") and "found" or "MISSING"
                local text = "[DubzDarkRP] lua/" .. ROOT .. name .. ": " .. state

                if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text .. "\n") else print(text) end
            end
        end
    end)
end

local missing = missingFiles()

if #missing > 0 then
    MsgC(Color(255, 80, 80), "[DubzDarkRP] ", color_white, "missing files in lua/" .. ROOT .. ": " .. table.concat(missing, ", ") .. ". Upload the whole addon.\n")
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
    id = "dubz_darkrp",
    name = "Dubz DarkRP Management",
    version = "0.1.0",
    api = 1,
    dependencies = {"dubz_framework"},
    files = files
}

if DFW.Packages and DFW.Packages.Submit then
    DFW.Packages.Submit(manifest)
else
    DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
