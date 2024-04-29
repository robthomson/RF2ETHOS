-- RotorFlight + ETHOS LUA configuration
local environment = system.getVersion()

local LUA_VERSION = "2.0 - 240229"

apiVersion = 0

local uiStatus = {init = 1, mainMenu = 2, pages = 3, confirm = 4}

local pageStatus = {display = 1, editing = 2, saving = 3, eepromWrite = 4, rebooting = 5}

local telemetryStatus = {ok = 1, noSensor = 2, noTelemetry = 3}

local uiMsp = {reboot = 68, eepromWrite = 250}

local uiState = uiStatus.init
local prevUiState
local pageState = pageStatus.display
-- local requestTimeout = 1.5   -- in seconds (originally 0.8)
local currentPage = 1
local currentField = 1
local saveTS = 0
local saveRetries = 0
local popupMenuActive = 1
local pageScrollY = 0
local mainMenuScrollY = 0
local telemetryState
local saveTimeout, saveMaxRetries, MainMenu, Page, init, popupMenu, requestTimeout, rssiSensor
createForm = false
local isSaving = false
local wasSaving = false
local isRefreshing = false
local wasRefreshing = false
local lastLabel = nil
local NewRateTable
RateTable = nil
ResetRates = nil
reloadRates = false

local mspDataLoaded = false

currentServoID = 1 -- this is default servo id
currentServoCount = 4
servoDataLoaded = false

lastServoCount = nil
reloadServos = false

defaultRateTable = 4 -- ACTUAL

-- New variables for Ethos version
local screenTitle = nil
local lastEvent = nil
local enterEvent = nil
local enterEventTime
local callCreate = true
local lastPage

local lastIdx = nil
local lastSubPage = nil
local lastTitle = nil
local lastScript = nil

lcdNeedsInvalidate = false

protocol = nil
radio = nil
sensor = nil

rfglobals = {}

local function decimalInc(dec)
    local decTable = {10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000, 100000000000}

    if dec == nil then
        return 1
    else
        return decTable[dec]
    end
end

local function saveSettings()
    if Page.values then
        local payload = Page.values
        if Page.preSave then payload = Page.preSave(Page) end
        saveTS = os.clock()
        if pageState == pageStatus.saving then
            saveRetries = saveRetries + 1
        else
            -- print("Attempting to write page values...")
            pageState = pageStatus.saving
            saveRetries = 0
        end
        protocol.mspWrite(Page.write, payload)
    end
end

local function eepromWrite()
    saveTS = os.clock()
    if pageState == pageStatus.eepromWrite then
        saveRetries = saveRetries + 1
    else
        -- print("Attempting to write to eeprom...")
        pageState = pageStatus.eepromWrite
        saveRetries = 0
    end
    protocol.mspRead(uiMsp.eepromWrite)
end

local function rebootFc()
    -- Only sent once.  I think a response may come back from FC if successful?
    -- May want to either check for that and repeat if not, or check for loss of telemetry to confirm, etc.
    -- TODO: Implement an auto-retry?  Right now if the command gets lost then there's just no reboot and no notice.
    -- print("Attempting to reboot the FC (one shot)...")
    saveTS = os.clock()
    pageState = pageStatus.rebooting
    protocol.mspRead(uiMsp.reboot)
    -- https://github.com/rotorflight/rotorflight-firmware/blob/9a5b86d915df557ff320f30f1376cb8ce9377157/src/main/msp/msp.c#L1853
end

local function invalidatePages()
    Page = nil
    pageState = pageStatus.display
    saveTS = 0
    collectgarbage()
    lcdNeedsInvalidate = true
end

local function dataBindFields()
	if Page.fields ~= nil and Page.values ~= nil then
		for i = 1, #Page.fields do
			if #Page.values >= Page.minBytes then
				local f = Page.fields[i]
				if f.vals then
					f.value = 0
					for idx = 1, #f.vals do
						local raw_val = Page.values[f.vals[idx]] or 0
						raw_val = raw_val << ((idx - 1) * 8)
						f.value = f.value | raw_val
					end
					local bits = #f.vals * 8
					if f.min and f.min < 0 and (f.value & (1 << (bits - 1)) ~= 0) then f.value = f.value - (2 ^ bits) end
					f.value = f.value / (f.scale or 1)
				end
			end
		end
	end	
end

