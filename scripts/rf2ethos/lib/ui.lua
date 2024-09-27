local ui = {}

local arg = {...}
local config = arg[1]
local compile = arg[2]

function ui.progessDisplay(title, message)

    if rf2ethos.app.dialogs.progressDisplay == true then return end

    rf2ethos.app.audio.playLoading = true

    if title == nil then title = "Loading..." end
    if message == nil then message = "Loading data from flight controller..." end

    rf2ethos.app.dialogs.progressDisplay = true
    rf2ethos.app.dialogs.progressWatchDog = os.clock()
    rf2ethos.app.dialogs.progress = form.openProgressDialog(title, message)
    rf2ethos.app.dialogs.progressDisplay = true
    rf2ethos.app.dialogs.progressCounter = 0
    if rf2ethos.app.dialogs.progress ~= nil then
        rf2ethos.app.dialogs.progress:value(0)
        rf2ethos.app.dialogs.progress:closeAllowed(false)
    end
end

function ui.progessNolinkDisplay()
    rf2ethos.app.dialogs.nolinkDisplay = true
    rf2ethos.app.dialogs.noLink = form.openProgressDialog("Connecting", "Connecting")
    rf2ethos.app.dialogs.noLink:closeAllowed(false)
    rf2ethos.app.dialogs.noLink:value(0)
end

function ui.progessDisplaySave()
    rf2ethos.app.dialogs.saveDisplay = true
    rf2ethos.app.dialogs.saveWatchDog = os.clock()
    rf2ethos.app.dialogs.save = form.openProgressDialog("Saving...", "Saving data...")
    rf2ethos.app.dialogs.save:value(0)
    rf2ethos.app.dialogs.save:closeAllowed(false)
end

-- we wrap a simple rate limiter into this to prevent cpu overload when handling msp
function ui.progessDisplayValue(value, message)

    --if rf2ethos.app.triggers.mspBusy == true then return end

    if value >= 100 then
        rf2ethos.app.dialogs.progress:value(value)
        if message ~= nil then rf2ethos.app.dialogs.progress:message(message) end
        return
    end

    local now = os.clock()
    if (now - rf2ethos.app.dialogs.progressRateLimit) >= rf2ethos.app.dialogs.progressRate then
        rf2ethos.app.dialogs.progressRateLimit = now
        rf2ethos.app.dialogs.progress:value(value)
        if message ~= nil then rf2ethos.app.dialogs.progress:message(message) end
    end

end

-- we wrap a simple rate limiter into this to prevent cpu overload when handling msp
function ui.progessDisplaySaveValue(value, message)

    --if rf2ethos.app.triggers.mspBusy == true then return end

    if value >= 100 then
        rf2ethos.app.dialogs.save:value(value)
        if message ~= nil then rf2ethos.app.dialogs.save:message(message) end
        return
    end

    local now = os.clock()
    if (now - rf2ethos.app.dialogs.saveRateLimit) >= rf2ethos.app.dialogs.saveRate then
        rf2ethos.app.dialogs.saveRateLimit = now
        rf2ethos.app.dialogs.save:value(value)
        if message ~= nil then rf2ethos.app.dialogs.save:message(message) end
    end

end

function ui.progessDisplayClose()
    if rf2ethos.app.dialogs.progress ~= nil then rf2ethos.app.dialogs.progress:close() end
end

function ui.progessDisplayCloseAllowed(status)
    if rf2ethos.app.dialogs.progress ~= nil then rf2ethos.app.dialogs.progress:closeAllowed(status) end
end

function ui.progessDisplayMessage(message)
    if rf2ethos.app.dialogs.progress ~= nil then rf2ethos.app.dialogs.progress:message(message) end
end

function ui.progessDisplaySaveClose()
    if rf2ethos.app.dialogs.progress ~= nil then rf2ethos.app.dialogs.save:close() end
end

function ui.progessDisplaySaveMessage(message)
    if rf2ethos.app.dialogs.save ~= nil then rf2ethos.app.dialogs.save:message(message) end
end

function ui.progessDisplaySaveCloseAllowed(status)
    if rf2ethos.app.dialogs.save ~= nil then rf2ethos.app.dialogs.save:closeAllowed(status) end
end

function ui.progessNolinkDisplayClose()
    rf2ethos.app.dialogs.noLink:close()
end

