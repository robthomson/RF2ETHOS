local ui = {}

function ui.showProgressDialog()
    -- show progress dialog
	if rf2ethos.config.progressDialogStyle == 1 then
		rf2ethos.dialogs.progressDisplay = true
		rf2ethos.dialogs.progressWatchDog = os.clock()
		rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller. ")
		rf2ethos.dialogs.progress:value(0)
		rf2ethos.dialogs.progress:closeAllowed(false)
	end
end

function ui.openMainMenu()

    local MainMenu = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages.lua"))()

    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

    -- clear all nav vars
    rf2ethos.lastIdx = nil
    rf2ethos.lastSubPage = nil
    rf2ethos.lastTitle = nil
    rf2ethos.lastScript = nil
    rf2ethos.lastPage = nil

    -- reset page to nil as should be nil on this page
    -- rf2ethos.Page = nil

    rf2ethos.triggers.mspDataLoaded = false
    rf2ethos.uiState = rf2ethos.uiStatus.mainMenu
    rf2ethos.triggers.escPowerCycle = false
    rf2ethos.escMenuState = 0

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/iconsize")
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end

    local sc
    local panel

    form.clear()

    for idx, value in ipairs(MainMenu.sections) do

        local sc = value.section

        form.addLine(value.title)

        lc = 0
        for pidx, pvalue in ipairs(MainMenu.pages) do
            if pvalue.section == value.section then

                if lc == 0 then
                    if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
                    if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
                    if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.radio.buttonPadding end
                end

                if lc >= 0 then x = (buttonW + padding) * lc end

                if rf2ethos.config.iconsizeParam ~= 0 then
                    if rf2ethos.gfx_buttons[pidx] == nil then rf2ethos.gfx_buttons[pidx] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/menu/" .. pvalue.image) end
                else
                    rf2ethos.gfx_buttons[pidx] = nil
                end

                form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                    text = pvalue.title,
                    icon = rf2ethos.gfx_buttons[pidx],
                    options = FONT_S,
                    paint = function()
                    end,
                    press = function()				
                        if pvalue.script == "pids.lua" then
                            ui.showProgressDialog()
                            rf2ethos.ui.openPagePIDLoader(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "servos.lua" then
                            ui.showProgressDialog()
                            rf2ethos.ui.openPageSERVOSLoader(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "rates.lua" and pvalue.subpage == 1 then
                            ui.showProgressDialog()
                            rf2ethos.ui.openPageRATESLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                        elseif pvalue.script == "esc.lua" then
							ui.showProgressDialog()
                            rf2ethos.ui.openPageESC(pidx, pvalue.title, pvalue.script)
							rf2ethos.triggers.closeProgress = true
                        elseif pvalue.script == "preferences.lua" then
							ui.showProgressDialog()
                            rf2ethos.ui.openPagePreferences(pidx, pvalue.title, pvalue.script)
							rf2ethos.triggers.closeProgress = true
                        else
                            ui.showProgressDialog()
                            rf2ethos.ui.openPageDefaultLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                        end
                    end
                })

                lc = lc + 1

                if lc == numPerRow then lc = 0 end
            end
        end

    end
end