-- Run lcd.invalidate() if anything actionable comes back from it.
local function processMspReply(cmd, rx_buf, err)
    if Page and rx_buf ~= nil then
        if environment.simulation ~= true then
            -- print(
            --    "Page is processing reply for cmd " ..
            --        tostring(cmd) .. " len rx_buf: " .. #rx_buf .. " expected: " .. Page.minBytes
            -- )
        end
    end
    if not Page or not rx_buf then
    elseif cmd == Page.write then
        -- check if this page requires writing to eeprom to save (most do)
        if Page.eepromWrite then
            -- don't write again if we're already responding to earlier page.write()s
            if pageState ~= pageStatus.eepromWrite then eepromWrite() end
        elseif pageState ~= pageStatus.eepromWrite then
            -- If we're not already trying to write to eeprom from a previous save, then we're done.
            invalidatePages()
        end
        lcdNeedsInvalidate = true
    elseif cmd == uiMsp.eepromWrite then
        if Page.reboot then rebootFc() end
        invalidatePages()
    elseif (cmd == Page.read) and (#rx_buf > 0) then
        -- print("processMspReply:  Page.read and non-zero rx_buf")
        Page.values = rx_buf
        if Page.postRead then
            -- print("Postread executed")
            Page.postRead(Page)
        end
        dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
            -- print("Postload executed")
        end
        mspDataLoaded = true
        lcdNeedsInvalidate = true
    end
end

local function requestPage()
    if Page.read and ((not Page.reqTS) or (Page.reqTS + requestTimeout <= os.clock())) then
        -- print("Trying requestPage()")
        Page.reqTS = os.clock()
        protocol.mspRead(Page.read)
    end
end

function sportTelemetryPop()
    -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
    local frame = sensor:popFrame()
    if frame == nil then return nil, nil, nil, nil end
    -- physId = physical / remote sensor Id (aka sensorId)
    --   0x00 for FPORT, 0x1B for SmartPort
    -- primId = frame ID  (should be 0x32 for reply frames)
    -- appId = data Id
    return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

function sportTelemetryPush(sensorId, frameId, dataId, value)
    -- OpenTX:
    -- When called without parameters, it will only return the status of the output buffer without sending anything.
    --   Equivalent in Ethos may be:   sensor:idle() ???
    -- @param sensorId  physical sensor ID
    -- @param frameId   frame ID
    -- @param dataId    data ID
    -- @param value     value
    -- @retval boolean  data queued in output buffer or not.
    -- @retval nil      incorrect telemetry protocol.  (added in 2.3.4)
    return sensor:pushFrame({physId = sensorId, primId = frameId, appId = dataId, value = value})
end

-- Ethos: when the RF1 and RF2 system tools are both installed, RF1 tries to call getRSSI in RF2 and gets stuck.
-- To avoid this, getRSSI is renamed in RF2.
function rf2touch_getRSSI()
    -- print("getRSSI RF2")
    if environment.simulation == true then return 100 end

    if rssiSensor ~= nil and rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

function getTime() return os.clock() * 100 end

function loadScript(script) return loadfile(script) end

function getWindowSize()
    return lcd.getWindowSize()
    -- return 784, 406
    -- return 472, 288
    -- return 472, 240
end

local function updateTelemetryState()
    local oldTelemetryState = telemetryState

    if not rssiSensor then
        telemetryState = telemetryStatus.noSensor
    elseif rf2touch_getRSSI() == 0 then
        telemetryState = telemetryStatus.noTelemetry
    else
        telemetryState = telemetryStatus.ok
    end

    if oldTelemetryState ~= telemetryState then lcdNeedsInvalidate = true end
end

local function clipValue(val, min, max)
    if val < min then
        val = min
    elseif val > max then
        val = max
    end
    return val
end

function getFieldValue(f)
	
    local v

    if f.value ~= nil then
        if f.decimals ~= nil then
            v = rf2touch_round(f.value * decimalInc(f.decimals))
        else
            v = f.value
        end
    else
        v = 0
    end

    if f.mult ~= nil then v = math.floor(v * f.mult + 0.5) end

    return v
end


local function saveValue(currentField)
    if environment.simulation == true then return end

    local f = Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do 
		Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8) 
	end
    if f.upd and Page.values then f.upd(Page) end
end


