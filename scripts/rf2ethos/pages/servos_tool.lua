local labels = {}
local fields = {}

local inFocus = false
local triggerOverRide = false
local triggerOverRideAll = false
local inOverRide = false
local triggerCenterChange = false
local currentServoCenter
local lastSetServoCenter
local lastServoChangeTime = os.clock()
local servoIndex = rf2ethos.currentServoIndex - 1
local isSaving = false

local servoCount
local configs = {}

if rf2ethos.tailMode == 1 or rf2ethos.tailMode == 2 then
    servoTable = {"CYCLIC PITCH", "CYCLIC LEFT", "CYCLIC RIGHT"}
else
    servoTable = {"CYCLIC PITCH", "CYCLIC LEFT", "CYCLIC RIGHT", "TAIL"}
end

local function servoCenterFocusAllOn(self)

    rf2ethos.audio.playServoOverideEnable = true

    for i = 0, #configs do
        local message = {
            command = 193, -- MSP_SET_SERVO_OVERRIDE
            payload = {i}
        }
        rf2ethos.mspHelper.writeU16(message.payload, 0)
        rf2ethos.mspQueue:add(message)
    end
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
end

local function servoCenterFocusAllOff(self)

    for i = 0, #configs do
        local message = {
            command = 193, -- MSP_SET_SERVO_OVERRIDE
            payload = {i}
        }
        rf2ethos.mspHelper.writeU16(message.payload, 2001)
        rf2ethos.mspQueue:add(message)
    end
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
end

local function servoCenterFocusOff(self)
    local message = {
        command = 193, -- MSP_SET_SERVO_OVERRIDE
        payload = {servoIndex}
    }
    rf2ethos.mspHelper.writeU16(message.payload, 2001)
    rf2ethos.mspQueue:add(message)
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
end

local function servoCenterFocusOn(self)
    local message = {
        command = 193, -- MSP_SET_SERVO_OVERRIDE
        payload = {servoIndex}
    }
    rf2ethos.mspHelper.writeU16(message.payload, 0)
    rf2ethos.mspQueue:add(message)
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
    rf2ethos.triggers.closeProgressLoader = true
end

local function saveServoSettings(self)

    local servoCenter = math.floor(configs[servoIndex]['mid'])
    local servoMin = math.floor(configs[servoIndex]['min'])
    local servoMax = math.floor(configs[servoIndex]['max'])
    local servoScaleNeg = math.floor(configs[servoIndex]['scaleNeg'])
    local servoScalePos = math.floor(configs[servoIndex]['scalePos'])
    local servoRate = math.floor(configs[servoIndex]['rate'])
    local servoSpeed = math.floor(configs[servoIndex]['speed'])
    local servoFlags = math.floor(configs[servoIndex]['flags'])
    local servoReverse = math.floor(configs[servoIndex]['reverse'])
    local servoGeometry = math.floor(configs[servoIndex]['geometry'])

    if servoReverse == 0 and servoGeometry == 0 then
        servoFlags = 0
    elseif servoReverse == 1 and servoGeometry == 0 then
        servoFlags = 1
    elseif servoReverse == 0 and servoGeometry == 1 then
        servoFlags = 2
    elseif servoReverse == 1 and servoGeometry == 1 then
        servoFlags = 3
    end

    local message = {
        command = 212, -- MSP_SET_SERVO_CONFIGURATION
        payload = {}
    }
    rf2ethos.mspHelper.writeU8(message.payload, servoIndex)
    rf2ethos.mspHelper.writeU16(message.payload, servoCenter)
    rf2ethos.mspHelper.writeU16(message.payload, servoMin)
    rf2ethos.mspHelper.writeU16(message.payload, servoMax)
    rf2ethos.mspHelper.writeU16(message.payload, servoScaleNeg)
    rf2ethos.mspHelper.writeU16(message.payload, servoScalePos)
    rf2ethos.mspHelper.writeU16(message.payload, servoRate)
    rf2ethos.mspHelper.writeU16(message.payload, servoSpeed)
    rf2ethos.mspHelper.writeU16(message.payload, servoFlags)

    if rf2ethos.config.mspTxRxDebug == true or rf2ethos.config.logEnable == true then
        local logData = "{" .. rf2ethos.utils.joinTableItems(message.payload, ", ") .. "}"

        rf2ethos.utils.log(logData)

        if rf2ethos.config.mspTxRxDebug == true then print(logData) end

    end
    rf2ethos.mspQueue:add(message)

