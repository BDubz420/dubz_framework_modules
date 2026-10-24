local NOTICE_SOUND = "buttons/button15.wav"

hook.Add("DubzWorkflowNotice", "DubzWorkflow_Notice", function(payload)
    if not isstring(payload.text) then return end

    surface.PlaySound(NOTICE_SOUND)

    if payload.kind == "popup" then
        DFW.UI.Confirm(DubzWorkflow.Phrase("NoticeTitle"), payload.text, function() DubzWorkflow.Open() end, {
            confirmLabel = DubzWorkflow.Phrase("NoticeOpen")
        })
    else
        DFW.UI.Notify(payload.text, "info")
    end
end)