function getServoValue(currentIndex)

	-- when the form field loads; this function is called.
	-- it retrieves the value from the msp data
	-- and returns it as variable v
	
	-- its a bit convoluted because I dont really understand how
	-- the previous code worked and kind of hacked it together :(
	
    if Page.values ~= nil then
        servoCount = currentServoCount
        local servoConfiguration = {}
        for i = 1, servoCount do
           servoConfiguration[i] = {}
           for j = 1, 16 do 
			servoConfiguration[i][j] = Page.values[1 + (i - 1) * 16 + j] 
		   end
        end
        Page.minBytes = 1 + 16

        for i = 1, 16 do 
			Page.values[1 + i] = servoConfiguration[currentServoID][i] 
		end
        Page.fields[1].value = currentServoID
        dataBindFields()

        v = Page.fields[currentIndex].value
    end
    if v == nil then v = 0 end

    return v
end

local function saveServoValue(currentIndex)

	-- every time a field changes - this function is called.
	-- it should in theory write the data that is found in
	-- f.value (Page.fields[currentIndex].value) 
	-- into the Page.values field for the current Index

    if environment.simulation == true then return end

    local f = Page.fields[currentIndex]


	for idx = 1, 16 do 
		Page.values[1 + idx] = f.value >> ((idx - 1) * 8) 
	end	

    if f.upd and Page.values then f.upd(Page) end

end

local translations = {en = "RF2 TOUCH"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end



function msgBox(str,border)
    lcd.font(FONT_STD)

    local w, h = lcd.getWindowSize()
    boxW = math.floor(w / 2)
    boxH = 45
    tsizeW, tsizeH = lcd.getTextSize(str)

    -- draw the background
    if isDARKMODE then
        lcd.color(lcd.RGB(40, 40, 40))
    else
        lcd.color(lcd.RGB(240, 240, 240))
    end
    lcd.drawFilledRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH)

    -- draw the border
	if border == nil or border == true then
		if isDARKMODE then
			-- dark theme
			lcd.color(lcd.RGB(255, 255, 255, 1))
		else
			-- light theme
			lcd.color(lcd.RGB(90, 90, 90))
		end
		lcd.drawRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH)
	end

    if isDARKMODE then
        -- dark theme
        lcd.color(lcd.RGB(255, 255, 255, 1))
    else
        -- light theme
        lcd.color(lcd.RGB(90, 90, 90))
    end
    lcd.drawText((w / 2) - tsizeW / 2, (h / 2) - tsizeH / 2, str)

    lcd.invalidate()

    return
end

-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)
    -- print("Event received:", category, value, x, y)
    return false
end

function paint()
    if environment.simulation ~= true then if telemetryState ~= 1 then msgBox("NO RF LINK") end end
    if isSaving then
        if pageState >= pageStatus.saving then
            -- print(saveMsg)
            local saveMsg = ""
            if pageState == pageStatus.saving then
                saveMsg = "Saving..."
                if saveRetries > 0 then saveMsg = "Retry #" .. string.format("%u", saveRetries) end
            elseif pageState == pageStatus.eepromWrite then
                saveMsg = "Updating..."
                if saveRetries > 0 then saveMsg = "Retry #" .. string.format("%u", saveRetries) end
            elseif pageState == pageStatus.rebooting then
                saveMsg = "Rebooting..."
            end
            msgBox(saveMsg)
        else
            isSaving = false
        end
    end

    if isRefreshing then
        -- print("Got to paint isRefresh")
        msgBox("Refreshing")
    end

    -- this displays message box - but for now we disable due to
    -- lcd overlay issue
    -- bounce to frsky..
	--if uiState ~= uiStatus.mainMenu then
	--	if mspDataLoaded == false then
	--		msgBox("Loading...",false)
	--	else
	--		lcd.invalidate()
	--	end
	--end

end

function wakeupForm()
    if lastScript == "rates.lua" and lastSubPage == 1 then
        if Page.fields then
            local v = Page.fields[13].value
            if v ~= nil then activeRateTable = math.floor(v) end

            if activeRateTable ~= nil then
                if activeRateTable ~= RateTable then
                    RateTable = activeRateTable
                    collectgarbage()
                    -- reloadRates = true
                    isRefeshing = true
                    wasRefreshing = true
                    createForm = true
                    form.clear()
                end
            end
        end
    end

    if lastScript == "servos.lua" then
        if servoDataLoaded == true then
            -- print("Updating initial values")
            for i = 1, #Page.fields do
                local f = Page.fields[i]
                f.value = getServoValue(i)
            end
            dataBindFields()

            servoDataLoaded = false
        end
    end

    if telemetryState ~= 1 or (pageState >= pageStatus.saving) or mspDataLoaded == false then
        -- we dont refresh as busy doing other stuff
        -- print("Form invalidation disabled....")
    else
        if (isSaving == false and wasSaving == false) or (isRefreshing == false and wasRefreshing == false) then form.invalidate() end
    end
end

