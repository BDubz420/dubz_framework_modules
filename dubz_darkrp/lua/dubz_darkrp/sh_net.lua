local MESSAGES = {"drp_sync", "drp_job", "drp_edit", "drp_result", "drp_open"}

for _, name in ipairs(MESSAGES) do DFW.Net.Pool(name) end
