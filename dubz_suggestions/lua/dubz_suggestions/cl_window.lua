local config = DubzSuggestions.Config
local Client = DubzSuggestions.Client
local WINDOW_ICON = "communication/forum"
local frame

function DubzSuggestions.Open()
    if not DubzSuggestions.Enabled() then
        DFW.UI.Notify(DubzSuggestions.Phrase("ErrorDisabled"), "danger")
        return
    end

    if IsValid(frame) then frame:Remove() end

    frame = DFW.UI.CreateFrame(DubzSuggestions.Phrase("WindowTitle"), config.WindowWidth, config.WindowHeight, WINDOW_ICON, {module = "suggestions"})
    frame:SetSubtitle(DubzSuggestions.Phrase("WindowSubtitle"))

    local content = frame:GetContent()

    DubzSuggestions.Public.Build(content)
    DubzSuggestions.Form.Build(content)

    local closed = frame.OnClose

    frame.OnClose = function(...)
        Client.Close()

        if closed then return closed(...) end
    end

    Client.Request()
end

concommand.Add(config.ConsoleCommand, function()
    DubzSuggestions.Open()
end)