function ui.openPageRATESLoader(idx, subpage, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
    collectgarbage()

    -- rf2ethos.dialogs.progressDisplay = true
    -- rf2ethos.dialogs.progressWatchDog = os.clock()
    -- rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    -- rf2ethos.dialogs.progress:value(0)
    -- rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.lastPage = script

    rf2ethos.triggers.isLoading = true
    -- rf2ethos.utils.log("Finished: rf2ethos.ui.openPageRATESLoader")
end

function ui.openPageRATES(idx, subpage, title, script)

    if rf2ethos.Page.fields then
        local v = rf2ethos.Page.fields[13].value
        if v ~= nil then rf2ethos.activeRateTable = math.floor(v) end

        if rf2ethos.activeRateTable ~= nil then
            if rf2ethos.activeRateTable ~= rf2ethos.RateTable then
                rf2ethos.RateTable = rf2ethos.activeRateTable

                if rf2ethos.dialogs.progressDisplay == true then
                    rf2ethos.dialogs.progressWatchDog = nil
                    rf2ethos.dialogs.progressDisplay = false
                    rf2ethos.dialogs.progress:close()
                end
                rf2ethos.ui.openPageRATESLoader(idx, subpage, title, script)

            end
        end
    end

    rf2ethos.config.rateswitchParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/rateswitch")
    if rf2ethos.config.rateswitchParam ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.rateswitchParam, ",")
        rf2ethos.config.rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    longPage = false

    form.clear()

    rf2ethos.ui.fieldHeader(title)

    local numCols = #rf2ethos.Page.cols
    local screenWidth = rf2ethos.config.lcdWidth - 10
    local padding = 10
    local paddingTop = rf2ethos.radio.linePaddingTop
    local h = rf2ethos.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine(rf2ethos.Page.rTableName)

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = rf2ethos.Page.cols[loc]
        tsizeW, tsizeH = lcd.getTextSize(colLabel)
        pos = {x = posX - tsizeW + paddingRight, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    for ri, rv in ipairs(rf2ethos.Page.rows) do _G["rf2ethos_RATEROWS_" .. ri] = form.addLine(rv) end

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageIdx = i
        local currentField = i

        if f.subpage == 1 then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * rf2ethos.utils.decimalInc(f.decimals)
            maxValue = f.max * rf2ethos.utils.decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end

            field = form.addNumberField(_G["rf2ethos_RATEROWS_" .. f.row], pos, minValue, maxValue, function()
                local value = rf2ethos.getFieldValue(f)
                return value
            end, function(value)
                f.value = rf2ethos.saveFieldValue(f, value)
                rf2ethos.saveValue(i)
            end)
            if f.default ~= nil then
                local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
                if f.mult ~= nil then default = math.floor(default * f.mult) end
                if f.scale ~= nil then default = math.floor(default / f.scale) end
                field:default(default)
            else
                field:default(0)
            end
            if f.decimals ~= nil then field:decimals(f.decimals) end
            if f.unit ~= nil then field:suffix(f.unit) end
            if f.step ~= nil then field:step(f.step) end
            if f.help ~= nil then
                if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                    local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                    field:help(helpTxt)
                end
            end
        end
    end

    -- if rf2ethos.dialogs.progressDisplay == true then
    --	rf2ethos.triggers.closeProgress = true
    -- end

end

function ui.openPageESC(idx, title, script)

    -- rf2ethos.utils.log("openrf2ethos.PageESC")

    rf2ethos.escMenuState = 1

    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

    rf2ethos.triggers.mspDataLoaded = false
    rf2ethos.uiState = rf2ethos.uiStatus.mainMenu
    rf2ethos.triggers.escPowerCycle = false

    form.clear()

    rf2ethos.lastIdx = idx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    ESC = {}

    rf2ethos.escMode = true

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/iconsize")
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local padding = rf2ethos.radio.buttonPadding

    local sc
    local panel

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW

    field = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.lastIdx = nil
            rf2ethos.lastPage = nil
            rf2ethos.lastSubPage = nil
            rf2ethos.escMode = false
            rf2ethos.ui.openMainMenu()
        end
    })
    field:focus()

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end

    local ESCMenu = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()

    local lc = 0
    local bx = 0

    for pidx, pvalue in ipairs(ESCMenu.pages) do

        if lc == 0 then
            if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if rf2ethos.config.iconsizeParam ~= 0 then
            if rf2ethos.esc_buttons[pidx] == nil then rf2ethos.esc_buttons[pidx] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/esc/" .. pvalue.image) end
        else
            rf2ethos.esc_buttons[pidx] = nil
        end

        form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.esc_buttons[pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.ui.showProgressDialog()
                rf2ethos.ui.openPageESCToolLoader(pvalue.folder)
            end
        })

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function ui.openPageESCToolLoader(folder)

    rf2ethos.escManufacturer = folder
    rf2ethos.escScript = nil
    rf2ethos.escMode = true

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    ESC.init = assert(compile.loadScript(rf2ethos.config.toolDir .. "esc/" .. folder .. "/init.lua"))()
    rf2ethos.triggers.escPowerCycle = ESC.init.powerCycle

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "esc/" .. folder .. "/esc_info.lua"))()

    rf2ethos.triggers.isLoading = true

