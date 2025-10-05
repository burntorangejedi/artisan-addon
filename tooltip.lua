local ADDON_NAME = ...

-- Simple reagent -> professions cache
local reagentProfessions = {}

local function addReagentProfession(itemID, professionName)
    if not itemID or not professionName then return end
    reagentProfessions[itemID] = reagentProfessions[itemID] or {}
    reagentProfessions[itemID][professionName] = true
end

-- Expose a rescan function to force the profession scan from other modules
_G.Artisan_RescanProfessions = function()
    ScanTradeSkill()
end

local function extractItemIDFromLink(link)
    if not link then return nil end
    local itemId = link:match("item:(%d+)")
    if itemId then return tonumber(itemId) end
    return nil
end

-- Scan trade skill list (old and newer APIs where available)
local function ScanTradeSkill()
    -- Try classic trade skill API
    if GetNumTradeSkills and GetTradeSkillInfo then
        local skillName = GetTradeSkillLine and GetTradeSkillLine() or (TradeSkillFrame and TradeSkillFrameTitleText and TradeSkillFrameTitleText:GetText())
        skillName = skillName or "Unknown"
        local num = GetNumTradeSkills()
        for i = 1, num do
            local name, type = GetTradeSkillInfo(i)
            local reagentCount = GetTradeSkillNumReagents and GetTradeSkillNumReagents(i) or 0
            for r = 1, reagentCount do
                local reagentName, reagentTexture, reagentCountNeeded, reagentNumOwned, reagentLink = GetTradeSkillReagentInfo(i, r)
                local id = extractItemIDFromLink(reagentLink)
                if id then addReagentProfession(id, skillName) end
            end
            -- Try to capture the product item link for this recipe
            local prodLink
            if GetTradeSkillItemLink then
                prodLink = GetTradeSkillItemLink(i)
            elseif GetTradeSkillRecipeLink then
                prodLink = GetTradeSkillRecipeLink(i)
            end
            if prodLink then
                local pid = extractItemIDFromLink(prodLink)
                if pid then
                    local charKey = (UnitName("player") or "Unknown").."@"..(GetRealmName() or "?")
                    ArtisanDB = ArtisanDB or {}
                    ArtisanDB.crafters = ArtisanDB.crafters or {}
                    ArtisanDB.crafters[pid] = ArtisanDB.crafters[pid] or {}
                    ArtisanDB.crafters[pid][charKey] = true
                end
            end
        end
    end

    -- Try craft API (for CraftFrame)
    if GetNumCrafts and GetCraftInfo then
        local skillName = CraftFrame and CraftFrameTitleText and CraftFrameTitleText:GetText() or "Unknown"
        local num = GetNumCrafts and GetNumCrafts() or 0
        for i = 1, num do
            local name = GetCraftInfo(i)
            local reagentCount = GetCraftNumReagents and GetCraftNumReagents(i) or 0
            for r = 1, reagentCount do
                local reagentName, reagentTexture, reagentCountNeeded, reagentNumOwned, reagentLink = GetCraftReagentInfo(i, r)
                local id = extractItemIDFromLink(reagentLink)
                if id then addReagentProfession(id, skillName) end
            end
            -- Try to capture the product item link for this craft
            local prodLink
            if GetCraftItemLink then
                prodLink = GetCraftItemLink(i)
            elseif GetCraftRecipeLink then
                prodLink = GetCraftRecipeLink(i)
            end
            if prodLink then
                local pid = extractItemIDFromLink(prodLink)
                if pid then
                    local charKey = (UnitName("player") or "Unknown").."@"..(GetRealmName() or "?")
                    ArtisanDB = ArtisanDB or {}
                    ArtisanDB.crafters = ArtisanDB.crafters or {}
                    ArtisanDB.crafters[pid] = ArtisanDB.crafters[pid] or {}
                    ArtisanDB.crafters[pid][charKey] = true
                end
            end
        end
    end
end

-- Public debug function (helps during testing)
_G.Artisan_ShowReagentProfessions = function(itemLink)
    local id = extractItemIDFromLink(itemLink)
    if not id then return end
    local profs = reagentProfessions[id]
    if not profs then
        print("No profession data cached for:", itemLink)
        return
    end
    local list = {}
    for p in pairs(profs) do table.insert(list, p) end
    print(itemLink .. " is used by: " .. table.concat(list, ", "))
end

-- Show which characters can craft an item (persisted in ArtisanDB.crafters)
_G.Artisan_ShowCrafters = function(itemLink)
    local id = extractItemIDFromLink(itemLink)
    if not id then return end
    ArtisanDB = ArtisanDB or {}
    local c = ArtisanDB.crafters and ArtisanDB.crafters[id]
    if not c then
        print("No craft data cached for:", itemLink)
        return
    end
    local list = {}
    for k in pairs(c) do table.insert(list, k) end
    print(itemLink .. " craftable by: " .. table.concat(list, ", "))
end

-- Tooltip augmentation
local lastLink

local function getConfiguredModifier()
    if ArtisanDB and ArtisanDB.modifier then
        return ArtisanDB.modifier
    end
    return "ALT"
end

local function shouldShowForCurrentModifier()
    local cfg = getConfiguredModifier()
    if cfg == "ALWAYS" then return true end
    if cfg == "NONE" then return false end
    if cfg == "ALT" then return IsAltKeyDown() end
    if cfg == "SHIFT" then return IsShiftKeyDown() end
    if cfg == "CTRL" or cfg == "CONTROL" then return IsControlKeyDown() end
    return false
