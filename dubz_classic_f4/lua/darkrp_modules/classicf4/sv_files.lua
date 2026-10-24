-- Sends the F4 menu files in f4/ to clients (keep in sync with the list in cl_init.lua).
local base = "darkrp_modules/classicf4/f4/"

local files = {
	"cl_config.lua",
	"cl_frame.lua",
	"tabs/cl_main.lua",
	"tabs/cl_jobs.lua",
	"tabs/cl_shop.lua",
	"tabs/cl_organization.lua",
	"tabs/cl_laws.lua",
	"tabs/cl_info.lua",
	"tabs/cl_help.lua",
	"tabs/cl_rules.lua",
	"tabs/cl_guidelines.lua",
	"tabs/cl_donate.lua",
	"cl_toggle.lua",
}

for _, name in ipairs(files) do
	AddCSLuaFile(base .. name)
end
