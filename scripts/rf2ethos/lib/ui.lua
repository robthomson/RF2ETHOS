local ui = {}

function ui.progessDisplay(title, message)

    if rf2ethos.dialogs.progressDisplay == true then return end

    rf2ethos.audio.playLoading = true

    if title == nil then title = "Loading..." end
    if message == nil then message = "Loading data from flight controller..." end

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog(title, message)
    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressCounter = 0
    if rf2ethos.dialogs.progress ~= nil then
        rf2ethos.dialogs.progress:value(0)
        rf2ethos.dialogs.progress:closeAllowed(false)
    end
end

function ui.progessNolinkDisplay()
    rf2ethos.dialogs.nolinkDisplay = true
    rf2ethos.dialogs.noLink = form.openProgressDialog("Connecting", "Connecting")
    rf2ethos.dialogs.noLink:closeAllowed(false)
    rf2ethos.dialogs.noLink:value(0)
end

function ui.progessDisplaySave()
    rf2ethos.dialogs.saveDisplay = true
    rf2ethos.dialogs.saveWatchDog = os.clock()
    rf2ethos.dialogs.save = form.openProgressDialog("Saving...", "Saving data...")
    rf2ethos.dialogs.save:value(0)
    rf2ethos.dialogs.save:closeAllowed(false)
end

-- we wrap a simple rate limiter into this to prevent cpu overload when handling msp
function ui.progessDisplayValue(value, message)

    --if rf2ethos.triggers.mspBusy == true then return end

    if value >= 100 then
        rf2ethos.dialogs.progress:value(value)
        if message ~= nil then rf2ethos.dialogs.progress:message(message) end
        return
    end

    local now = os.clock()
    if (now - rf2ethos.dialogs.progressRateLimit) >= rf2ethos.dialogs.progressRate then
        rf2ethos.dialogs.progressRateLimit = now
        rf2ethos.dialogs.progress:value(value)
        if message ~= nil then rf2ethos.dialogs.progress:message(message) end
    end

end

-- we wrap a simple rate limiter into this to prevent cpu overload when handling msp
function ui.progessDisplaySaveValue(value, message)

    --if rf2ethos.triggers.mspBusy == true then return end

    if value >= 100 then
        rf2ethos.dialogs.save:value(value)
        if message ~= nil then rf2ethos.dialogs.save:message(message) end
        return
    end

    local now = os.clock()
    if (now - rf2ethos.dialogs.saveRateLimit) >= rf2ethos.dialogs.saveRate then
        rf2ethos.dialogs.saveRateLimit = now
        rf2ethos.dialogs.save:value(value)
        if message ~= nil then rf2ethos.dialogs.save:message(message) end
    end

end

function ui.progessDisplayClose()
    if rf2ethos.dialogs.progress ~= nil then rf2ethos.dialogs.progress:close() end
    collectgarbage()
end

function ui.progessDisplayCloseAllowed(status)
    if rf2ethos.dialogs.progress ~= nil then rf2ethos.dialogs.progress:closeAllowed(status) end
end

function ui.progessDisplayMessage(message)
    if rf2ethos.dialogs.progress ~= nil then rf2ethos.dialogs.progress:message(message) end
end

function ui.progessDisplaySaveClose()
    if rf2ethos.dialogs.progress ~= nil then rf2ethos.dialogs.save:close() end
    collectgarbage()
end

function ui.progessDisplaySaveMessage(message)
    if rf2ethos.dialogs.save ~= nil then rf2ethos.dialogs.save:message(message) end
end

function ui.progessDisplaySaveCloseAllowed(status)
    if rf2ethos.dialogs.save ~= nil then rf2ethos.dialogs.save:closeAllowed(status) end
end

function ui.progessNolinkDisplayClose()
    rf2ethos.dialogs.noLink:close()
    collectgarbage()
end