-- we wrap a simple rate limiter into this to prevent cpu overload when handling msp
function ui.progessDisplayNoLinkValue(value, message)

    --if rf2ethos.app.triggers.mspBusy == true then return end

    if value >= 100 then
        rf2ethos.app.dialogs.noLink:value(value)
        if message ~= nil then rf2ethos.app.dialogs.noLink:message(message) end
        return
    end

    local now = os.clock()
    if (now - rf2ethos.app.dialogs.nolinkRateLimit) >= rf2ethos.app.dialogs.nolinkRate then
        rf2ethos.app.dialogs.nolinkRateLimit = now
        rf2ethos.app.dialogs.noLink:value(value)
        if message ~= nil then rf2ethos.app.dialogs.noLink:message(message) end
    end

end

function ui.openMainMenu()

    local MainMenu = assert(compile.loadScript(config.toolDir .. "pages.lua"))()

    if tonumber(rf2ethos.utils.makeNumber(config.environment.major .. config.environment.minor .. config.environment.revision)) < config.ethosVersion then return end

    -- clear all nav vars
    rf2ethos.app.lastIdx = nil
    rf2ethos.app.lastTitle = nil
    rf2ethos.app.lastScript = nil
    rf2ethos.lastPage = nil

    --rf2ethos.msp.protocol.mspIntervalOveride = nil

    rf2ethos.app.triggers.isReady = false
    rf2ethos.app.uiState = rf2ethos.app.uiStatus.mainMenu
    rf2ethos.app.triggers.disableRssiTimeout = false

    -- size of buttons
    config.iconsizeParam = rf2ethos.app.preferences.interface.iconSize
    if config.iconsizeParam == nil or config.iconsizeParam == "" then
        config.iconsizeParam = 1
    else
        config.iconsizeParam = tonumber(config.iconsizeParam)
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    if config.iconsizeParam == 0 then
        padding = rf2ethos.app.radio.buttonPaddingSmall
        buttonW = (config.lcdWidth - padding) / rf2ethos.app.radio.buttonsPerRow - padding
        buttonH = rf2ethos.app.radio.navbuttonHeight
        numPerRow = rf2ethos.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if config.iconsizeParam == 1 then

        padding = rf2ethos.app.radio.buttonPaddingSmall
        buttonW = rf2ethos.app.radio.buttonWidthSmall
        buttonH = rf2ethos.app.radio.buttonHeightSmall
        numPerRow = rf2ethos.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if config.iconsizeParam == 2 then

        padding = rf2ethos.app.radio.buttonPadding
        buttonW = rf2ethos.app.radio.buttonWidth
        buttonH = rf2ethos.app.radio.buttonHeight
        numPerRow = rf2ethos.app.radio.buttonsPerRow
    end

    local sc
    local panel

    form.clear()

    if rf2ethos.app.gfx_buttons["mainmenu"] == nil then rf2ethos.app.gfx_buttons["mainmenu"] = {} end
    if rf2ethos.app.menuLastSelected["mainmenu"] == nil then rf2ethos.app.menuLastSelected["mainmenu"] = 1 end

    for idx, value in ipairs(MainMenu.sections) do

        local sc = value.section

        form.addLine(value.title)

        lc = 0
        for pidx, pvalue in ipairs(MainMenu.pages) do
            if pvalue.section == value.section then

                if lc == 0 then
                    if config.iconsizeParam == 0 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
                    if config.iconsizeParam == 1 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
                    if config.iconsizeParam == 2 then y = form.height() + rf2ethos.app.radio.buttonPadding end
                end

                if lc >= 0 then x = (buttonW + padding) * lc end

                if config.iconsizeParam ~= 0 then
                    if rf2ethos.app.gfx_buttons["mainmenu"][pidx] == nil then
                        rf2ethos.app.gfx_buttons["mainmenu"][pidx] = lcd.loadMask(config.toolDir .. "gfx/menu/" .. pvalue.image)
                    end
                else
                    rf2ethos.app.gfx_buttons["mainmenu"][pidx] = nil
                end

                rf2ethos.app.formFields[pidx] = form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                    text = pvalue.title,
                    icon = rf2ethos.app.gfx_buttons["mainmenu"][pidx],
                    options = FONT_S,
                    paint = function()
                    end,
                    press = function()
                        rf2ethos.app.menuLastSelected["mainmenu"] = pidx
                        rf2ethos.app.ui.progessDisplay()
                        rf2ethos.app.ui.openPage(pidx, pvalue.title, pvalue.script)
                    end
                })

                if rf2ethos.app.menuLastSelected["mainmenu"] == pidx then rf2ethos.app.formFields[pidx]:focus() end

                lc = lc + 1

                if lc == numPerRow then lc = 0 end
            end
        end

    end
    
