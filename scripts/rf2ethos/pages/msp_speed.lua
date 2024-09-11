local line = {}
local fields = {}

local formLoaded = false
local triggerStart = false
local startTest = false
local startTestTime = os.clock()
local startTestLength = 30

local testLoader
local testLoaderDisplay = false
local testLoaderUpdateRate = 2
local testLoaderUpdateTime = os.clock()
local testLoaderStepSize = 100 / (startTestLength / 2)
local testLoaderStepSizeValue = 0

local mspQueryStartTime
local mspQueryTimeCount = 0
local getMSPCount = 0

local mspSpeedTest = false
mspSpeedTestStats = {}
mspSpeedTestStats['total'] = 0
mspSpeedTestStats['success'] = 0
mspSpeedTestStats['total'] = 0
mspSpeedTestStats['retries'] = 0
mspSpeedTestStats['timeouts'] = 0
mspSpeedTestStats['checksum'] = 0

local space = "          "

local function openPage(pidx, title, script)

    rf2ethos.lastIdx = pidx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    local w, h = rf2ethos.utils.getWindowSize()

    local y = rf2ethos.radio.linePaddingTop

    form.clear()

    local titleline = form.addLine("Msp speed")

    local buttonW = 100
    local buttonWs = buttonW - (buttonW * 20) / 100
    local x = w - 10

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x - 5 - buttonW - buttonWs - 5 - buttonWs, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.ui.openMainMenu()

        end
    })
    rf2ethos.formNavigationFields['menu']:focus()

    -- ACTION BUTTON
    rf2ethos.formNavigationFields['tool'] = form.addButton(line, {x = x - 5 - buttonWs - buttonWs, y = rf2ethos.radio.linePaddingTop, w = buttonWs, h = rf2ethos.radio.navbuttonHeight}, {
        text = "*",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            triggerStart = true
        end
    })

    -- HELP BUTTON
    local help = assert(compile.loadScript(rf2ethos.config.toolDir .. "help/pages.lua"))()
    local section = string.gsub(rf2ethos.lastScript, ".lua", "") -- remove .lua
    rf2ethos.formNavigationFields['help'] = form.addButton(line, {x = x - buttonWs, y = rf2ethos.radio.linePaddingTop, w = buttonWs, h = rf2ethos.radio.navbuttonHeight}, {
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
    

    line['total'] = form.addLine("Total queries")
    fields['total'] = form.addStaticText(line['total'], nil, space .. "-")

    line['success'] = form.addLine("Successful queries")
    fields['success'] = form.addStaticText(line['success'], nil, space .. "-")    

    line['timeouts'] = form.addLine("Timeouts")
    fields['timeouts'] = form.addStaticText(line['timeouts'], nil, space .. "-")      

    line['retries'] = form.addLine("Retries")
    fields['retries'] = form.addStaticText(line['retries'], nil, space .. "-")         

    line['checksum'] = form.addLine("Checksum errors")
    fields['checksum'] = form.addStaticText(line['checksum'], nil, space .. "-")    

    line['time'] = form.addLine("Average query time")
    fields['time'] = form.addStaticText(line['time'], nil, space .. "-")        

    formLoaded = true
end

local function updateStats()

    fields['total']:value(space .. tostring(mspSpeedTestStats['total']))

    fields['retries']:value(space .. tostring(mspSpeedTestStats['retries']))

    fields['timeouts']:value(space .. tostring(mspSpeedTestStats['timeouts']))
    
    fields['checksum']:value(space .. tostring(mspSpeedTestStats['checksum']))

    -- sometimes we get an exception where we close the dialog before final query.. and it shift result be 1
    -- catch this and show correct
    if (mspSpeedTestStats['success'] == mspSpeedTestStats['total'] - 1) and mspSpeedTestStats['timeouts'] == 0 then
        fields['success']:value(space .. tostring(mspSpeedTestStats['success']))
    else
        fields['success']:value(space .. tostring(mspSpeedTestStats['success']))
    end

    local avgQueryTime = rf2ethos.utils.round(mspQueryTimeCount / mspSpeedTestStats['total'], 2) .. "s"
    fields['time']:value(space .. tostring(avgQueryTime))

end

local function getMSPPidBandwidth()
    local message = {
        command = 94, -- MSP_STATUS
        processReply = function(self, buf)

        end,
        simulatorResponse = {3, 25, 250, 0, 12, 0, 1, 30, 30, 45, 50, 50, 100, 15, 15, 20, 2, 10, 10, 15, 100, 100, 5, 0, 30, 0, 25, 0, 40, 55, 40, 75, 20, 25, 0, 15, 45, 45, 15, 15, 20}
    }
    rf2ethos.mspQueue:add(message)
end

local function getMSPServos()
    local message = {
        command = 120, -- MSP_STATUS
        processReply = function(self, buf)

        end,
        simulatorResponse = {
            4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
            120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
        }
    }
    rf2ethos.mspQueue:add(message)
end

local function getMSPPids()
    local message = {
        command = 112, -- MSP_STATUS
        processReply = function(self, buf)

        end,
        simulatorResponse = {70, 0, 225, 0, 90, 0, 120, 0, 100, 0, 200, 0, 70, 0, 120, 0, 100, 0, 125, 0, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 25, 0, 25, 0}
    }
    rf2ethos.mspQueue:add(message)
end

local function getMSP()
    -- three diff msp queries. 
    if getMSPCount == 0 then
        getMSPPidBandwidth()
        getMSPCount = 1
    elseif getMSPCount == 1 then
        getMSPServos()
        getMSPCount = 2
    else
        getMSPPids()
        getMSPCount = 0
    end
end

local function wakeup()

    if formLoaded == true then
        rf2ethos.triggers.closeProgressLoader = true
        formLoaded = false
    end

    if triggerStart == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger test
                    startTestTime = os.clock()
                    startTest = true
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
            title = "Start",
            message = "Would you like to start the test?  It will take " .. startTestLength .. "s to complete.",
            buttons = buttons,
            wakeup = function()
            end,
            paint = function()
            end,
            options = TEXT_LEFT
        })

        triggerStart = false
    end

    if startTest == true then
        local now = os.clock()

        -- launch progress box
        if testLoaderDisplay == false then
            testLoader = form.openProgressDialog("Testing..", "Testing msp performance...")
            testLoader:value(0)
            testLoader:closeAllowed(false)
            testLoaderDisplay = true
            testLoaderStepSizeValue = 0
            getMSPCount = 0
            mspSpeedTest = true

            mspSpeedTestStats['total'] = 0
            mspSpeedTestStats['retries'] = 0
            mspSpeedTestStats['success'] = 0
            mspSpeedTestStats['timeouts'] = 0
            mspSpeedTestStats['total'] = 0

        end

        -- update progress box
        if (now - testLoaderUpdateRate) >= testLoaderUpdateTime then
            testLoaderUpdateTime = now
            testLoader:value(testLoaderStepSizeValue)
            testLoaderStepSizeValue = testLoaderStepSizeValue + testLoaderStepSize
        end

        -- close progress box
        if (now - startTestLength) > startTestTime then

            updateStats()
            mspSpeedTest = false
            startTest = false
            testLoader:close()
            testLoaderDisplay = false
        end

        -- do msp query
        if rf2ethos.mspQueue:isProcessed() then
            mspSpeedTestStats['total'] = mspSpeedTestStats['total'] + 1
            mspQueryStartTime = os.clock()
            getMSP()
        end

    end

end

function mspSuccess(self)
    if mspSpeedTest == true then
        mspQueryTimeCount = mspQueryTimeCount + os.clock() - mspQueryStartTime
        mspSpeedTestStats['success'] = mspSpeedTestStats['success'] + 1
    end
end

function mspTimeout(self)
    if mspSpeedTest == true then mspSpeedTestStats['timeouts'] = mspSpeedTestStats['timeouts'] + 1 end
end

function mspRetry(self)
    if mspSpeedTest == true then mspSpeedTestStats['retries'] = mspSpeedTestStats['retries'] + (self.retryCount - 1) end
end

function mspChecksum(self)
    if mspSpeedTest == true then mspSpeedTestStats['checksum'] = mspSpeedTestStats['checksum'] + 1 end
end

rf2ethos.uiState = rf2ethos.uiStatus.pages

return {title = "Msp speed", openPage = openPage, mspRetry = mspRetry, mspSuccess = mspSuccess, mspTimeout = mspTimeout, mspChecksum = mspChecksum, wakeup = wakeup, event = event}
