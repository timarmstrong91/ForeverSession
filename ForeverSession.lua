local addonName, addon = ...
addon = addon or {}
local frame = CreateFrame("Frame", "ForeverSessionFrame", UIParent)
frame:SetSize(224, 108)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

local resetButton = CreateFrame("Button", "ForeverSessionResetButton", frame, "UIPanelButtonTemplate")
resetButton:SetSize(58, 20)
resetButton:SetClampedToScreen(true)
resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, 0)
resetButton:SetText("Reset")
resetButton:Hide()

local resetMenu = CreateFrame("Frame", "ForeverSessionResetMenu", UIParent, "BackdropTemplate")
resetMenu:SetSize(132, 5 * 23 + 10)
resetMenu:SetFrameStrata("DIALOG")
resetMenu:SetClampedToScreen(true)
resetMenu:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 12,
    insets = {left = 3, right = 3, top = 3, bottom = 3}})
resetMenu:SetBackdropColor(0.035, 0.028, 0.025, 0.98)
resetMenu:SetBackdropBorderColor(0.72, 0.55, 0.3, 1)
resetMenu:Hide()
resetMenu:SetScript("OnUpdate", function(self)
    if IsMouseButtonDown and IsMouseButtonDown("LeftButton")
        and not self:IsMouseOver() and not resetButton:IsMouseOver() then
        self:Hide()
    end
end)
local resetActions = {}
for index, entry in ipairs({
    {"Reset all", "all"}, {"Reset XP", "xp"}, {"Reset gold", "gold"},
    {"Reset honor", "honor"}, {"Reset reputation", "reputation"},
}) do
    local button = CreateFrame("Button", nil, resetMenu, "UIPanelButtonTemplate")
    button:SetSize(116, 20)
    button:SetPoint("TOP", resetMenu, "TOP", 0, -5 - (index - 1) * 23)
    button:SetText(entry[1])
    button:SetScript("OnClick", function() end)
    resetActions[#resetActions + 1] = {button = button, tracker = entry[2]}
end

-- All decoration stays inside the same panel bounds; no offset shadow rectangle.
local background = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
background:SetAllPoints()
background:SetColorTexture(0.035, 0.028, 0.025, 0.94)

local edges = {}
local function Edge(point)
    local edge = frame:CreateTexture(nil, "BORDER")
    edge:SetPoint(point, frame, point, 0, 0)
    edges[#edges + 1] = edge
end
Edge("TOPLEFT")
Edge("BOTTOMLEFT")
Edge("TOPLEFT")
Edge("TOPRIGHT")

local text = frame:CreateFontString(nil, "OVERLAY")
text:SetFont(STANDARD_TEXT_FONT, 28, "OUTLINE")
text:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -29)
text:SetTextColor(1, 0.86, 0.54)
text:SetText("0")

local title = frame:CreateFontString(nil, "OVERLAY")
title:SetFont(STANDARD_TEXT_FONT, 10, "")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -12)
title:SetTextColor(0.73, 0.59, 0.38)
title:SetText("SESSION EXPERIENCE")

local unit = frame:CreateFontString(nil, "OVERLAY")
unit:SetFont(STANDARD_TEXT_FONT, 10, "")
unit:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -62)
unit:SetTextColor(0.68, 0.65, 0.59)
unit:SetText("XP / HOUR")

local gainedText = frame:CreateFontString(nil, "OVERLAY")
gainedText:SetFont(STANDARD_TEXT_FONT, 10, "")
gainedText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 12)
gainedText:SetTextColor(0.76, 0.73, 0.66)
gainedText:SetText("+0")

local durationText = frame:CreateFontString(nil, "OVERLAY")
durationText:SetFont(STANDARD_TEXT_FONT, 10, "")
durationText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 12)
durationText:SetTextColor(0.53, 0.51, 0.47)
durationText:SetText("00:00:00")

local levelTimeLabel = frame:CreateFontString(nil, "OVERLAY")
levelTimeLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
levelTimeLabel:SetText("NEXT LEVEL")
local levelTimeText = frame:CreateFontString(nil, "OVERLAY")
levelTimeText:SetFont(STANDARD_TEXT_FONT, 11, "")
levelTimeText:SetText("—")
local killsLabel = frame:CreateFontString(nil, "OVERLAY")
killsLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
killsLabel:SetText("KILLS TO LEVEL")
local killsText = frame:CreateFontString(nil, "OVERLAY")
killsText:SetFont(STANDARD_TEXT_FONT, 11, "")
killsText:SetText("—")

local moneyLabel = frame:CreateFontString(nil, "OVERLAY")
moneyLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
moneyLabel:SetText("GOLD / HOUR")
local moneyText = frame:CreateFontString(nil, "OVERLAY")
moneyText:SetFont(STANDARD_TEXT_FONT, 12, "")
moneyText:SetText("—")

local gainedLabel = frame:CreateFontString(nil, "OVERLAY")
gainedLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
gainedLabel:SetText("XP GAINED")
local durationLabel = frame:CreateFontString(nil, "OVERLAY")
durationLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
durationLabel:SetText("SESSION TIME")

local progressTrack = frame:CreateTexture(nil, "ARTWORK")
progressTrack:SetColorTexture(0.18, 0.14, 0.20, 1)
local progress = frame:CreateTexture(nil, "ARTWORK", nil, 1)
progress:SetColorTexture(0.64, 0.43, 0.84, 1)
progress:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -78)
progress:SetSize(1, 3)
progress:Hide()

local highlight = frame:CreateTexture(nil, "BACKGROUND")
highlight:SetAllPoints()
highlight:SetColorTexture(0.75, 0.53, 0.23, 0.07)
highlight:Hide()