end

local function onSaveMenuProgress()
    rf2ethos.ui.progessDisplay("Saving...", "Saving data...")
    saveServoSettings()
    rf2ethos.mspQueue:add(mspEepromWrite)
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
end

local function onSaveMenu()
    local buttons = {
        {
            label = "        OK        ",
            action = function()
                rf2ethos.audio.playSaving = true
                isSaving = true

                return true
            end
        }, {
            label = "CANCEL",
            action = function()
                return true
            end
        }
    }
    local theTitle = "Save settings"
    local theMsg = "Save current page to flight controller"

    form.openDialog({
        width = nil,
        title = theTitle,
        message = theMsg,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
        end,
        options = TEXT_LEFT
    })

    rf2ethos.triggers.triggerSave = false
end

local function onToolMenu(self)

    local buttons
    if inOverRide == false then
        buttons = {
            {
                label = "        ALL        ",
                action = function()

                    -- we cant launch the loader here to se rely on the modules
                    -- wakup function to do this
                    triggerOverRide = true
                    triggerOverRideAll = true
                    return true
                end
            }, {
                label = servoTable[servoIndex + 1],
                action = function()

                    -- we cant launch the loader here to se rely on the modules
                    -- wakup function to do this
                    triggerOverRide = true
                    triggerOverRideAll = false
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
                label = "        OK        ",
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
    if inOverRide == false then
        title = "Enable servo overide"
        message = "Enable servo overide for either all servos or just this servo.\r\n\r\nThis will result in all values on this page being saved when adjusting the servo center point."
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

local function onNavMenu(self)

    if inOverRide == true or inFocus == true then

        rf2ethos.audio.playServoOverideDisable = true

        inOverRide = false
        inFocus = false

        rf2ethos.ui.progessDisplay("Servo overide...", "Disabling servo overide.")

        if triggerOverRideAll == true then
            rf2ethos.Page.servoCenterFocusAllOff(self)
        else
            rf2ethos.Page.servoCenterFocusOff(self)
        end
        rf2ethos.triggers.closeProgressLoader = true
    end

    rf2ethos.ui.progessDisplay()
    rf2ethos.ui.openPage(rf2ethos.lastIdx, rf2ethos.lastTitle, "servos.lua")

end

local function wakeup(self)

    if isSaving == true then
        onSaveMenuProgress()
        isSaving = false
    end

    -- filter changes to servo center - essentially preventing queue getting flooded    
    if inFocus == true or inOverRide == true then

        currentServoCenter = configs[servoIndex]['mid']

        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastServoChangeTime) >= settleTime) and rf2ethos.mspQueue:isProcessed() then
            if currentServoCenter ~= lastSetServoCenter then
                lastSetServoCenter = currentServoCenter
                lastServoChangeTime = now
                self.saveServoSettings(self)
            end
        end
    end

    if triggerOverRide == true then
        triggerOverRide = false

        if inOverRide == false then

            rf2ethos.audio.playServoOverideEnable = true

            rf2ethos.ui.progessDisplay("Servo overide...", "Enabling servo overide.")

            if triggerOverRideAll == true then
                rf2ethos.Page.servoCenterFocusAllOn(self)
            else
                rf2ethos.Page.servoCenterFocusOn(self)
            end
            inOverRide = true
        else

            rf2ethos.audio.playServoOverideDisable = true

            rf2ethos.ui.progessDisplay("Servo overide...", "Disabling servo overide.")

            if triggerOverRideAll == true then
                rf2ethos.Page.servoCenterFocusAllOff(self)
            else
                rf2ethos.Page.servoCenterFocusOff(self)
            end
            inOverRide = false

        end
    end
end

function preSavePayload(payload)
    -- shift index to correct number
    payload[1] = servoIndex
    return payload
end