-- WAKEUP:  Called every ~30-50ms by the main Ethos software loop
function wakeup(widget)
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier

    updateTelemetryState()

    if uiState == uiStatus.init then
        -- print("Init")
        local prevInit
        if init ~= nil then prevInit = init.t end
        init = init or assert(loadScript("/scripts/RF2TOUCH/ui_init.lua"))()

        local initSuccess = init.f()

        print(initSuccess)

        if prevInit ~= init.t then
            -- Update initialization message
            lcd.invalidate()
        end
        if not initSuccess then
            -- waiting on api version to finish successfully.

            return 0
        end
        init = nil
        invalidatePages()
        uiState = prevUiState or uiStatus.mainMenu
        prevUiState = nil
    elseif uiState == uiStatus.mainMenu then
        -- print("Menu")
    elseif uiState == uiStatus.pages then
        if prevUiState ~= uiState then
            lcdNeedsInvalidate = true
            prevUiState = uiState
        end

        if pageState == pageStatus.saving then
            if (saveTS + saveTimeout) < os.clock() then
                if saveRetries < saveMaxRetries then
                    saveSettings()
                    lcdNeedsInvalidate = true
                else
                    -- print("Failed to write page values!")
                    invalidatePages()
                end
                -- drop through to processMspReply to send MSP_SET and see if we've received a response to this yet.
            end
        elseif pageState == pageStatus.eepromWrite then
            if (saveTS + saveTimeout) < os.clock() then
                if saveRetries < saveMaxRetries then
                    eepromWrite()
                    lcdNeedsInvalidate = true
                else
                    -- print("Failed to write to eeprom!")
                    invalidatePages()
                end
                -- drop through to processMspReply to send MSP_SET and see if we've received a response to this yet.
            end
        end
        if not Page then
            -- print("Reloading data : " .. lastPage)
            Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. lastPage))()
            collectgarbage()
        end
        if not Page.values and pageState == pageStatus.display then requestPage() end
    end

    mspProcessTxQ()
    processMspReply(mspPollReply())
    lastEvent = nil

    -- handle some display stuff to bring form in and out of focus for no rf link
    if telemetryState ~= 1 then
        -- we have no telemetry - hide the form
        if environment.simulation ~= true then
            form.clear()
            createForm = true
        end
    elseif (pageState >= pageStatus.saving) then
        form.clear()
        createForm = true
    else
        if createForm == true then
            if wasSaving == true then
                if lastScript == "pids.lua" or lastIdx == 1 then
                    openPagePID(lastIdx, lastTitle, lastScript)
                elseif lastScript == "rates.lua" and lastSubPage == 1 then
                    openPageRATES(lastIdx, lastSubPage, lastTitle, lastScript)
                elseif lastScript == "servos.lua" then
                    openPageSERVOS(lastIdx, lastTitle, lastScript)
                else
                    openPageDefault(lastIdx, lastSubPage, lastTitle, lastScript)
                end
                wasSaving = false
            elseif wasRefreshing == true then
                if lastScript == "pids.lua" or lastIdx == 1 then
                    openPagePID(lastIdx, lastTitle, lastScript)
                elseif lastScript == "rates.lua" and lastSubPage == 1 then
                    openPageRATES(lastIdx, lastSubPage, lastTitle, lastScript)
                elseif lastScript == "servos.lua" then
                    openPageSERVOS(lastIdx, lastTitle, lastScript)
                else
                    openPageDefault(lastIdx, lastSubPage, lastTitle, lastScript)
                end
                wasRefeshing = false
            elseif reloadRates == true then
                openPageRATES(lastIdx, lastSubPage, lastTitle, lastScript)
            elseif reloadServos == true then
                openPageSERVOS(lastIdx, lastTitle, lastScript)
            else
                openMainMenu()
            end
            createForm = false
        else
            createForm = false
        end
    end
end

-- local openMainMenu

local function convertPageValueTable(tbl)
    local thetable = {}
    if tbl[0] ~= nil then
        thetable[0] = {}
        thetable[0][1] = tbl[0]
        thetable[0][2] = 0
    end
    for idx, value in ipairs(tbl) do
        thetable[idx] = {}
        thetable[idx][1] = value
        thetable[idx][2] = idx
    end
    return thetable
end

function print_r(node)
    local cache, stack, output = {}, {}, {}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k, v in pairs(node) do size = size + 1 end

        local cur_index = 1
        for k, v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then
                if (string.find(output_str, "}", output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str, "\n", output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output, output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "[" .. tostring(k) .. "]"
                else
                    key = "['" .. tostring(k) .. "']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep("\t", depth) .. key .. " = " .. tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep("\t", depth) .. key .. " = {\n"
                    table.insert(stack, node)
                    table.insert(stack, v)
                    cache[node] = cur_index + 1
                    break
                else
                    output_str = output_str .. string.rep("\t", depth) .. key .. " = '" .. tostring(v) .. "'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}" end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}" end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output, output_str)
    output_str = table.concat(output)

    print(output_str)
end

local function writeText(x, y, str)
    if lcd.darkMode() then
        lcd.color(lcd.RGB(255, 255, 255))
    else
        lcd.color(lcd.RGB(90, 90, 90))
    end
    lcd.drawText(x, y, str)
end

function navigationButtons(x, y, w, h)
    form.addTextButton(line, {x = x, y = y, w = w, h = h}, "MENU", function()
        ResetRates = false
        openMainMenu()
    end)
    form.addTextButton(line, {x = colStart + buttonW + padding, y = y, w = buttonW, h = h}, "SAVE", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    isSaving = true
                    wasSaving = true
                    rf2touch_resetRates()
                    rf2touch_debugSave()
                    saveSettings()
                    return true
                end
            }, {label = "CANCEL", action = function() return true end}
        }
        form.openDialog("SAVE SETTINGS TO FBL", "Save current page to flight controller", buttons)
    end)
    form.addTextButton(line, {x = colStart + (buttonW + padding) * 2, y = y, w = buttonW, h = h}, "REFRESH", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    isRefeshing = true
                    wasRefreshing = true
                    createForm = true
                    form.clear()
                    return true
                end
            }, {label = "CANCEL", action = function() return true end}
        }
        form.openDialog("REFRESH", "Reload data from flight controller", buttons)
    end)