local goldTrim = {}
local goldTrimAvailable = C_Texture.GetAtlasInfo("levelup-bar-gold") ~= nil
for _, point in ipairs({ "TOPLEFT", "BOTTOMLEFT" }) do
    local trim = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    -- The native atlas places its visible rule at the texture's lower edge.
    -- Align that edge to BOTH panel boundaries, rather than the top texture bounds.
    trim:SetPoint("BOTTOMLEFT", frame, point, 0, 0)
    if goldTrimAvailable then trim:SetAtlas("levelup-bar-gold", false) end
    trim:Hide()
    goldTrim[#goldTrim + 1] = trim
end

local db, session
local options
local ready, dirty = false, false
local elapsedSinceUpdate = 0
local hovered = false
local hoverExitAt
local moneyAvailable = false
local bagsDirty = false
local lastCelebratedLevel
local groups = {}
local watchedFaction, honorCurrent
local xpAvailable = true
local lastLayoutScale

addon.defaults = {
    showXP = true, showHonor = false, showReputation = false,
    scale = 100, width = 224, fontSize = 24, barHeight = 2, backgroundOpacity = 50, borderOpacity = 50,
    showBackground = true, showBorder = true, showTitle = true, showFooter = true,
    showProgress = true, hoverHighlight = true, outline = true, detailOutline = false,
    showTimeToLevel = true, showKillsToLevel = true, showGold = false, includeLootValue = false,
    showGoldTrim = true, debugEffects = false, levelUpEffects = true,
    rateColor = "ffffdb8a", accentColor = "ffb88740", detailColor = "ffbeb8a8",
    backgroundColor = "ff090706", progressColor = "ffa36ed6", reputationColor = "ff27613b", honorColor = "ff9c3035",
}
local ranges = {
    scale = {60, 180}, width = {180, 420}, fontSize = {18, 42}, barHeight = {1, 16},
    backgroundOpacity = {0, 100}, borderOpacity = {0, 100},
}

local function IsNumber(value)
    if issecretvalue and issecretvalue(value) then return false end
    return type(value) == "number" and value == value
end

local function NormalizeOptions()
    if type(db.appearance) ~= "table" then db.appearance = {} end
    options = db.appearance
    options.debugArt = nil -- Retired artwork-preview setting.
    options.previewShimmer, options.previewGoldFlash, options.previewEcho = nil, nil, nil
    -- Migrate the selected mode once; retain the old extra-gold preference.
    if type(options.showXP) ~= "boolean" then
        local previous = options.tracker or "xp"
        if previous ~= "xp" and previous ~= "gold" and previous ~= "honor" and previous ~= "reputation" then previous = "xp" end
        options.showXP = previous == "xp"
        options.showHonor = previous == "honor"
        options.showReputation = previous == "reputation"
        if previous == "gold" then options.showGold = true end
    end
    options.tracker = nil
    -- 28 was the old default; migrate it so the main rate is less dominant.
    if options.fontSize == 28 then options.fontSize = 24 end
    for key, default in pairs(addon.defaults) do
        local value = options[key]
        if type(default) == "number" then
            if not IsNumber(value) then value = default end
            value = math.max(ranges[key][1], math.min(ranges[key][2], value))
        elseif type(default) == "boolean" then
            if type(value) ~= "boolean" then value = default end
        elseif type(value) ~= "string" or not value:match("^%x%x%x%x%x%x%x%x$") then
            value = default
        end
        options[key] = value
    end
    if type(db.locked) ~= "boolean" then db.locked = false end
end

local function RGB(hex)
    return tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255
end

local function ShowWhen(region, enabled)
    if enabled then region:Show() else region:Hide() end
end

local function Position(region, point, x, y)
    region:ClearAllPoints()
    region:SetPoint(point, frame, point, x, y)
end

-- Thin quads must occupy a real screen pixel even at small panel/UI scales.
local function PixelSize(size, minimum)
    if PixelUtil and PixelUtil.GetNearestPixelSize then
        return PixelUtil.GetNearestPixelSize(size, frame:GetEffectiveScale(), minimum)
    end
    local factor = 1
    if GetPhysicalScreenSize then
        local _, height = GetPhysicalScreenSize()
        if height and height > 0 then factor = 768 / height end
    end
    local scale = frame:GetEffectiveScale()
    return math.max(minimum or 0, math.floor(size * scale / factor + 0.5)) * factor / scale
end

local function StableTexture(texture)
    if texture.SetRoundLayoutToNearestPixel then texture:SetRoundLayoutToNearestPixel(true) end
    -- Avoid independently snapping UVs on narrow, stretched native artwork.
    if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
    if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
end
if frame.SetRoundLayoutToNearestPixel then frame:SetRoundLayoutToNearestPixel(true) end
for _, texture in ipairs({background, edges[1], edges[2], edges[3], edges[4],
    progressTrack, progress, goldTrim[1], goldTrim[2]}) do StableTexture(texture) end

local function NewLabel(value)
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 10, "")
    label:SetText(value or "—")
    return label
end

local function NewGroup(key, caption, totalCaption)
    local group = {key = key, label = NewLabel(caption), value = NewLabel("0"),
        totalLabel = NewLabel(totalCaption), total = NewLabel("0")}
    if key ~= "gold" then
        group.milestoneLabel, group.milestone = NewLabel("NEXT STANDING"), NewLabel()
        group.track = frame:CreateTexture(nil, "ARTWORK")
        group.fill = frame:CreateTexture(nil, "ARTWORK", nil, 1)
        StableTexture(group.track)
        StableTexture(group.fill)
    end
    return group
end

groups.xp = {key = "xp", label = unit, value = text, totalLabel = gainedLabel, total = gainedText,
    milestoneLabel = levelTimeLabel, milestone = levelTimeText, track = progressTrack, fill = progress}
groups.gold = {key = "gold", label = moneyLabel, value = moneyText,
    totalLabel = NewLabel("NET GOLD"), total = NewLabel("0")}
groups.honor = NewGroup("honor", "HONOR / HOUR", "HONOR GAINED")
groups.reputation = NewGroup("reputation", "REP / HOUR", "REP GAINED")
groups.reputation.faction = NewLabel("No watched faction")
local noTrackers = NewLabel("Enable a tracker in /fs")
local dividers = {}
for index = 1, 4 do
    local divider = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    if goldTrimAvailable then divider:SetAtlas("levelup-bar-gold", false) end
    StableTexture(divider)
    divider:SetAlpha(0.72)
    divider:Hide()
    dividers[index] = divider
end
addon.groups = groups

