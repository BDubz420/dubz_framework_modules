local Ui = DubzF4.Ui
local NUMBER_WIDTH = 44

local function addRule(scroll, rule, index)
    local card = Ui.Card(scroll)
    local number = Ui.Label(card, string.format("%02d", index), "heading", DFW.UI.GetTheme().accent, TEXT_ALIGN_CENTER)
    local text = Ui.Paragraph(card, rule.text, "body", DFW.UI.GetTheme().text)
    local pad = DFW.UI.Space("MD")

    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))
    card:DockPadding(pad, pad, pad, pad)
    number:Dock(LEFT)
    number:SetWide(NUMBER_WIDTH)
    text:Dock(FILL)

    card.PerformLayout = function(self, w)
        local wanted = text:GetTall() + pad * 2

        if self:GetTall() ~= wanted then self:SetTall(math.max(wanted, NUMBER_WIDTH)) end
    end
    card:SetTall(NUMBER_WIDTH + pad)
end

local function build(page)
    Ui.Header(page, DubzF4.Phrase("Rules"), DubzF4.Phrase("RulesHint"))

    local scroll = Ui.Scroll(page)

    scroll:Dock(FILL)

    for index, rule in ipairs(DubzF4.Rows("rules")) do addRule(scroll, rule, index) end
end

DubzF4.Tabs:Register("rules", {name = "TabRules", icon = "darkrp/agenda", order = 80, build = build})