end

function ui.progressDisplay()

    if rf2ethos.app.dialogs.progressDisplay == true then return true end
    if rf2ethos.app.dialogs.saveDisplay == true then return true end
    if rf2ethos.app.dialogs.progressDisplayEsc == true then return true end
    if rf2ethos.app.dialogs.nolinkDisplay == true then return true end
    if rf2ethos.app.dialogs.badversionDisplay == true then return true end

    return false
end

function ui.getLabel(id, page)
    for i, v in ipairs(page) do if id ~= nil then if v.label == id then return v end end end
end

function ui.fieldChoice(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then

        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.app.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if f.t ~= nil then
            if f.t2 ~= nil then f.t = f.t2 end

            if f.label ~= nil then f.t = "    " .. f.t end
        end
        formLineCnt = formLineCnt + 1
        rf2ethos.formLines[formLineCnt] = form.addLine(f.t)
        if f.position ~= nil then
            posField = f.position
        else
            posField = nil
        end 
        postText = nil
    end

    rf2ethos.app.formFields[i] = form.addChoiceField(rf2ethos.formLines[formLineCnt], posField, rf2ethos.utils.convertPageValueTable(f.table, f.tableIdxInc), function()
        local value = rf2ethos.utils.getFieldValue(f)

        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then f.postEdit(rf2ethos.app.Page, value) end
        if f.onChange then f.onChange(rf2ethos.app.Page, value) end
        f.value = rf2ethos.utils.saveFieldValue(f, value)
        rf2ethos.app.saveValue(i)
    end)

    if f.disable == true then rf2ethos.app.formFields[i]:enable(false) end
end

function ui.fieldNumber(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.app.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        if f.t ~= nil then

            if f.label ~= nil then f.t = "    " .. f.t end
        else
            f.t = ""
        end

        formLineCnt = formLineCnt + 1

        rf2ethos.formLines[formLineCnt] = form.addLine(f.t)

        if f.position ~= nil then
            posField = f.position
        else
            posField = nil
        end 
        postText = nil
    end



    if f.offset ~= nil then
        if f.min ~= nil then
            f.min = f.min + f.offset
        end
        if f.max ~= nil then
            f.max = f.max + f.offset
        end    
    end

    minValue = rf2ethos.utils.scaleValue(f.min, f)
    maxValue = rf2ethos.utils.scaleValue(f.max, f)
    

    if f.mult ~= nil then
        minValue = minValue * f.mult
        maxValue = maxValue * f.mult
    end


    if minValue == nil then minValue = 0 end
    if maxValue == nil then maxValue = 0 end
    rf2ethos.app.formFields[i] = form.addNumberField(rf2ethos.formLines[formLineCnt], posField, minValue, maxValue, function()
        local value = rf2ethos.utils.getFieldValue(f)

        return value
    end, function(value)
        if f.postEdit then f.postEdit(rf2ethos.app.Page) end
        if f.onChange then f.onChange(rf2ethos.app.Page) end

        f.value = rf2ethos.utils.saveFieldValue(f, value)
        rf2ethos.app.saveValue(i)
    end)

    if config.ethosRunningVersion >= 1514 then
        if f.onFocus ~= nil then
            rf2ethos.app.formFields[i]:onFocus(function()
                f.onFocus(rf2ethos.app.Page)
            end)
        end
    end

    if f.default ~= nil then    
        if f.offset ~= nil then f.default = f.default + f.offset end      
        local default = f.default * rf2ethos.utils.decimalInc(f.decimals)     
        if f.mult ~= nil then default = default * f.mult end
        rf2ethos.app.formFields[i]:default(default)
    else
        rf2ethos.app.formFields[i]:default(0)
    end

    if f.decimals ~= nil then rf2ethos.app.formFields[i]:decimals(f.decimals) end
    if f.unit ~= nil then rf2ethos.app.formFields[i]:suffix(f.unit) end
    if f.step ~= nil then rf2ethos.app.formFields[i]:step(f.step) end
    if f.disable == true then rf2ethos.app.formFields[i]:enable(false) end

    if f.help ~= nil then
        if rf2ethos.app.fieldHelpTxt[f.help]['t'] ~= nil then
            local helpTxt = rf2ethos.app.fieldHelpTxt[f.help]['t']
            rf2ethos.app.formFields[i]:help(helpTxt)
        end
    end

end

function ui.fieldStaticText(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.app.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        if f.t ~= nil then

            if f.label ~= nil then f.t = "    " .. f.t end
        else
            f.t = ""
        end

        formLineCnt = formLineCnt + 1

        rf2ethos.formLines[formLineCnt] = form.addLine(f.t)

        if f.position ~= nil then
            posField = f.position
        else
            posField = nil
        end    
        postText = nil
    end

    if HideMe == true then
        -- posField = {x = 2000, y = 0, w = 20, h = 20}
    end

    rf2ethos.app.formFields[i] = form.addStaticText(rf2ethos.formLines[formLineCnt], posField, rf2ethos.utils.getFieldValue(f))

    if config.ethosRunningVersion >= 1514 then
        if f.onFocus ~= nil then
            rf2ethos.app.formFields[i]:onFocus(function()
                f.onFocus(rf2ethos.app.Page)
            end)
        end
    end

    if f.decimals ~= nil then rf2ethos.app.formFields[i]:decimals(f.decimals) end
    if f.unit ~= nil then rf2ethos.app.formFields[i]:suffix(f.unit) end
    if f.step ~= nil then rf2ethos.app.formFields[i]:step(f.step) end

end

function ui.fieldText(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.app.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if rf2ethos.app.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        if f.t ~= nil then

            if f.label ~= nil then f.t = "    " .. f.t end
        else
            f.t = ""
        end

        formLineCnt = formLineCnt + 1

        rf2ethos.formLines[formLineCnt] = form.addLine(f.t)

        if f.position ~= nil then
            posField = f.position
        else
            posField = nil
        end 
        postText = nil
    end

    if HideMe == true then
        -- posField = {x = 2000, y = 0, w = 20, h = 20}
    end

    rf2ethos.app.formFields[i] = form.addTextField(rf2ethos.formLines[formLineCnt], posField, function()
        local value = rf2ethos.utils.getFieldValue(f)
        return value
    end, function(value)
        if f.postEdit then f.postEdit(rf2ethos.app.Page) end
        if f.onChange then f.onChange(rf2ethos.app.Page) end

        f.value = rf2ethos.utils.saveFieldValue(f, value)
        rf2ethos.app.saveValue(i)
    end)

    if config.ethosRunningVersion >= 1514 then
        if f.onFocus ~= nil then
            rf2ethos.app.formFields[i]:onFocus(function()
                f.onFocus(rf2ethos.app.Page)
            end)
        end
    end

    if f.disable == true then rf2ethos.app.formFields[i]:enable(false) end

    if f.help ~= nil then
        if rf2ethos.app.fieldHelpTxt[f.help]['t'] ~= nil then
            local helpTxt = rf2ethos.app.fieldHelpTxt[f.help]['t']
            rf2ethos.app.formFields[i]:help(helpTxt)
        end
    end

end

function ui.fieldLabel(f, i, l)

    if f.t ~= nil then
        if f.t2 ~= nil then f.t = f.t2 end

        if f.label ~= nil then f.t = "    " .. f.t end
    end

    if f.label ~= nil then
        local label = rf2ethos.app.ui.getLabel(f.label, l)

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
            rf2ethos.formLines[formLineCnt] = form.addLine(labelName)
            form.addStaticText(rf2ethos.formLines[formLineCnt], nil, "")

            rf2ethos.lastLabel = f.label
        end
    else
        labelID = nil
    end
end

function ui.fieldHeader(title)
    local w, h = rf2ethos.utils.getWindowSize()
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor(((w) * 59.4) / 100)
    if rf2ethos.app.radio.navButtonOffset ~= nil then colStart = colStart - rf2ethos.app.radio.navButtonOffset end

    if rf2ethos.app.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.app.radio.menuButtonWidth
    end
    buttonH = rf2ethos.app.radio.navbuttonHeight

    rf2ethos.app.formFields['menu'] = form.addLine("")
    

    rf2ethos.app.formFields['title'] = form.addStaticText(rf2ethos.app.formFields['menu'], {x = 0, y = rf2ethos.app.radio.linePaddingTop, w = config.lcdWidth, h = rf2ethos.app.radio.navbuttonHeight}, title)    
    
    rf2ethos.app.ui.navigationButtons(w - 5, rf2ethos.app.radio.linePaddingTop, buttonW, buttonH)
end

function ui.openPage(idx, title, script, extra1, extra2, extra3, extra5, extra5)

    rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages
    rf2ethos.app.triggers.isReady = false
    rf2ethos.app.formFields = {}
    rf2ethos.formLines = {}

    rf2ethos.app.Page = assert(compile.loadScript(config.toolDir .. "pages/" .. script))()


    if rf2ethos.app.Page.openPage then
        rf2ethos.app.Page.openPage(idx, title, script, extra1, extra2, extra3, extra5, extra5)
    else

        rf2ethos.app.lastIdx = idx
        rf2ethos.app.lastTitle = title
        rf2ethos.app.lastScript = script

        local fieldAR = {}

        rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages
        rf2ethos.app.triggers.isReady = false

        longPage = false

        form.clear()

        rf2ethos.lastPage = script

        if rf2ethos.app.Page.pageTitle ~= nil then
            rf2ethos.app.ui.fieldHeader(rf2ethos.app.Page.pageTitle)
        else
            rf2ethos.app.ui.fieldHeader(title)
        end

        if rf2ethos.app.Page.headerLine ~= nil then
            local headerLine = form.addLine("")
            local headerLineText =
                form.addStaticText(headerLine, {x = 0, y = rf2ethos.app.radio.linePaddingTop, w = config.lcdWidth, h = rf2ethos.app.radio.navbuttonHeight}, rf2ethos.app.Page.headerLine)
        end


        formLineCnt = 0

        for i = 1, #rf2ethos.app.Page.fields do
            local f = rf2ethos.app.Page.fields[i]
            local l = rf2ethos.app.Page.labels
            local pageValue = f
            local pageIdx = i
            local currentField = i

            rf2ethos.app.ui.fieldLabel(f, i, l)

            if f.hidden ~= true then

                if f.type == 0 then
                    rf2ethos.app.ui.fieldStaticText(f, i)
                elseif f.table or f.type == 1 then
                    rf2ethos.app.ui.fieldChoice(f, i)
                elseif f.type == 2 then
                    rf2ethos.app.ui.fieldNumber(f, i)
                elseif f.type == 3 then
                    rf2ethos.app.ui.fieldText(f, i)
                else
                    rf2ethos.app.ui.fieldNumber(f, i)
                end

            end
        end
    end

end

function ui.navigationButtons(x, y, w, h)

    local xOffset = 0
    local padding = 5
    local wS = w - (w * 20) / 100
    local helpOffset = 0
    local toolOffset = 0
    local reloadOffset = 0
    local saveOffset = 0
    local menuOffset = 0

    local navButtons
    if rf2ethos.app.Page.navButtons == nil then
        navButtons = {menu = true, save = true, reload = true, help = true}
    else
        navButtons = rf2ethos.app.Page.navButtons
    end

    -- calc all offsets
    -- these are done 'early' to enable the actual placement of the buttons on
    -- display to be rendered by ethos in the right order - for scrolling via
    -- keypad to work.
    if navButtons.help ~= nil and navButtons.help == true then xOffset = xOffset + wS + padding end
    helpOffset = x - xOffset

    if navButtons.tool ~= nil and navButtons.tool == true then xOffset = xOffset + wS + padding end
    toolOffset = x - xOffset

    if navButtons.reload ~= nil and navButtons.reload == true then xOffset = xOffset + w + padding end
    reloadOffset = x - xOffset

    if navButtons.save ~= nil and navButtons.save == true then xOffset = xOffset + w + padding end
    saveOffset = x - xOffset

    if navButtons.menu ~= nil and navButtons.menu == true then xOffset = xOffset + w + padding end
    menuOffset = x - xOffset

    -- MENU BTN
    if navButtons.menu ~= nil and navButtons.menu == true then

        rf2ethos.app.formNavigationFields['menu'] = form.addButton(line, {x = menuOffset, y = y, w = w, h = h}, {
            text = "MENU",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                if rf2ethos.app.Page and rf2ethos.app.Page.onNavMenu then
                    rf2ethos.app.Page.onNavMenu(rf2ethos.app.Page)
                else
                    rf2ethos.app.ui.openMainMenu()
                end
            end
        })
        rf2ethos.app.formNavigationFields['menu']:focus()
    end

    -- SAVE BTN
    if navButtons.save ~= nil and navButtons.save == true then

        rf2ethos.app.formNavigationFields['save'] = form.addButton(line, {x = saveOffset, y = y, w = w, h = h}, {
            text = "SAVE",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                if rf2ethos.app.Page and rf2ethos.app.Page.onSaveMenu then
                    rf2ethos.app.Page.onSaveMenu(rf2ethos.app.Page)
                else
                    rf2ethos.app.triggers.triggerSave = true
                end
            end
        })
    end

    -- RELOAD BTN
    if navButtons.reload ~= nil and navButtons.reload == true then

        rf2ethos.app.formNavigationFields['reload'] = form.addButton(line, {x = reloadOffset, y = y, w = w, h = h}, {
            text = "RELOAD",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()

                if rf2ethos.app.Page and rf2ethos.app.Page.onReloadMenu then
                    rf2ethos.app.Page.onReloadMenu(rf2ethos.app.Page)
                else
                    rf2ethos.app.triggers.triggerReload = true
                end
                return true
            end
        })
    end

    -- TOOL BUTTON
    if navButtons.tool ~= nil and navButtons.tool == true then
        rf2ethos.app.formNavigationFields['tool'] = form.addButton(line, {x = toolOffset, y = y, w = wS, h = h}, {
            text = "*",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.app.Page.onToolMenu()
            end
        })
    end

    -- HELP BUTTON
    if navButtons.help ~= nil and navButtons.help == true then

        local help = assert(compile.loadScript(config.toolDir .. "help/pages.lua"))()
        local section = string.gsub(rf2ethos.app.lastScript, ".lua", "") -- remove .lua

        rf2ethos.app.formNavigationFields['help'] = form.addButton(line, {x = helpOffset, y = y, w = wS, h = h}, {
            text = "?",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                if rf2ethos.app.Page and rf2ethos.app.Page.onHelpMenu then
                    rf2ethos.app.Page.onHelpMenu(rf2ethos.app.Page)
                else
                    rf2ethos.app.ui.openPagehelp(help.data, section)
                end
            end
        })
    end

end

function ui.openPagehelp(helpdata, section)
    local txtData
    local qr

    if section == "rates" then
        txtData = helpdata[section]["table"][rf2ethos.RateTable]
    else
        txtData = helpdata[section]["TEXT"]
    end
    if helpdata[section]["qrCODE"] ~= nil then
        qr = config.toolDir .. helpdata[section]["qrCODE"]
    else
        qr = nil
    end

    local message = ""

    -- find point that qr starts
    local qw = rf2ethos.app.radio.helpQrCodeSize
    local qh = rf2ethos.app.radio.helpQrCodeSize + rf2ethos.app.radio.buttonPadding
    local qx = (config.lcdWidth - qw - rf2ethos.app.radio.buttonPadding / 2) - rf2ethos.app.radio.buttonPadding

    -- wrap text because of image on right
    for k, v in ipairs(txtData) do
        local count = rf2ethos.utils.countCarriageReturns(message)

        message = message .. rf2ethos.utils.wrapText(v, qx) .. "\r\n\r\n"

    end

    local buttons = {
        {
            label = "CLOSE",
            action = function()
                return true
            end
        }
    }

    local bitmap
    if qr ~= nil then
        bitmap = lcd.loadBitmap(qr)
    else
        bitmap = nil
    end

    form.openDialog({
        width = config.lcdWidth,
        title = "Help - " .. rf2ethos.app.lastTitle,
        message = message,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()

            local w = config.lcdWidth
            local h = config.lcdHeight
            local left = w * 0.75

            local qw = rf2ethos.app.radio.helpQrCodeSize
            local qh = rf2ethos.app.radio.helpQrCodeSize

            if qr ~= nil then
                local qy = rf2ethos.app.radio.buttonPadding
                local qx = config.lcdWidth - qw - rf2ethos.app.radio.buttonPadding / 2
                lcd.drawBitmap(qx, qy, bitmap, qw, qh)
            end

        end,
        options = TEXT_LEFT
    })

end

return ui