end
--

--[[
-- page types
T_NUMERIC = 0
T_LIST = 1
T_HEADER = 2
T_BOOL = 3
T_TEXT = 4
T_NUMERIC_ALT = 4

-- label types
T_LABEL = 0
T_EXPAND = 1
]]
local function getInlineSize(id)
    for i, v in ipairs(Page.labels) do
        if id ~= nil then
            if v.label == id then
                if v.inline_size == nil then
                    return 10
                else
                    return v.inline_size
                end
            end
        end
    end
end

local function getInlinePositions(f)
    inline_size = getInlineSize(f.label)

    local w, h = lcd.getWindowSize()
    local colStart

    local padding = 5
    local fieldW = (w * inline_size) / 100

    local eX
    local eW = fieldW - padding
    local eH = radio.buttonHeight
    local eY = radio.buttonPaddingTop
    local posX
    tsizeW, tsizeH = lcd.getTextSize(f.t)

    if f.inline == 5 then
        posX = w - fieldW * 9 - tsizeW - padding
        posText = {x = posX, y = eY, w = tsizeW, h = eH}

        posX = w - fieldW * 9
        posField = {x = posX, y = eY, w = eW, h = eH}
    elseif f.inline == 4 then
        posX = w - fieldW * 7 - tsizeW - padding
        posText = {x = posX, y = eY, w = tsizeW, h = eH}

        posX = w - fieldW * 7
        posField = {x = posX, y = eY, w = eW, h = eH}
    elseif f.inline == 3 then
        posX = w - fieldW * 5 - tsizeW - padding
        posText = {x = posX, y = eY, w = tsizeW, h = eH}

        posX = w - fieldW * 5
        posField = {x = posX, y = eY, w = eW, h = eH}
    elseif f.inline == 2 then
        posX = w - fieldW * 3 - tsizeW - padding
        posText = {x = posX, y = eY, w = tsizeW, h = eH}

        posX = w - fieldW * 3
        posField = {x = posX, y = eY, w = eW, h = eH}
    elseif f.inline == 1 then
        posX = w - fieldW - tsizeW - padding
        posText = {x = posX, y = eY, w = tsizeW, h = eH}

        posX = w - fieldW
        posField = {x = posX, y = eY, w = eW, h = eH}
    end

    ret = {posText = posText, posField = posField}

    return ret
end

local function defaultRates(x)
    local defaults = {}
    --
    --[[
	--there values are presented 
	defaults[0] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }  -- NONE - OK
	defaults[1] = { 1.8, 1.8, 1.8, 2.03, 0, 0, 0, 0.01, 0, 0, 0, 0 } --BF 
	defaults[2] = { 360, 360, 360, 12.5, 0, 0, 0, 0, 0, 0, 0, 0 } -- RACEFL 
	defaults[3] = { 1.8, 1.8, 1.8, 2.5, 0, 0, 0, 0, 0, 0, 0, 0 } -- KISS
	defaults[4] = { 360, 360, 360, 12, 360, 360, 360, 12, 0, 0, 0, 0 } -- ACTUAL
	defaults[5] = { 1.8, 1.8, 1.8, 2.5, 360, 360, 360, 500, 0, 0, 0, 0 } --QUICK
	]] -- these values are stored but scaled on presentation
    defaults[0] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} -- NONE - OK
    defaults[1] = {180, 180, 180, 203, 0, 0, 0, 1, 0, 0, 0, 0} -- BF
    defaults[2] = {36, 36, 36, 50, 0, 0, 0, 0, 0, 0, 0, 0} -- RACEFL
    defaults[3] = {180, 180, 180, 205, 0, 0, 0, 0, 0, 0, 0, 0} -- KISS
    defaults[4] = {36, 36, 30, 48, 36, 36, 36, 48, 0, 0, 0, 0} -- ACTUAL
    defaults[5] = {180, 180, 180, 205, 36, 36, 36, 104.16, 0, 0, 0, 0} -- QUICK

    return defaults[x]
end

function rf2touch_resetRates()
    if lastScript == "rates.lua" and lastSubPage == 2 then
        if ResetRates == true then
            NewRateTable = Page.fields[13].value

            local newTable = defaultRates(NewRateTable)

            for k, v in pairs(newTable) do
                local f = Page.fields[k]
                for idx = 1, #f.vals do Page.values[f.vals[idx]] = v >> ((idx - 1) * 8) end
            end
            ResetRates = false
        end
    end
end

function rf2touch_debugSave()
    -- this function runs before save action
    -- happens.  use it to do debug if needed

    if lastScript == "servos.lua" then

        -- Page.fields[1].value = currentServoID
        -- saveValue(currentServoID, 1)
        -- local f = Page.fields[1]

        -- print(f.value)

        -- for idx = 1, #f.vals do
        --	Page.values[f.vals[idx]] = currentServoID >> ((idx - 1) * 8)
        -- end

        -- print(Page.fields[1].value)
    end
