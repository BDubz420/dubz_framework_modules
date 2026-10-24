-- Classic F4 menu loader. DarkRP only auto-loads files that sit directly in this folder, so the menu
-- code lives in f4/ and is included here in a fixed order (sv_files.lua sends those files to clients).
-- The menu code itself is unchanged from the single-file version; it is just split by tab.
DubzF4 = DubzF4 or {}

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
	include(base .. name)
end
