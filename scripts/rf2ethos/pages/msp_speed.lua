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
local doNextMsp = true

local mspSpeedTest = false
mspSpeedTestStats = {}
mspSpeedTestStats['total'] = 0
mspSpeedTestStats['success'] = 0
mspSpeedTestStats['total'] = 0
mspSpeedTestStats['retries'] = 0
mspSpeedTestStats['timeouts'] = 0
mspSpeedTestStats['checksum'] = 0


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


    if rf2ethos.config.ethosRunningVersion < 1516 then

        line['total'] = form.addLine("Total queries")
        fields['total'] = form.addTextField(line['total'], nil, function()
            return mspSpeedTestStats['total']
        end, function(value)
        end)
        fields['total']:enable(false)

        line['success'] = form.addLine("Successful queries")
        fields['success'] = form.addTextField(line['success'], nil, function()
            return mspSpeedTestStats['success']
        end, function(value)
        end)
        fields['success']:enable(false)

        line['timeouts'] = form.addLine("Timeouts")
        fields['timeouts'] = form.addTextField(line['timeouts'], nil, function()
            return mspSpeedTestStats['timeouts']
        end, function(value)
        end)
        fields['timeouts']:enable(false)

        line['retries'] = form.addLine("Retries")
        fields['retries'] = form.addTextField(line['retries'], nil, function()
            return mspSpeedTestStats['retries']
        end, function(value)
        end)
        fields['retries']:enable(false)

        line['checksum'] = form.addLine("Checksum errors")
        fields['checksum'] = form.addTextField(line['checksum'], nil, function()
            return mspSpeedTestStats['checksum']
        end, function(value)
        end)
        fields['checksum']:enable(false)

        line['time'] = form.addLine("Average query time")
        fields['time'] = form.addTextField(line['time'], nil, function()
            return "0s"
        end, function(value)
        end)
        fields['time']:enable(false)
        
    else

        local posText = {x = x - 5 - buttonW - buttonWs - 5 - buttonWs, y = rf2ethos.radio.linePaddingTop, w = 100, h = rf2ethos.radio.navbuttonHeight}

    
        line['total'] = form.addLine("Total queries")
        fields['total'] = form.addStaticText(line['total'], posText, "-")

        line['success'] = form.addLine("Successful queries")
        fields['success'] = form.addStaticText(line['success'], posText, "-")    

        line['timeouts'] = form.addLine("Timeouts")
        fields['timeouts'] = form.addStaticText(line['timeouts'], posText, "-")      

        line['retries'] = form.addLine("Retries")
        fields['retries'] = form.addStaticText(line['retries'], posText, "-")         

        line['checksum'] = form.addLine("Checksum errors")
        fields['checksum'] = form.addStaticText(line['checksum'], posText, "-")    

        line['time'] = form.addLine("Average query time")
        fields['time'] = form.addStaticText(line['time'], posText, "-")
    end

    formLoaded = true
end

local function updateStats()


    if rf2ethos.config.ethosRunningVersion < 1516 then

        fields['total'] = form.addTextField(line['total'], nil, function()
            return mspSpeedTestStats['total']
        end, function(value)
        end)
        fields['total']:enable(false)

        fields['retries'] = form.addTextField(line['retries'], nil, function()
            return mspSpeedTestStats['retries']
        end, function(value)
        end)
        fields['retries']:enable(false)

        fields['timeouts'] = form.addTextField(line['timeouts'], nil, function()
            return mspSpeedTestStats['timeouts']
        end, function(value)
        end)
        fields['timeouts']:enable(false)

        fields['checksum'] = form.addTextField(line['checksum'], nil, function()
            return mspSpeedTestStats['checksum']
        end, function(value)
        end)
        fields['checksum']:enable(false)

        if (mspSpeedTestStats['success'] == mspSpeedTestStats['total'] - 1) and mspSpeedTestStats['timeouts'] == 0 then
            fields['success'] = form.addTextField(line['success'], nil, function()
                return mspSpeedTestStats['total']
            end, function(value)
            end)
            fields['success']:enable(false)
        else
            fields['success'] = form.addTextField(line['success'], nil, function()
                return mspSpeedTestStats['success']
            end, function(value)
            end)
            fields['success']:enable(false)
        end

        local avgQueryTime = rf2ethos.utils.round(mspQueryTimeCount / mspSpeedTestStats['total'], 2) .. "s"
        fields['time'] = form.addTextField(line['time'], nil, function()
            return avgQueryTime
        end, function(value)
        end)
        fields['time']:enable(false)
        

    else
        fields['total']:value(tostring(mspSpeedTestStats['total']))

        fields['retries']:value(tostring(mspSpeedTestStats['retries']))

        fields['timeouts']:value(tostring(mspSpeedTestStats['timeouts']))
        
        fields['checksum']:value(tostring(mspSpeedTestStats['checksum']))

        if (mspSpeedTestStats['success'] == mspSpeedTestStats['total'] - 1) and mspSpeedTestStats['timeouts'] == 0 then
            fields['success']:value(tostring(mspSpeedTestStats['success']))
        else
            fields['success']:value(tostring(mspSpeedTestStats['success']))
        end

        local avgQueryTime = rf2ethos.utils.round(mspQueryTimeCount / mspSpeedTestStats['total'], 2) .. "s"
        fields['time']:value(tostring(avgQueryTime))    
    end
end

local function getMSPPidBandwidth()
    local message = {
        command = 94, -- MSP_STATUS
        processReply = function(self, buf)
            doNextMsp = true               
        end,
        simulatorResponse = {3, 25, 250, 0, 12, 0, 1, 30, 30, 45, 50, 50, 100, 15, 15, 20, 2, 10, 10, 15, 100, 100, 5, 0, 30, 0, 25, 0, 40, 55, 40, 75, 20, 25, 0, 15, 45, 45, 15, 15, 20}
    }
    rf2ethos.mspQueue:add(message)
end

local function getMSPServos()
    local message = {
        command = 120, -- MSP_STATUS
        processReply = function(self, buf)
            doNextMsp = true
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
            doNextMsp = true
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
    
    local avgQueryTime = rf2ethos.utils.round(mspQueryTimeCount / mspSpeedTestStats['total'], 2) .. "s"
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
            mspQueryTimeCount = 0

            mspSpeedTestStats = {}
            mspSpeedTestStats['total'] = 0
            mspSpeedTestStats['success'] = 0
            mspSpeedTestStats['total'] = 0
            mspSpeedTestStats['retries'] = 0
            mspSpeedTestStats['timeouts'] = 0
            mspSpeedTestStats['checksum'] = 0    

            
            doNextMsp = true

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
            
            if doNextMsp == true then
                doNextMsp = false
                getMSP()
                collectgarbage()
            end    
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
