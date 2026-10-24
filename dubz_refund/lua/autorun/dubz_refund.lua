-- Dubz Refund: when the server restarts or crashes, players don't lose what they bought. The next time their
-- character joins, a menu offers their lost entities back: small ones respawn next to them (owned by them again),
-- big ones (stoves, TVs ...) give cash back instead, so nobody drops a pile of props at the spawn. Settings and the
-- rules for which entities respawn live in the Dubz Framework admin menu (!dubzconfig > Refund).
-- Do not install the old "Simple Refund System" (darkrp_refund_sys) next to this.
DubzRefund = DubzRefund or {}

local files = {"sh_config.lua", "sh_framework.lua", "sv_refund.lua", "cl_refund.lua"}

for _, name in ipairs(files) do
	-- the server file is never sent to clients, so only the server checks for it
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_refund/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzRefund] ", color_white, "lua/dubz_refund/" .. name .. " is missing. Upload the whole lua/dubz_refund/ folder (not just the autorun). Not loaded.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_refund/sh_config.lua")
	AddCSLuaFile("dubz_refund/sh_framework.lua")
	AddCSLuaFile("dubz_refund/cl_refund.lua")
end

include("dubz_refund/sh_config.lua")

if SERVER then
	local ok, err = pcall(include, "dubz_refund/sv_refund.lua")
	if not ok then ErrorNoHalt("[DubzRefund] sv_refund.lua failed to load: " .. tostring(err) .. "\n") end
else
	include("dubz_refund/cl_refund.lua")
end

-- Dubz Framework: hand the framework a manifest so Refund shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_refund",
	name = "Dubz Refund",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_refund/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