-- we wrap a simple rate limiter into this to prevent cpu overload when handling msp
function ui.progessDisplayNoLinkValue(value, message)

    if rf2ethos.triggers.mspBusy == true then return end

    if value >= 100 then
        rf2ethos.dialogs.noLink:value(value)
        if message ~= nil then rf2ethos.dialogs.noLink:message(message) end
        return
    end

    local now = os.clock()
    if (now - rf2ethos.dialogs.nolinkRateLimit) >= rf2ethos.dialogs.nolinkRate then
        rf2ethos.dialogs.nolinkRateLimit = now
        rf2ethos.dialogs.noLink:value(value)
        if message ~= nil then rf2ethos.dialogs.noLink:message(message) end
    end

end

function ui.openMainMenu()

    local MainMenu = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages.lua"))()

    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

    -- clear all nav vars
    rf2ethos.lastIdx = nil
    rf2ethos.lastTitle = nil
    rf2ethos.lastScript = nil
    rf2ethos.lastPage = nil

    rf2ethos.protocol.mspIntervalOveride = nil

    rf2ethos.triggers.isReady = false
    rf2ethos.uiState = rf2ethos.uiStatus.mainMenu
    rf2ethos.triggers.disableRssiTimeout = false

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

    if rf2ethos.gfx_buttons["mainmenu"] == nil then rf2ethos.gfx_buttons["mainmenu"] = {} end
    if rf2ethos.menuLastSelected["mainmenu"] == nil then rf2ethos.menuLastSelected["mainmenu"] = 1 end

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
                    if rf2ethos.gfx_buttons["mainmenu"][pidx] == nil then
                        rf2ethos.gfx_buttons["mainmenu"][pidx] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/menu/" .. pvalue.image)
                    end
                else
                    rf2ethos.gfx_buttons["mainmenu"][pidx] = nil
                end

                rf2ethos.formFields[pidx] = form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                    text = pvalue.title,
                    icon = rf2ethos.gfx_buttons["mainmenu"][pidx],
                    options = FONT_S,
                    paint = function()
                    end,
                    press = function()
                        rf2ethos.menuLastSelected["mainmenu"] = pidx
                        rf2ethos.ui.progessDisplay()
                        rf2ethos.ui.openPage(pidx, pvalue.title, pvalue.script)
                    end
                })

                if rf2ethos.menuLastSelected["mainmenu"] == pidx then rf2ethos.formFields[pidx]:focus() end

                lc = lc + 1

                if lc == numPerRow then lc = 0 end
            end
        end

    end
    
    collectgarbage()
end

function ui.progressDisplay()

    if rf2ethos.dialogs.progressDisplay == true then return true end
    if rf2ethos.dialogs.saveDisplay == true then return true end
    if rf2ethos.dialogs.progressDisplayEsc == true then return true end
    if rf2ethos.dialogs.nolinkDisplay == true then return true end
    if rf2ethos.dialogs.badversionDisplay == true then return true end

    return false
end

function ui.getLabel(id, page)
    for i, v in ipairs(page) do if id ~= nil then if v.label == id then return v end end end
end