local function Layout()
    if not options then return end
    local padding, gap = 14, 8
    local entries, sections = {}, 0
    local function Row(label, value) entries[#entries + 1] = {label = label, value = value} end
    local function Section()
        if sections > 0 then entries[#entries + 1] = {divider = true} end
        sections = sections + 1
    end
    for _, group in pairs(groups) do
        for _, key in ipairs({"label", "value", "totalLabel", "total", "milestoneLabel", "milestone", "track", "fill", "faction"}) do
            if group[key] then group[key]:Hide() end
        end
    end
    killsLabel:Hide(); killsText:Hide(); durationLabel:Hide(); durationText:Hide(); noTrackers:Hide()
    for _, divider in ipairs(dividers) do divider:Hide() end
    for _, key in ipairs({"xp", "gold", "honor", "reputation"}) do
        local group = groups[key]
        if group.enabled then
            Section()
            if group.faction then Row(group.faction) end
            Row(group.label, group.value)
            if options.showProgress and group.bar and group.bar.maximum > 0 then entries[#entries + 1] = {bar = group} end
            if options.showTimeToLevel and group.hasMilestone then Row(group.milestoneLabel, group.milestone) end
            if key == "xp" and options.showKillsToLevel then Row(killsLabel, killsText) end
            if options.showFooter then Row(group.totalLabel, group.total) end
        end
    end
    if sections == 0 then Row(noTrackers) end
    if options.showFooter then Section(); Row(durationLabel, durationText) end
    local width = options.width
    for _, entry in ipairs(entries) do
        if entry.label then
            width = math.max(width, entry.label:GetStringWidth() +
                (entry.value and entry.value:GetStringWidth() + 20 or 0) + 2 * padding)
        end
    end
    title:SetText("SESSION STATS")
    ShowWhen(title, options.showTitle)
    if options.showTitle then width = math.max(width, title:GetStringWidth() + 2 * padding) end
    width = PixelSize(width, 1)
    local y = padding
    if options.showTitle then
        Position(title, "TOPLEFT", padding, -y)
        y = y + title:GetStringHeight() + gap
    end
    local dividerIndex = 0
    for index, entry in ipairs(entries) do
        if index > 1 then y = y + gap end
        if entry.divider then
            dividerIndex = dividerIndex + 1
            local divider = dividers[dividerIndex]
            -- Match the outer trim's visible lower edge, with a shorter inset rule.
            divider:ClearAllPoints()
            divider:SetPoint("BOTTOM", frame, "TOP", 0, -y)
            divider:SetSize(PixelSize((width - 2 * padding) * 0.82, 1), PixelSize(6, 2))
            ShowWhen(divider, goldTrimAvailable)
            y = y + PixelSize(1, 1)
        elseif entry.bar then
            local group = entry.bar
            local height = PixelSize(options.barHeight, 1)
            Position(group.track, "TOPLEFT", padding, -y)
            group.track:SetSize(width - 2 * padding, height)
            group.track:Show()
            Position(group.fill, "TOPLEFT", padding, -y)
            if group.bar.xp > 0 then
                group.fill:SetSize((width - 2 * padding) * math.min(1, group.bar.xp / group.bar.maximum), height)
                group.fill:Show()
            end
            y = y + height
        else
            local height = math.max(entry.label:GetStringHeight(), entry.value and entry.value:GetStringHeight() or 0)
            entry.label:ClearAllPoints()
            entry.label:SetPoint("LEFT", frame, "TOPLEFT", padding, -(y + height / 2))
            entry.label:Show()
            if entry.value then
                entry.value:ClearAllPoints()
                entry.value:SetPoint("RIGHT", frame, "TOPRIGHT", -padding, -(y + height / 2))
                entry.value:Show()
            end
            y = y + height
        end
    end
    local height = y + padding
    frame:SetSize(width, height)
    lastLayoutScale = frame:GetEffectiveScale()
    local thickness = PixelSize(1, 1)
    edges[1]:SetSize(width, thickness); edges[2]:SetSize(width, thickness)
    edges[3]:SetSize(thickness, height); edges[4]:SetSize(thickness, height)
    for _, trim in ipairs(goldTrim) do trim:SetSize(width, PixelSize(8, 2)) end
end

local function Snapshot()
    local xp, maximum, level = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
    if not IsNumber(xp) or not IsNumber(maximum) or not IsNumber(level)
        or xp < 0 or maximum < 0 or level < 1 then
        return nil
    end
    return { xp = xp, maximum = maximum, level = level }
end

local function FormatNumber(value)
    local result = string.format("%.0f", math.max(0, value))
    local count
    repeat
        result, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
    until count == 0
    return result
end

local function RecordKillXP(message)
    if not session or type(message) ~= "string" then return end
    -- CHAT_MSG_COMBAT_XP_GAIN is the game's creature-XP channel. Its amount is
    -- localized text, so collect the first decimal number and ignore separators.
    local amount = message:match("(%d[%d%.,]*)")
    amount = amount and tonumber((amount:gsub("[%.,]", "")))
    if not IsNumber(amount) or amount <= 0 then return end
    session.lastKillXP = amount
    dirty = true
end

local function KillsToLevel()
    local current = session and session.previous
    if not current or current.maximum <= 0 or not IsNumber(session.lastKillXP) or session.lastKillXP <= 0 then return "—" end
    if GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel and GameRulesUtil.IsPlayerAtEffectiveMaxLevel() then
        return "Max level"
    end
    return FormatNumber(math.ceil(math.max(0, current.maximum - current.xp) / session.lastKillXP))
end

local function PotentialQuestXP()
    if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not C_QuestLog.GetInfo
        or not C_QuestLog.IsComplete or not GetQuestLogRewardXP then return nil, nil end
    local entryCount = C_QuestLog.GetNumQuestLogEntries()
    if not IsNumber(entryCount) then return nil, nil end
    local total, completed, rewardData, completionData = 0, 0, true, true
    for index = 1, entryCount do
        local info = C_QuestLog.GetInfo(index)
        if info and not info.isHeader and IsNumber(info.questID) then
            local reward = GetQuestLogRewardXP(info.questID)
            if not IsNumber(reward) then
                rewardData = false
                completionData = false
            elseif reward > 0 then
                total = total + reward
                local isComplete = C_QuestLog.IsComplete(info.questID)
                if issecretvalue and issecretvalue(isComplete) then
                    completionData = false
                elseif isComplete then
                    completed = completed + reward
                end
            end
        end
    end
    return rewardData and total or nil, rewardData and completionData and completed or nil
end

local function ReadXP()
    if not session then return end
    local current = Snapshot()
    if not current then return false end
    local previous = session.previous
    if previous then
        local gain = 0
        if current.level == previous.level then
            gain = current.xp - previous.xp
        elseif current.level == previous.level + 1 then
            -- Keep the OLD level's XP requirement, including the last level at cap.
            gain = previous.maximum - previous.xp + current.xp
        else
            -- GM level changes / beta boosts cannot be reconstructed from UnitXP.
            -- Rebaseline rather than inventing XP for skipped levels.
            session.discontinuous = true
        end
        session.gained = session.gained + math.max(0, gain)
    end
    session.previous = current
    return true
end

local function FormatDuration(seconds)
    seconds = math.max(0, math.ceil(seconds))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end

local function TimeToLevel(rate)
    local current = session and session.previous
    if not current then return "—" end
    if current.maximum <= 0 or (GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel
        and GameRulesUtil.IsPlayerAtEffectiveMaxLevel()) then
        return "Max level"
    end
    if IsXPUserDisabled and IsXPUserDisabled() then return "XP paused" end
    if rate <= 0 then return "—" end
    local remaining = math.max(0, current.maximum - current.xp)
    return FormatDuration(remaining * 3600 / rate)
end

local function ReadMoney()
    if not session then return end
    local balance = GetMoney()
    moneyAvailable = IsNumber(balance) and balance >= 0
    if not moneyAvailable then return end
    if not IsNumber(session.moneyInitial) or session.moneyInitial < 0
        or not IsNumber(session.moneyStarted) or session.moneyStarted > GetTime() then
        -- On an upgrade mid-login, money tracking starts here; the XP session survives.
        session.moneyInitial = balance
        session.moneyStarted = GetTime()
    end
    session.moneyNet = balance - session.moneyInitial
end

local function FormatMoney(amount)
    -- Work in integer copper; convert the magnitude before adding the loss sign.
    local copper = math.floor(math.abs(amount) + 0.5)
    local sign = amount < 0 and copper > 0 and "-" or ""
    return sign .. C_CurrencyInfo.GetCoinTextureString(copper, 12)
end

local function ItemKey(link)
    if issecretvalue and issecretvalue(link) then return nil end
    local id = type(link) == "string" and link:match("|Hitem:(%d+)")
    -- Link context can change on level-up; track stable item IDs across those changes.
    return id and "item:" .. id or nil
end

local function BagCounts()
    local counts = {}
    for bag = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemInfo(bag, slot)
            if item then
                local key = ItemKey(item.hyperlink)
                if key and IsNumber(item.stackCount) then
                    counts[key] = (counts[key] or 0) + item.stackCount
                end
            end
        end
    end
    return counts
end

local lootPatterns
local function QueueLoot(message)
    if not session or type(message) ~= "string" or (issecretvalue and issecretvalue(message)) then return end
    if not lootPatterns then
        lootPatterns = {}
        for _, name in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF" }) do
            local template = _G[name]
            if type(template) == "string" then
                -- Use the client's localized self-loot formats, including positional placeholders.
                template = template:gsub("%%%d+%$s", "%%s"):gsub("%%%d+%$d", "%%d")
                local pattern = template:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
                pattern = pattern:gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
                lootPatterns[#lootPatterns + 1] = "^" .. pattern .. "$"
            end
        end
    end
    for _, pattern in ipairs(lootPatterns) do
        local first, second = message:match(pattern)
        local link = ItemKey(first) and first or (ItemKey(second) and second)
        local key = ItemKey(link)
        if key then
            local quantity = tonumber(first) or tonumber(second) or 1
            if quantity > 0 then
                local record = session.lootRecords[key]
                if not record then
                    record = { link = link, count = 0, pending = 0 }
                    session.lootRecords[key] = record
                end
                record.pending = record.pending + quantity
                record.pendingUntil = GetTime() + 10
            end
            return
        end
    end
end

local function ReadLootValue()
    if not session then return end
    local current = BagCounts()
    local total = 0
    for key, record in pairs(session.lootRecords) do
        local held = current[key] or 0
        local removed = math.max(0, (session.bagCounts[key] or 0) - held)
        -- Retire looted units first when a stack shrinks. Moving/splitting stacks is neutral.
        record.count = math.min(held, math.max(0, record.count - removed))
        local received = math.min(math.max(0, held - record.count), record.pending)
        record.count = record.count + received
        record.pending = record.pending - received
        if record.pendingUntil and GetTime() > record.pendingUntil then record.pending = 0 end
        if record.count <= 0 and record.pending <= 0 then
            session.lootRecords[key] = nil
        else
            local price = ({ C_Item.GetItemInfo(record.link) })[11]
            if IsNumber(price) and price >= 0 then
                record.price = price
            elseif not record.requested then
                C_Item.RequestLoadItemDataByID(record.link)
                record.requested = true
            end
            total = total + record.count * (record.price or 0)
        end
    end
    session.bagCounts = current
    session.lootValue = total
end


local function HonorSnapshot()
    -- Forever's Camelot PvP pane uses faction 2800 for rank points.
    if C_MajorFactions and C_MajorFactions.GetMajorFactionProgressionInfo
        and C_MajorFactions.GetTotalReputationForRenownLevel then
        local info = C_MajorFactions.GetMajorFactionProgressionInfo(2800)
        if info and IsNumber(info.renownLevel) and IsNumber(info.renownReputationEarned)
            and IsNumber(info.renownLevelThreshold) then
            local base = C_MajorFactions.GetTotalReputationForRenownLevel(2800, info.renownLevel)
            if IsNumber(base) then
                return {xp = info.renownReputationEarned, maximum = info.renownLevelThreshold,
                    level = info.renownLevel, total = base + info.renownReputationEarned,
                    source = "rank", capped = IsNumber(info.maxLevel) and info.renownLevel >= info.maxLevel,
                    weeklyCapped = C_MajorFactions.IsWeeklyRenownCapped and C_MajorFactions.IsWeeklyRenownCapped(2800)}
            end
        end
    end
    if UnitHonor and UnitHonorMax and UnitHonorLevel then
        local value, maximum, level = UnitHonor("player"), UnitHonorMax("player"), UnitHonorLevel("player")
        if IsNumber(value) and IsNumber(maximum) and IsNumber(level) and value >= 0 and maximum > 0 then
            return {xp = value, maximum = maximum, level = level, source = "honor"}
        end
    end
end

local function RememberFaction(data)
    if not data or not IsNumber(data.factionID) or not IsNumber(data.currentStanding)
        or (data.isHeader and not data.isHeaderWithRep) then return end
    local id = data.factionID
    local record = session.reputations[id]
    if not record then
        record = {started = GetTime(), initial = data.currentStanding}
        session.reputations[id] = record
    end
    record.gained = data.currentStanding - record.initial
    return record
end

local function ReadOtherTrackers()
    if not session then return end
    honorCurrent = HonorSnapshot()
    if honorCurrent then
        local record = session.honor
        if not record then
            record = {started = GetTime(), gained = 0}
            session.honor = record
        end
        local previous = record.previous
        if previous and previous.source == honorCurrent.source then
            local gain = 0
            if honorCurrent.total and previous.total then gain = honorCurrent.total - previous.total
            elseif honorCurrent.level == previous.level then gain = honorCurrent.xp - previous.xp
            elseif honorCurrent.level == previous.level + 1 then
                gain = previous.maximum - previous.xp + honorCurrent.xp
            end
            record.gained = record.gained + math.max(0, gain)
        end
        record.previous = honorCurrent
    end
    watchedFaction = nil
    if not C_Reputation or not C_Reputation.GetWatchedFactionData then return end
    -- Capture visible factions at login and retain independent baselines across switches.
    if not session.reputations then
        session.reputations = {}
        if C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
            for index = 1, C_Reputation.GetNumFactions() do
                RememberFaction(C_Reputation.GetFactionDataByIndex(index))
            end
        end
    end
    if C_Reputation.GetFactionDataByID then
        for id in pairs(session.reputations) do RememberFaction(C_Reputation.GetFactionDataByID(id)) end
    end
    local data = C_Reputation.GetWatchedFactionData()
    if data and RememberFaction(data) then watchedFaction = data end
end

local function SignedNumber(value, positiveSign)
    return (value < 0 and "-" or (positiveSign and "+" or "")) .. FormatNumber(math.abs(value))
end

local function UpdateGroup(group, enabled, available, gained, started, bar, milestone)
    group.enabled, group.available = enabled, available
    local duration = math.max(0, GetTime() - (started or GetTime()))
    local rate = duration > 0 and gained * 3600 / duration or 0
    group.bar = bar and bar.maximum > 0 and bar or nil
    group.hasMilestone = milestone ~= nil
    group.value:SetText(available and (group.key == "gold" and FormatMoney(rate) or SignedNumber(rate)) or
        (group.key == "reputation" and "No faction" or "Unavailable"))
    group.value:SetTextColor(RGB(options.rateColor))
    if available and rate < 0 then group.value:SetTextColor(1, 0.48, 0.38) end
    group.total:SetText(available and (group.key == "gold" and FormatMoney(gained) or
        (group.key == "xp" and FormatNumber(gained) or SignedNumber(gained, true))) or "—")
    if group.milestone then group.milestone:SetText(milestone or "—") end
    return rate
end

local function Estimate(bar, gained, started)
    if not bar or bar.maximum <= 0 then return "Maximum" end
    local duration = math.max(0, GetTime() - (started or GetTime()))
    local rate = duration > 0 and gained * 3600 / duration or 0
    return rate > 0 and FormatDuration(math.max(0, bar.maximum - bar.xp) * 3600 / rate) or "—"
end

local function Render()
    if not session then return end
    local duration = math.max(0, GetTime() - session.started)
    local rate = duration > 0 and session.gained * 3600 / duration or 0
    UpdateGroup(groups.xp, options.showXP, xpAvailable, session.gained, session.started,
        xpAvailable and session.previous, xpAvailable and TimeToLevel(rate) or "—")
    killsText:SetText(xpAvailable and KillsToLevel() or "—")

    local moneyTotal = (session.moneyNet or 0) + (options.includeLootValue and (session.lootValue or 0) or 0)
    UpdateGroup(groups.gold, options.showGold, moneyAvailable, moneyTotal, session.moneyStarted)

    local honor = session.honor
    local honorBar = honorCurrent and not honorCurrent.capped and honorCurrent or nil
    local honorEstimate
    if honorCurrent then
        honorEstimate = honorCurrent.capped and "Maximum" or (honorCurrent.weeklyCapped and "Weekly cap" or
            Estimate(honorBar, honor and honor.gained or 0, honor and honor.started))
    end
    groups.honor.milestoneLabel:SetText(honorCurrent and honorCurrent.source == "rank" and "NEXT RANK" or "NEXT HONOR LEVEL")
    UpdateGroup(groups.honor, options.showHonor, honorCurrent ~= nil, honor and honor.gained or 0,
        honor and honor.started, honorBar, honorEstimate)

    local data = watchedFaction
    local record = data and session.reputations and session.reputations[data.factionID]
    local repBar
    if data and IsNumber(data.currentReactionThreshold) and IsNumber(data.nextReactionThreshold) then
        local maximum = data.nextReactionThreshold - data.currentReactionThreshold
        if maximum > 0 then repBar = {xp = math.max(0, data.currentStanding - data.currentReactionThreshold), maximum = maximum} end
    end
    groups.reputation.faction:SetText(data and data.name or "Choose a watched faction")
    UpdateGroup(groups.reputation, options.showReputation, data ~= nil, record and record.gained or 0,
        record and record.started, repBar, data and Estimate(repBar, record and record.gained or 0, record and record.started))
    -- Individual resets leave the one shared session clock intact.
    durationText:SetText(FormatDuration(math.floor(math.max(0, GetTime() - (session.loginStarted or session.started)))))
    Layout()
end

local function SavePosition()
    local x, y = frame:GetCenter()
    if x and y then
        local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        db.x = x * ratio - UIParent:GetWidth() / 2
        db.y = y * ratio - UIParent:GetHeight() / 2
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", db.x / ratio, db.y / ratio)
    end
end

local function Place()
    frame:ClearAllPoints()
    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    frame:SetPoint("CENTER", UIParent, "CENTER", (db.x or 0) / ratio, (db.y or 160) / ratio)
end

function addon.ApplyAppearance()
    if not db then return end
    NormalizeOptions()
    frame:StopMovingOrSizing()
    frame:SetScale(options.scale / 100)
    Place()
    local flags = options.detailOutline and "OUTLINE" or ""
    for _, label in ipairs({title, killsLabel, killsText, durationLabel, durationText, noTrackers}) do
        label:SetFont(STANDARD_TEXT_FONT, 10, flags)
        label:SetTextColor(RGB(options.detailColor))
    end
    title:SetTextColor(RGB(options.accentColor))
    for _, group in pairs(groups) do
        group.value:SetFont(STANDARD_TEXT_FONT, options.fontSize, options.outline and "OUTLINE" or "")
        for _, key in ipairs({"label", "totalLabel", "total", "milestoneLabel", "milestone", "faction"}) do
            if group[key] then
                group[key]:SetFont(STANDARD_TEXT_FONT, 10, flags)
                group[key]:SetTextColor(RGB((key == "milestone" or key == "faction") and options.accentColor or options.detailColor))
            end
        end
    end
    local r, g, b = RGB(options.backgroundColor)
    background:SetColorTexture(r, g, b, options.backgroundOpacity / 100)
    ShowWhen(background, options.showBackground)
    r, g, b = RGB(options.accentColor)
    for _, edge in ipairs(edges) do
        edge:SetColorTexture(r, g, b, options.borderOpacity / 100)
        ShowWhen(edge, options.showBorder)
    end
    for _, trim in ipairs(goldTrim) do
        ShowWhen(trim, options.showGoldTrim and goldTrimAvailable)
    end
    highlight:SetColorTexture(r, g, b, 0.07)
    ShowWhen(highlight, hovered and options.hoverHighlight)
    for key, group in pairs(groups) do
        if group.fill then
            r, g, b = RGB(key == "reputation" and options.reputationColor or (key == "honor" and options.honorColor or options.progressColor))
            group.fill:SetColorTexture(1, 1, 1, 1)
            group.fill:SetGradient("HORIZONTAL",
                CreateColor(r * 0.92, g * 0.92, b * 0.92, 0.62),
                CreateColor(r + (1 - r) * 0.08, g + (1 - g) * 0.08, b + (1 - b) * 0.08, 0.62))
            group.track:SetColorTexture(r * 0.2, g * 0.2, b * 0.2, 0.38)
        end
    end
    if session then Render() else Layout() end
end

function addon.GetOptions() return options, db end
function addon.GetEffectTargets() return frame, progressTrack end
function addon.Center()
    frame:StopMovingOrSizing()
    db.x, db.y = 0, 160
    Place()
end

local function StartSession(isInitialLogin, isReloadingUI)
    local now = GetTime()
    local saved = db.session
    -- Restore ONLY for /reload. A fresh login always starts from zero.
    if not isInitialLogin and isReloadingUI and type(saved) == "table"
        and saved.version == 1 and IsNumber(saved.started) and saved.started <= now
        and IsNumber(saved.gained) and saved.gained >= 0
        and type(saved.previous) == "table"
        and IsNumber(saved.previous.xp) and IsNumber(saved.previous.maximum)
        and IsNumber(saved.previous.level) then
        session = saved
    else
        session = { version = 1, started = now, gained = 0, previous = Snapshot() }
    end
    if not IsNumber(session.loginStarted) then session.loginStarted = session.started end
    db.session = session
    if type(session.lootRecords) ~= "table" then session.lootRecords = {} end
    if type(session.bagCounts) ~= "table" then session.bagCounts = BagCounts() end
    ReadMoney()
    ReadLootValue()
    ReadOtherTrackers()
    xpAvailable = session.previous ~= nil
    ready = true
    dirty = true
    Render()
end

local function ResetTracker(tracker)
    if not ready or not session then return end
    local now = GetTime()
    if tracker == "all" then
        StartSession(true, false)
        session.reset = true
    elseif tracker == "xp" then
        session.started = now
        session.gained = 0
        session.previous = Snapshot()
        session.lastKillXP = nil
        session.discontinuous = nil
        session.reset = true
        xpAvailable = session.previous ~= nil
        Render()
    elseif tracker == "gold" then
        local balance = GetMoney()
        moneyAvailable = IsNumber(balance) and balance >= 0
        session.moneyInitial = moneyAvailable and balance or nil
        session.moneyStarted = now
        session.moneyNet = 0
        session.lootRecords = {}
        session.bagCounts = BagCounts()
        session.lootValue = 0
        Render()
    elseif tracker == "honor" then
        honorCurrent = HonorSnapshot()
        session.honor = honorCurrent and {started = now, gained = 0, previous = honorCurrent} or nil
        Render()
    elseif tracker == "reputation" then
        ReadOtherTrackers()
        for id, record in pairs(session.reputations or {}) do
            local getFaction = C_Reputation and C_Reputation.GetFactionDataByID
            local data = getFaction and getFaction(id)
            if data and IsNumber(data.currentStanding) then
                record.started = now
                record.initial = data.currentStanding
                record.gained = 0
            end
        end
        Render()
    end
    dirty = true
end

for _, action in ipairs(resetActions) do
    local tracker = action.tracker
    action.button:SetScript("OnClick", function()
        ResetTracker(tracker)
        resetMenu:Hide()
        GameTooltip:Hide()
    end)
end

resetButton:SetScript("OnClick", function()
    if not ready then return end
    if resetMenu:IsShown() then
        resetMenu:Hide()
    else
        resetMenu:ClearAllPoints()
        resetMenu:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -3)
        resetMenu:Show()
    end
end)
resetButton:SetScript("OnEnter", function(self)
    hovered, hoverExitAt = true, nil
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Reset tracking", 1, 0.82, 0.25)
    GameTooltip:AddLine("Choose all trackers or reset XP, gold, honor, or reputation individually.", 1, 1, 1, true)
    GameTooltip:Show()
end)
resetButton:SetScript("OnLeave", function()
    hoverExitAt = GetTime() + 0.15
    GameTooltip:Hide()
end)

frame:SetScript("OnDragStart", function(self)
    if db and not db.locked then
        GameTooltip:Hide()
        resetButton:Hide()
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then SavePosition() end
    if ready and hovered then resetButton:Show() end
end)
frame:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
        if addon.category and Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(addon.category:GetID())
        elseif addon.category then
            print("Forever Session: the settings panel is not available.")
        end
    end
end)
local tooltipDetailed
local function RefreshFrameTooltip()
    if not hovered or not frame:IsMouseOver() then return end
    local detailed = IsAltKeyDown and IsAltKeyDown() or false
    if tooltipDetailed == detailed and GameTooltip:IsShown() then return end
    tooltipDetailed = detailed
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:SetText(detailed and "Forever Session — Details" or "Forever Session", 1, 0.82, 0.25)
    if session then
        local current = session.previous
        if options.showXP then
            if current and current.maximum > 0 then
                GameTooltip:AddLine(string.format("Current level progress: %s / %s XP", FormatNumber(current.xp), FormatNumber(current.maximum)), 1, 1, 1)
            end
            if IsNumber(session.lastKillXP) and session.lastKillXP > 0 then
                GameTooltip:AddLine("Most recent creature XP: " .. FormatNumber(session.lastKillXP), 1, 1, 1)
            else
                GameTooltip:AddLine("Kill estimate is waiting for a creature XP award.", 0.7, 0.7, 0.7)
            end
            if session.discontinuous then
                GameTooltip:AddLine("A multi-level jump was detected; skipped levels are excluded from session XP.", 1, 0.5, 0.2, true)
            end
            if detailed then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("XP RATE", 1, 0.82, 0.25)
                GameTooltip:AddLine("All XP since login or reset ÷ elapsed time, including idle time.", 0.75, 0.75, 0.75, true)
                GameTooltip:AddLine("NEXT LEVEL", 1, 0.82, 0.25)
                GameTooltip:AddLine("XP remaining ÷ your session XP/hour rate.", 0.75, 0.75, 0.75, true)
                GameTooltip:AddLine("KILLS TO LEVEL", 1, 0.82, 0.25)
                GameTooltip:AddLine("XP remaining ÷ XP from your last creature kill.", 0.75, 0.75, 0.75, true)
                GameTooltip:AddLine("PROGRESS BAR", 1, 0.82, 0.25)
                GameTooltip:AddLine("Shows XP earned in the current level.", 0.75, 0.75, 0.75, true)
            end
            local potentialXP, completedQuestXP = PotentialQuestXP()
            GameTooltip:AddLine("QUEST XP", 1, 0.82, 0.25)
            GameTooltip:AddDoubleLine("Potential from quest log", potentialXP and (FormatNumber(potentialXP) .. " XP") or "Unavailable", 0.75, 0.75, 0.75, 1, 1, 1)
            GameTooltip:AddDoubleLine("Completed quests", completedQuestXP and (FormatNumber(completedQuestXP) .. " XP") or "Unavailable", 0.75, 0.75, 0.75, 1, 1, 1)
            if detailed then
                GameTooltip:AddLine("Completed XP is the reward total for complete quests still in your log.", 0.7, 0.7, 0.7, true)
            end
        end
        if options.showReputation then
            GameTooltip:AddLine(watchedFaction and watchedFaction.name or "Choose a watched faction in the Reputation panel.", 1, 1, 1, true)
            if detailed then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("REPUTATION", 1, 0.82, 0.25)
                GameTooltip:AddLine("Net change toward the next standing. Each faction keeps its own timer.", 0.75, 0.75, 0.75, true)
            end
        end
        if options.showHonor and detailed then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("HONOR", 1, 0.82, 0.25)
            GameTooltip:AddLine(honorCurrent and honorCurrent.source == "rank" and "Forever PvP rank points toward the next rank." or "Progress toward the next supported honor level.", 0.75, 0.75, 0.75, true)
        end
        for _, key in ipairs({"honor", "reputation"}) do
            local group = groups[key]
            if group.enabled and group.bar then
                GameTooltip:AddLine((key == "honor" and "Honor" or "Reputation") .. " progress: " ..
                    FormatNumber(group.bar.xp) .. " / " .. FormatNumber(group.bar.maximum), 1, 1, 1)
            end
        end
        if options.showGold and moneyAvailable then
            GameTooltip:AddLine("Unsold loot value: " .. FormatMoney(session.lootValue or 0), 1, 0.82, 0.25)
            GameTooltip:AddLine("Money tracking duration: " .. FormatDuration(GetTime() - session.moneyStarted), 0.7, 0.7, 0.7)
            if detailed then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("GOLD RATE", 1, 0.82, 0.25)
                GameTooltip:AddLine("Net money change ÷ tracking time; optionally includes unsold loot.", 0.75, 0.75, 0.75, true)
                GameTooltip:AddLine("Purchases, repairs, trades, and mail affect your balance.", 0.75, 0.75, 0.75, true)
            end
        end
    end
    if detailed then
        GameTooltip:AddLine(db and db.locked and "The panel is locked. Use /fs unlock to move it." or "Left-drag to move the panel; use /fs lock to keep it in place.", 0.75, 0.75, 0.75)
        GameTooltip:AddLine("Right-click the panel to open settings.", 0.75, 0.75, 0.75)
        GameTooltip:AddLine("Hold Alt while hovering for these descriptions.", 0.75, 0.75, 0.75)
    else
        GameTooltip:AddLine("Hold Alt for details · Right-click for settings", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end

frame:SetScript("OnEnter", function(self)
    hovered, hoverExitAt, tooltipDetailed = true, nil, nil
    if ready then resetButton:Show() end
    ShowWhen(highlight, options and options.hoverHighlight)
    RefreshFrameTooltip()
end)
frame:SetScript("OnLeave", function()
    -- Brief grace allows moving across the small gap to the reset button.
    hoverExitAt = GetTime() + 0.15
    GameTooltip:Hide()
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then
            if db and addon.RegisterOptions and addon.RegisterOptions() then self:UnregisterEvent("ADDON_LOADED") end
            return
        end
        if type(ForeverSessionDB) ~= "table" then ForeverSessionDB = {} end
        db = ForeverSessionDB
        if not IsNumber(db.x) then db.x = 0 end
        if not IsNumber(db.y) then db.y = 160 end
        addon.ApplyAppearance()
        if addon.RegisterOptions and addon.RegisterOptions() then self:UnregisterEvent("ADDON_LOADED") end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local initialLogin, reloadingUI = ...
        if not ready then
            StartSession(initialLogin, reloadingUI)
            local currentLevel = UnitLevel("player")
            if IsNumber(currentLevel) then lastCelebratedLevel = currentLevel end
        end
        dirty = true
    elseif event == "PLAYER_XP_UPDATE" then
        local unit = ...
        if unit == "player" then dirty = true end
    elseif event == "PLAYER_LEVEL_UP" then
        -- Sample on the next rendered frame so UnitLevel/UnitXP agree after rollover.
        dirty = true
        local newLevel = ...
        if ready and IsNumber(newLevel) and newLevel > 0
            and (not lastCelebratedLevel or newLevel > lastCelebratedLevel) then
            lastCelebratedLevel = newLevel
            addon.PlayLevelUp(newLevel)
        end
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        RecordKillXP(...)
    elseif event == "QUEST_LOG_UPDATE" then
        tooltipDetailed = nil
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        if db then addon.ApplyAppearance() end
    elseif event == "UPDATE_FACTION" or event == "FACTION_STANDING_CHANGED" or event == "HONOR_XP_UPDATE"
        or event == "HONOR_LEVEL_UPDATE" or event == "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" then
        dirty = true
    elseif event == "PLAYER_MONEY" then
        dirty = true
    elseif event == "CHAT_MSG_LOOT" then
        QueueLoot(...)
    elseif event == "BAG_UPDATE_DELAYED" then
        bagsDirty = true
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        bagsDirty = true
    elseif event == "PLAYER_LOGOUT" then
        if ready then ReadXP(); ReadMoney(); ReadLootValue(); ReadOtherTrackers() end
        if db then SavePosition() end
    end
end)

frame:SetScript("OnUpdate", function(_, elapsed)
    if hovered then
        if frame:IsMouseOver() or resetButton:IsMouseOver() then
            hoverExitAt = nil
            if frame:IsMouseOver() then RefreshFrameTooltip() end
        else
            hoverExitAt = hoverExitAt or GetTime() + 0.15
            if GetTime() >= hoverExitAt then
                hovered, hoverExitAt = false, nil
                tooltipDetailed = nil
                resetButton:Hide()
                highlight:Hide()
            end
        end
    end
    if not ready then return end
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if dirty or bagsDirty or elapsedSinceUpdate >= 1 or lastLayoutScale ~= frame:GetEffectiveScale() then
        -- Bag contents must settle before consuming pending loot messages.
        if bagsDirty or elapsedSinceUpdate >= 1 then ReadLootValue() end
        bagsDirty = false
        dirty = false
        elapsedSinceUpdate = 0
        ReadMoney()
        xpAvailable = ReadXP()
        ReadOtherTrackers()
        Render()
    end
end)

for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_LOG_UPDATE", "PLAYER_MONEY", "CHAT_MSG_LOOT", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "PLAYER_LOGOUT", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "UPDATE_FACTION", "FACTION_STANDING_CHANGED", "HONOR_XP_UPDATE", "HONOR_LEVEL_UPDATE", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" }) do
    frame:RegisterEvent(event)
end

SLASH_FOREVERSESSION1 = "/fs"
SLASH_FOREVERSESSION2 = "/foreversession"
SlashCmdList.FOREVERSESSION = function(message)
    if not db then return end
    local command = message:lower():match("^%s*(.-)%s*$")
    if command == "lock" then
        if addon.lockSetting then addon.lockSetting:SetValue(true) else db.locked = true end
    elseif command == "unlock" then
        if addon.lockSetting then addon.lockSetting:SetValue(false) else db.locked = false end
    elseif command == "center" then
        addon.Center()
    elseif command == "" or command == "options" then
        if addon.category then
            Settings.OpenToCategory(addon.category:GetID())
        else
            print("Forever Session: the addon options page is not available yet.")
        end
        return
    else
        print("|cffffd145Forever Session:|r /fs lock, /fs unlock, /fs center. Left-drag the text to move it.")
        return
    end
    print("|cffffd145Forever Session:|r " .. (command == "center" and "Position restored." or (db.locked and "Locked." or "Unlocked.")))
end

-- Manual level-up effect previews.
do
local built, effects = false, {}
local messageText = ""

local function Atlas(texture, name)
    if not C_Texture.GetAtlasInfo(name) then return false end
    texture:SetAtlas(name, false)
    return true
end

local function Animation(group, kind, order, duration)
    local animation = group:CreateAnimation(kind)
    animation:SetOrder(order)
    animation:SetDuration(duration)
    animation:SetSmoothing("IN_OUT")
    return animation
end

local function Fade(region, peak, hold)
    region:SetAlpha(0)
    region:Hide()
    local group = region:CreateAnimationGroup()
    local first = Animation(group, "Alpha", 1, 0.2)
    first:SetFromAlpha(0)
    first:SetToAlpha(peak)
    first:SetEndDelay(hold or 0.3)
    local last = Animation(group, "Alpha", 2, 0.8)
    last:SetFromAlpha(peak)
    last:SetToAlpha(0)
    group:SetScript("OnPlay", function() region:Show() end)
    group:SetScript("OnFinished", function() region:Hide() end)
    group:SetScript("OnStop", function() region:Hide() end)
    return group
end

local function Build()
    if built then return end
    built = true
    local panel = addon.GetEffectTargets()
    local function Layer(name, behind)
        local region = CreateFrame("Frame", "ForeverSessionEffect" .. name, panel)
        region:SetAllPoints(panel)
        if behind then region:SetFrameLevel(panel:GetFrameLevel()) end
        region:EnableMouse(false)
        return region
    end

    local pulse = Layer("Pulse")
    local pulseAvailable = true
    for _, point in ipairs({"TOPLEFT", "BOTTOMLEFT"}) do
        local texture = pulse:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("BOTTOMLEFT", panel, point, 0, 0)
        texture:SetPoint("BOTTOMRIGHT", panel, point == "TOPLEFT" and "TOPRIGHT" or "BOTTOMRIGHT", 0, 0)
        texture:SetHeight(PixelSize(8, 2))
        StableTexture(texture)
        texture:SetBlendMode("ADD")
        pulseAvailable = Atlas(texture, "levelup-bar-gold") and pulseAvailable
    end
    effects.pulse = {group = Fade(pulse, 1, 0.2), available = pulseAvailable}

    local glow = Layer("Glow", true)
    local glowTexture = glow:CreateTexture(nil, "BACKGROUND")
    glowTexture:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    glowTexture:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 1)
    glowTexture:SetBlendMode("ADD")
    effects.glow = {group = Fade(glow, 0.5, 0.4), available = Atlas(glowTexture, "levelup-glow-gold")}

    local message = Layer("Message")
    local label = message:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE")
    label:SetTextColor(1, 0.84, 0.42)
    label:SetPoint("BOTTOM", panel, "TOP", 0, 10)
    effects.message = {group = Fade(message, 1, 0.9), available = true, label = label}

    effects.message.region = message
    local function FinishMessage()
        message:Hide()
        message:SetScript("OnUpdate", nil)
        label:SetText(messageText)
    end
    effects.message.group:SetScript("OnFinished", FinishMessage)
    effects.message.group:SetScript("OnStop", FinishMessage)


