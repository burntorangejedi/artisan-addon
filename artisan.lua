local ADDON_NAME, _ = ...
local Artisan = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")

-- Global command registry for modular commands
ArtisanCommands = ArtisanCommands or {}


-- Modular command loader
local commandModules = {
    help = "commands/help.lua",
    export = "commands/export.lua",
    options = "commands/options.lua",
    rescan = "commands/rescan.lua",
}

-- Fonts are registered by `fonts.lua` via the global Artisan_RegisterFonts()

function Artisan:OnInitialize()
    if Artisan_RegisterFonts then
        Artisan_RegisterFonts()
    end
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
