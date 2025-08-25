local addonName, Artisan = ...
local LSM = LibStub("LibSharedMedia-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Saved variable stub (replace with your actual DB reference)
Artisan.db = Artisan.db or {
    profile = {
        selectedFont = "Compulsion Sans",
    }
}

-- Apply selected font globally
function Artisan:ApplySelectedFont()
    local fontPath = LSM:Fetch("font", Artisan.db.profile.selectedFont)
    local size = 14
    local flags = nil

    local function SetFont(obj)
        if obj then obj:SetFont(fontPath, size, flags) end
    end

    SetFont(GameFontNormal)
    SetFont(GameFontHighlight)
    SetFont(GameFontDisable)
    SetFont(NumberFontNormal)
    SetFont(NumberFontNormalSmall)
    SetFont(GameFontNormalSmall)
end

-- Config table
local options = {
    name = "Artisan Fonts",
    type = "group",
    args = {
        font = {
            type = "select",
            name = "Global Font",
            desc = "Choose a font to apply across the UI",
            values = LSM:HashTable("font"),
            get = function() return Artisan.db.profile.selectedFont end,
            set = function(_, val)
                Artisan.db.profile.selectedFont = val
                Artisan:ApplySelectedFont()
                if Artisan.preview then
                    local path = LSM:Fetch("font", val)
                    Artisan.preview:SetFont(path, 16, "OUTLINE")
                end
            end,
        },
        preview = {
            type = "group",
            name = "Preview",
            inline = true,
            args = {
                spacer = {
                    type = "description",
                    name = "",
                    fontSize = "large",
                    image = function()
                        if not Artisan.preview then
                            local frame = AceGUI:Create("Label")
                            frame:SetText("The quick brown Vulpera jumps over the lazy Orc.")
                            local path = LSM:Fetch("font", Artisan.db.profile.selectedFont)
                            frame:SetFont(path, 16)
                            Artisan.preview = frame.label
                        end
                        return nil
                    end,
                    width = "full",
                },
            },
        },
    },
}

-- Register config
AceConfig:RegisterOptionsTable("Artisan Fonts", options)
AceConfigDialog:AddToBlizOptions("Artisan Fonts", "Artisan Fonts")