end

local function fieldChoice(f, i)
    if lastSubPage ~= nil and f.subpage ~= nil then if f.subpage ~= lastSubPage then return end end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if f.t ~= nil then if f.t2 ~= nil then f.t = f.t2 end end

        local p = getInlinePositions(f)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if f.t ~= nil then
            if f.t2 ~= nil then f.t = f.t2 end

            if f.label ~= nil then f.t = "    " .. f.t end
        end
        formLineCnt = formLineCnt + 1
        line = form.addLine(f.t)
        posField = nil
        postText = nil
    end

    field = form.addChoiceField(line, posField, convertPageValueTable(f.table), function()
        local value = getFieldValue(f)
        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then f.postEdit(Page) end
        f.value = saveFieldValue(f, value)
        saveValue(i)
    end)
end




function rf2touch_round(number, precision)
    if precision == nil then precision = 0 end
    local fmtStr = string.format("%%0.%sf", precision)
    number = string.format(fmtStr, number)
    number = tonumber(number)
    return number
end

function saveFieldValue(f, value)
    if value ~= nil then
        if f.decimals ~= nil then
            f.value = value / decimalInc(f.decimals)
        else
            f.value = value
        end
        if f.postEdit then f.postEdit(Page) end
    end

    if f.mult ~= nil then f.value = f.value / f.mult end

    return f.value
end

local function scaleValue(value, f)
    local v
    v = value * decimalInc(f.decimals)
    if f.scale ~= nil then v = v / f.scale end
    v = rf2touch_round(v)
    return v
end

local function fieldNumber(f, i)
    if lastSubPage ~= nil and f.subpage ~= nil then if f.subpage ~= lastSubPage then return end end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if f.t ~= nil then if f.t2 ~= nil then f.t = f.t2 end end

        local p = getInlinePositions(f)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if f.t ~= nil then
            if f.t2 ~= nil then f.t = f.t2 end

            if f.label ~= nil then f.t = "    " .. f.t end
        else
            f.t = ""
        end

        formLineCnt = formLineCnt + 1

        line = form.addLine(f.t)

        posField = nil
        postText = nil
    end

    minValue = scaleValue(f.min, f)
    maxValue = scaleValue(f.max, f)
    if f.mult ~= nil then
        minValue = minValue * f.mult
        maxValue = maxValue * f.mult
    end

    if HideMe == true then
        -- posField = {x = 2000, y = 0, w = 20, h = 20}
    end

    field = form.addNumberField(line, posField, minValue, maxValue, function()
        local value = getFieldValue(f)

        return value
    end, function(value)
        if f.postEdit then f.postEdit(Page) end

        f.value = saveFieldValue(f, value)
        saveValue(i)
    end)

    if f.default ~= nil then
        local default = f.default * decimalInc(f.decimals)
        if f.mult ~= nil then default = default * f.mult end
        field:default(default)
    else
        field:default(0)
    end

    if f.decimals ~= nil then field:decimals(f.decimals) end
    if f.unit ~= nil then field:suffix(f.unit) end
    if f.step ~= nil then field:step(f.step) end
end

local function getLabel(id, page) for i, v in ipairs(page) do if id ~= nil then if v.label == id then return v end end end end

local function fieldLabel(f, i, l)
    if lastSubPage ~= nil and f.subpage ~= nil then if f.subpage ~= lastSubPage then return end end

    if f.t ~= nil then
        if f.t2 ~= nil then f.t = f.t2 end

        if f.label ~= nil then f.t = "    " .. f.t end
    end

    if f.label ~= nil then
        local label = getLabel(f.label, l)

        local labelValue = label.t
        local labelID = label.label

        if label.t2 ~= nil then labelValue = label.t2 end
        if f.t ~= nil then
            labelName = labelValue
        else
            labelName = "unknown"
        end

        if f.label ~= lastLabel then
            if label.type == nil then label.type = 0 end

            formLineCnt = formLineCnt + 1
            line = form.addLine(labelName)
            form.addStaticText(line, nil, "")

            lastLabel = f.label
        end
    else
        labelID = nil
    end
end

