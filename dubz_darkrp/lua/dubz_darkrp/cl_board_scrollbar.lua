local Board = DubzDarkRP.Board
local BAR_HEIGHT = 12
local MIN_THUMB = 40
local TRACK_INSET = 2

local PANEL = {}

function PANEL:Init()
    self:SetTall(BAR_HEIGHT)
    self:Dock(BOTTOM)
    self:DockMargin(0, DFW.UI.Space("XS"), 0, 0)
end

function PANEL:SetScroller(scroller)
    self.Scroller = scroller
end

function PANEL:Geometry()
    local scroller = self.Scroller

    if not IsValid(scroller) then return nil end

    local total = scroller:GetCanvas():GetWide()
    local view = scroller:GetWide()

    if view <= 0 or total <= view then return nil end

    local thumb = math.max(self:GetWide() * view / total, MIN_THUMB)

    return thumb, self:GetWide() - thumb, total - view
end

function PANEL:ThumbX(travel, range)
    return ((self.Scroller.OffsetX or 0) / range) * travel
end

function PANEL:Paint(w, h)
    local thumb, travel, range = self:Geometry()

    if not thumb then return end

    local theme = DFW.UI.GetTheme()
    local x = self:ThumbX(travel, range)

    draw.RoundedBox(h / 2, 0, 0, w, h, theme.surfaceAlt)
    draw.RoundedBox(h / 2, x, TRACK_INSET / 2, thumb, h - TRACK_INSET, self.Grab and theme.accent or theme.raised)
end

function PANEL:OnMousePressed()
    local thumb, travel, range = self:Geometry()

    if not thumb then return end

    local x = self:CursorPos()
    local thumbX = self:ThumbX(travel, range)

    self.Grab = (x >= thumbX and x <= thumbX + thumb) and x - thumbX or thumb / 2
    self:MouseCapture(true)
end

function PANEL:OnMouseReleased()
    self.Grab = nil
    self:MouseCapture(false)
end

function PANEL:Think()
    if not self.Grab then return end

    if not input.IsMouseDown(MOUSE_LEFT) then
        self:OnMouseReleased()
        return
    end

    local thumb, travel, range = self:Geometry()

    if not thumb then return end

    local x = self:CursorPos()

    self.Scroller:SetScroll(math.Clamp((x - self.Grab) / travel, 0, 1) * range)
end

vgui.Register("DubzDarkRP.HScroll", PANEL, "Panel")

function Board.Scrollbar(parent)
    return vgui.Create("DubzDarkRP.HScroll", parent)
end
