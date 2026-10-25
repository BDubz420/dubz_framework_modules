local MESSAGES = {"drp_sync", "drp_job", "drp_edit", "drp_result", "drp_open", "drp_settings", "drp_setting", "drp_settingsync"}

for _, name in ipairs(MESSAGES) do DFW.Net.Pool(name) end
