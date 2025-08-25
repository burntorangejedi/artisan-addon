local addonName, Artisan = ...
local LSM = LibStub("LibSharedMedia-3.0")
if not LSM then return end

Artisan.fonts = {
    list = {
        { name="CreatoDisplay Black", file="CreatoDisplay-Black.ttf" },
        { name="CreatoDisplay Bold", file="CreatoDisplay-Bold.ttf" },
        { name="CreatoDisplay ExtraBold", file="CreatoDisplay-ExtraBold.ttf" },
        { name="CreatoDisplay Light", file="CreatoDisplay-Light.ttf" },
        { name="CreatoDisplay Medium", file="CreatoDisplay-Medium.ttf" },
        { name="CreatoDisplay Regular", file="CreatoDisplay-Regular.ttf" },
    }
}

for _, font in ipairs(Artisan.fonts.list) do
    local path = "Interface\\AddOns\\" .. addonName .. "\\media\\" .. font.file
    LSM:Register("font", font.name, path)
end

Artisan.fonts.default = LSM:Fetch("font", "Compulsion Sans")