local pages = {}

pages[#pages + 1] = {title = "SCORPION", folder = "scorp", image = "scorpion.png"}
pages[#pages + 1] = {title = "HOBBYWING 5", folder = "hw5", image = "hobbywing.png"}
pages[#pages + 1] = {title = "YGE", folder = "yge", image = "yge.png"}
pages[#pages + 1] = {title = "FLYROTOR", folder = "flrtr", image = "flrtr.png"}
pages[#pages + 1] = {title = "XDFLY", folder = "flrtr", image = "xdfly.png", disabled = true}

local function openPage(pidx, title, script)

    rf2ethos.msp.protocol.mspIntervalOveride = nil

    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

    rf2ethos.app.triggers.isReady = false
    rf2ethos.app.uiState = rf2ethos.app.uiStatus.mainMenu

    form.clear()

    rf2ethos.lastIdx = idx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    ESC = {}

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.app.preferences.interface.iconSize
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    local w, h = rf2ethos.utils.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = rf2ethos.app.radio.buttonPadding

    local sc
    local panel

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW - 10

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x, y = rf2ethos.app.radio.linePaddingTop, w = buttonW, h = rf2ethos.app.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.lastIdx = nil
            rf2ethos.lastPage = nil

            if rf2ethos.Page and rf2ethos.Page.onNavMenu then rf2ethos.Page.onNavMenu(rf2ethos.Page) end

            rf2ethos.app.ui.openMainMenu()
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
        padding = rf2ethos.app.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.app.radio.buttonsPerRow - padding
        buttonH = rf2ethos.app.radio.navbuttonHeight
        numPerRow = rf2ethos.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.app.radio.buttonPaddingSmall
        buttonW = rf2ethos.app.radio.buttonWidthSmall
        buttonH = rf2ethos.app.radio.buttonHeightSmall
        numPerRow = rf2ethos.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.app.radio.buttonPadding
        buttonW = rf2ethos.app.radio.buttonWidth
        buttonH = rf2ethos.app.radio.buttonHeight
        numPerRow = rf2ethos.app.radio.buttonsPerRow
    end

    local ESCMenu = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()

    local lc = 0
    local bx = 0

    if rf2ethos.app.gfx_buttons["escmain"] == nil then rf2ethos.app.gfx_buttons["escmain"] = {} end
    if rf2ethos.app.menuLastSelected["escmain"] == nil then rf2ethos.app.menuLastSelected["escmain"] = 1 end

    for pidx, pvalue in ipairs(ESCMenu.pages) do

        if lc == 0 then
            if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if rf2ethos.config.iconsizeParam ~= 0 then
            if rf2ethos.app.gfx_buttons["escmain"][pidx] == nil then rf2ethos.app.gfx_buttons["escmain"][pidx] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/esc/" .. pvalue.image) end
        else
            rf2ethos.app.gfx_buttons["escmain"][pidx] = nil
        end

        rf2ethos.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.app.gfx_buttons["escmain"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.app.menuLastSelected["escmain"] = pidx
                rf2ethos.app.ui.progessDisplay()
                rf2ethos.app.ui.openPage(pidx, pvalue.folder, "esc_tool.lua")
            end
        })

        if pvalue.disabled == true then rf2ethos.app.formFields[pidx]:enable(false) end

        if rf2ethos.app.menuLastSelected["escmain"] == pidx then rf2ethos.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    rf2ethos.app.triggers.closeProgressLoader = true

    return
end

rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages

return {title = "ESC", pages = pages, openPage = openPage}
