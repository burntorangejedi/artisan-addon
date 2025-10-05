local ADDON_NAME = ...
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)

local options = {
    name = "Artisan",
    -- provide a minimal handler object so AceConfigDialog has a valid handler context
    handler = {},
    type = 'group',
    args = {
        modifier = {
            type = 'select',
            name = 'Tooltip modifier',
            desc = 'Which modifier key shows profession info on tooltips',
            values = { ALT = 'Alt', SHIFT = 'Shift', CTRL = 'Ctrl', ALWAYS = 'Always', NONE = 'None' },
            get = function() return ArtisanDB and ArtisanDB.modifier or 'ALT' end,
            set = function(info, val)
                ArtisanDB = ArtisanDB or {}
                ArtisanDB.modifier = val
            end,
        },
    },
}

if AceConfig and AceConfigDialog then
    AceConfig:RegisterOptionsTable("Artisan", options)
    -- Try to add to Blizzard options safely. Some clients or loading orders may cause AddToBlizOptions
    -- to fail because the Blizzard options frame or internal state isn't ready. Use pcall and
    -- defer to PLAYER_LOGIN if necessary.
    local ok, err = pcall(function() AceConfigDialog:AddToBlizOptions("Artisan", "Artisan") end)
    if not ok then
        -- Defer until PLAYER_LOGIN
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LOGIN")
        f:SetScript("OnEvent", function(self)
            pcall(function() AceConfigDialog:AddToBlizOptions("Artisan", "Artisan") end)
            self:UnregisterEvent("PLAYER_LOGIN")
        end)
    end
end
