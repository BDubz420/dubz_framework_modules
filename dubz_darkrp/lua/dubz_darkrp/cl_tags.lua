local CHIP_HEIGHT = 26
local GAP = 6
local PAD = 8
local MIN_ENTRY = 140
local CLOSE_ZONE = 22
local SPLIT = "[%s,]"
local TOKEN = "[^%s,]+"

local PANEL = {}

function PANEL:Init()
    self.Items = {}
    self.Chips = {}
    self.Entry = vgui.Create("DTextEntry", self)

    self.Entry:SetFont(DFW.UI.Font("Body"))
    self.Entry.OnChange = function(entry) self:Consume(entry) end
    self.Entry.Paint = function(entry)
        local theme = DFW.UI.GetTheme()

        entry:DrawTextEntryText(theme.text, theme.accent, theme.text)

        if entry:GetValue() == "" and #self.Items == 0 then
            DFW.Draw.Text(self.Placeholder or "", "Body", 2, entry:GetTall() / 2, theme.textDim)
        end
    end

    local base = self.Entry.OnKeyCodeTyped

    self.Entry.OnKeyCodeTyped = function(entry, code)
        if code == KEY_BACKSPACE and entry:GetValue() == "" and #self.Items > 0 then
            self:RemoveItem(self.Items[#self.Items])
            return
        end

        if code == KEY_ENTER then
            self:Commit()
            return
        end

        if base then return base(entry, code) end
    end
end

function PANEL:SetPlaceholder(text)
    self.Placeholder = text
end

function PANEL:Changed()
    if self.OnItemsChanged then self.OnItemsChanged(self:GetItems()) end
end

function PANEL:BuildChip(item)
    local chip = vgui.Create("DButton", self)
    local textWidth = DFW.UI.TextSize(item, "Small")

    chip:SetText("")
    chip:SetSize(textWidth + 14 + CLOSE_ZONE, CHIP_HEIGHT)
    chip.Paint = function(button, w, h)
        local theme = DFW.UI.GetTheme()
        local overClose = button:IsHovered() and (button:CursorPos()) > w - CLOSE_ZONE

        draw.RoundedBox(h / 2, 0, 0, w, h, theme.raised)
        DFW.Draw.Text(item, "Small", 10, h / 2, theme.text)
        DFW.Draw.Text("x", "Body", w - CLOSE_ZONE / 2, h / 2 - 1, overClose and theme.danger or theme.textDim, TEXT_ALIGN_CENTER)
    end
    chip.DoClick = function(button)
        if (button:CursorPos()) > button:GetWide() - CLOSE_ZONE then self:RemoveItem(item) end
    end

    self.Chips[item] = chip
end

function PANEL:AddItem(item)
    if item == "" or self.Chips[item] then return end

    self.Items[#self.Items + 1] = item
    self:BuildChip(item)
    self:InvalidateLayout()
end

function PANEL:RemoveItem(item)
    for index, value in ipairs(self.Items) do
        if value == item then
            table.remove(self.Items, index)
            break
        end
    end

    if IsValid(self.Chips[item]) then self.Chips[item]:Remove() end

    self.Chips[item] = nil
    self:InvalidateLayout()
    self:Changed()
end

function PANEL:ResetEntry(text)
    local entry = self.Entry

    entry:SetText(text)
    entry:SetCaretPos(#text)

    timer.Simple(0, function()
        if not IsValid(entry) then return end

        entry:SetText(text)
        entry:SetCaretPos(#text)
    end)
end

function PANEL:Consume(entry)
    local text = entry:GetValue()

    if not string.find(text, SPLIT) then return end

    local tokens = {}
    local complete = string.find(text, SPLIT .. "$") ~= nil

    for token in string.gmatch(text, TOKEN) do tokens[#tokens + 1] = token end

    local remaining = complete and "" or (table.remove(tokens) or "")

    for _, token in ipairs(tokens) do self:AddItem(token) end

    self:ResetEntry(remaining)
    self:Changed()
end

function PANEL:Commit()
    local pending = string.Trim(self.Entry:GetValue())

    self:ResetEntry("")
    self:AddItem(pending)
    self:Changed()
end

function PANEL:SetItems(list)
    for _, chip in pairs(self.Chips) do chip:Remove() end

    self.Items, self.Chips = {}, {}

    for _, item in ipairs(list or {}) do self:AddItem(item) end

    self:ResetEntry("")
end

function PANEL:GetItems()
    local items = table.Copy(self.Items)
    local pending = string.Trim(self.Entry:GetValue())

    if pending ~= "" and not self.Chips[pending] then items[#items + 1] = pending end

    return items
end

function PANEL:PerformLayout(w)
    local x, y = PAD, PAD

    for _, item in ipairs(self.Items) do
        local chip = self.Chips[item]

        if x + chip:GetWide() > w - PAD and x > PAD then
            x = PAD
            y = y + CHIP_HEIGHT + GAP
        end

        chip:SetPos(x, y)
        x = x + chip:GetWide() + GAP
    end

    if w - x - PAD < MIN_ENTRY and x > PAD then
        x = PAD
        y = y + CHIP_HEIGHT + GAP
    end

    self.Entry:SetPos(x, y)
    self.Entry:SetSize(math.max(w - x - PAD, MIN_ENTRY), CHIP_HEIGHT)

    local wanted = y + CHIP_HEIGHT + PAD

    if self:GetTall() ~= wanted then
        self:SetTall(wanted)

        if self.OnHeightChanged then self.OnHeightChanged(wanted) end

        self:InvalidateParent()
    end
end

function PANEL:OnMousePressed()
    self.Entry:RequestFocus()
end

function PANEL:Paint(w, h)
    local theme = DFW.UI.GetTheme()

    DFW.Draw.Card(0, 0, w, h, {radius = "SM", color = theme.surfaceAlt, border = theme.borderSoft})
end

vgui.Register("DubzDarkRP.Tags", PANEL, "Panel")
