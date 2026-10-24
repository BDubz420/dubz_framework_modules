DubzF4.Ui = DubzF4.Ui or {}

local Ui = DubzF4.Ui
local HEADER_HEIGHT = 40
local SEARCH_HEIGHT = 32

function Ui.Label(parent, text, style, color, align)
    local label = parent:Add("DFW.Label")

    label:SetText(text)
    label:SetStyle(style or "body")

    if color then label:SetColor(color) end
    if align then label:SetAlign(align) end

    return label
end

function Ui.Paragraph(parent, text, style, color)
    local paragraph = parent:Add("DFW.Paragraph")

    paragraph:SetText(text)
    paragraph:SetStyle(style or "muted")

    if color then paragraph:SetColor(color) end

    return paragraph
end

function Ui.Card(parent)
    return parent:Add("DFW.Card")
end

function Ui.Scroll(parent)
    return vgui.Create("DFW.ScrollPanel", parent)
end

function Ui.OnSized(panel, build)
    local base = panel.PerformLayout
    local built = false

    panel.PerformLayout = function(self, w, h)
        if base then base(self, w, h) end

        if built or w <= 0 or h <= 0 then return end

        built = true
        build(w, h)
    end
end

function Ui.Distribute(panel, gap)
    panel.PerformLayout = function(self, w, h)
        local children = self:GetChildren()
        local count = #children

        if count == 0 then return end

        local each = math.floor((w - gap * (count - 1)) / count)

        for i, child in ipairs(children) do
            child:SetPos((i - 1) * (each + gap), 0)
            child:SetSize(each, h)
        end
    end
end

function Ui.Header(parent, title, caption)
    local header = vgui.Create("Panel", parent)
    local heading = Ui.Label(header, title, "heading")

    header:Dock(TOP)
    header:SetTall(HEADER_HEIGHT)
    heading:Dock(LEFT)
    heading:SetWide(DFW.UI.TextSize(title, "Heading") + DFW.UI.Space("LG"))

    if caption then
        local note = Ui.Label(header, caption, "small")

        note:Dock(FILL)
    end

    return header
end

function Ui.Search(parent, placeholder, onChange)
    local entry = vgui.Create("DFW.TextEntry", parent)

    entry:SetPlaceholder(placeholder)
    entry:SetTall(SEARCH_HEIGHT)
    entry.OnChange = function(self) onChange(string.lower(self:GetValue())) end

    return entry
end

function Ui.Gap()
    return DFW.UI.Space("MD")
end