function ui.fieldChoice(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then

        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
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

    rf2ethos.formFields[i] = form.addChoiceField(rf2ethos.formLines[formLineCnt], posField, rf2ethos.utils.convertPageValueTable(f.table, f.tableIdxInc), function()
        local value = rf2ethos.utils.getFieldValue(f)

        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then f.postEdit(rf2ethos.Page, value) end
        if f.onChange then f.onChange(rf2ethos.Page, value) end
        f.value = rf2ethos.utils.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)

    if f.disable == true then rf2ethos.formFields[i]:enable(false) end
end

function ui.fieldNumber(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

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
    rf2ethos.formFields[i] = form.addNumberField(rf2ethos.formLines[formLineCnt], posField, minValue, maxValue, function()
        local value = rf2ethos.utils.getFieldValue(f)

        return value
    end, function(value)
        if f.postEdit then f.postEdit(rf2ethos.Page) end
        if f.onChange then f.onChange(rf2ethos.Page) end

        f.value = rf2ethos.utils.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)

    if rf2ethos.config.ethosRunningVersion >= 1514 then
        if f.onFocus ~= nil then
            rf2ethos.formFields[i]:onFocus(function()
                f.onFocus(rf2ethos.Page)
            end)
        end
    end

    if f.default ~= nil then    
        if f.offset ~= nil then f.default = f.default + f.offset end      
        local default = f.default * rf2ethos.utils.decimalInc(f.decimals)     
        if f.mult ~= nil then default = default * f.mult end
        rf2ethos.formFields[i]:default(default)
    else
        rf2ethos.formFields[i]:default(0)
    end

    if f.decimals ~= nil then rf2ethos.formFields[i]:decimals(f.decimals) end
    if f.unit ~= nil then rf2ethos.formFields[i]:suffix(f.unit) end
    if f.step ~= nil then rf2ethos.formFields[i]:step(f.step) end
    if f.disable == true then rf2ethos.formFields[i]:enable(false) end

    if f.help ~= nil then
        if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
            local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
            rf2ethos.formFields[i]:help(helpTxt)
        end
    end

end

function ui.fieldStaticText(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

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

    rf2ethos.formFields[i] = form.addStaticText(rf2ethos.formLines[formLineCnt], posField, rf2ethos.utils.getFieldValue(f))

    if rf2ethos.config.ethosRunningVersion >= 1514 then
        if f.onFocus ~= nil then
            rf2ethos.formFields[i]:onFocus(function()
                f.onFocus(rf2ethos.Page)
            end)
        end
    end

    if f.decimals ~= nil then rf2ethos.formFields[i]:decimals(f.decimals) end
    if f.unit ~= nil then rf2ethos.formFields[i]:suffix(f.unit) end
    if f.step ~= nil then rf2ethos.formFields[i]:step(f.step) end

end

function ui.fieldText(f, i)

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(rf2ethos.formLines[formLineCnt], posText, f.t)
    else
        if rf2ethos.radio.text == 2 then if f.t2 ~= nil then f.t = f.t2 end end

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

    rf2ethos.formFields[i] = form.addTextField(rf2ethos.formLines[formLineCnt], posField, function()
        local value = rf2ethos.utils.getFieldValue(f)
        return value
    end, function(value)
        if f.postEdit then f.postEdit(rf2ethos.Page) end
        if f.onChange then f.onChange(rf2ethos.Page) end

        f.value = rf2ethos.utils.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)

    if rf2ethos.config.ethosRunningVersion >= 1514 then
        if f.onFocus ~= nil then
            rf2ethos.formFields[i]:onFocus(function()
                f.onFocus(rf2ethos.Page)
            end)
        end
    end

    if f.disable == true then rf2ethos.formFields[i]:enable(false) end

    if f.help ~= nil then
        if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
            local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
            rf2ethos.formFields[i]:help(helpTxt)
        end
    end

end

function ui.fieldLabel(f, i, l)

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
    if rf2ethos.radio.navButtonOffset ~= nil then colStart = colStart - rf2ethos.radio.navButtonOffset end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.menuButtonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight

    rf2ethos.formFields['menu'] = form.addLine(title)
    rf2ethos.ui.navigationButtons(w - 5, rf2ethos.radio.linePaddingTop, buttonW, buttonH)
end

function ui.openPage(idx, title, script, extra1, extra2, extra3, extra5, extra5)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.isReady = false
    rf2ethos.formFields = {}
    rf2ethos.formLines = {}

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
    collectgarbage()

    if rf2ethos.Page.openPage then
        rf2ethos.Page.openPage(idx, title, script, extra1, extra2, extra3, extra5, extra5)
    else

        rf2ethos.lastIdx = idx
        rf2ethos.lastTitle = title
        rf2ethos.lastScript = script

        local fieldAR = {}

        rf2ethos.uiState = rf2ethos.uiStatus.pages
        rf2ethos.triggers.isReady = false

        longPage = false

        form.clear()

        rf2ethos.lastPage = script

        if rf2ethos.Page.pageTitle ~= nil then
            rf2ethos.ui.fieldHeader(rf2ethos.Page.pageTitle)
        else
            rf2ethos.ui.fieldHeader(title)
        end

        if rf2ethos.Page.headerLine ~= nil then
            local headerLine = form.addLine("")
            local headerLineText =
                form.addStaticText(headerLine, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.navbuttonHeight}, rf2ethos.Page.headerLine)
        end

        formLineCnt = 0

        for i = 1, #rf2ethos.Page.fields do
            local f = rf2ethos.Page.fields[i]
            local l = rf2ethos.Page.labels
            local pageValue = f
            local pageIdx = i
            local currentField = i

            rf2ethos.ui.fieldLabel(f, i, l)

            if f.hidden ~= true then

                if f.type == 0 then
                    rf2ethos.ui.fieldStaticText(f, i)
                elseif f.table or f.type == 1 then
                    rf2ethos.ui.fieldChoice(f, i)
                elseif f.type == 2 then
                    rf2ethos.ui.fieldNumber(f, i)
                elseif f.type == 3 then
                    rf2ethos.ui.fieldText(f, i)
                else
                    rf2ethos.ui.fieldNumber(f, i)
                end

            end
        end
    end
    collectgarbage()
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
    if rf2ethos.Page.navButtons == nil then
        navButtons = {menu = true, save = true, reload = true, help = true}
    else
        navButtons = rf2ethos.Page.navButtons
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

        rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = menuOffset, y = y, w = w, h = h}, {
            text = "MENU",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                if rf2ethos.Page and rf2ethos.Page.onNavMenu then
                    rf2ethos.Page.onNavMenu(rf2ethos.Page)
                else
                    rf2ethos.ui.openMainMenu()
                end
            end
        })
        rf2ethos.formNavigationFields['menu']:focus()
    end

    -- SAVE BTN
    if navButtons.save ~= nil and navButtons.save == true then

        rf2ethos.formNavigationFields['save'] = form.addButton(line, {x = saveOffset, y = y, w = w, h = h}, {
            text = "SAVE",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                if rf2ethos.Page and rf2ethos.Page.onSaveMenu then
                    rf2ethos.Page.onSaveMenu(rf2ethos.Page)
                else
                    rf2ethos.triggers.triggerSave = true
                end
            end
        })
    end

    -- RELOAD BTN
    if navButtons.reload ~= nil and navButtons.reload == true then

        rf2ethos.formNavigationFields['reload'] = form.addButton(line, {x = reloadOffset, y = y, w = w, h = h}, {
            text = "RELOAD",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()

                if rf2ethos.Page and rf2ethos.Page.onReloadMenu then
                    rf2ethos.Page.onReloadMenu(rf2ethos.Page)
                else
                    rf2ethos.triggers.triggerReload = true
                end
                return true
            end
        })
    end

    -- TOOL BUTTON
    if navButtons.tool ~= nil and navButtons.tool == true then
        rf2ethos.formNavigationFields['tool'] = form.addButton(line, {x = toolOffset, y = y, w = wS, h = h}, {
            text = "*",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.Page.onToolMenu()
            end
        })
    end

    -- HELP BUTTON
    if navButtons.help ~= nil and navButtons.help == true then

        local help = assert(compile.loadScript(rf2ethos.config.toolDir .. "help/pages.lua"))()
        local section = string.gsub(rf2ethos.lastScript, ".lua", "") -- remove .lua

        rf2ethos.formNavigationFields['help'] = form.addButton(line, {x = helpOffset, y = y, w = wS, h = h}, {
            text = "?",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                if rf2ethos.Page and rf2ethos.Page.onHelpMenu then
                    rf2ethos.Page.onHelpMenu(rf2ethos.Page)
                else
                    rf2ethos.ui.openPagehelp(help.data, section)
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
        qr = rf2ethos.config.toolDir .. helpdata[section]["qrCODE"]
    else
        qr = nil
    end

    local message = ""

    -- find point that qr starts
    local qw = rf2ethos.radio.helpQrCodeSize
    local qh = rf2ethos.radio.helpQrCodeSize + rf2ethos.radio.buttonPadding
    local qx = (rf2ethos.config.lcdWidth - qw - rf2ethos.radio.buttonPadding / 2) - rf2ethos.radio.buttonPadding

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

            if qr ~= nil then
                local qy = rf2ethos.radio.buttonPadding
                local qx = rf2ethos.config.lcdWidth - qw - rf2ethos.radio.buttonPadding / 2
                lcd.drawBitmap(qx, qy, bitmap, qw, qh)
            end

        end,
        options = TEXT_LEFT
    })

end

return ui
