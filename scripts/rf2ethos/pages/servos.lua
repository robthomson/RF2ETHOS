
-- create 16 servos in disabled state
local servoTable = {}
servoTable = {}
servoTable['sections'] = {}

local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()


local function buildServoTable()

        for i = 1, rf2ethos.config.servoCount do
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
                                -- this is because when swiching models this may or may not have
                                -- been created.
                                if servoTable[4] == nil then
                                        servoTable[4] = {}
                                end
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


        rf2ethos.bg.protocol.mspIntervalOveride = nil

        if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. rf2ethos.config.environment.minor .. rf2ethos.config.environment.revision)) < rf2ethos.config.ethosVersion then return end

        rf2ethos.app.triggers.isReady = false
        rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages

        form.clear()

        rf2ethos.app.lastIdx = idx
        rf2ethos.app.lastTitle = title
        rf2ethos.app.lastScript = script

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

        buttonW = 100
        local x = windowWidth - buttonW - 10

        rf2ethos.app.ui.fieldHeader("Servos")



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

        local lc = 0
        local bx = 0


        if rf2ethos.app.gfx_buttons["servos"] == nil then rf2ethos.app.gfx_buttons["servos"] = {} end
        if rf2ethos.app.menuLastSelected["servos"] == nil then rf2ethos.app.menuLastSelected["servos"] = 1 end

        if rf2ethos.app.gfx_buttons["servos"] == nil then rf2ethos.app.gfx_buttons["servos"] = {} end
        if rf2ethos.app.menuLastSelected["servos"] == nil then rf2ethos.app.menuLastSelected["servos"] = 1 end

        for pidx, pvalue in ipairs(servoTable) do

                if pvalue.disabled ~= true then
                
                                if pvalue.section == "swash" and lc == 0 then
                                        local headerLine = form.addLine("")
                                        local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.app.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.app.radio.navbuttonHeight}, headerLineText())
                                end

                                if pvalue.section == "tail" then
                                        local headerLine = form.addLine("")
                                        local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.app.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.app.radio.navbuttonHeight}, "TAIL")
                                end                

                                if pvalue.section == "other" then
                                        local headerLine = form.addLine("")
                                        local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.app.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.app.radio.navbuttonHeight}, "TAIL")
                                end 
                
                                if lc == 0 then
                                        if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
                                        if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
                                        if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.app.radio.buttonPadding end
                                end

                                if lc >= 0 then bx = (buttonW + padding) * lc end

                                if rf2ethos.config.iconsizeParam ~= 0 then
                                        if rf2ethos.app.gfx_buttons["servos"][pidx] == nil then rf2ethos.app.gfx_buttons["servos"][pidx] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/servos/" .. pvalue.image) end
                                else
                                        rf2ethos.app.gfx_buttons["servos"][pidx] = nil
                                end

                                rf2ethos.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                                        text = pvalue.title,
                                        icon = rf2ethos.app.gfx_buttons["servos"][pidx],
                                        options = FONT_S,
                                        paint = function()
                                        end,
                                        press = function()
                                                rf2ethos.app.menuLastSelected["servos"] = pidx
                                                rf2ethos.currentServoIndex = pidx
                                                rf2ethos.app.ui.progessDisplay()                           
                                                rf2ethos.app.ui.openPage(pidx, pvalue.title, "servos_tool.lua",servoTable)
                                        end
                                })

                                if pvalue.disabled == true then rf2ethos.app.formFields[pidx]:enable(false) end

                                if rf2ethos.app.menuLastSelected["servos"] == pidx then rf2ethos.app.formFields[pidx]:focus() end

                                lc = lc + 1

                                if lc == numPerRow then lc = 0 end
                end
        end


        rf2ethos.app.triggers.closeProgressLoader = true

        return
end

local function getServoCount(callback, callbackParam)
        local message = {
                command = 120, -- MSP_SERVO_CONFIGURATIONS
                processReply = function(self, buf)
                        local servoCount = rf2ethos.bg.mspHelper.readU8(buf)
                        
                        -- update master one in case changed
                        rf2ethos.config.servoCountNew = servoCount

                        if callback then
                                callback(callbackParam)
                        end        
                end,
                -- 2 servos
                -- simulatorResponse = {
                --        2,
                --        220, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
                --        221, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
                -- }
                -- 4 servos
                simulatorResponse = {
                        4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
                        120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
                }
        }
        rf2ethos.bg.mspQueue:add(message)
end


local function openPageInit(pidx, title, script)

        if rf2ethos.config.servoCount ~= nil then
                        buildServoTable()
                        openPage(pidx, title, script)
        else
                        local message = {
                                command = 120, -- MSP_SERVO_CONFIGURATIONS
                                processReply = function(self, buf)
                                         if #buf >= 10 then
                                                        local servoCount = rf2ethos.bg.mspHelper.readU8(buf)
                                                        
                                                        -- update master one in case changed
                                                        rf2ethos.config.servoCount = servoCount
                                        end
                                end,
                                simulatorResponse = {
                                        4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
                                        120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
                                }
                        }
                        rf2ethos.bg.mspQueue:add(message)
                        
                        local message = {
                                command = 192, -- MSP_SERVO_OVERIDE
                                processReply = function(self, buf)
                                         if #buf >= 10 then
                                         
                                                        for i = 0, rf2ethos.config.servoCount do
                                                                buf.offset = i
                                                                local servoOverride = rf2ethos.bg.mspHelper.readU8(buf)
                                                                if servoOverride == 0 then
                                                                        rf2ethos.utils.log("Servo overide: true")
                                                                        rf2ethos.config.servoOverride = true
                                                                end
                                                        end                                         
                                        end
                                        if rf2ethos.config.servoOverride == nil then
                                                rf2ethos.config.servoOverride = false 
                                        end        
                                end,
                                simulatorResponse = {209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7}
                        }
                        rf2ethos.bg.mspQueue:add(message)                        
                        
        end                
