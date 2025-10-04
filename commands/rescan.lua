ArtisanCommands = ArtisanCommands or {}

ArtisanCommands.rescan = function(self, rest)
    if _G.Artisan_RescanProfessions then
        _G.Artisan_RescanProfessions()
        self:Print("Artisan: profession scan complete.")
    else
        self:Print("Artisan: rescan not available.")
    end
end
