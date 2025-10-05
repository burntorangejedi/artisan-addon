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
    libs = "commands/libs.lua",
}

-- Fonts are registered by `fonts.lua` via the global Artisan_RegisterFonts()

function Artisan:OnInitialize()
    if Artisan_RegisterFonts then
        Artisan_RegisterFonts()
    end
    -- Runtime self-check: report presence and versions of key Ace libraries to help debug load-order issues
    local function libInfo(name)
        local ok, lib = pcall(function() return LibStub(name, true) end)
        if ok and lib then
            local minor = lib and lib.minor or "?"
            return string.format("%s v%s", name, tostring(minor))
        end
        return string.format("%s (missing)", name)
    end

    local info = {
        libInfo("LibStub"),
        libInfo("AceConfigRegistry-3.0"),
        libInfo("AceConfig-3.0"),
        libInfo("AceConfigDialog-3.0"),
    }
    -- Print a short one-line status so load-order issues are obvious in the chat log.
    self:Print("Lib status: " .. table.concat(info, ", "))

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
