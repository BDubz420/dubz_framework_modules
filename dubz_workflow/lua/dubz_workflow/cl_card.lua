DubzWorkflow.Card = DubzWorkflow.Card or {}

local Card = DubzWorkflow.Card
local State = DubzWorkflow.State
local config = DubzWorkflow.Config
local CARD_HEIGHT = 96
local PAD = 14
local ROW = 20

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function fit(text, font, limit)
    if DFW.UI.TextSize(text, font) <= limit then return text end

    while #text > 1 and DFW.UI.TextSize(text .. "…", font) > limit do text = string.sub(text, 1, #text - 1) end

    return text .. "…"
end

function Card.PriorityRank(priority)
    for index, entry in ipairs(DubzWorkflow.List("priorities")) do
        if entry == priority then return index end
    end

    return 0
end

local function priorityColor(theme, priority)
    local rank = Card.PriorityRank(priority)
    local top = #DubzWorkflow.List("priorities")

    if rank >= top and top > 1 then return theme.danger or theme.accent end

    if rank == top - 1 and top > 2 then return theme.warning or theme.accent end

    return theme.accent
end

Card.PriorityColor = priorityColor
Card.Fit = fit

function Card.TaskColor(theme, task)
    return task.color and DubzWorkflow.PaletteColor(task.color) or priorityColor(theme, task.priority)
end

function Card.Names(task)
    local names = {}

    for _, entry in ipairs(task.assignees or {}) do names[#names + 1] = entry.n ~= "" and entry.n or entry.s end

    return #names > 0 and table.concat(names, ", ") or phrase("Unassigned")
end

function Card.Overdue(task)
    return task.status ~= "done" and task.due and task.due ~= "" and task.due < os.date("%Y-%m-%d")
end

local function lineThree(task)
    if task.status == "done" and task.doneBy then
        return phrase("DoneBy", {name = task.doneBy.n, date = os.date("%Y-%m-%d", task.doneAt or 0)}), false
    end

    if Card.Overdue(task) then return phrase("Overdue", {date = task.due}), true end

    if task.due and task.due ~= "" then return phrase("Due", {date = task.due}), false end

    if task.claimedBy then return phrase("ClaimedBy", {name = task.claimedBy.n}), false end

    return "", false
end

function Card.Build(list, task, onOpen)
    local card = list:Add("DFW.Card")

    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("SM"))
    card:SetTall(CARD_HEIGHT)
    card:SetCursor("hand")
    card:SetAccent(Card.TaskColor(DFW.UI.GetTheme(), task))

    card.PaintOver = function(_, w)
        local theme = DFW.UI.GetTheme()
        local limit = w - PAD * 2 - 6
        local extra, alert = lineThree(task)

        DFW.Draw.Text(fit(task.title, "BodyBold", limit), "BodyBold", PAD + 6, PAD + ROW / 2, theme.text)
        DFW.Draw.Text(fit(Card.Names(task), "Small", limit), "Small", PAD + 6, PAD + ROW + ROW / 2, theme.textMuted)

        if task.summary and task.summary ~= "" then
            DFW.Draw.Text(fit(task.summary, "Tiny", limit), "Tiny", PAD + 6, PAD + ROW * 2 + ROW / 2, theme.textDim)
        end

        if extra ~= "" then
            DFW.Draw.Text(extra, "Tiny", PAD + 6, PAD + ROW * 3 + ROW / 2, alert and (theme.danger or theme.accent) or theme.textDim)
        end
    end

    card.OnMousePressed = function() onOpen(task.id) end

    return card
end