end

function addon.StopEffects()
    for _, effect in pairs(effects) do effect.group:Stop() end
    if effects.message then
        effects.message.region:SetScript("OnUpdate", nil)
        effects.message.label:SetText(messageText)
    end
end

local function StartShimmer()
    local started = GetTime()
    local label = effects.message.label
    local count = #messageText -- LEVEL and the numeric level contain ASCII only.
    effects.message.region:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - started
        if elapsed >= 1.4 then
            label:SetText(messageText)
            self:SetScript("OnUpdate", nil)
            return
        end
        -- Sweep a narrow warm-white highlight through the actual glyphs.
        local center = -2 + elapsed / 1.4 * (count + 4)
        local letters = {}
        for index = 1, count do
            local strength = math.max(0, 1 - math.abs(index - center) / 1.6)
            local green = math.floor((0.84 + 0.16 * strength) * 255 + 0.5)
            local blue = math.floor((0.42 + 0.53 * strength) * 255 + 0.5)
            letters[index] = string.format("|cffff%02x%02x%s|r", green, blue, messageText:sub(index, index))
        end
        label:SetText(table.concat(letters))
    end)
end

local function PlayCelebration(level)
    Build()
    addon.StopEffects()
    messageText = "LEVEL " .. math.floor(level)
    effects.message.label:SetText(messageText)
    for _, key in ipairs({"pulse", "glow", "message"}) do
        if effects[key].available then effects[key].group:Play() end
    end
    StartShimmer()
end

function addon.PlayLevelUp(level)
    local options = addon.GetOptions()
    if not options or not options.levelUpEffects then return end
    -- Use the event level; UnitLevel can still report the previous level here.
    PlayCelebration(level)
end

function addon.PreviewLevelUp()
    local options = addon.GetOptions()
    if not options or not options.debugEffects then return end
    local level = UnitLevel("player")
    if (issecretvalue and issecretvalue(level)) or type(level) ~= "number" then return end
    -- Preview independently of the automatic-effects toggle and level-event deduplication.
    PlayCelebration(level)
end

end
