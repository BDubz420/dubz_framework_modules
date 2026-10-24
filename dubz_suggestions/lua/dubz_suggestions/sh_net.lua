local MESSAGES = {
    "sg_request", "sg_close", "sg_state", "sg_item", "sg_remove", "sg_submit", "sg_vote",
    "sg_moderate", "sg_admin", "sg_adminlist", "sg_result", "sg_ping", "sg_open", "sg_openadmin"
}

for _, name in ipairs(MESSAGES) do DFW.Net.Pool(name) end
