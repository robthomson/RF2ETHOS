
-- create 16 servos in disabled state
local servoTable = {}
servoTable = {}
servoTable['sections'] = {}

if rf2ethos.config.servoCount == nil then
    rf2ethos.config.servoCount = 4
end

for i = 1, 16 do
    servoTable[i] = {}
    servoTable[i] = {}
    servoTable[i]['title'] = "SERVO " .. i
    servoTable[i]['image'] = "servo".. i .. ".png"
    servoTable[i]['disabled'] = true
end

for i = 1,rf2ethos.config.servoCount do
    -- enable actual number of servos
    servoTable[i]['disabled'] = false
    

    if rf2ethos.config.swashMode == 0 then
        -- we do nothing as we cannot determine any servo names
    elseif rf2ethos.config.swashMode == 1 then
        -- servo mode is direct - only servo for sure we know name of is tail
        if rf2ethos.config.tailMode == 0 then
            servoTable[4]['title'] = "TAIL" 
            servoTable[4]['image'] = "tail.png"
            servoTable[4]['section'] = 1
        end
    elseif rf2ethos.config.swashMode == 2 or rf2ethos.config.swashMode == 3 or rf2ethos.config.swashMode == 4 then
        -- servo mode is cppm - 
        servoTable[1]['title'] = "CYC. PITCH" 
        servoTable[1]['image'] = "cpitch.png" 
  
        servoTable[2]['title'] = "CYC. LEFT" 
        servoTable[2]['image'] = "cleft.png" 
    
        servoTable[3]['title'] = "CYC. RIGHT" 
        servoTable[3]['image'] = "cright.png" 
     
        if rf2ethos.config.tailMode == 0 then
            servoTable[4]['title'] = "TAIL" 
            servoTable[4]['image'] = "tail.png"
        else
            --servoTable[4]['disabled'] = true
        end
    elseif rf2ethos.config.swashMode == 5 or rf2ethos.config.swashMode == 6 then
        -- servo mode is fpm 90
        --servoTable[3]['disabled'] = true 
        if rf2ethos.config.tailMode == 0 then
            servoTable[4]['title'] = "TAIL" 
            servoTable[4]['image'] = "tail.png"
        else
            --servoTable[4]['disabled'] = true        
        end
    end 
end

local function swashMixerType()
    local txt
    if rf2ethos.config.swashMode == 0 then
       txt = "NONE"
    elseif rf2ethos.config.swashMode == 1 then
       txt = "DIRECT"
    elseif rf2ethos.config.swashMode == 2 then
       txt = "CPPM 120°"
    elseif rf2ethos.config.swashMode == 3 then
       txt = "CPPM 135°"
    elseif rf2ethos.config.swashMode == 4 then
       txt = "CPPM 140°"
    elseif rf2ethos.config.swashMode == 5 then
       txt = "FPPM 90° L"
    elseif rf2ethos.config.swashMode == 6 then
       txt = "FPPM 90° R"
    else
        txt = "UNKNOWN"
    end
    
    return txt
end

local function openPage(pidx, title, script)

    rf2ethos.protocol.mspIntervalOveride = nil

    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

    rf2ethos.triggers.isReady = false
    rf2ethos.uiState = rf2ethos.uiStatus.mainMenu

    form.clear()

    rf2ethos.lastIdx = idx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

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

    buttonW = 100
    local x = windowWidth - buttonW - 10

    if rf2ethos.Page.pageTitle ~= nil then
        rf2ethos.ui.fieldHeader(rf2ethos.Page.pageTitle)
    else
        rf2ethos.ui.fieldHeader(title)
    end


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

    local lc = 0
    local bx = 0


    if rf2ethos.gfx_buttons["servos"] == nil then rf2ethos.gfx_buttons["servos"] = {} end
    if rf2ethos.menuLastSelected["servos"] == nil then rf2ethos.menuLastSelected["servos"] = 1 end

    if rf2ethos.gfx_buttons["servos"] == nil then rf2ethos.gfx_buttons["servos"] = {} end
    if rf2ethos.menuLastSelected["servos"] == nil then rf2ethos.menuLastSelected["servos"] = 1 end

    for pidx, pvalue in ipairs(servoTable) do

        if pvalue.disabled ~= true then
        
                if pvalue.section == "swash" and lc == 0 then
                    local headerLine = form.addLine("")
                    local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.navbuttonHeight}, headerLineText())
                end

                if pvalue.section == "tail" then
                    local headerLine = form.addLine("")
                    local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.navbuttonHeight}, "TAIL")
                end        

                if pvalue.section == "other" then
                    local headerLine = form.addLine("")
                    local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.navbuttonHeight}, "TAIL")
                end 
        
                if lc == 0 then
                    if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
                    if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
                    if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.radio.buttonPadding end
                end

                if lc >= 0 then bx = (buttonW + padding) * lc end

                if rf2ethos.config.iconsizeParam ~= 0 then
                    if rf2ethos.gfx_buttons["servos"][pidx] == nil then rf2ethos.gfx_buttons["servos"][pidx] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/servos/" .. pvalue.image) end
                else
                    rf2ethos.gfx_buttons["servos"][pidx] = nil
                end

                rf2ethos.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                    text = pvalue.title,
                    icon = rf2ethos.gfx_buttons["servos"][pidx],
                    options = FONT_S,
                    paint = function()
                    end,
                    press = function()
                        rf2ethos.menuLastSelected["servos"] = pidx
                        rf2ethos.currentServoIndex = pidx
                        rf2ethos.ui.progessDisplay()
                        rf2ethos.ui.openPage(pidx, pvalue.title, "servos_tool.lua",servoTable)

                    end
                })

                if pvalue.disabled == true then rf2ethos.formFields[pidx]:enable(false) end

                if rf2ethos.menuLastSelected["servos"] == pidx then rf2ethos.formFields[pidx]:focus() end

                lc = lc + 1

                if lc == numPerRow then lc = 0 end
        end
    end


    rf2ethos.triggers.closeProgressLoader = true

    return
end

rf2ethos.uiState = rf2ethos.uiStatus.pages

return {title = "Servos", openPage = openPage,navButtons = {menu = true, save = false, reload = false, tool = false, help = true}}
