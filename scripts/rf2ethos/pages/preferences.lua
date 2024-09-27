local function postLoad(self)
    rf2ethos.app.triggers.closeProgressLoader = true
end

local function openPage(idx, title, script)
    rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages
    rf2ethos.app.triggers.isReady = false

    rf2ethos.app.lastIdx = idx
    rf2ethos.app.lastTitle = title
    rf2ethos.app.lastScript = script
    -- rf2ethos.app.Page = nil

    form.clear()

    local w, h = rf2ethos.utils.getWindowSize()

    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.app.radio.navButtonOffset ~= nil then colStart = colStart - rf2ethos.app.radio.navButtonOffset end

    if rf2ethos.app.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.app.radio.buttonWidth
    end
    buttonH = rf2ethos.app.radio.navbuttonHeight

    local x = w

    line = form.addLine("Preferences")

    rf2ethos.app.formNavigationFields['menu'] = form.addButton(line, {x = x - (buttonW + padding) * 1, y = rf2ethos.app.radio.linePaddingTop, w = buttonW, h = buttonH}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.app.lastIdx = nil
            rf2ethos.lastPage = nil

            if rf2ethos.app.Page and rf2ethos.app.Page.onNavMenu then rf2ethos.app.Page.onNavMenu(rf2ethos.app.Page) end

            rf2ethos.app.ui.openMainMenu()
        end
    })
    rf2ethos.app.formNavigationFields['menu']:focus()

    local uipanel = form.addExpansionPanel("User interface")
    uipanel:open(true)

    rf2ethos.config.audioParam = rf2ethos.app.preferences.interface.audio
    if rf2ethos.config.audioParam == nil or rf2ethos.config.audioParam == "" then rf2ethos.config.audioParam = 0 end

    line = uipanel:addLine("Audio")
    rf2ethos.app.formFields[0] = form.addChoiceField(line, nil, {{"All", 0}, {"Alerts", 1}, {"Disable", 2}}, function()
        return rf2ethos.config.audioParam
    end, function(newValue)
        rf2ethos.config.audioParam = newValue
        rf2ethos.app.preferences.interface.audio = newValue
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    rf2ethos.config.iconsizeParam = rf2ethos.app.preferences.interface.iconSize
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then rf2ethos.config.iconsizeParam = 1 end

    line = uipanel:addLine("Button style")
    rf2ethos.app.formFields[1] = form.addChoiceField(line, nil, {{"Text", 0}, {"Small image", 1}, {"Large images", 2}}, function()
        return rf2ethos.config.iconsizeParam
    end, function(newValue)
        rf2ethos.config.iconsizeParam = newValue
        rf2ethos.app.preferences.interface.iconSize = newValue
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    -- PROFILE
    rf2ethos.config.profileswitchParamPreference = rf2ethos.app.preferences.advanced.profileSwitch
    if rf2ethos.config.profileswitchParamPreference ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.profileswitchParamPreference, ",")
        rf2ethos.config.profileswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = uipanel:addLine("Switch profile")
    rf2ethos.app.formFields[2] = form.addSourceField(line, nil, function()
        return rf2ethos.config.profileswitchParam
    end, function(newValue)
        rf2ethos.config.profileswitchParam = newValue
        local member = rf2ethos.config.profileswitchParam:member()
        local category = rf2ethos.config.profileswitchParam:category()
        rf2ethos.app.preferences.advanced.profileSwitch = category .. "," .. member        
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    -- RATES
    rf2ethos.config.rateswitchParamPreference = rf2ethos.app.preferences.advanced.rateSwitch
    if rf2ethos.config.rateswitchParamPreference ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.rateswitchParamPreference, ",")
        rf2ethos.config.rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = uipanel:addLine("Switch rates")
    rf2ethos.app.formFields[3] = form.addSourceField(line, nil, function()
        return rf2ethos.config.rateswitchParam
    end, function(newValue)
        rf2ethos.config.rateswitchParam = newValue
        local member = rf2ethos.config.rateswitchParam:member()
        local category = rf2ethos.config.rateswitchParam:category()
        rf2ethos.app.preferences.advanced.rateSwitch = category .. "," .. member         
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    local advpanel = form.addExpansionPanel("Advanced")
    advpanel:open(true)

    -- TIMEOUT
    rf2ethos.config.watchdogParam = rf2ethos.app.preferences.advanced.watchdog
    if rf2ethos.config.watchdogParam == nil or rf2ethos.config.watchdogParam == "" then rf2ethos.config.watchdogParam = 15 end
    line = advpanel:addLine("Timeout")
    rf2ethos.app.formFields[4] = form.addChoiceField(line, nil, {{"Default", 15}, {"10s", 10}, {"15s", 15}, {"20s", 20}, {"25s", 25}, {"30s", 30}}, function()
        return rf2ethos.config.watchdogParam
    end, function(newValue)
        rf2ethos.config.watchdogParam = newValue
        rf2ethos.app.preferences.advanced.watchdog = newValue
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    -- COMPILATION
    rf2ethos.config.compilationParam = rf2ethos.app.preferences.advanced.compilation
    if rf2ethos.config.compilationParam == nil or rf2ethos.config.compilationParam == "" then rf2ethos.config.compilationParam = 0 end
    line = advpanel:addLine("Compilation")
    rf2ethos.app.formFields[5] = form.addChoiceField(line, nil, {{"Enable", 0}, {"Disable", 1}, {"Use switch", 2}}, function()
        return tonumber(rf2ethos.config.compilationParam)
    end, function(newValue)
        rf2ethos.config.compilationParam = newValue
        rf2ethos.app.preferences.advanced.compilation = newValue
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)

        if newValue == 2 then
            rf2ethos.app.formFields[6]:enable(true)
        else
            rf2ethos.app.formFields[6]:enable(false)
        end

    end)

    -- COMPILATION SWITCH
    rf2ethos.config.compilationswitchParamPreference = rf2ethos.app.preferences.advanced.compilationSwitch
    if rf2ethos.config.compilationswitchParamPreference ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.compilationswitchParamPreference, ",")
        rf2ethos.config.compilationswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = advpanel:addLine("   Switch")
    rf2ethos.app.formFields[6] = form.addSwitchField(line, nil, function()
        return rf2ethos.config.compilationswitchParam
    end, function(newValue)
        rf2ethos.config.compilationswitchParam = newValue
        local member = rf2ethos.config.compilationswitchParam:member()
        local category = rf2ethos.config.compilationswitchParam:category()
        rf2ethos.app.preferences.advanced.compilationSwitch = category .. "," .. member         
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    if tonumber(rf2ethos.config.compilationParam) == 2 then
        rf2ethos.app.formFields[6]:enable(true)
    else
        rf2ethos.app.formFields[6]:enable(false)
    end

    -- DEMO MODE
    rf2ethos.config.demoswitchParamPreference = rf2ethos.app.preferences.advanced.demoSwitch
    if rf2ethos.config.demoswitchParamPreference ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.demoswitchParamPreference, ",")
        rf2ethos.config.demoswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = advpanel:addLine("Demo mode")
    rf2ethos.app.formFields[7] = form.addSwitchField(line, nil, function()
        return rf2ethos.config.demoswitchParam
    end, function(newValue)
        rf2ethos.config.demoswitchParam = newValue
        local member = rf2ethos.config.demoswitchParam:member()
        local category = rf2ethos.config.demoswitchParam:category()
        rf2ethos.app.preferences.advanced.demoSwitch = category .. "," .. member         
        rf2ethos.ini.save(rf2ethos.config.toolDir .. 'preferences.ini',rf2ethos.app.preferences)
    end)

    postLoad()

end

return {title = "Preferences", openPage = openPage}