end

local function addProfessionsToTooltip(tt, link)
    if not link then return end
    local id = extractItemIDFromLink(link)
    if not id then return end
    local profs = reagentProfessions[id]
    if not profs then return end
    local list = {}
    for p in pairs(profs) do table.insert(list, p) end
    if #list == 0 then return end
    table.sort(list)
    tt:AddLine(" ")
    tt:AddLine("Used by: ", 1, 0.82, 0)
    tt:AddLine(table.concat(list, ", "), 1, 1, 1)
    tt:Show()
end

local function addCraftableToTooltip(tt, link)
    if not link then return end
    local id = extractItemIDFromLink(link)
    if not id then return end
    ArtisanDB = ArtisanDB or {}
    local c = ArtisanDB.crafters and ArtisanDB.crafters[id]
    if not c then return end
    local meKey = (UnitName("player") or "Unknown").."@"..(GetRealmName() or "?")
    local others = {}
    local you = false
    for k in pairs(c) do
        if k == meKey then you = true else table.insert(others, k) end
    end
    if not you and #others == 0 then return end
    -- Build display list: prefer "You" for current character, and short names for alts
    local display = {}
    if you then table.insert(display, "You") end
    for _, k in ipairs(others) do
        local short = k:match("([^@]+)") or k
        table.insert(display, short)
    end
    tt:AddLine(" ")
    tt:AddLine("Craftable by: ", 0.8, 0.8, 0.2)
    tt:AddLine(table.concat(display, ", "), 1, 1, 1)
    tt:Show()
end

local function safeHandleTooltip(tt)
    if not tt then return end
    local name, link = tt:GetItem()
    lastLink = link
    if not link then return end
    if shouldShowForCurrentModifier() then
        addProfessionsToTooltip(tt, link)
        addCraftableToTooltip(tt, link)
    end
end

local tooltipHook = CreateFrame("Frame")
tooltipHook:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" or event == "TRADE_SKILL_UPDATE" then
        ScanTradeSkill()
    elseif event == "PLAYER_LOGIN" then
        -- nothing for now, cache will build when user opens professions
    elseif event == "MODIFIER_STATE_CHANGED" then
        -- refresh tooltip when any modifier changes if tooltip is visible
        if GameTooltip and GameTooltip:IsShown() and lastLink then
            GameTooltip:ClearLines()
            GameTooltip:SetHyperlink(lastLink)
            if shouldShowForCurrentModifier() then
                addProfessionsToTooltip(GameTooltip, lastLink)
                addCraftableToTooltip(GameTooltip, lastLink)
            end
        end
    end
end)

tooltipHook:RegisterEvent("PLAYER_LOGIN")
-- Some clients (retail vs classic/versions) may not define all trade/craft events.
-- Use pcall to register events so we don't throw an error when an event is unknown.
pcall(function() tooltipHook:RegisterEvent("TRADE_SKILL_SHOW") end)
pcall(function() tooltipHook:RegisterEvent("CRAFT_SHOW") end)
pcall(function() tooltipHook:RegisterEvent("TRADE_SKILL_UPDATE") end)
pcall(function() tooltipHook:RegisterEvent("MODIFIER_STATE_CHANGED") end)

-- Robust tooltip hooking: prefer OnTooltipSetItem, otherwise fall back to hooksecurefunc on setter methods
local function tryHookGameTooltip()
    local hooked = false
    if GameTooltip and GameTooltip.HookScript then
        local canHook = true
        if GameTooltip.HasScript then
            canHook = GameTooltip:HasScript("OnTooltipSetItem")
        end
        if canHook then
            local ok = pcall(function()
                GameTooltip:HookScript("OnTooltipSetItem", function(tt) safeHandleTooltip(tt) end)
            end)
            hooked = ok
        end
    end

    -- Fallbacks using hooksecurefunc for common tooltip setters
    if not hooked and _G.hooksecurefunc then
        pcall(function() hooksecurefunc(GameTooltip, "SetHyperlink", function(tt, link) safeHandleTooltip(tt) end) end)
        pcall(function() hooksecurefunc(GameTooltip, "SetBagItem", function(tt, bag, slot) safeHandleTooltip(tt) end) end)
        pcall(function() hooksecurefunc(GameTooltip, "SetInventoryItem", function(tt, unit, slot) safeHandleTooltip(tt) end) end)
        pcall(function() hooksecurefunc(GameTooltip, "SetMerchantItem", function(tt, index) safeHandleTooltip(tt) end) end)
        -- Consider other setters if needed
    end
end

tryHookGameTooltip()

-- Also hook ItemRefTooltip (links opened from chat)
local function tryHookItemRefTooltip()
    if not ItemRefTooltip then return end
    local hooked = false
    if ItemRefTooltip and ItemRefTooltip.HookScript then
        local canHookRef = true
        if ItemRefTooltip.HasScript then
            canHookRef = ItemRefTooltip:HasScript("OnTooltipSetItem")
        end
        if canHookRef then
            local ok = pcall(function()
                ItemRefTooltip:HookScript("OnTooltipSetItem", function(tt) safeHandleTooltip(tt) end)
            end)
            hooked = ok
        end
    end

    if not hooked and _G.hooksecurefunc then
        pcall(function() hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tt, link) safeHandleTooltip(tt) end) end)
    end
end

tryHookItemRefTooltip()