end

-- initialise menu for specific type of esc
-- basically we load libraries then read
-- /scripts/rf2ethosmsp/esc/<TYPE>/pages.lua
function ui.openPageESCTool(folder)

    -- rf2ethos.utils.log("ui.openPageESCTool")

    rf2ethos.escMenuState = 2

    if rf2ethos.triggers.escPowerCycle == true then
        rf2ethos.uiState = rf2ethos.uiStatus.pages
        rf2ethos.triggers.triggerESCLOADER = true
    else
        rf2ethos.uiState = rf2ethos.uiStatus.MainMenu
    end

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight

    local y = rf2ethos.radio.linePaddingTop

    form.clear()

    line = form.addLine(rf2ethos.lastTitle .. ' / ' .. ESC.init.toolName)

    buttonW = 100
    local x = windowWidth - buttonW

    field = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.triggerESCMAINMENU = true
        end
    })
    field:focus()

    ESC.pages = assert(compile.loadScript(rf2ethos.config.toolDir .. "esc/" .. folder .. "/pages.lua"))()

    if rf2ethos.Page.escinfo then
        local model = rf2ethos.Page.escinfo[1].t
        local version = rf2ethos.Page.escinfo[2].t
        local fw = rf2ethos.Page.escinfo[3].t

        if model == "" then
            model = "UNKNOWN ESC"
            rf2ethos.escUnknown = true
        else
            rf2ethos.escUnknown = false
        end

        if rf2ethos.triggers.escPowerCycle == true and model == "UNKNOWN ESC" then

            if rf2ethos.triggers.escPowerCycleAnimation == nil or rf2ethos.triggers.escPowerCycleAnimation == "-" or rf2ethos.triggers.escPowerCycleAnimation == "" then
                rf2ethos.triggers.escPowerCycleAnimation = "+"
            else
                rf2ethos.triggers.escPowerCycleAnimation = "-"
            end

            line = form.addLine("")
            form.addStaticText(line, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.buttonHeight},
                               "Please power cycle the speed controller " .. rf2ethos.triggers.escPowerCycleAnimation)

        else
            rf2ethos.triggers.triggerESCLOADER = false
            line = form.addLine("")
            form.addStaticText(line, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.buttonHeight}, model .. " " .. version .. " " .. fw)

        end
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/iconsize")

    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end

    local lc = 0
    local bx = 0

    for pidx, pvalue in ipairs(ESC.pages) do

        if lc == 0 then
            if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if rf2ethos.config.iconsizeParam ~= 0 then
            if rf2ethos.esctool_buttons[pvalue.image] == nil then rf2ethos.esctool_buttons[pvalue.image] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/esc/" .. pvalue.image) end
        else
            rf2ethos.esctool_buttons[pvalue.image] = nil
        end

        -- rf2ethos.utils.log("x = " .. bx .. ", y = " .. y .. ", w = " .. buttonW .. ", h = " .. buttonH)
        field = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.esctool_buttons[pvalue.image],
            options = FONT_S,
            paint = function()
            end,
            press = function()
				rf2ethos.ui.showProgressDialog()
                rf2ethos.openESCFormLoader(folder, pvalue.script)
            end
        })

        if rf2ethos.escUnknown == true then field:enable(false) end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function rf2ethos.openESCFormLoader(folder, script)

    -- rf2ethos.utils.log("rf2ethos.openESCFormLoader")

    rf2ethos.escManufacturer = folder
    rf2ethos.escScript = script
    rf2ethos.escMode = true

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "esc/" .. folder .. "/pages/" .. script))()
    collectgarbage()

    -- rf2ethos.dialogs.progressDisplay = true
    -- rf2ethos.dialogs.progressWatchDog = os.clock()
    -- rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    -- rf2ethos.dialogs.progress:value(0)
    -- rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.triggers.isLoading = true