local function getServoConfigurations(callback, callbackParam)
    local message = {
        command = 120, -- MSP_SERVO_CONFIGURATIONS
        processReply = function(self, buf)
            servoCount = rf2ethos.mspHelper.readU8(buf)
            -- print("Servo count "..tostring(servoCount))
            for i = 0, servoCount - 1 do
                local config = {}

                config.name = servoTable[servoIndex + 1]
                config.mid = rf2ethos.mspHelper.readU16(buf)
                config.min = rf2ethos.mspHelper.readS16(buf)
                config.max = rf2ethos.mspHelper.readS16(buf)
                config.scaleNeg = rf2ethos.mspHelper.readU16(buf)
                config.scalePos = rf2ethos.mspHelper.readU16(buf)
                config.rate = rf2ethos.mspHelper.readU16(buf)
                config.speed = rf2ethos.mspHelper.readU16(buf)
                config.flags = rf2ethos.mspHelper.readU16(buf)

                if config.flags == 1 or config.flags == 3 then
                    config.reverse = 1
                else
                    config.reverse = 0
                end

                if config.flags == 2 or config.flags == 3 then
                    config.geometry = 1
                else
                    config.geometry = 0
                end

                configs[i] = config

            end
            callback(callbackParam)
        end,
        -- 2 servos
        -- simulatorResponse = {
        --    2,
        --    220, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
        --    221, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
        -- }
        -- 4 servos
        simulatorResponse = {
            4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
            120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
        }
    }
    rf2ethos.mspQueue:add(message)
end

local function getServoConfigurationsEnd(callbackParam)
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
end

