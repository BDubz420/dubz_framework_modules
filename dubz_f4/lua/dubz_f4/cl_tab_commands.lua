local Ui = DubzF4.Ui
local Adapter = DubzF4.Adapter
local config = DubzF4.Config
local CARD_HEIGHT = 84
local ICON_SIZE = 28
local RUN_WIDTH = 90
local FALLBACK_ICON = "misc/handyman"

local function enabledCommands()
    local commands = {}

    for _, row in ipairs(DubzF4.Rows("commands")) do
        if row.enabled ~= false and row.cmd ~= "" then commands[#commands + 1] = row end
    end

    return commands
end

local function runCommand(command)
    if command.prompt_title == "" then
        Adapter.Run(command.cmd)
        return
    end

    DFW.UI.Prompt(command.prompt_title, command.prompt_text, "", function(text)
        if text and text ~= "" then Adapter.Run(command.cmd, text) end
    end)
end

local function addCard(layout, command, width)
    local card = layout:Add("DFW.Card")
    local name = Ui.Label(card, command.name, "bodybold")
    local desc = Ui.Label(card, command.desc or "", "small")
    local run = vgui.Create("DFW.Button", card)
    local icon = command.icon ~= "" and command.icon or FALLBACK_ICON
    local pad = DFW.UI.Space("LG")
    local textX = pad + ICON_SIZE + DFW.UI.Space("MD")

    card:SetSize(width, CARD_HEIGHT)
    run:SetLabel(DubzF4.Phrase("Run"))
    run:SetVariant("primary")
    run.DoClick = function() runCommand(command) end

    card.PaintOver = function(_, _, h) DFW.Icons.Draw(icon, pad, (h - ICON_SIZE) / 2, ICON_SIZE, ICON_SIZE, DFW.UI.GetTheme().accent) end
    card.PerformLayout = function(_, w, h)
        name:SetPos(textX, h / 2 - 20)
        name:SetSize(w - textX - RUN_WIDTH - pad * 2, 20)
        desc:SetPos(textX, h / 2 + 2)
        desc:SetSize(w - textX - RUN_WIDTH - pad * 2, 18)
        run:SetPos(w - RUN_WIDTH - pad, (h - 36) / 2)
        run:SetSize(RUN_WIDTH, 36)
    end
end

local function build(page)
    local commands = enabledCommands()
    Ui.Header(page, DubzF4.Phrase("QuickCommands"), DubzF4.Phrase("Available", {count = #commands}))

    local scroll = Ui.Scroll(page)

    scroll:Dock(FILL)

    Ui.OnSized(scroll, function(w)
        local gap = DFW.UI.Space("MD")
        local columns = config.CommandColumns
        local cardWidth = math.floor((w - 18 - gap * (columns - 1)) / columns)
        local layout = scroll:Add("DIconLayout")

        layout:Dock(TOP)
        layout:SetSpaceX(gap)
        layout:SetSpaceY(gap)
        layout:SetTall(math.ceil(#commands / columns) * (CARD_HEIGHT + gap))

        for _, command in ipairs(commands) do addCard(layout, command, cardWidth) end
    end)
end

DubzF4.Tabs:Register("commands", {name = "TabCommands", icon = "misc/handyman", order = 70, build = build})