end

local function event(widget, category, value, x, y)

        if category == 5 or value == 35 then
                rf2ethos.app.Page.onNavMenu(self)
                return true
        end

        return false
end

local function onToolMenu(self)

        local buttons
        if rf2ethos.config.servoOverride == false then
                buttons = {
                        {
                                label = "                OK                ",
                                action = function()

                                        -- we cant launch the loader here to se rely on the modules
                                        -- wakeup function to do this
                                        triggerOverRide = true
                                        triggerOverRideAll = true
                                        return true
                                end
                        }, {
                                label = "CANCEL",
                                action = function()
                                        return true
                                end
                        }
                }
        else
                buttons = {
                        {
                                label = "                OK                ",
                                action = function()

                                        -- we cant launch the loader here to se rely on the modules
                                        -- wakup function to do this
                                        triggerOverRide = true
                                        return true
                                end
                        }, {
                                label = "CANCEL",
                                action = function()
                                        return true
                                end
                        }
                }
        end
        local message
        local title
        if rf2ethos.config.servoOverride == false then
                title = "Enable servo overide"
                message = "Servo overide allows you to 'trim' your servo center point in real time."
        else
                title = "Disable servo overide"
                message = "Return control of the servos to the flight controller"
        end

        form.openDialog({
                width = nil,
                title = title,
                message = message,
                buttons = buttons,
                wakeup = function()
                end,
                paint = function()
                end,
                options = TEXT_LEFT
        })

end

local function wakeup()
        if triggerOverRide == true then
                triggerOverRide = false

                if rf2ethos.config.servoOverride == false then
                        rf2ethos.app.audio.playServoOverideEnable = true
                        rf2ethos.app.ui.progessDisplay("Servo overide...", "Enabling servo overide.")
                        rf2ethos.app.Page.servoCenterFocusAllOn(self)
                        rf2ethos.config.servoOverride = true
                else
                        rf2ethos.app.audio.playServoOverideDisable = true
                        rf2ethos.app.ui.progessDisplay("Servo overide...", "Disabling servo overide.")
                        rf2ethos.app.Page.servoCenterFocusAllOff(self)
                        rf2ethos.config.servoOverride = false
                end
        end
        
        local now = os.clock()
        if ((now - lastServoCountTime) >= 2) and rf2ethos.bg.mspQueue:isProcessed() then
                        lastServoCountTime = now
                        
                        getServoCount()
                        
                        if rf2ethos.config.servoCountNew ~= nil then
                                        if rf2ethos.config.servoCountNew ~= rf2ethos.config.servoCount then
                                                        rf2ethos.app.triggers.triggerReloadNoPrompt = true
                                        end
                        end
                        
        end        
        
end

local function servoCenterFocusAllOn(self)

        rf2ethos.app.audio.playServoOverideEnable = true

        for i = 0, #servoTable do
                local message = {
                        command = 193, -- MSP_SET_SERVO_OVERRIDE
                        payload = {i}
                }
                rf2ethos.bg.mspHelper.writeU16(message.payload, 0)
                rf2ethos.bg.mspQueue:add(message)
        end
        rf2ethos.app.triggers.isReady = true
        rf2ethos.app.triggers.closeProgressLoader = true
end

local function servoCenterFocusAllOff(self)

        for i = 0, #servoTable do
                local message = {
                        command = 193, -- MSP_SET_SERVO_OVERRIDE
                        payload = {i}
                }
                rf2ethos.bg.mspHelper.writeU16(message.payload, 2001)
                rf2ethos.bg.mspQueue:add(message)
        end
        rf2ethos.app.triggers.isReady = true
        rf2ethos.app.triggers.closeProgressLoader = true
end

local function onNavMenu(self)


        if rf2ethos.config.servoOverride == true or inFocus == true then
                rf2ethos.app.audio.playServoOverideDisable = true
                rf2ethos.config.servoOverride = false
                inFocus = false
                rf2ethos.app.ui.progessDisplay("Servo overide...", "Disabling servo overide.")
                rf2ethos.app.Page.servoCenterFocusAllOff(self)
                rf2ethos.app.triggers.closeProgressLoader = true
        end
        --rf2ethos.app.ui.progessDisplay()
        rf2ethos.app.ui.openMainMenu()

end


return {title = "Servos", 
                event = event, 
                openPage = openPageInit,
                onToolMenu = onToolMenu,
                onNavMenu = onNavMenu,
                servoCenterFocusAllOn = servoCenterFocusAllOn,
                servoCenterFocusAllOff = servoCenterFocusAllOff,                
                wakeup = wakeup,
                navButtons = {menu = true, save = false, reload = true, tool = true, help = true}
                }
