local fields = {}
local labels = {}
local fcStatus = {}
local dataflashSummary = {}
local wakeupScheduler = os.clock()
local status = {}
local summary = {}
local triggerEraseDataFlash = false
local enableWakeup = false

local displayType = 3
local disableType = true
local displayPos
if rf2ethos.config.ethosRunningVersion >= 1516 then
        displayType = 0
        disableType = false
        
        local w, h = rf2ethos.utils.getWindowSize()
        local buttonW = 100
        local buttonWs = buttonW - (buttonW * 20) / 100
        local x = w - 15        
  
        displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = rf2ethos.app.radio.linePaddingTop, w = 100, h = rf2ethos.app.radio.navbuttonHeight}
end 

fields[1] = {t = "Arming Flags", value = "", type = displayType, disable = disableType, position = displayPos}
fields[2] = {t = "Dataflash Free Space", value = "", type = displayType, disable = disableType, position = displayPos}
fields[3] = {t = "Real-time load", value = "", type = displayType, disable = disableType, position = displayPos}
fields[4] = {t = "CPU load", value = "", type = displayType, disable = disableType, position = displayPos}

local function getStatus()
        local message = {
                command = 101, -- MSP_STATUS
                processReply = function(self, buf)
                        -- status.pidCycleTime = rf2ethos.bg.mspHelper.readU16(buf)
                        -- status.gyroCycleTime = rf2ethos.bg.mspHelper.readU16(buf)
                        buf.offset = 12
                        status.realTimeLoad = rf2ethos.bg.mspHelper.readU16(buf)
                        -- print("Real-time load: "..tostring(status.realTimeLoad))
                        status.cpuLoad = rf2ethos.bg.mspHelper.readU16(buf)
                        -- print("CPU load: "..tostring(status.cpuLoad))
                        buf.offset = 18
                        status.armingDisableFlags = rf2ethos.bg.mspHelper.readU32(buf)
                        buf.offset = 24
                        status.profile = rf2ethos.bg.mspHelper.readU8(buf)
                        -- print("Profile: "..tostring(status.profile))
                        buf.offset = 26
                        status.rateProfile = rf2ethos.bg.mspHelper.readU8(buf)
                        -- print("Rate Profile: "..tostring(status.rateProfile))

                end,
                simulatorResponse = {240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1}
        }

        rf2ethos.bg.mspQueue:add(message)
end