end

--
function rf2ethos.openESCForm(folder, script)

    -- rf2ethos.utils.log("rf2ethos.openESCForm")

    rf2ethos.escMenuState = 3

    local fieldAR = {}
    rf2ethos.uiState = rf2ethos.uiStatus.pages
    longPage = false
    form.clear()

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local y = rf2ethos.radio.linePaddingTop

    local w = rf2ethos.config.lcdWidth
    local h = rf2ethos.config.lcdHeight
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.radio.navButtonOffset ~= nil then colStart = colStart - rf2ethos.radio.navButtonOffset end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.buttonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight
    line = form.addLine(rf2ethos.lastTitle .. ' / ' .. ESC.init.toolName .. ' / ' .. rf2ethos.Page.title)

    rf2ethos.ui.navigationButtonsEscForm(rf2ethos.config.lcdWidth, rf2ethos.radio.linePaddingTop, buttonW, rf2ethos.radio.navbuttonHeight)

    if rf2ethos.Page.escinfo then
        local model = rf2ethos.Page.escinfo[1].t
        local version = rf2ethos.Page.escinfo[2].t
        local fw = rf2ethos.Page.escinfo[3].t
        line = form.addLine(model .. " " .. version .. " " .. fw)
    end

    formLineCnt = 0

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageValue = f
        local pageIdx = i
        local currentField = i

        rf2ethos.ui.fieldLabel(f, i, l)

        if f.table or f.type == 1 then
            rf2ethos.ui.fieldChoice(f, i)
        else
            rf2ethos.ui.fieldNumber(f, i)
        end
    end

    -- if rf2ethos.dialogs.progressDisplay == true then
    --	rf2ethos.triggers.closeProgress = true
    -- end

end

