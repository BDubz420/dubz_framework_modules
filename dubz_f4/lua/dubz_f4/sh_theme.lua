local function c(r, g, b, a)
    return Color(r, g, b, a or 255)
end

DFW.Themes.Register("dubz_midnight", {
    name = "Dubz Midnight",
    colors = {
        background = c(14, 16, 24, 240), surface = c(24, 28, 40, 235), surfaceAlt = c(34, 40, 56, 225),
        raised = c(46, 54, 76), border = c(70, 82, 112), borderSoft = c(44, 52, 74),
        text = c(238, 241, 250), textMuted = c(170, 178, 200), textDim = c(118, 126, 150),
        accent = c(120, 170, 255), accentHover = c(150, 192, 255), onAccent = c(10, 14, 26),
        danger = c(240, 98, 98), success = c(96, 210, 140), warning = c(244, 170, 90),
        info = c(110, 176, 250), gold = c(236, 196, 96),
        shadow = c(0, 0, 0, 80), overlay = c(0, 0, 0, 170),
        track = c(8, 10, 16, 230), outline = c(90, 104, 140), slot = c(10, 12, 20, 160)
    },
    radius = {XS = 2, SM = 4, MD = 8, LG = 10, XL = 14},
    spacing = {XS = 4, SM = 8, MD = 12, LG = 16, XL = 24}
})