local function getDataflashSummary()
        local message = {
                command = 70, -- MSP_DATAFLASH_SUMMARY
                processReply = function(self, buf)
                        -- rf2ethos.print("buf length: "..#buf)
                        local flags = rf2ethos.bg.mspHelper.readU8(buf)
                        summary.ready = (flags & 1) ~= 0
                        summary.supported = (flags & 2) ~= 0
                        summary.sectors = rf2ethos.bg.mspHelper.readU32(buf)
                        summary.totalSize = rf2ethos.bg.mspHelper.readU32(buf)
                        summary.usedSize = rf2ethos.bg.mspHelper.readU32(buf)

                end,
                simulatorResponse = {3, 1, 0, 0, 0, 0, 4, 0, 0, 0, 3, 0, 0}
        }
        rf2ethos.bg.mspQueue:add(message)
end

local function eraseDataflash()
        local message = {
                command = 72, -- MSP_DATAFLASH_ERASE
                processReply = function(self, buf)
                        local summary = {}
                end,
                simulatorResponse = {}
        }
        rf2ethos.bg.mspQueue:add(message)
end

local function postLoad(self)
        --print("postLoad")
end

local function postRead(self)
        --print("postLoad")
end

local function readMSP()
        getStatus()
        getDataflashSummary()
        rf2ethos.app.triggers.isReady = true
        enableWakeup = true
end

local function armingDisableFlagsToString(flags)
        local t = ""
        for i = 0, 25 do
                if (flags & (1 << i)) ~= 0 then
                        if t ~= "" then t = t .. ", " end
                        if i == 0 then t = t .. "No Gyro" end
                        if i == 1 then t = t .. "Fail Safe" end
                        if i == 2 then t = t .. "RX Fail Safe" end
                        if i == 3 then t = t .. "Bad RX Recovery" end
                        if i == 4 then t = t .. "Box Fail Safe" end
                        if i == 5 then t = t .. "Governor" end
                        -- if i == 6 then t = t .. "Crash Detected" end
                        if i == 7 then t = t .. "Throttle" end
                        if i == 8 then t = t .. "Angle" end
                        if i == 9 then t = t .. "Boot Grace Time" end
                        if i == 10 then t = t .. "No Pre Arm" end
                        if i == 11 then t = t .. "Load" end
                        if i == 12 then t = t .. "Calibrating" end
                        if i == 13 then t = t .. "CLI" end
                        if i == 14 then t = t .. "CMS Menu" end
                        if i == 15 then t = t .. "BST" end
                        if i == 16 then t = t .. "MSP" end
                        if i == 17 then t = t .. "Paralyze" end
                        if i == 18 then t = t .. "GPS" end
                        if i == 19 then t = t .. "Resc" end
                        if i == 20 then t = t .. "RPM Filter" end
                        if i == 21 then t = t .. "Reboot Required" end
                        if i == 22 then t = t .. "DSHOT Bitbang" end
                        if i == 23 then t = t .. "Acc Calibration" end
                        if i == 24 then t = t .. "Motor Protocol" end
                        if i == 25 then t = t .. "Arm Switch" end
                end
        end
        if t == "" then t = "N/A" end
        return t
end

local function getFreeDataflashSpace()
        if not summary.supported then return "N/A" end
        local freeSpace = summary.totalSize - summary.usedSize
        return string.format("%.1f MB", freeSpace / (1024 * 1024))
end

local function wakeup()

        -- prevent wakeup running until after initialised
        if enableWakeup == false then return end

        if triggerEraseDataFlash == true then
                rf2ethos.app.audio.playEraseFlash = true
                triggerEraseDataFlash = false

                rf2ethos.app.ui.progessDisplay("Erasing...", "Erasing dataflash.")
                rf2ethos.app.Page.eraseDataflash()
                rf2ethos.app.triggers.isReady = true
        end

        if triggerEraseDataFlash == false then
                local now = os.clock()
                if (now - wakeupScheduler) >= 2 then
                        wakeupScheduler = now
                        firstRun = false
                        if rf2ethos.bg.mspQueue:isProcessed() then

                                getStatus()
                                getDataflashSummary()

                                if rf2ethos.config.ethosRunningVersion < 1516 then
                                   if status.armingDisableFlags ~= nil then
                                                local value = armingDisableFlagsToString(status.armingDisableFlags)
                                                rf2ethos.app.formFields[1] = form.addTextField(rf2ethos.app.formLines[1], nil, function()
                                                        return value
                                                end, function(newValue)
                                                        text = value
                                                end)
                                                rf2ethos.app.formFields[1]:enable(false)
                                        end

                                        if summary.supported == true then
                                                local value = getFreeDataflashSpace()
                                                rf2ethos.app.formFields[2] = form.addTextField(rf2ethos.app.formLines[2], nil, function()
                                                        return value
                                                end, function(newValue)
                                                        text = value
                                                end)
                                                rf2ethos.app.formFields[2]:enable(false)
                                        end

                                        if status.realTimeLoad ~= nil then
                                                local value = status.realTimeLoad
                                                rf2ethos.app.formFields[3] = form.addNumberField(rf2ethos.app.formLines[3], nil, value, value, function()
                                                        return value
                                                end, function(value)
                                                end)
                                                rf2ethos.app.formFields[3]:suffix("%")
                                                rf2ethos.app.formFields[3]:decimals(1)
                                                rf2ethos.app.formFields[3]:enable(false)
                                        end
                                        if status.cpuLoad ~= nil then
                                                local value = status.cpuLoad
                                                rf2ethos.app.formFields[4] = form.addNumberField(rf2ethos.app.formLines[4], nil, value, value, function()
                                                        return value
                                                end, function(value)
                                                end)
                                                rf2ethos.app.formFields[4]:suffix("%")
                                                rf2ethos.app.formFields[4]:decimals(1)
                                                rf2ethos.app.formFields[4]:enable(false)
                                        end                                   
                                else
                                        if status.armingDisableFlags ~= nil then
                                           local value = armingDisableFlagsToString(status.armingDisableFlags)
                                           rf2ethos.app.formFields[1]:value(value)
                                        end

                                        if summary.supported == true then
                                                local value = getFreeDataflashSpace()
                                                rf2ethos.app.formFields[2]:value(value)
                                        end

                                        if status.realTimeLoad ~= nil then
                                                local value =  math.floor(status.realTimeLoad /10)
                                                rf2ethos.app.formFields[3]:value(tostring(value) .. "%")
                                                if value >= 60 then
                                                        rf2ethos.app.formFields[4]:color(RED)
                                                end                                        
                                        end
                                        if status.cpuLoad ~= nil then
                                                local value = status.cpuLoad/10
                                                rf2ethos.app.formFields[4]:value(tostring(value) .. "%")
                                                if value >= 60 then
                                                        rf2ethos.app.formFields[4]:color(RED)
                                                end
                                        end
                                 end   

                                rf2ethos.app.triggers.closeProgressLoader = true
                        end
                end
        end

end

local function onToolMenu(self)

        local buttons = {
                {
                        label = "                OK                ",
                        action = function()

                                -- we cant launch the loader here to se rely on the modules
                                -- wakup function to do this
                                triggerEraseDataFlash = true
                                return true
                        end
                }, {
                        label = "CANCEL",
                        action = function()
                                return true
                        end
                }
        }
        local message
        local title

        title = "Erase"
        message = "Would you like to erase the dataflash?"

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

return {
        read = readMSP,
        write = nil,
        title = "Status",
        reboot = false,
        eepromWrite = false,
        minBytes = 0,
        wakeup = wakeup,
        labels = labels,
        fields = fields,
        refreshswitch = false,
        simulatorResponse = {},
        postLoad = postLoad,
        postRead = postRead,
        eraseDataflash = eraseDataflash,
        onToolMenu = onToolMenu,
        navButtons = {menu = true, save = false, reload = false, tool = true, help = true}
}
