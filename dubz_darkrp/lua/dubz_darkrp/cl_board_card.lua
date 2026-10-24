DubzDarkRP.Board = DubzDarkRP.Board or {}

local Board = DubzDarkRP.Board
local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local CARD_HEIGHT = 64
local DRAG_GROUP = "dubz_drp_card"

local STATUS = {
    draft = {text = "TagDraft", color = "success"},
    removed = {text = "TagRemoved", color = "danger"},
    custom = {text = "TagCustom", color = "info"},
    edited = {text = "TagEdited", color = "warning"}
}

Board.DragGroup = DRAG_GROUP

local function paintCard(card, selected, w, h)
    local theme = DFW.UI.GetTheme()
    local tag = STATUS[card.Row.status]
    local hover = DFW.Anim.Lerp(card, "hover", card:IsHovered() and 1 or 0, 14)
    local picked = DFW.Anim.Lerp(card, "picked", selected() == card.Row.id and 1 or 0, 12)
    local alpha = card.Row.status == "removed" and 0.55 or 1

    draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, DFW.Anim.Color(theme.surface, theme.raised, math.max(hover * 0.55, picked)))

    surface.SetDrawColor(card.Color or theme.accent)
    surface.DrawRect(0, 8, 3, h - 16)
    DFW.Draw.Text(card.Title, "BodyBold", 14, h / 2 - 10, DFW.UI.WithAlpha(theme.text, 255 * alpha))
    DFW.Draw.Text(card.Subtitle, "Small", 14, h / 2 + 11, theme.textMuted)

    if tag then DFW.Draw.Text(DubzDarkRP.Phrase(tag.text), "Tiny", w - 12, h / 2 - 10, theme[tag.color], TEXT_ALIGN_RIGHT) end

    local badge = card.Kind == "jobs" and DubzWorkflow and DubzWorkflow.JobBadge and DubzWorkflow.JobBadge(card.Row.id)

    if badge then DFW.Draw.Text(badge.text, "Tiny", w - 12, h / 2 + 11, badge.color or theme.textMuted, TEXT_ALIGN_RIGHT) end
end

function Board.Card(parent, kind, row, selected, onSelect)
    local card = parent:Add("DButton")
    local data = Fields.Extract(row.entry, kind)

    card:SetText("")
    card:Dock(TOP)
    card:SetTall(CARD_HEIGHT)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("XS"))
    card:Droppable(DRAG_GROUP)

    card.Row = row
    card.Kind = kind
    card.Title = data.name or row.id
    card.Subtitle = Kinds.Subtitle(kind, data)
    card.Color = istable(data.color) and Color(data.color.r, data.color.g, data.color.b, 255) or nil
    card.DoClick = function() onSelect(row) end
    card.Paint = function(self, w, h) paintCard(self, selected, w, h) end

    return card
end
