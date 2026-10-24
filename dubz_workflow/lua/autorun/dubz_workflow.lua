DubzWorkflow = DubzWorkflow or {}

local ROOT = "dubz_workflow/"
local LOCAL_FILES = {"sh_config.lua", "sh_diagnostics.lua"}
local PACKAGE_FILES = {
    "sh_net.lua",
    "sh_framework.lua",
    "sh_server.lua",
    "cl_net.lua",
    "cl_links.lua",
    "cl_jobs.lua",
    "cl_suggestions.lua",
    "cl_calendar.lua",
    "cl_format.lua",
    "cl_card.lua",
    "cl_board.lua",
    "cl_detail.lua",
    "cl_editor.lua",
    "cl_notice.lua",
    "cl_window.lua"
}
local SERVER_FILES = {
    "sv_store.lua",
    "sv_staff.lua",
    "sv_tasks.lua",
    "sv_sync.lua",
    "sv_notify.lua",
    "sv_logic.lua",
    "sv_jobs.lua",
    "sv_suggestions.lua",
    "sv_requests.lua",
    "sv_commands.lua"
}
local FILE_GROUPS = SERVER and {LOCAL_FILES, PACKAGE_FILES, SERVER_FILES} or {LOCAL_FILES, PACKAGE_FILES}

DubzWorkflow.ServerFiles = SERVER_FILES

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
    concommand.Add("dubz_workflow_check", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end

        for _, list in ipairs(FILE_GROUPS) do
            for _, name in ipairs(list) do
                local state = file.Exists(ROOT .. name, "LUA") and "found" or "MISSING"
                local text = "[DubzWorkflow] lua/" .. ROOT .. name .. ": " .. state

                if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text .. "\n") else print(text) end
            end
        end
    end)
end

local missing = missingFiles()

if #missing > 0 then
    MsgC(Color(255, 80, 80), "[DubzWorkflow] ", color_white, "missing files in lua/" .. ROOT .. ": " .. table.concat(missing, ", ") .. ". Upload the whole addon.\n")
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
    id = "dubz_workflow",
    name = "Dubz Workflow",
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
