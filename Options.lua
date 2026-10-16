local _, addon = ...

function addon.RegisterOptions()
    if addon.category then return true end
    if not Settings or not Settings.RegisterVerticalLayoutCategory then return false end
    local options, db = addon.GetOptions()
    if not options then return false end
    local category, layout = Settings.RegisterVerticalLayoutCategory("Forever Session")
    addon.category = category
    local appearanceSettings = {}

    local function Header(name, description)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name, description))
    end

    local function Register(key, label, default, storage)
        local setting = Settings.RegisterAddOnSetting(category, "ForeverSession_" .. key,
            key, storage or options, type(default), label, default)
        setting:SetValueChangedCallback(function()
            if key == "debugEffects" and addon.StopEffects then addon.StopEffects() end
            if key == "levelUpEffects" and not options.levelUpEffects and addon.StopEffects then addon.StopEffects() end
            addon.ApplyAppearance()
        end)
        if key ~= "locked" then appearanceSettings[key] = setting end
        return setting
    end

    local function Check(key, label, tooltip)
        local setting = Register(key, label, addon.defaults[key])
        return Settings.CreateCheckbox(category, setting, tooltip)
    end

    local function Slider(key, label, minimum, maximum, step, tooltip, suffix)
        local setting = Register(key, label, addon.defaults[key])
        local sliderOptions = Settings.CreateSliderOptions(minimum, maximum, step)
        sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return string.format("%d%s", value, suffix or "")
        end)
        Settings.CreateSlider(category, setting, sliderOptions, tooltip)
    end

    local function Color(key, label, tooltip)
        local setting = Register(key, label, addon.defaults[key])
        Settings.CreateColorSwatch(category, setting, tooltip)
    end

    Header("Layout", "Changes apply immediately and are saved for this character. Left-drag the panel to move it.")
    addon.lockSetting = Register("locked", "Lock position", false, db)
    Settings.CreateCheckbox(category, addon.lockSetting, "Prevent dragging. The panel remains readable and its tooltip still works.")
    Slider("scale", "Scale", 60, 180, 5, "Scale the whole panel while keeping its screen position.", "%")
    Slider("width", "Width", 180, 420, 10, "Minimum panel width. The panel grows if needed to fit large values.", "")
    Slider("fontSize", "Number size", 18, 42, 1, "Resize the rate in every tracker group. The panel height adjusts automatically.", "")
    Slider("barHeight", "Bar height", 1, 16, 1, "Adjust the height of the XP, honor, and reputation progress bars. The panel grows to keep spacing balanced. Default: 2.", "")
    Check("outline", "Number outline", "Add a thin outline to each tracker rate.")
    Check("detailOutline", "Text outline", "Outline all other panel text: title, labels, timer, level and kill estimates, and gold value. Coin icons keep their native appearance.")

    Header("Tracking", "Rates run from login or their individual reset, include idle time, and survive /reload.")
    Check("showXP", "XP", "Show the XP group with its rate, level progress, estimates, and total.")
    Check("showGold", "Gold", "Show the gold group with native coin icons and net money total. Spending can make the rate negative. Gold has no progress bar.")
    Check("showHonor", "Honor", "Show the honor group with its rate, PvP rank progress, estimate, and total.")
    Check("showReputation", "Reputation", "Show the watched faction, reputation rate, next-standing progress, estimate, and total. Choose a watched faction in the game's Reputation panel.")
    Check("showTimeToLevel", "Time to milestone", "Show the next-milestone estimate inside each relevant group: level, PvP rank, or reputation standing.")
    Check("showKillsToLevel", "Kills to level", "Show kills remaining based on your most recent creature XP award. Displays — until the first creature XP award.")
    Check("includeLootValue", "Include loot value", "Add the vendor sell value of items looted this session that are still in your bags. Items with no sell price add nothing. Selling an item replaces its estimated value with actual money, so it is not counted twice. Banked, equipped, consumed, or discarded items no longer add bag value.")
    Check("showFooter", "Session totals", "Show totals within each tracker group and one shared session time at the bottom.")
    Check("showProgress", "Progress bar", "Show a progress bar in each relevant tracker group. Gold has no bar.")

    Header("Appearance", "Show or hide the panel decorations. Changes apply immediately.")
    Check("levelUpEffects", "Level-up effects", "Play the gold pulse, gold glow, and shimmering new-level message together on level-up. Enabled by default, independently of Debug previews.")
    Check("showGoldTrim", "Gold trim", "Draw the native level-up gold bar at the top and bottom of the panel. Independent of background and border opacity. Enabled by default.")
    Check("showBackground", "Background", "Draw a background behind the text.")
    Slider("backgroundOpacity", "Background opacity", 0, 100, 5, "0% is transparent; 100% is opaque. Text stays fully visible.", "%")
    Check("showBorder", "Border", "Draw a fine border inside the panel bounds.")
    Slider("borderOpacity", "Border opacity", 0, 100, 5, "Adjust the strength of all four border edges.", "%")
    Check("showTitle", "Title", "Show a small session heading above the rate.")
    Check("hoverHighlight", "Hover highlight", "Add a subtle accent tint when the mouse is over the panel.")

    Header("Colors", "Click a swatch to choose a color. Cancel in the color picker restores the previous color.")
    Color("rateColor", "Rate color", "Color of each tracker rate and positive gold value. Losses use red.")
    Color("accentColor", "Accent color", "Color of the title, border, level-time estimate, and hover highlight.")
    Color("detailColor", "Text color", "Color of labels, session totals, and elapsed time.")
    Color("backgroundColor", "Background color", "Panel background color. Use the opacity slider to set transparency.")
    Color("progressColor", "XP bar color", "Color of the XP progress bar.")

    Color("honorColor", "Honor bar color", "Red by default, with the same subtle gradient as the other progress bars.")
    Color("reputationColor", "Reputation bar color", "Dark green by default, with the same subtle gradient as the other progress bars.")

    Header("Debug", "Preview the full level-up celebration without changing your stats.")
    local debugToggle = Check("debugEffects", "Debug previews", "Enable the level-up preview button below. Off by default. Turning this off stops an active effect.")
    local preview = CreateSettingsButtonInitializer("Level-up effect", "Preview level-up", addon.PreviewLevelUp,
        "Play the gold pulse, gold glow, and shimmering level message together. Preview works even when automatic effects are disabled.", true)
    preview:SetParentInitializer(debugToggle, function() return options.debugEffects end)
    layout:AddInitializer(preview)

    Header("Reset", "These controls preserve all tracking totals and timers.")
    layout:AddInitializer(CreateSettingsButtonInitializer("Position", "Recenter", addon.Center,
        "Move the panel above the center of the screen without changing its appearance.", true))
    layout:AddInitializer(CreateSettingsButtonInitializer("Appearance", "Reset appearance", function()
        for key, setting in pairs(appearanceSettings) do
            setting:SetValue(addon.defaults[key], true)
        end
    end, "Restore the default size, colors, opacity, and display elements. Position and lock state are preserved.", true))
    Settings.RegisterAddOnCategory(category)
    return true
end
