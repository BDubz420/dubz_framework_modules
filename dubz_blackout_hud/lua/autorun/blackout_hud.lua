-- Blackout HUD loader. Modules live in lua/blackout_hud/ and load in the order below.
-- Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
BHUD = BHUD or {}

local modules = {
	"sv_boot.lua",
	"sh_config.lua",
	"sh_state.lua",
	"sh_playtime.lua",
	"sv_playtime.lua",
	"sv_events.lua",
	"cl_config.lua",
	"cl_util.lua",
	"cl_layout.lua",
	"cl_bars.lua",
	"cl_topbar.lua",
	"cl_agenda.lua",
	"cl_prompts.lua",
	"cl_laws.lua",
	"cl_ammo.lua",
	"cl_popup.lua",
	"cl_death.lua",
	"cl_overhead.lua",
	"cl_doors.lua",
	"cl_cinematic.lua",
	"cl_hud.lua",
}

-- Stop with one clear message if the module folder wasn't uploaded, instead of dozens of errors.
local missing = {}
for _, name in ipairs(modules) do
	-- The client never receives sv_ files, so only check the files this realm actually loads.
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("blackout_hud/" .. name, "LUA") then missing[#missing + 1] = name end
end

if #missing > 0 then
	MsgC(Color(255, 80, 80), "[BlackoutHUD] ", color_white,
		#missing .. " of " .. #modules .. " files are missing from lua/blackout_hud/ (first: " .. missing[1] ..
		"). Upload the whole lua/blackout_hud folder and restart. The HUD was not loaded.\n")
	return
end

-- Send every client file first, so one broken server file can't stop clients from getting the HUD.
if SERVER then
	for _, name in ipairs(modules) do
		if string.sub(name, 1, 2) ~= "sv" then AddCSLuaFile("blackout_hud/" .. name) end
	end
end

for _, name in ipairs(modules) do
	local path = "blackout_hud/" .. name
	local realm = string.sub(name, 1, 2)

	if realm == "sh" or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT) then
		-- A broken module reports its error but doesn't stop the others from loading.
		local ok, err = pcall(include, path)
		if not ok then ErrorNoHalt("[BlackoutHUD] " .. path .. " failed to load: " .. tostring(err) .. "\n") end
		if not ok and realm == "sh" then return end
	end
end

-- Dubz Framework: hand the framework a manifest so the HUD shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework the HUD runs with the sh_config.lua values.
if SERVER then AddCSLuaFile("blackout_hud/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "blackout_hud",
	name = "Blackout HUD",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"blackout_hud/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