function ui.openPagePIDLoader(idx, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
    collectgarbage()

    -- rf2ethos.dialogs.progressDisplay = true
    -- rf2ethos.dialogs.progressWatchDog = os.clock()
    -- rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    -- rf2ethos.dialogs.progress:value(0)
    -- rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.lastPage = script

    rf2ethos.triggers.isLoading = true

    -- rf2ethos.utils.log("Finished: rf2ethos.ui.openPagePID")
end

function ui.openPagePID(idx, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    longPage = false

    form.clear()

    rf2ethos.ui.fieldHeader(title)
    local numCols
    if rf2ethos.Page.cols ~= nil then
        numCols = #rf2ethos.Page.cols
    else
        numCols = 6
    end
    local screenWidth = rf2ethos.config.lcdWidth - 10
    local padding = 10
    local paddingTop = rf2ethos.radio.linePaddingTop
    local h = rf2ethos.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine("")

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = rf2ethos.Page.cols[loc]
        pos = {x = posX, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    for ri, rv in ipairs(rf2ethos.Page.rows) do _G["rf2ethos_PIDROWS_" .. ri] = form.addLine(rv) end

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        minValue = f.min * rf2ethos.utils.decimalInc(f.decimals)
        maxValue = f.max * rf2ethos.utils.decimalInc(f.decimals)
        if f.mult ~= nil then
            minValue = minValue * f.mult
            maxValue = maxValue * f.mult
        end

        field = form.addNumberField(_G["rf2ethos_PIDROWS_" .. f.row], pos, minValue, maxValue, function()
            local value = rf2ethos.getFieldValue(f)
            return value
        end, function(value)
            f.value = rf2ethos.saveFieldValue(f, value)
            rf2ethos.saveValue(i)
        end)
        if f.default ~= nil then
            local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
            if f.mult ~= nil then default = default * f.mult end
            field:default(default)
        else
            field:default(0)
        end
        if f.decimals ~= nil then field:decimals(f.decimals) end
        if f.unit ~= nil then field:suffix(f.unit) end
        if f.help ~= nil then
            if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                field:help(helpTxt)
            end
        end
    end

    -- if rf2ethos.dialogs.progressDisplay == true then
    --	rf2ethos.triggers.closeProgress = true
    -- end

end

function ui.openPageSERVOSLoader(idx, title, script)

    -- rf2ethos.utils.log("openrf2ethos.ui.openPageSERVOSLoader")

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
    collectgarbage()

    -- rf2ethos.dialogs.progressDisplay = true
    -- rf2ethos.dialogs.progressWatchDog = os.clock()
    -- rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    -- rf2ethos.dialogs.progress:value(0)
    -- rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    rf2ethos.triggers.isLoading = true

    -- rf2ethos.utils.log("Finished: rf2ethos.ui.openPageSERVOS")
end

function ui.openPageSERVOS(idx, title, script)

    -- rf2ethos.utils.log("openrf2ethos.ui.openPageSERVOS")

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    local numPerRow = 2

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local padding = rf2ethos.radio.buttonPadding
    local h = rf2ethos.radio.navbuttonHeight
    local w = ((windowWidth) / numPerRow) - (padding * numPerRow - 1)

    local y = rf2ethos.radio.linePaddingTop

    longPage = false

    form.clear()

    rf2ethos.lastPage = script

    rf2ethos.ui.fieldHeader(title)

    -- we add a servo selector that is not part of msp table
    -- this is done as a selector - to pass a servoID on refresh
    if rf2ethos.Page.servoCount == 3 then
        servoTable = {"ELEVATOR", "CYCLIC LEFT", "CYCLIC RIGHT"}
    else
        servoTable = {"ELEVATOR", "CYCLIC LEFT", "CYCLIC RIGHT", "TAIL"}
    end

    -- we can now loop throught pages to get values
    formLineCnt = 0
    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageValue = f
        local pageIdx = i
        local currentField = i

        if i == 1 then
            line = form.addLine("Servo")
            field = form.addChoiceField(line, nil, rf2ethos.utils.convertPageValueTable(servoTable), function()
                value = rf2ethos.lastChangedServo
                if rf2ethos.Page == nil then
                    rf2ethos.triggers.wasReloading = true
                    rf2ethos.triggers.createForm = true
                else
                    rf2ethos.Page.fields[1].value = value
                end
                return value
            end, function(value)
                rf2ethos.Page.servoChanged(rf2ethos.Page, value)
                return true
            end)
        else
            if f.hideme == nil or f.hideme == false then
                line = form.addLine(f.t)
                field = form.addNumberField(line, nil, f.min, f.max, function()
                    local value = rf2ethos.getFieldValue(f)
                    return value
                end, function(value)
                    f.value = rf2ethos.saveFieldValue(f, value)
                    rf2ethos.saveValue(i)
                end)
                if f.default ~= nil then
                    local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
                    if f.mult ~= nil then default = default * f.mult end
                    field:default(default)
                else
                    field:default(0)
                end
                if f.decimals ~= nil then field:decimals(f.decimals) end
                if f.unit ~= nil then field:suffix(f.unit) end
                if f.help ~= nil then
                    if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                        local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                        field:help(helpTxt)
                    end
                end
            end
        end
    end

    -- if rf2ethos.dialogs.progressDisplay == true then
    --	rf2ethos.triggers.closeProgress = true
    -- end

end

function ui.getLabel(id, page)
    for i, v in ipairs(page) do if id ~= nil then if v.label == id then return v end end end
end

function ui.fieldChoice(f, i)
    if rf2ethos.lastSubPage ~= nil and f.subpage ~= nil then if f.subpage ~= rf2ethos.lastSubPage then return end end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then

        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if f.t ~= nil then
            if f.t2 ~= nil then f.t = f.t2 end

            if f.label ~= nil then f.t = "    " .. f.t end
        end
        formLineCnt = formLineCnt + 1
        line = form.addLine(f.t)
        posField = nil
        postText = nil
    end

    field = form.addChoiceField(line, posField, rf2ethos.utils.convertPageValueTable(f.table, f.tableIdxInc), function()
        local value = rf2ethos.getFieldValue(f)

        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then f.postEdit(rf2ethos.Page) end
        f.value = rf2ethos.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)
end

function ui.fieldNumber(f, i)
    if rf2ethos.lastSubPage ~= nil and f.subpage ~= nil then if f.subpage ~= rf2ethos.lastSubPage then return end end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        if f.t ~= nil then

            if f.label ~= nil then f.t = "    " .. f.t end
        else
            f.t = ""
        end

        formLineCnt = formLineCnt + 1

        line = form.addLine(f.t)

        posField = nil
        postText = nil
    end

    minValue = rf2ethos.utils.scaleValue(f.min, f)
    maxValue = rf2ethos.utils.scaleValue(f.max, f)
    if f.mult ~= nil then
        minValue = minValue * f.mult
        maxValue = maxValue * f.mult
    end

    if HideMe == true then
        -- posField = {x = 2000, y = 0, w = 20, h = 20}
    end

    field = form.addNumberField(line, posField, minValue, maxValue, function()
        local value = rf2ethos.getFieldValue(f)

        return value
    end, function(value)
        if f.postEdit then f.postEdit(rf2ethos.Page) end

        f.value = rf2ethos.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)

    if f.default ~= nil then
        local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
        if f.mult ~= nil then default = default * f.mult end
        field:default(default)
    else
        field:default(0)
    end

    if f.decimals ~= nil then field:decimals(f.decimals) end
    if f.unit ~= nil then field:suffix(f.unit) end
    if f.step ~= nil then field:step(f.step) end

    if f.help ~= nil then
        if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
            local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
            field:help(helpTxt)
        end
    end

end

function ui.fieldLabel(f, i, l)
    if rf2ethos.lastSubPage ~= nil and f.subpage ~= nil then if f.subpage ~= rf2ethos.lastSubPage then return end end

    if f.t ~= nil then
        if f.t2 ~= nil then f.t = f.t2 end

        if f.label ~= nil then f.t = "    " .. f.t end
    end

    if f.label ~= nil then
        local label = rf2ethos.ui.getLabel(f.label, l)

        local labelValue = label.t
        local labelID = label.label

        if label.t2 ~= nil then labelValue = label.t2 end
        if f.t ~= nil then
            labelName = labelValue
        else
            labelName = "unknown"
        end

        if f.label ~= rf2ethos.lastLabel then
            if label.type == nil then label.type = 0 end

            formLineCnt = formLineCnt + 1
            line = form.addLine(labelName)
            form.addStaticText(line, nil, "")

            rf2ethos.lastLabel = f.label
        end
    else
        labelID = nil
    end
end

function ui.fieldHeader(title)
    local w = rf2ethos.config.lcdWidth
    local h = rf2ethos.config.lcdHeight
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.radio.navButtonOffset ~= nil then colStart = colStart - rf2ethos.radio.navButtonOffset end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.menuButtonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight

    line = form.addLine(title)
    rf2ethos.ui.navigationButtons(w, rf2ethos.radio.linePaddingTop, buttonW, buttonH)
end

function ui.openPageDefaultLoader(idx, subpage, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
    collectgarbage()

    -- rf2ethos.dialogs.progressDisplay = true
    -- rf2ethos.dialogs.progressWatchDog = os.clock()
    -- rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    -- rf2ethos.dialogs.progress:value(0)
    -- rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    rf2ethos.triggers.isLoading = true

    -- rf2ethos.utils.log("Finished: rf2ethos.ui.openPageDefaultLoader")

end

function ui.openPageDefault(idx, subpage, title, script)

    local fieldAR = {}

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    longPage = false

    form.clear()

    rf2ethos.lastPage = script

    rf2ethos.ui.fieldHeader(title)

    formLineCnt = 0

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageValue = f
        local pageIdx = i
        local currentField = i

        rf2ethos.ui.fieldLabel(f, i, l)

        if f.table or f.type == 1 then
            rf2ethos.ui.fieldChoice(f, i)
        else
            rf2ethos.ui.fieldNumber(f, i)
        end
    end

    -- if rf2ethos.dialogs.progressDisplay == true then
    --	rf2ethos.triggers.closeProgress = true
    -- end

end

function ui.openPagePreferences(idx, title, script)
    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = nil
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.triggers.isLoading = false
    rf2ethos.Page = nil

    form.clear()

    local w = rf2ethos.config.lcdWidth
    local h = rf2ethos.config.lcdHeight
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.radio.navButtonOffset ~= nil then colStart = colStart - rf2ethos.radio.navButtonOffset end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.buttonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight

    local x = w

    line = form.addLine("Preferences")

    field = form.addButton(line, {x = x - (buttonW + padding) * 1, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = buttonH}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.lastIdx = nil
            rf2ethos.lastPage = nil
            rf2ethos.lastSubPage = nil
            rf2ethos.escMode = false
            rf2ethos.ui.openMainMenu()
        end
    })
    field:focus()

    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/iconsize")
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then rf2ethos.config.iconsizeParam = 1 end
    line = form.addLine("Button style")
    form.addChoiceField(line, nil, {{"Text", 0}, {"Small image", 1}, {"Large images", 2}}, function()
        return rf2ethos.config.iconsizeParam
    end, function(newValue)
        rf2ethos.config.iconsizeParam = newValue
        rf2ethos.utils.storePreference(rf2ethos.config.toolDir .. "/preferences/iconsize", rf2ethos.config.iconsizeParam)
    end)

    -- PROFILE
    rf2ethos.config.profileswitchParamPreference = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/profileswitch")
    if rf2ethos.config.profileswitchParamPreference ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.profileswitchParamPreference, ",")
        rf2ethos.config.profileswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = form.addLine("Switch profile")
    form.addSourceField(line, nil, function()
        return rf2ethos.config.profileswitchParam
    end, function(newValue)
        rf2ethos.config.profileswitchParam = newValue
        local member = rf2ethos.config.profileswitchParam:member()
        local category = rf2ethos.config.profileswitchParam:category()
        rf2ethos.utils.storePreference(rf2ethos.config.toolDir .. "/preferences/profileswitch", category .. "," .. member)
    end)

    rf2ethos.config.rateswitchParamPreference = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/rateswitch")
    if rf2ethos.config.rateswitchParamPreference ~= nil then
        local s = rf2ethos.utils.explode(rf2ethos.config.rateswitchParamPreference, ",")
        rf2ethos.config.rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = form.addLine("Switch rates")
    form.addSourceField(line, nil, function()
        return rf2ethos.config.rateswitchParam
    end, function(newValue)
        rf2ethos.config.rateswitchParam = newValue
        local member = rf2ethos.config.rateswitchParam:member()
        local category = rf2ethos.config.rateswitchParam:category()
        rf2ethos.utils.storePreference(rf2ethos.config.toolDir .. "/preferences/rateswitch", category .. "," .. member)
    end)

    rf2ethos.config.watchdogParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/watchdog")
    if rf2ethos.config.watchdogParam == nil or rf2ethos.config.watchdogParam == "" then rf2ethos.config.watchdogParam = 15 end
    line = form.addLine("Timeout")
    form.addChoiceField(line, nil, {{"Default", 1}, {"10s", 10}, {"15s", 15}, {"20s", 20}, {"25s", 25}, {"30s", 30}}, function()
        return rf2ethos.config.watchdogParam
    end, function(newValue)
        rf2ethos.config.watchdogParam = newValue
        rf2ethos.utils.storePreference(rf2ethos.config.toolDir .. "/preferences/watchdog", rf2ethos.config.watchdogParam)
    end)

end

function ui.navigationButtonsEscForm(x, y, w, h)

    local padding = 5
    local helpWidth = 0

    field = form.addButton(line, {x = x - w - padding - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.resetRates = false
            rf2ethos.escMode = true
            rf2ethos.escNotReadyCount = 0
            collectgarbage()
            ui.openPageESCTool(rf2ethos.escManufacturer)
        end
    })
    field:focus()

    form.addButton(line, {x = x - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.escNotReadyCount = 0
            rf2ethos.triggers.triggerSAVE = true
        end
    })

    form.addButton(line, {x = x - w - padding, y = y, w = w, h = h}, {
        text = "RELOAD",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()

            local buttons = {
                {
                    label = "        OK        ",
                    action = function()
                        -- trigger RELOAD
                        rf2ethos.triggers.triggerESCRELOAD = true
                        return true
                    end
                }, {
                    label = "CANCEL",
                    action = function()
                        return true
                    end
                }
            }
            form.openDialog({
                width = nil,
                title = "REFRESH",
                message = "Reload configuration from ESC",
                buttons = buttons,
                wakeup = function()
                end,
                paint = function()
                end,
                options = TEXT_LEFT
            })

        end
    })

end

function ui.navigationButtons(x, y, w, h)

    local helpWidth
    local section
    local page

    help = assert(compile.loadScript(rf2ethos.config.toolDir .. "help/pages.lua"))()
    section = string.gsub(rf2ethos.lastScript, ".lua", "") -- remove .lua
    page = rf2ethos.lastSubPage
    if page == nil then
        section = section
    else
        section = section .. '_' .. page
    end

    if help.data[section] then
        helpWidth = w - (w * 20) / 100
    else
        helpWidth = 0
    end

    field = form.addButton(line, {x = x - (helpWidth + padding) - (w + padding) * 3, y = y, w = w, h = h}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.resetRates = false
            rf2ethos.ui.openMainMenu()
        end
    })
    field:focus()

    form.addButton(line, {x = x - (helpWidth + padding) - (w + padding) * 2, y = y, w = w, h = h}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.triggerSAVE = true
        end
    })

    form.addButton(line, {x = x - (helpWidth + padding) - (w + padding), y = y, w = w, h = h}, {
        text = "RELOAD",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.triggerRELOAD = true
        end
    })

    if helpWidth > 0 then

        form.addButton(line, {x = x - (helpWidth + padding), y = y, w = helpWidth, h = h}, {
            text = "?",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.ui.openPagehelp(help.data, section)
            end
        })

    end

