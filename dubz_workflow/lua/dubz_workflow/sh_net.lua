local MESSAGES = {
    "wf_request", "wf_close", "wf_state", "wf_task", "wf_remove", "wf_save", "wf_action",
    "wf_presence", "wf_result", "wf_notice", "wf_open", "wf_jobreq", "wf_jobs", "wf_jobset", "wf_jobtask",
    "wf_sugreq", "wf_sugs", "wf_sugact", "wf_sugtask"
}

for _, name in ipairs(MESSAGES) do DFW.Net.Pool(name) end
