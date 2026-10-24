local Board = DubzDarkRP.Board
local HEADER_HEIGHT = 38

local function makeReceiver(panel, onDrop)
    panel:Receiver(Board.DragGroup, function(_, panels, dropped)
        if dropped and panels[1] and panels[1].Row then onDrop(panels[1].Row) end
    end)
end

function Board.Column(kind, name, rows, handlers)
    local column = vgui.Create("DFW.Card")
    local config = DubzDarkRP.Config
    local pad = DFW.UI.Space("SM")
    local header = vgui.Create("Panel", column)
    local count = vgui.Create("DFW.Badge", header)
    local title = vgui.Create("DFW.Label", header)
    local scroll = vgui.Create("DFW.ScrollPanel", column)

    column:SetWide(config.ColumnWidth)
    column:DockPadding(pad, pad, pad, pad)
    header:Dock(TOP)
    header:SetTall(HEADER_HEIGHT)

    title:SetText(name)
    title:SetStyle("bodybold")
    title:Dock(FILL)
    count:SetText(tostring(#rows))
    count:SetKind("muted")
    count:SizeToContents()
    count:Dock(RIGHT)
    count:SetWide(count:GetWide())
    count:DockMargin(0, 9, 0, 9)

    scroll:Dock(FILL)

    if #rows == 0 then
        local empty = vgui.Create("DFW.Label", scroll)

        empty:SetText(DubzDarkRP.Phrase("EmptyColumn"))
        empty:SetStyle("small")
        empty:SetAlign(TEXT_ALIGN_CENTER)
        empty:Dock(TOP)
        empty:SetTall(40)
    end

    for _, row in ipairs(rows) do Board.Card(scroll, kind, row, handlers.Selected, handlers.Select) end

    local function onDrop(row) handlers.Move(row, name) end

    makeReceiver(column, onDrop)
    makeReceiver(scroll, onDrop)
    makeReceiver(scroll:GetCanvas(), onDrop)

    return column
end
