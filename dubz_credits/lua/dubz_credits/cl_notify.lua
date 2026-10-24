DubzCredits = DubzCredits or {}

function DubzCredits.Notify(msg, notifyType, time)
    notifyType = notifyType or 0
    time = time or 5

    if DarkRP and DarkRP.notify then
        DarkRP.notify(LocalPlayer(), notifyType, time, msg)
    else
        chat.AddText(
            Color(0, 150, 255),
            "[Credits] ",
            color_white,
            msg
        )
    end
end

net.Receive("DubzCredits_Notify", function()
    local msg = net.ReadString()
    local t = net.ReadUInt(4)
    DubzCredits.Notify(msg, t, 6)
end)
