ArtisanCommands = ArtisanCommands or {}

local function probeLib(name)
    local ok, lib = pcall(function() return LibStub(name, true) end)
    if not ok or not lib then return nil end
    local info = { name = name }
    info.minor = lib.minor
    -- capture a readable identity
    info.tostring = tostring(lib)
    return info
end

local function makeReport(names, verbose)
    local report = {}
    for _, name in ipairs(names) do
        local info = probeLib(name)
        if info then
            if verbose then
                table.insert(report, string.format("%s - v%s - %s", info.name, tostring(info.minor or "?"), info.tostring))
            else
                table.insert(report, string.format("%s - v%s", info.name, tostring(info.minor or "?")))
            end
        else
            table.insert(report, string.format("%s - (missing)", name))
        end
    end
    return report
end

-- Print versions or presence of common libs via LibStub
ArtisanCommands.libs = function(self, rest)
    rest = rest and rest:match("^%s*(.-)%s*$") or ""
    local mode = rest:lower()

    local names = {
        "LibStub",
        "AceAddon-3.0",
        "AceConsole-3.0",
        "AceConfigRegistry-3.0",
        "AceConfig-3.0",
        "AceConfigCmd-3.0",
        "AceConfigDialog-3.0",
        "AceGUI-3.0",
        "LibSharedMedia-3.0",
        "CallbackHandler-1.0",
    }

    if mode == "" or mode == "help" then
        self:Print("/artisan libs [help|verbose|save]")
        self:Print("  (no arg) - show a short list of common libs")
        self:Print("  verbose  - show extra identity info for each lib")
        self:Print("  save     - save the current report to ArtisanDB.lib_status")
        return
    end

    local verbose = (mode == "verbose")
    local report = makeReport(names, verbose)

    self:Print("Registered libs:")
    for _, line in ipairs(report) do self:Print("  " .. line) end

    if mode == "save" then
        ArtisanDB = ArtisanDB or {}
        ArtisanDB.lib_status = report
        self:Print("Saved lib status to ArtisanDB.lib_status")
    end
end

-- end