local function fieldHeader(title)
    local w, h = lcd.getWindowSize()
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    buttonW = (w - colStart) / 3 - padding
    buttonH = radio.buttonHeight
    line = form.addLine(title)
    navigationButtons(colStart, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
end

function openPageDefault(idx, subpage, title, script)
    local LCD_W, LCD_H = getWindowSize()


	local fieldAR = {}

    uiState = uiStatus.pages

    longPage = false

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    form.clear()

    lastPage = script

    fieldHeader(title)

    Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. script))()
    collectgarbage()

    formLineCnt = 0

    for i = 1, #Page.fields do
        local f = Page.fields[i]
        local l = Page.labels
        local pageValue = f
        local pageIdx = i
        local currentField = i

        fieldLabel(f, i, l)

        if f.table or f.type == 1 then
            fieldChoice(f, i)
        else
            fieldNumber(f, i)
        end
    end
    -- display menu at footer

    if formLineCnt * (radio.buttonHeight + radio.buttonPadding) > LCD_H then
        line = form.addLine("")
        navigationButtons(colStart, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
    end

    lcdNeedsInvalidate = true
end


function openPageSERVOS(idx, title, script)
    local LCD_W, LCD_H = getWindowSize()

    reloadServos = false

    uiState = uiStatus.pages

    local numPerRow = 2

    local windowWidth, windowHeight = lcd.getWindowSize()

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = ((windowWidth) / numPerRow) - (padding * numPerRow - 1)

    local y = radio.buttonPaddingTop

    longPage = false

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    form.clear()

    lastPage = script

    Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. script))()
    collectgarbage()

    fieldHeader(title)

    -- we add a servo selector that is not part of msp table
    -- this is done as a selector - to pass a servoID on refresh
    if currentServoCount == 3 then
        servoTable = {"ELEVATOR", "CYCLIC LEFT", "CYCLIC RIGHT"}
    else
        servoTable = {"ELEVATOR", "CYCLIC LEFT", "CYCLIC RIGHT", "TAIL"}
    end

    -- we can now loop throught pages to get values
    formLineCnt = 0
    for i = 1, #Page.fields do
        local f = Page.fields[i]
        local l = Page.labels
        local pageValue = f
        local pageIdx = i
        local currentField = i

        if i == 1 then
            line = form.addLine("Servo")
            field = form.addChoiceField(line, nil, convertPageValueTable(servoTable), function()
                value = currentServoID
                Page.fields[1].value = currentServoID
                return value
            end, function(value)
                currentServoID = value

                f.value = saveFieldValue(f, value)
                saveServoValue(i)

                isRefeshing = true
                wasRefreshing = true
                createForm = true
                return true
            end)
        else
            if f.hideme == nil or f.hideme == false then
                line = form.addLine(f.t)
                field = form.addNumberField(line, nil, f.min, f.max, function()
                    local value = getFieldValue(f)
                    return value
                end, function(value)
                    f.value = saveFieldValue(f, value)
                    saveServoValue(i)
                end)
                if f.default ~= nil then
                    local default = f.default * decimalInc(f.decimals)
                    if f.mult ~= nil then default = default * f.mult end
                    field:default(default)
                else
                    field:default(0)
                end
                if f.decimals ~= nil then field:decimals(f.decimals) end
                if f.unit ~= nil then field:suffix(f.unit) end
            end
        end
    end

    lcdNeedsInvalidate = true
end