end

function ui.openPagehelp(helpdata, section)
    local txtData

    if section == "rates_1" then
        txtData = helpdata[section]["table"][rf2ethos.RateTable]
    else
        txtData = helpdata[section]["TEXT"]
    end
    local qr = rf2ethos.config.toolDir .. helpdata[section]["qrCODE"]

    local message = ""

    -- wrap text because of image on right
    for k, v in ipairs(txtData) do message = message .. v .. "\n\n" end

    local buttons = {
        {
            label = "CLOSE",
            action = function()
                return true
            end
        }
    }

    local bitmap = lcd.loadBitmap(qr)

    form.openDialog({
        width = rf2ethos.config.lcdWidth,
        title = "Help - " .. rf2ethos.lastTitle,
        message = message,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
            local w = rf2ethos.config.lcdWidth
            local h = rf2ethos.config.lcdHeight
            local left = w * 0.75

            local qw = rf2ethos.radio.helpQrCodeSize
            local qh = rf2ethos.radio.helpQrCodeSize

            local qy = rf2ethos.radio.buttonPadding
            local qx = rf2ethos.config.lcdWidth - qw - rf2ethos.radio.buttonPadding / 2
            lcd.drawBitmap(qx, qy, bitmap, qw, qh)

        end,
        options = TEXT_LEFT
    })

end

return ui
