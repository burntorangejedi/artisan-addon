local ADDON_NAME, _ = ...
local Artisan = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")

-- Global command registry for modular commands
ArtisanCommands = ArtisanCommands or {}


-- Modular command loader
local commandModules = {
    help = "commands/help.lua",
    export = "commands/export.lua",
}

-- Register fonts with LibSharedMedia
local function RegisterArtisanFonts()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return end
    local fontList = {
        { key = "CreatoDisplay-Black",     file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-Black.ttf" },
        { key = "CreatoDisplay-Bold",      file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-Bold.ttf" },
        { key = "CreatoDisplay-ExtraBold", file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-ExtraBold.ttf" },
        { key = "CreatoDisplay-Light",     file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-Light.ttf" },
        { key = "CreatoDisplay-Medium",    file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-Medium.ttf" },
        { key = "CreatoDisplay-Regular",   file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-Regular.ttf" },
        { key = "CreatoDisplay-Thin",      file = "Interface/AddOns/" .. ADDON_NAME .. "/media/CreatoDisplay-Thin.ttf" },
    }
    for _, font in ipairs(fontList) do
        LSM:Register("font", font.key, font.file)
    end
end

function Artisan:OnInitialize()
    RegisterArtisanFonts()
    self:RegisterChatCommand("artisan", "HandleSlashCommand")
end

function Artisan:HandleSlashCommand(input)
    input = input and input:trim() or ""
    if input == "" then
        self:Print("Artisan loaded. Type /artisan help for options.")
        return
    end

    local cmd, rest = input:match("^(%S+)%s*(.*)$")
    local handler = ArtisanCommands[cmd]
    if type(handler) == "function" then
        handler(self, rest)
        return
    end

    self:Print("Unknown command. Type /artisan help for options.")
end