function openPagePID(idx, title, script)
    local LCD_W, LCD_H = getWindowSize()

    uiState = uiStatus.pages

    longPage = false

    lastIdx = idx
    lastSubPage = nil
    lastTitle = title
    lastScript = script

    form.clear()

    lastPage = script
    Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. script))()
    collectgarbage()

    fieldHeader(title)

    local numCols = #Page.cols
    local screenWidth = LCD_W - 10
    local padding = 10
    local paddingTop = 8
    local h = radio.buttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine("")

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = Page.cols[loc]
        pos = {x = posX, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    for ri, rv in ipairs(Page.rows) do _G["RF2TOUCH_PIDROWS_" .. ri] = form.addLine(rv) end

    for i = 1, #Page.fields do
        local f = Page.fields[i]
        local l = Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        minValue = f.min * decimalInc(f.decimals)
        maxValue = f.max * decimalInc(f.decimals)
        if f.mult ~= nil then
            minValue = minValue * f.mult
            maxValue = maxValue * f.mult
        end

        field = form.addNumberField(_G["RF2TOUCH_PIDROWS_" .. f.row], pos, minValue, maxValue, function()
            local value = getFieldValue(f)
            return value
        end, function(value)
            f.value = saveFieldValue(f, value)
            saveValue(i)
        end)
        if f.default ~= nil then
            local default = f.default * decimalInc(f.decimals)
            if f.mult ~= nil then default = default * f.mult end
            field:default(default)
        else
            field:default(0)
        end
        if f.decimals ~= nil then field:decimals(f.decimals) end
        if f.unit ~= nil then field:suffix(f.unit) end
    end

    -- display menu at footer
    if Page.longPage ~= nil then
        if Page.longPage == true then
            line = form.addLine("")
            navigationButtons(colStart, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
        end
    end

    lcdNeedsInvalidate = true
end

function openPageRATES(idx, subpage, title, script)
    local LCD_W, LCD_H = getWindowSize()

    uiState = uiStatus.pages

    longPage = false

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    form.clear()

    lastPage = script
    Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. script))()
    collectgarbage()

    fieldHeader(title)

    local numCols = #Page.cols
    local screenWidth = LCD_W - 10
    local padding = 10
    local paddingTop = 8
    local h = radio.buttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine(Page.rTableName)

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = Page.cols[loc]
        tsizeW, tsizeH = lcd.getTextSize(colLabel)
        pos = {x = posX - tsizeW + paddingRight, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    for ri, rv in ipairs(Page.rows) do _G["RF2TOUCH_RATEROWS_" .. ri] = form.addLine(rv) end

    for i = 1, #Page.fields do
        local f = Page.fields[i]
        local l = Page.labels
        local pageIdx = i
        local currentField = i

        if f.subpage == 1 then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * decimalInc(f.decimals)
            maxValue = f.max * decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end

            field = form.addNumberField(_G["RF2TOUCH_RATEROWS_" .. f.row], pos, minValue, maxValue, function()
                local value = getFieldValue(f)
                return value
            end, function(value)
                f.value = saveFieldValue(f, value)
                saveValue(i)
            end)
            if f.default ~= nil then
                local default = f.default * decimalInc(f.decimals)
                if f.mult ~= nil then default = math.floor(default * f.mult) end
                if f.scale ~= nil then default = math.floor(default / f.scale) end
                field:default(default)
            else
                field:default(0)
            end
            if f.decimals ~= nil then field:decimals(f.decimals) end
            if f.unit ~= nil then field:suffix(f.unit) end
            if f.step ~= nil then field:step(f.step) end
        end
    end

    -- display menu at footer
    if Page.longPage ~= nil then
        if Page.longPage == true then
            line = form.addLine("")
            navigationButtons(colStart, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
        end
    end

    lcdNeedsInvalidate = true
end

local function getSection(id, sections)
    for i, v in ipairs(sections) do
        print(v)
        if id ~= nil then if v.section == id then return v end end
    end
end

function openMainMenu()
    mspDataLoaded = false
    uiState = uiStatus.mainMenu

    local numPerRow = 3

    local windowWidth, windowHeight = lcd.getWindowSize()

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = ((windowWidth) / numPerRow) - (padding * numPerRow - 1)
    -- local x = 0

    local y = radio.buttonPaddingTop

    form.clear()

    -- create drop downs

    for idx, value in ipairs(MainMenu.sections) do
        panel = form.addLine(value.title)

        lc = 0
        for pidx, pvalue in ipairs(MainMenu.pages) do
            if pvalue.section == value.section then
                if lc == 0 then
                    line = form.addLine("")
                    x = padding
                end

                if lc >= 1 then x = (w + (padding * numPerRow)) * lc end

                form.addTextButton(line, {x = x, y = y, w = w, h = h}, pvalue.title, function()
                    if pvalue.script == "pids.lua" then
                        openPagePID(pidx, pvalue.title, pvalue.script)
                    elseif pvalue.script == "servos.lua" then
                        openPageSERVOS(pidx, pvalue.title, pvalue.script)
                    elseif pvalue.script == "rates.lua" and pvalue.subpage == 1 then
                        openPageRATES(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                    else
                        openPageDefault(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                    end
                end)

                lc = lc + 1

                if lc == numPerRow then lc = 0 end
            end
        end
    end
end

local function create()
    protocol = assert(loadScript("/scripts/RF2TOUCH/protocols.lua"))()
    radio = assert(loadScript("/scripts/RF2TOUCH/radios.lua"))().msp
    assert(loadScript(protocol.mspTransport))()
    assert(loadScript("/scripts/RF2TOUCH/MSP/common.lua"))()

    sensor = sport.getSensor({primId = 0x32})
    rssiSensor = system.getSource("RSSI")
    if not rssiSensor then
        rssiSensor = system.getSource("RSSI 2.4G")
        if not rssiSensor then
            rssiSensor = system.getSource("RSSI 900M")
            if not rssiSensor then
                rssiSensor = system.getSource("Rx RSSI1")
                if not rssiSensor then rssiSensor = system.getSource("Rx RSSI2") end
            end
        end
    end

    -- Initial var setting
    saveTimeout = protocol.saveTimeout
    saveMaxRetries = protocol.saveMaxRetries
    requestTimeout = protocol.pageReqTimeout
    uiState = uiStatus.init
    init = nil
    lastEvent = nil
    apiVersion = 0

    MainMenu = assert(loadScript("/scripts/RF2TOUCH/pages.lua"))()

    -- force page to get pickup data as it loads in
    form.onWakeup(function() wakeupForm() end)

    openMainMenu()
end

local function close()
    -- print("Close")
    pageLoaded = 100
    pageTitle = nil
    pageFile = nil
    system.exit()
end

local icon = lcd.loadMask("/scripts/RF2TOUCH/RF.png")

local function init() system.registerSystemTool({event = event, paint = paint, name = name, icon = icon, create = create, wakeup = wakeup, close = close}) end

return {init = init}
