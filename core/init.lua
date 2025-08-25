local addonName, Artisan = ...
Artisan.name = addonName

-- Load font registration
local fonts = {}
Artisan.fonts = fonts
Artisan.RegisterFonts = function()
    if not LibStub then return end
    local LSM = LibStub("LibSharedMedia-3.0")
    if not LSM then return end

    fonts.list = {
        { name = "Compulsion Sans", file = "CompulsionSans.ttf" },
        { name = "Forge Runes", file = "ForgeRunes.ttf" },
    }

    for _, font in ipairs(fonts.list) do
        local path = "Interface\\AddOns\\" .. addonName .. "\\media\\" .. font.file
        LSM:Register("font", font.name, path)
    end

    fonts.default = LSM:Fetch("font", "Compulsion Sans")
end

-- Load global font override
Artisan.ApplyGlobalFont = function()
    if not fonts.default then return end
    local size = 14
    local flags = nil

    local function SetFont(obj)
        if obj then obj:SetFont(fonts.default, size, flags) end
    end

    SetFont(GameFontNormal)
    SetFont(GameFontHighlight)
    SetFont(GameFontDisable)
    SetFont(NumberFontNormal)
    SetFont(NumberFontNormalSmall)
    SetFont(GameFontNormalSmall)
end

-- Initialize
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, name)
    if name == addonName then
        Artisan.RegisterFonts()
        Artisan.ApplyGlobalFont()
        print("|cffffcc00[Artisan]|r Fonts loaded and applied.")
    end
end)