local function openPage(idx, title, script, extra1, extra2, extra3, extra5, extra5)

    configs = {}
    configs[servoIndex] = {}
    configs[servoIndex]['name'] = servoTable[servoIndex + 1]
    configs[servoIndex]['mid'] = 0
    configs[servoIndex]['min'] = 0
    configs[servoIndex]['max'] = 0
    configs[servoIndex]['scaleNeg'] = 0
    configs[servoIndex]['scalePos'] = 0
    configs[servoIndex]['rate'] = 0
    configs[servoIndex]['speed'] = 0
    configs[servoIndex]['flags'] = 0
    configs[servoIndex]['geometry'] = 0
    configs[servoIndex]['reverse'] = 0

    rf2ethos.formLines = {}

    rf2ethos.lastIdx = idx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    form.clear()

    if rf2ethos.Page.pageTitle ~= nil then
        rf2ethos.ui.fieldHeader(rf2ethos.Page.pageTitle)
    else
        rf2ethos.ui.fieldHeader(title)
    end

    if rf2ethos.Page.headerLine ~= nil then
        local headerLine = form.addLine("")
        local headerLineText = form.addStaticText(headerLine, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.navbuttonHeight}, rf2ethos.Page.headerLine)
    end

    if configs[servoIndex] and servoTable[servoIndex + 1] then
        local idx = 1
        rf2ethos.formLines[idx] = form.addLine("Servo")
        rf2ethos.formFields[idx] = form.addTextField(rf2ethos.formLines[idx], nil, function()
            return configs[servoIndex]['name']
        end, function(value)
            configs[servoIndex]['name'] = value
        end)
        rf2ethos.formFields[idx]:enable(false)
    end

    if configs[servoIndex]['mid'] ~= nil then
        local idx = 2
        local minValue = 50
        local maxValue = 2250
        local defaultValue = 1500
        local suffix = nil
        local helpTxt = rf2ethos.fieldHelpTxt['servoMid']['t']
        rf2ethos.formLines[idx] = form.addLine("Center")
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['mid']
        end, function(value)
            configs[servoIndex]['mid'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['min'] ~= nil then
        local idx = 3
        local minValue = -1000
        local maxValue = 1000
        local defaultValue = -700
        local suffix = nil
        rf2ethos.formLines[idx] = form.addLine("Minimum")
        local helpTxt = rf2ethos.fieldHelpTxt['servoMin']['t']
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['min']
        end, function(value)
            configs[servoIndex]['min'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['max'] ~= nil then
        local idx = 4
        local minValue = -1000
        local maxValue = 1000
        local defaultValue = 700
        local suffix = nil
        local helpTxt = rf2ethos.fieldHelpTxt['servoMax']['t']
        rf2ethos.formLines[idx] = form.addLine("Maximum")
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['max']
        end, function(value)
            configs[servoIndex]['max'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['scaleNeg'] ~= nil then
        local idx = 5
        local minValue = 100
        local maxValue = 1000
        local defaultValue = 500
        local suffix = nil
        local helpTxt = rf2ethos.fieldHelpTxt['servoScaleNeg']['t']
        rf2ethos.formLines[idx] = form.addLine("Scale negative")
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['scaleNeg']
        end, function(value)
            configs[servoIndex]['scaleNeg'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['scalePos'] ~= nil then
        local idx = 6
        local minValue = 100
        local maxValue = 1000
        local defaultValue = 500
        local suffix = nil
        local helpTxt = rf2ethos.fieldHelpTxt['servoScalePos']['t']
        rf2ethos.formLines[idx] = form.addLine("Scale positive")
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['scalePos']
        end, function(value)
            configs[servoIndex]['scalePos'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['rate'] ~= nil then
        local idx = 7
        local minValue = 50
        local maxValue = 5000
        local defaultValue = 333
        local suffix = "Hz"
        local helpTxt = rf2ethos.fieldHelpTxt['servoRate']['t']
        rf2ethos.formLines[idx] = form.addLine("Rate")
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['rate']
        end, function(value)
            configs[servoIndex]['rate'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['speed'] ~= nil then
        local idx = 8
        local minValue = 0
        local maxValue = 60000
        local defaultValue = 0
        local suffix = "ms"
        local helpTxt = rf2ethos.fieldHelpTxt['servoSpeed']['t']
        rf2ethos.formLines[idx] = form.addLine("Speed")
        rf2ethos.formFields[idx] = form.addNumberField(rf2ethos.formLines[idx], nil, minValue, maxValue, function()
            return configs[servoIndex]['speed']
        end, function(value)
            configs[servoIndex]['speed'] = value
        end)
        if suffix ~= nil then rf2ethos.formFields[idx]:suffix(suffix) end
        if defaultValue ~= nil then rf2ethos.formFields[idx]:default(defaultValue) end
        if helpTxt ~= nil then rf2ethos.formFields[idx]:help(helpTxt) end
    end

    if configs[servoIndex]['flags'] ~= nil then
        local idx = 9
        local minValue = 0
        local maxValue = 1000
        local table = {"NO", "YES"}
        local tableIdxInc = -1
        local value
        rf2ethos.formLines[idx] = form.addLine("Reverse")
        rf2ethos.formFields[idx] = form.addChoiceField(rf2ethos.formLines[idx], nil, rf2ethos.utils.convertPageValueTable(table, tableIdxInc), function()
            return configs[servoIndex]['reverse']
        end, function(value)
            configs[servoIndex]['reverse'] = value
        end)
    end

    if configs[servoIndex]['flags'] ~= nil then
        local idx = 10
        local minValue = 0
        local maxValue = 1000
        local table = {"NO", "YES"}
        local tableIdxInc = -1
        local value
        rf2ethos.formLines[idx] = form.addLine("Geometry")
        rf2ethos.formFields[idx] = form.addChoiceField(rf2ethos.formLines[idx], nil, rf2ethos.utils.convertPageValueTable(table, tableIdxInc), function()
            return configs[servoIndex]['geometry']
        end, function(value)
            configs[servoIndex]['geometry'] = value
        end)
    end

    getServoConfigurations(getServoConfigurationsEnd)

end

local function event(widget, category, value, x, y)

    if value == KEY_ENTER_LONG then
        onSaveMenu()
        system.killEvents(KEY_ENTER_LONG)
        return true
    end

    if category == 5 or value == 35 then
        rf2ethos.ui.openPage(pidx, "Servos", "servos.lua")
        return true
    end

    return false
end

return {
    title = "Servos",
    reboot = false,
    eepromWrite = true,
    event = event,
    setValues = setValues,
    servoChanged = servoChanged,
    servoCenterFocusOn = servoCenterFocusOn,
    servoCenterFocusOff = servoCenterFocusOff,
    servoCenterFocusAllOn = servoCenterFocusAllOn,
    servoCenterFocusAllOff = servoCenterFocusAllOff,
    saveServoSettings = saveServoSettings,
    onToolMenu = onToolMenu,
    wakeup = wakeup,
    openPage = openPage,
    onNavMenu = onNavMenu,
    onSaveMenu = onSaveMenu,
    pageTitle = "Servos",
    navButtons = {menu = true, save = true, reload = true, tool = true, help = true}

}
