local ADDON_NAME = ...
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)

local options = {
    name = "Artisan",
    handler = nil,
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
    AceConfigDialog:AddToBlizOptions("Artisan", "Artisan")
end
