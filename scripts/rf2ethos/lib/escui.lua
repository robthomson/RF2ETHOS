escui = {}


function escui.progessDisplayESC()

    if rf2ethos.dialogs.progressDisplay == true then
        --	ui.progessDisplayClose()
    end

    rf2ethos.dialogs.progressDisplayEsc = true
    rf2ethos.dialogs.progressESC = form.openProgressDialog("Searching...", "Please power cycle the esc")
    rf2ethos.dialogs.progressESC:value(0)
end

function escui.progessDisplayESCClose()
    rf2ethos.dialogs.progressESC:close()
end

function escui.progessDisplayESCValue(value, message)

    if rf2ethos.triggers.mspBusy == true then return end

    rf2ethos.dialogs.progressESC:value(value)
    if message ~= nil then rf2ethos.dialogs.progressESC:message(message) end
end


function escui.navigationButtonsEscForm(x, y, w, h)

    local padding = 5
    local helpWidth = 0

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x - w - padding - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.escMode = true
            rf2ethos.escNotReadyCount = 0
            collectgarbage()

            if rf2ethos.Page and rf2ethos.Page.onNavMenu then rf2ethos.Page.onNavMenu(rf2ethos.Page) end

            escui.openPageEscTool(rf2ethos.escManufacturer)
        end
    })
    rf2ethos.formNavigationFields['menu']:focus()

    rf2ethos.formNavigationFields['save'] = form.addButton(line, {x = x - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()

            if rf2ethos.Page and rf2ethos.Page.onSaveMenu then rf2ethos.Page.onSaveMenu(rf2ethos.Page) end

            rf2ethos.escNotReadyCount = 0
            rf2ethos.triggers.triggerSave = true
        end
    })

    rf2ethos.formNavigationFields['reload'] = form.addButton(line, {x = x - w - padding, y = y, w = w, h = h}, {
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
                        rf2ethos.triggers.triggerEscReload = true

                        if rf2ethos.Page and rf2ethos.Page.onReloadMenu then rf2ethos.Page.onReloadMenu(rf2ethos.Page) end

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

function escui.openPageEsc(idx, title, script)

    rf2ethos.escMenuState = 1

    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

    rf2ethos.triggers.isReady = false
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

    local w, h = rf2ethos.utils.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = rf2ethos.radio.buttonPadding

    local sc
    local panel

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW - 10

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.lastIdx = nil
            rf2ethos.lastPage = nil
            rf2ethos.escMode = false

            if rf2ethos.Page and rf2ethos.Page.onNavMenu then rf2ethos.Page.onNavMenu(rf2ethos.Page) end

            rf2ethos.ui.openMainMenu()
        end
    })
    rf2ethos.formNavigationFields['menu']:focus()

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

        rf2ethos.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.esc_buttons[pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.escMenuLastSelected = pidx
                rf2ethos.escToolMenuLastSelected = 1 -- reset as have changed
                rf2ethos.ui.progessDisplay()
                rf2ethos.escui.openPageEscInfo(pvalue.folder)
            end
        })

        if pvalue.disabled == true then rf2ethos.formFields[pidx]:enable(false) end

        if rf2ethos.escMenuLastSelected == pidx then rf2ethos.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

	rf2ethos.triggers.closeProgressLoader = true

end

-- we init the tool because we need to know the make and model of the esc in use for 
-- the first menu to bother to display
-- the page is expected to return a wakeup function that then triggers ui.openPageEscTool(folder)
function escui.openPageEscInfo(folder)

    rf2ethos.escManufacturer = folder
    rf2ethos.escScript = nil
    rf2ethos.escMode = true

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.isReady = false

    ESC.init = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/init.lua"))()
    rf2ethos.triggers.escPowerCycle = ESC.init.powerCycle

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/esc_info.lua"))()

end

-- initialise menu for specific type of esc
-- basically we load libraries then read
-- /scripts/rf2ethosmsp/pages/esc/<TYPE>/pages.lua
function escui.openPageEscTool(folder)

    rf2ethos.formFields = {}
    rf2ethos.formLines = {}
    -- rf2ethos.utils.log("ui.openPageEscTool")

    rf2ethos.escMenuState = 2

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight

    local y = rf2ethos.radio.linePaddingTop

    form.clear()

    line = form.addLine(rf2ethos.lastTitle .. ' / ' .. ESC.init.toolName)

    buttonW = 100
    local x = windowWidth - buttonW

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()

            if rf2ethos.Page and rf2ethos.Page.onNavMenu then rf2ethos.Page.onNavMenu(rf2ethos.Page) end

            rf2ethos.triggers.triggerEscMainMenu = true
        end
    })
    rf2ethos.formNavigationFields['menu']:focus()

    ESC.pages = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/pages.lua"))()

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

        line = form.addLine("")
        form.addStaticText(line, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.buttonHeight}, model .. " " .. version .. " " .. fw)

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
        rf2ethos.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.esctool_buttons[pvalue.image],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.escToolMenuLastSelected = pidx
                rf2ethos.ui.progessDisplay()
                rf2ethos.escui.openESCFormInit(folder, pvalue.script)

            end
        })

        if rf2ethos.escToolMenuLastSelected == pidx then rf2ethos.formFields[pidx]:focus() end

        if rf2ethos.escUnknown == true then rf2ethos.formFields[pidx]:enable(false) end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    rf2ethos.triggers.closeProgressLoader = true
end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function escui.openESCFormInit(folder, script)

    -- rf2ethos.utils.log("rf2ethos.escui.openESCFormLoader")

    rf2ethos.escManufacturer = folder
    rf2ethos.escScript = script
    rf2ethos.escMode = true

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.isReady = false

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/pages/" .. script))()
    collectgarbage()

end

function escui.openESCForm(folder, script)

    rf2ethos.triggers.closeProgressLoader = true
    -- rf2ethos.utils.log("rf2ethos.escui.openESCForm")

    rf2ethos.escMenuState = 3

    local fieldAR = {}
    rf2ethos.uiState = rf2ethos.uiStatus.pages
    longPage = false
    form.clear()

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local y = rf2ethos.radio.linePaddingTop

    local w, h = rf2ethos.utils.getWindowSize()
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

    rf2ethos.escui.navigationButtonsEscForm(w, rf2ethos.radio.linePaddingTop, buttonW, rf2ethos.radio.navbuttonHeight)

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

        if f.type == 0 then
            rf2ethos.ui.fieldText(f, i)
        elseif f.table or f.type == 1 then
            rf2ethos.ui.fieldChoice(f, i)
        else
            rf2ethos.ui.fieldNumber(f, i)
        end
    end

end

return escui