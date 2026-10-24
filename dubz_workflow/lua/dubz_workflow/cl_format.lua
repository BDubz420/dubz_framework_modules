DubzWorkflow.Format = DubzWorkflow.Format or {}

local Format = DubzWorkflow.Format
local LINE_HEIGHT = 20
local HEADING_HEIGHT = 28
local BLANK_HEIGHT = 10
local BULLET_INDENT = 18
local STEP_INDENT = 22

local function classify(line)
    local heading = string.match(line, "^#+%s*(.+)$")

    if heading then return {text = heading, font = "BodyBold", height = HEADING_HEIGHT, indent = 0} end

    local bullet = string.match(line, "^[-*]%s+(.+)$")

    if bullet then return {text = bullet, marker = "•", font = "Body", height = LINE_HEIGHT, indent = BULLET_INDENT} end

    local number, step = string.match(line, "^(%d+)[.)]%s+(.+)$")

    if number then return {text = step, marker = number .. ".", font = "Body", height = LINE_HEIGHT, indent = STEP_INDENT} end

    return {text = line, font = "Body", height = LINE_HEIGHT, indent = 0}
end

function Format.Prepare(text, width)
    local items, total = {}, 0

    for _, line in ipairs(string.Explode("\n", tostring(text or ""))) do
        line = string.Trim(line)

        if line == "" then
            items[#items + 1] = {blank = true, height = BLANK_HEIGHT}
            total = total + BLANK_HEIGHT
        else
            local entry = classify(line)

            for index, wrapped in ipairs(DFW.UI.WrapText(entry.text, entry.font, width - entry.indent)) do
                items[#items + 1] = {
                    text = wrapped, font = entry.font, indent = entry.indent, height = entry.height,
                    marker = index == 1 and entry.marker or nil
                }
                total = total + entry.height
            end
        end
    end

    return items, total
end

local function drawSegments(text, font, x, y, inCode, theme)
    local parts = string.Explode("`", text, false)

    for index, part in ipairs(parts) do
        if index > 1 then inCode = not inCode end

        if part ~= "" then
            DFW.Draw.Text(part, font, x, y, inCode and theme.accent or theme.text)
            x = x + DFW.UI.TextSize(part, font)
        end
    end

    return inCode
end

function Format.Draw(items, theme)
    local y, inCode = 0, false

    for _, item in ipairs(items) do
        if not item.blank then
            if item.marker then DFW.Draw.Text(item.marker, "Body", item.indent - 14, y + item.height / 2, theme.textMuted) end

            inCode = drawSegments(item.text, item.font, item.indent, y + item.height / 2, inCode, theme)
        end

        y = y + item.height
    end
end

function Format.Panel(parent, text)
    local panel = vgui.Create("Panel", parent)

    panel.Text = text
    panel.Laid = nil
    panel.Items = {}

    panel.PerformLayout = function(self, w)
        if w <= 0 or self.Laid == w then return end

        local items, total = Format.Prepare(self.Text, w)

        self.Laid = w
        self.Items = items
        self:SetTall(math.max(total, LINE_HEIGHT))
        self:InvalidateParent()
    end

    panel.Paint = function(self)
        Format.Draw(self.Items, DFW.UI.GetTheme())
    end

    return panel
end
