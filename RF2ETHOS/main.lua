-- RotorFlight + ETHOS LUA configuration
local environment = system.getVersion()

local LUA_VERSION = "2.0 - 240229"
local ETHOS_VERSION = 157
local ETHOS_VERSION_STR = "ETHOS < V1.5.7"

local DEBUG_MSP = false				-- display msp messages
local DEBUG_MSPVALUES = false  		-- display values received from valid msp
local DEBUG_BADESC_ENABLE = false  	-- enable ability to get into esc menus even if not detected

local SIM_ENABLE_RSSI = false	-- set this to true to enable debugging of msg boxes in sim mode

local ENABLE_HELP = true


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
local closingHELP = false

local lastLabel = nil
local NewRateTable
RateTable = nil
ResetRates = nil
reloadRates = false

isLoading = false
wasLoading = false

local dialogOPEN = false
local exitAPP = false
local noRFMsg = false
local triggerSAVE = false


local mspDataLoaded = false

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

local ESC_MODE = false
local ESC_MFG = nil
local ESC_SCRIPT = nil
local ESC_UNKNOWN = false	
local ESC_NOTREADYCOUNT = 0
		
lcdNeedsInvalidate = false

displayHELP = false
displayHELPMsg = nil
displayHELPQr = nil


protocol = nil
radio = nil
sensor = nil

rf2ethos = {}



local translations = {en = "RF2 ETHOS"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

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
		if ESC_MODE == true then
			payload[2] = 0
		end
        if Page.preSave then
            payload = Page.preSave(Page)
        end
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



function rf2ethos.dataBindFields()

    if Page.fields ~= nil and Page.values ~= nil then
        for i = 1, #Page.fields do
            if #Page.values >= Page.minBytes then
                local f = Page.fields[i]
                if f.vals then
                    f.value = 0
                    for idx = 1, #f.vals do
						local raw_val
						if ESC_MODE == true then
							raw_val = Page.values[f.vals[idx] + mspHeaderBytes] or 0
						else	
							raw_val = Page.values[f.vals[idx]] or 0
						end	
                        raw_val = raw_val << ((idx - 1) * 8)
                        f.value = f.value | raw_val
                    end
                    local bits = #f.vals * 8
                    if f.min and f.min < 0 and (f.value & (1 << (bits - 1)) ~= 0) then
                        f.value = f.value - (2 ^ bits)
                    end
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
			if DEBUG_MSP == true then
				if ESC_MODE == true then
					-- 1 extra byte - for esc signature?
					 print(
						"Page is processing reply for cmd " ..
							tostring(cmd) .. " len rx_buf: " .. #rx_buf .. " expected: " .. (Page.minBytes + 1)
					 )
				else
					 print(
						"Page is processing reply for ESC cmd " ..
							tostring(cmd) .. " len rx_buf: " .. #rx_buf .. " expected: " .. Page.minBytes
					 )				
				end
			end
        end
    end
    if not Page or not rx_buf then
    elseif cmd == Page.write then
        -- check if this page requires writing to eeprom to save (most do)
        if Page.eepromWrite then
            -- don't write again if we're already responding to earlier page.write()s
            if pageState ~= pageStatus.eepromWrite then
                eepromWrite()
            end
        elseif pageState ~= pageStatus.eepromWrite then
            -- If we're not already trying to write to eeprom from a previous save, then we're done.
            invalidatePages()
        end
        lcdNeedsInvalidate = true
    elseif cmd == uiMsp.eepromWrite then
        if Page.reboot then
            rebootFc()
        end
        invalidatePages()
    elseif ESC_MODE == true and (cmd == Page.read and err)  then
		if DEBUG_MSP == true then
			print("ESC not ready, waiting...")
		end
		ESC_NOTREADYCOUNT = ESC_NOTREADYCOUNT + 1
		if ESC_NOTREADYCOUNT >= 5 then
			ESC_UNKNOWN = true	
			mspDataLoaded = true		
			lcdNeedsInvalidate = true			
		end

    elseif ESC_MODE == true and (cmd == Page.read and #rx_buf >= mspHeaderBytes and rx_buf[1] ~= mspSignature) then
		ESC_UNKNOWN = true
        mspDataLoaded = true		
		lcdNeedsInvalidate = true
		if DEBUG_MSP == true then
			print("ESC not recognized")
		end
    elseif (cmd == Page.read) and (#rx_buf > 0) then
		if DEBUG_MSP == true then
         print("processMspReply:  Page.read and non-zero rx_buf")
		end 
        Page.values = rx_buf
        if Page.postRead then
			if DEBUG_MSP == true then
             print("Postread executed")
			end 
            Page.postRead(Page)
        end
        rf2ethos.dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
			if DEBUG_MSP == true then
             print("Postload executed")
			end 
        end
        mspDataLoaded = true
        lcdNeedsInvalidate = true
		ESC_UNKNOWN = false		
		ESC_NOTREADYCOUNT = 0
    end
	
	
end

local function requestPage()
    if Page.read and ((not Page.reqTS) or (Page.reqTS + requestTimeout <= os.clock())) then
        -- print("Trying requestPage()")
        Page.reqTS = os.clock()
        protocol.mspRead(Page.read)
    end
end

function rf2ethos.sportTelemetryPop()
    -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
    local frame = sensor:popFrame()
    if frame == nil then
        return nil, nil, nil, nil
    end
    -- physId = physical / remote sensor Id (aka sensorId)
    --   0x00 for FPORT, 0x1B for SmartPort
    -- primId = frame ID  (should be 0x32 for reply frames)
    -- appId = data Id
    return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

function rf2ethos.sportTelemetryPush(sensorId, frameId, dataId, value)
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
function rf2ethos.getRSSI()
    -- print("getRSSI RF2")
    if environment.simulation == true then
        return 100
    end

    if rssiSensor ~= nil and rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

function rf2ethos.getTime()
    return os.clock() * 100
end

function rf2ethos.loadScriptRF2ETHOS(script)
    --system.compile(script)
    return loadfile(script)
end

function rf2ethos.getWindowSize()
    return lcd.getWindowSize()
    -- return 784, 406
    -- return 472, 288
    -- return 472, 240
end

local function updateTelemetryState()

	local oldTelemetryState = telemetryState

	if not rssiSensor then
		telemetryState = telemetryStatus.noSensor
	elseif rf2ethos.getRSSI() == 0 then
		telemetryState = telemetryStatus.noTelemetry
	else
		telemetryState = telemetryStatus.ok
	end

	if oldTelemetryState ~= telemetryState then
		lcdNeedsInvalidate = true
	end

end

local function clipValue(val, min, max)
    if val < min then
        val = min
    elseif val > max then
        val = max
    end
    return val
end

function rf2ethos.getFieldValue(f)

	if DEBUG_MSPVALUES == true then
		print(f.t .. ":" .. f.value)
	end


    local v

    if f.value ~= nil then
        if f.decimals ~= nil then
            v = rf2ethos.round(f.value * decimalInc(f.decimals))
        else
            v = f.value
        end
    else
        v = 0
    end

    if f.mult ~= nil then
        v = math.floor(v * f.mult + 0.5)
    end

    return v
end

function rf2ethos.saveValue(currentField)
    if environment.simulation == true then
        return
    end



    local f = Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do
		if ESC_MODE == true then
			Page.values[f.vals[idx] + mspHeaderBytes] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8)		
		else
			Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8)
		end	
    end
    if f.upd and Page.values then
        f.upd(Page)
    end
end


function rf2ethos.openPageHELP(helpdata,section)
	local txtData

	if section == "rates_1" then
		txtData = helpdata[section]["table"][RateTable]
	else
		txtData = helpdata[section]["TEXT"]
	end	

	--forcing dialog for X14 due to focus bug
	-- all this will change once better/help dialogs are available in 
	if environment.board == "X14" or environment.board == "X14S"  then
		-- popup option to use in future once more
		-- granular option appear	

		local message = ""

		
		for k,v in ipairs(txtData) do
			message = message .. v .. "\n\n"
		end

        local buttons = {
			{
                label = "CLOSE",
                action = function()
                    return true
                end
            }
        }
		form.openDialog("Help - " .. lastTitle, message, buttons,1)


	else
		-- home spun popup
		local message = ""
		for k,v in ipairs(txtData) do
			v = rf2ethos.wrap(v, radio.helpTxtWrap, "", "")
			message = message .. v .. "\n\n"
		end		
		
		form.clear()
		displayHELPMsg = message
		displayHELPQr = helpdata[section]["QRCODE"]
		displayHELP = true		
		
	end

		
end




function rf2ethos.msgBoxHELP(str,qr)
    lcd.font(FONT_STD)

    displayHELP = true

    local w, h = lcd.getWindowSize()
    if w < 500 then
        boxW = w
    else
       boxW = w - math.floor((w * 2) / 100)
    end
    if h < 200 then
        boxH = h - 2
    else
        boxH = h - math.floor((h * 4) / 100)		
    end

    boxH = boxH -- radio.buttonPadding * 5
    boxW = boxW -- (radio.buttonPadding * 10)

    -- draw the backgrf2status.round
    if isDARKMODE then
        lcd.color(lcd.RGB(64, 64, 64))
    else
        lcd.color(lcd.RGB(208, 208, 208))
    end
    lcd.drawFilledRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH)

    -- draw the border
    lcd.color(lcd.RGB(40, 40, 40))
    lcd.drawRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH)

    -- draw the title
    if isDARKMODE then
        lcd.color(lcd.RGB(48, 48, 48))
    else
        lcd.color(lcd.RGB(160, 160, 160))
    end
    lcd.drawFilledRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH / 7)

    -- title text
    str_title = "Help - ".. lastTitle
    tsizeW, tsizeH = lcd.getTextSize(str_title)
    str_offset = (boxH / 7) / 2 - tsizeH / 2
    if isDARKMODE then
        lcd.color(lcd.RGB(255, 255, 255, 1))
    else
        lcd.color(lcd.RGB(90, 90, 90))
    end
    lcd.drawText((w / 2 - boxW / 2) + str_offset, h / 2 - boxH / 2 + str_offset, str_title)

    -- display message
	lcd.font(FONT_S)
    tsizeW, tsizeH = lcd.getTextSize(str)
    lcd.drawText((w / 2 - boxW / 2)+radio.buttonPadding, h / 2 - boxH / 2 + boxH / 7 + radio.buttonPadding, str)

	-- display QRCODE
	if qr ~= nil then
			local bitmap = lcd.loadBitmap(qr)
			
			local qw = radio.helpQrCodeSize
			local qh = radio.helpQrCodeSize
			
			local qy = h / 2 - boxH / 2 + boxH / 7 + radio.buttonPadding			
			local qx = boxW - qw - radio.buttonPadding/2
			lcd.drawBitmap(qx,qy,bitmap,qw,qh)	

	end


    -- create a button
	lcd.font(FONT_STD)
    str_exit = "CLOSE"
    tsizeW, tsizeH = lcd.getTextSize(str_exit)
    buttonX = ((w / 2 - boxW / 2) + boxW) - tsizeW - (radio.buttonPadding * 2)
    buttonY = ((h / 2 - boxH / 2) + boxH) - tsizeH - (radio.buttonPadding * 2)

    lcd.color(lcd.RGB(248, 176, 56))
    lcd.drawFilledRectangle(buttonX, buttonY, tsizeW + radio.buttonPadding, tsizeH + radio.buttonPadding)

    if isDARKMODE then
        lcd.color(lcd.RGB(64, 64, 64))
    else
        lcd.color(lcd.RGB(208, 208, 208))
    end
    lcd.drawText(buttonX + radio.buttonPadding / 2, buttonY + radio.buttonPadding / 2, str_exit)

    return
end

function rf2ethos.wrap(str, limit, indent, indent1)
  indent = indent or ""
  indent1 = indent1 or indent
  limit = limit or 79
  local here = 1-#indent1
  return indent1..str:gsub("(%s+)()(%S+)()",
  function(sp, st, word, fi)
	if fi-here > limit then
	  here = st - #indent
	  return "\n"..indent..word
	end
  end)
end


function rf2ethos.msgBox(str, border)
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

    lcdNeedsInvalidate = true

    return
end

-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)
    --print("Event received:", category, value, x, y)

	if uiState == uiStatus.pages then
		if value == KEY_ENTER_LONG then
				triggerSAVE = true
				system.killEvents(KEY_ENTER_BREAK)
				return true
		end
	end
	
	if uiState == uiStatus.MainMenu then
		if value == KEY_ENTER_LONG then
			system.killEvents(KEY_ENTER_BREAK)
			return true
		end
	end
	
    if displayHELP == true then
		local w, h = lcd.getWindowSize()
		if w < 500 then
			boxW = w
		else
			boxW = w - math.floor((w * 2) / 100)
		end
		if h < 200 then
			boxH = h - 2
		else
			boxH = h - math.floor((h * 4) / 100)
		end
		boxH = boxH -- radio.buttonPadding * 5
		boxW = boxW -- (radio.buttonPadding * 10)
		str_exit = "CLOSE"
		tsizeW, tsizeH = lcd.getTextSize(str_exit)
		buttonX = ((w / 2 - boxW / 2) + boxW) - tsizeW - (radio.buttonPadding * 2)
		buttonY = ((h / 2 - boxH / 2) + boxH) - tsizeH - (radio.buttonPadding * 2)
		buttonW = tsizeW + (radio.buttonPadding * 2)
		buttonH = tsizeH + (radio.buttonPadding * 2)

		if ((value == KEY_ENTER_FIRST) or (  (value == TOUCH_END) and ((x > buttonX and x < buttonX + buttonW) and (y > buttonY)))) then
			lcd.invalidate()	
			displayHELP = false
			displayHELPMsg = nil
			displayHELPQr = nil
			wasLoading = true  -- a trick to force form to reload
			createForm = true
			closingHELP = true
			uiState = uiStatus.pages
	
			print("Closing help")
			return (true)

		end
	else
		displayHELP = false
	end	

    return false
end

function rf2ethos.sensorMakeNumber(x)
    if x == nil or x == "" then
        x = 0
    end

    x = string.gsub(x, "%D+", "")
    x = tonumber(x)
    if x == nil or x == "" then
        x = 0
    end

    return x
end

function paint()


    if environment.simulation ~= true or SIM_ENABLE_RSSI == true then
        if telemetryState ~= 1 then
            rf2ethos.msgBox("NO RF LINK")
		else
			msgBox = false
        end
    end

	if displayHELP == true then
		rf2ethos.msgBoxHELP(displayHELPMsg,displayHELPQr)
	end
	
	
    if isSaving then
        if pageState >= pageStatus.saving then
            -- print(saveMsg)
            local saveMsg = ""
            if pageState == pageStatus.saving then
                saveMsg = "Saving..."
                if saveRetries > 0 then
                    saveMsg = "Retry #" .. string.format("%u", saveRetries)
                end
            elseif pageState == pageStatus.eepromWrite then
                saveMsg = "Updating..."
                if saveRetries > 0 then
                    saveMsg = "Retry #" .. string.format("%u", saveRetries)
                end
            elseif pageState == pageStatus.rebooting then
                saveMsg = "Rebooting..."
            end
            rf2ethos.msgBox(saveMsg)
        else
            isSaving = false
        end
    end

    if isLoading == true and uiState ~= uiStatus.mainMenu then
        if environment.simulation ~= true then
            rf2ethos.msgBox("Loading...")
        end
    end
end

function rf2ethos.wakeupForm()

	-- trigger save
	if triggerSAVE == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    isSaving = true
                    wasSaving = true
                    rf2ethos.resetRates()
                    rf2ethos.debugSave()
                    saveSettings()
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    return true
                end
            }
        }
        form.openDialog("SAVE SETTINGS TO FBL", "Save current page to flight controller", buttons)
		
		triggerSAVE = false
	end


	-- ethos version
    if tonumber(rf2ethos.sensorMakeNumber(environment.version)) < ETHOS_VERSION then
		if dialogOPEN == false and exitAPP ~= true then
				local buttons = {
					{
						label = "EXIT",
						action = function()
							dialogOPEN = false
							exitAPP = true
							return true
						end
					}
				}
				form.openDialog("Error", ETHOS_VERSION_STR, buttons)
				dialogOPEN = true
		end		
    end	

    if lastScript == "rates.lua" and lastSubPage == 1 then
        if Page.fields then
            local v = Page.fields[13].value
            if v ~= nil then
                activeRateTable = math.floor(v)
            end

            if activeRateTable ~= nil then
                if activeRateTable ~= RateTable then
                    RateTable = activeRateTable
                    collectgarbage()
                    -- reloadRates = true
                    wasSaving = true
                    createForm = true
                end
            end
        end
    end

    if telemetryState ~= 1 or (pageState >= pageStatus.saving) then
        -- we dont refresh as busy doing other stuff
        -- print("Form invalidation disabled....")
    else
        if (isSaving == false and wasSaving == false) or (isLoading == false and wasLoading == false) then
            form.invalidate()
        end
    end
end

function rf2ethos.clearScreen()
    local w, h = lcd.getWindowSize()
    if isDARKMODE then
        lcd.color(lcd.RGB(40, 40, 40))
    else
        lcd.color(lcd.RGB(240, 240, 240))
    end
    lcd.drawFilledRectangle(0, 0, w, h)
end

-- WAKEUP:  Called every ~30-50ms by the main Ethos software loop
function wakeup(widget)
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier

	if exitAPP == true then
		exitAPP = false
		form.invalidate()
		system.exit()
		return
	end

    updateTelemetryState()

    if uiState == uiStatus.init then
        -- print("Init")
        local prevInit
        if init ~= nil then
            prevInit = init.t
        end
        init = init or assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ui_init.lua"))()

        local initSuccess = init.f()

        --print(initSuccess)

        if prevInit ~= init.t then
            -- Update initialization message
            lcdNeedsInvalidate = true
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
            --lcdNeedsInvalidate = true
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
                    --lcdNeedsInvalidate = true
                else
                    -- print("Failed to write to eeprom!")
                    invalidatePages()
                end
                -- drop through to processMspReply to send MSP_SET and see if we've received a response to this yet.
            end
        end
        if not Page then
            -- print("Reloading data : " .. lastPage)
			if ESC_MODE == true then
				Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ESC/" .. ESC_MFG .. "/PAGES/" .. ESC_SCRIPT))()			
			else 
				Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages/" .. lastPage))()
				ESC_MFG = nil
				ESC_SCRIPT = nil
				ESC_MODE = false
			end	
            collectgarbage()
        end
        if not Page.values and pageState == pageStatus.display then
            requestPage()
        end
    end

    mspProcessTxQ()
    processMspReply(mspPollReply())
    lastEvent = nil

    -- handle some display stuff to bring form in and out of focus for no rf link
    if telemetryState ~= 1 and closingHELP == false then
		--print("No telemetry")
        -- we have no telemetry - hide the form
        if environment.simulation ~= true or SIM_ENABLE_RSSI == true then
            form.clear()
            createForm = true
        end
    elseif (pageState >= pageStatus.saving) and closingHELP == false then
		--print(">= pageStatus.saving")	
        form.clear()
        createForm = true
    else
        if createForm == true then
			--print("createForm == true")
			if closingHELP == true then  -- this is a bit messy but it essentially enables trh
				closingHELP = false
			end
            if wasSaving == true or environment.simulation == true then
                wasSaving = false
                if lastScript == "pids.lua" or lastIdx == 1 then
                    rf2ethos.openPagePIDLoader(lastIdx, lastTitle, lastScript)
                elseif lastScript == "rates.lua" and lastSubPage == 1 then
                    rf2ethos.openPageRATESLoader(lastIdx, lastSubPage, lastTitle, lastScript)
                elseif lastScript == "servos.lua" then
                    rf2ethos.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
				elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT == nil then
					rf2ethos.openPageESCToolLoader(ESC_MFG)					
				elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT ~= nil then
					rf2ethos.openESCFormLoader(ESC_MFG,ESC_SCRIPT)			
                else
                    rf2ethos.openPageDefaultLoader(lastIdx, lastSubPage, lastTitle, lastScript)
                end
            elseif wasLoading == true or environment.simulation == true then
				--print("wasLoading == true")
                wasLoading = false
                if lastScript == "pids.lua" or lastIdx == 1 then
                    rf2ethos.openPagePID(lastIdx, lastTitle, lastScript)
                elseif lastScript == "rates.lua" and lastSubPage == 1 then
                    rf2ethos.openPageRATES(lastIdx, lastSubPage, lastTitle, lastScript)
                elseif lastScript == "servos.lua" then
                    rf2ethos.openPageSERVOS(lastIdx, lastTitle, lastScript)
				elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT == nil then
					rf2ethos.openPageESCTool(ESC_MFG)
				elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT ~= nil then
					rf2ethos.openESCForm(ESC_MFG,ESC_SCRIPT)
                else
                    rf2ethos.openPageDefault(lastIdx, lastSubPage, lastTitle, lastScript)
                end
            elseif reloadRates == true or environment.simulation == true then
				--print("reloadRates == true")
                rf2ethos.openPageRATESLoader(lastIdx, lastSubPage, lastTitle, lastScript)
            elseif reloadServos == true then
				--print("reloadServos == true")
                rf2ethos.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
            else
				--print("openMainMenu")
                rf2ethos.openMainMenu()
            end
            createForm = false
        else
            createForm = false
        end

        if uiState ~= uiStatus.mainMenu then
            if environment.simulation == true or mspDataLoaded == true then
                --print("Got the data...")
                mspDataLoaded = false

                isLoading = false
                wasLoading = true

                createForm = true
            end
        end

    end
	
	if lcdNeedsInvalidate == true then
		lcd.invalidate()
		lcdNeedsInvalidate  = false
	end
	
end

-- local rf2ethos.openMainMenu

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

function rf2ethos.print_r(node)
    local cache, stack, output = {}, {}, {}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k, v in pairs(node) do
            size = size + 1
        end

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
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
        end

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

function rf2ethos.navigationButtons(x, y, w, h)

	local helpWidth
	local section
	local page
	
	if ENABLE_HELP == true then
		help =  assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/HELP/pages.lua"))()
		section = string.gsub(lastScript, ".lua" ,"") -- remove .lua
		page = lastSubPage	
		if page == nil then
			section = section
		else
			section = section .. '_' .. page
		end

		if help.data[section] then
			helpWidth = w - (w * 20)/100
		else
			helpWidth = 0	
		end
	else
		helpWidth = 0	
	end
	print (environment.board)
	if environment.board == "X10EXPRESS" or environment.board == "X14" or environment.board == "X14S" then
		ENABLE_HELP = false
		helpWidth = 0
	end

	form.addTextButton(line, {x = x - (helpWidth + padding) - (w + padding)*3, y = y, w = w, h = h}, "MENU", function()
        ResetRates = false
        rf2ethos.openMainMenu()
    end)
    form.addTextButton(line, {x = x - (helpWidth + padding) - (w + padding)*2, y = y, w = buttonW, h = h}, "SAVE", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    isSaving = true
                    wasSaving = true
                    rf2ethos.resetRates()
                    rf2ethos.debugSave()
                    saveSettings()
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    return true
                end
            }
        }
        form.openDialog("SAVE SETTINGS TO FBL", "Save current page to flight controller", buttons)
    end)	
    form.addTextButton(line, {x = x - (helpWidth + padding) - (w + padding), y = y, w = buttonW, h = h}, "RELOAD", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
                    wasSaving = true
                    createForm = true
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    return true
                end
            }
        }
        form.openDialog("RELOAD", "Reload data from flight controller", buttons)
    end)
	if ENABLE_HELP == true then
		if helpWidth > 0 then
				form.addTextButton(line, {x = x - (helpWidth + padding), y = y, w = helpWidth, h = h}, "?", function()
					rf2ethos.openPageHELP(help.data,section)
				end)	
		end	
	end	
end


function rf2ethos.navigationButtonsEscForm(x, y, w, h)
    form.addTextButton(line, {x = x, y = y, w = w, h = h}, "MENU", function()
        ResetRates = false
		ESC_MODE = false
		ESC_NOTREADYCOUNT = 0
		 collectgarbage()
        rf2ethos.openPageESCTool(ESC_MFG)
    end)
    form.addTextButton(line, {x = colStart + buttonW + padding, y = y, w = buttonW, h = h}, "SAVE", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    isSaving = true
                    wasSaving = true
					ESC_NOTREADYCOUNT = 0					
                    rf2ethos.debugSave()
                    saveSettings()
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    return true
                end
            }
        }
        form.openDialog("SAVE SETTINGS TO ESC", "Save current page to ESC", buttons)
    end)
    form.addTextButton(line, {x = colStart + (buttonW + padding) * 2, y = y, w = buttonW, h = h}, "RELOAD", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
					ESC_NOTREADYCOUNT = 0					
                    wasSaving = true
                    createForm = true
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    return true
                end
            }
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
				local size
                if v.inline_size == nil then
                    size = 13.6
                else
                    size = v.inline_size
                end				
				return size
				
            end
        end
    end
end

local function getInlinePositions(f)
    local tmp_inline_size = getInlineSize(f.label)	
	local inline_multiplier = radio.inlinesize_mult
	
	local inline_size = tmp_inline_size * inline_multiplier

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
        posX = w - fieldW - tsizeW - padding - padding
        posText = {x = posX, y = eY, w = tsizeW, h = eH}

        posX = w - fieldW - padding
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

function rf2ethos.resetRates()
    if lastScript == "rates.lua" and lastSubPage == 2 then
        if ResetRates == true then
            NewRateTable = Page.fields[13].value

            local newTable = defaultRates(NewRateTable)

            for k, v in pairs(newTable) do
                local f = Page.fields[k]
                for idx = 1, #f.vals do
                    Page.values[f.vals[idx]] = v >> ((idx - 1) * 8)
                end
            end
            ResetRates = false
        end
    end
end

function rf2ethos.debugSave()
    -- this function runs before save action
    -- happens.  use it to do debug if needed

    if lastScript == "servos.lua" then

        -- Page.fields[1].value = currentServoID
        -- rf2ethos.saveValue(currentServoID, 1)
        -- local f = Page.fields[1]

        -- print(f.value)

        -- for idx = 1, #f.vals do
        --	Page.values[f.vals[idx]] = currentServoID >> ((idx - 1) * 8)
        -- end

        -- print(Page.fields[1].value)
    end
end

local function fieldChoice(f, i)
    if lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= lastSubPage then
            return
        end
    end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then

        if radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        local p = getInlinePositions(f)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if f.t ~= nil then
            if f.t2 ~= nil then
                f.t = f.t2
            end

            if f.label ~= nil then
                f.t = "    " .. f.t
            end
        end
        formLineCnt = formLineCnt + 1
        line = form.addLine(f.t)
        posField = nil
        postText = nil
    end

    field = form.addChoiceField(line, posField, convertPageValueTable(f.table), function()
        local value = rf2ethos.getFieldValue(f)
	
        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then
            f.postEdit(Page)
        end
        f.value = rf2ethos.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)
end

function rf2ethos.round(number, precision)
    if precision == nil then
        precision = 0
    end
    local fmtStr = string.format("%%0.%sf", precision)
    number = string.format(fmtStr, number)
    number = tonumber(number)
    return number
end

function rf2ethos.saveFieldValue(f, value)
    if value ~= nil then
        if f.decimals ~= nil then
            f.value = value / decimalInc(f.decimals)
        else
            f.value = value
        end
        if f.postEdit then
            f.postEdit(Page)
        end
    end

    if f.mult ~= nil then
        f.value = f.value / f.mult
    end

    return f.value
end

local function scaleValue(value, f)
    local v
    v = value * decimalInc(f.decimals)
    if f.scale ~= nil then
        v = v / f.scale
    end
    v = rf2ethos.round(v)
    return v
end

local function fieldNumber(f, i)
    if lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= lastSubPage then
            return
        end
    end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        local p = getInlinePositions(f)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        if f.t ~= nil then

            if f.label ~= nil then
                f.t = "    " .. f.t
            end
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
        local value = rf2ethos.getFieldValue(f)

        return value
    end, function(value)
        if f.postEdit then
            f.postEdit(Page)
        end

        f.value = rf2ethos.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)

    if f.default ~= nil then
        local default = f.default * decimalInc(f.decimals)
        if f.mult ~= nil then
            default = default * f.mult
        end
        field:default(default)
    else
        field:default(0)
    end

    if f.decimals ~= nil then
        field:decimals(f.decimals)
    end
    if f.unit ~= nil then
        field:suffix(f.unit)
    end
    if f.step ~= nil then
        field:step(f.step)
    end
end

local function getLabel(id, page)
    for i, v in ipairs(page) do
        if id ~= nil then
            if v.label == id then
                return v
            end
        end
    end
end

local function fieldLabel(f, i, l)
    if lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= lastSubPage then
            return
        end
    end

    if f.t ~= nil then
        if f.t2 ~= nil then
            f.t = f.t2
        end

        if f.label ~= nil then
            f.t = "    " .. f.t
        end
    end

    if f.label ~= nil then
        local label = getLabel(f.label, l)



        local labelValue = label.t
        local labelID = label.label

        if label.t2 ~= nil then
            labelValue = label.t2
        end
        if f.t ~= nil then
            labelName = labelValue
        else
            labelName = "unknown"
        end

        if f.label ~= lastLabel then
            if label.type == nil then
                label.type = 0
            end

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
    if radio.navButtonOffset ~= nil then
        colStart = colStart - radio.navButtonOffset
    end

    if radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = radio.buttonWidth
    end
    buttonH = radio.buttonHeight
    line = form.addLine(title)
    rf2ethos.navigationButtons(w, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
end

function rf2ethos.openPageDefaultLoader(idx, subpage, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages/" .. script))()
    collectgarbage()

    form.clear()

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    lcdNeedsInvalidate = true

    isLoading = true

    print("Finished: rf2ethos.openPageDefaultLoader")

    if environment.simulation == true then
        rf2ethos.openPageDefault(idx, subpage, title, script)
    end

end

function rf2ethos.openPageDefault(idx, subpage, title, script)
    local LCD_W, LCD_H = rf2ethos.getWindowSize()

    local fieldAR = {}

    uiState = uiStatus.pages

    longPage = false

    form.clear()

    lastPage = script

    fieldHeader(title)

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
        rf2ethos.navigationButtons(LCD_W, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
    end

    lcdNeedsInvalidate = true
end

function rf2ethos.openPageSERVOSLoader(idx, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages/" .. script))()
    collectgarbage()

    form.clear()

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    lcdNeedsInvalidate = true
    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPageSERVOS(idx, title, script)
    end

    print("Finished: rf2ethos.openPageSERVOS")
end

function rf2ethos.openPageSERVOS(idx, title, script)
    local LCD_W, LCD_H = rf2ethos.getWindowSize()

    reloadServos = false

    uiState = uiStatus.pages

    local numPerRow = 2

    local windowWidth, windowHeight = lcd.getWindowSize()

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = ((windowWidth) / numPerRow) - (padding * numPerRow - 1)

    local y = radio.buttonPaddingTop

    longPage = false

    form.clear()

    lastPage = script

    fieldHeader(title)

    -- we add a servo selector that is not part of msp table
    -- this is done as a selector - to pass a servoID on refresh
    if Page.servoCount == 3 then
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
                value = rf2ethos.lastChangedServo
                Page.fields[1].value = value
                return value
            end, function(value)
                Page.servoChanged(Page, value)
                -- trigger RELOAD
                wasSaving = true
                createForm = true
                return true
            end)
        else
            if f.hideme == nil or f.hideme == false then
                line = form.addLine(f.t)
                field = form.addNumberField(line, nil, f.min, f.max, function()
                    local value = rf2ethos.getFieldValue(f)
                    return value
                end, function(value)
                    f.value = rf2ethos.saveFieldValue(f, value)
                    rf2ethos.saveValue(i)
                end)
                if f.default ~= nil then
                    local default = f.default * decimalInc(f.decimals)
                    if f.mult ~= nil then
                        default = default * f.mult
                    end
                    field:default(default)
                else
                    field:default(0)
                end
                if f.decimals ~= nil then
                    field:decimals(f.decimals)
                end
                if f.unit ~= nil then
                    field:suffix(f.unit)
                end
            end
        end
    end

    lcdNeedsInvalidate = true
end

function rf2ethos.openPagePIDLoader(idx, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages/" .. script))()
    collectgarbage()

    form.clear()

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    lcdNeedsInvalidate = true
    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPagePID(idx, title, script)
    end

    print("Finished: rf2ethos.openPagePID")
end

function rf2ethos.openPagePID(idx, title, script)
    local LCD_W, LCD_H = rf2ethos.getWindowSize()

    uiState = uiStatus.pages

    longPage = false

    form.clear()

    fieldHeader(title)

    local numCols = #Page.cols
    local screenWidth = LCD_W - 10
    local padding = 10
    local paddingTop = radio.buttonPaddingTop
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
    for ri, rv in ipairs(Page.rows) do
        _G["RF2ETHOS_PIDROWS_" .. ri] = form.addLine(rv)
    end

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

        field = form.addNumberField(_G["RF2ETHOS_PIDROWS_" .. f.row], pos, minValue, maxValue, function()
            local value = rf2ethos.getFieldValue(f)
            return value
        end, function(value)
            f.value = rf2ethos.saveFieldValue(f, value)
            rf2ethos.saveValue(i)
        end)
        if f.default ~= nil then
            local default = f.default * decimalInc(f.decimals)
            if f.mult ~= nil then
                default = default * f.mult
            end
            field:default(default)
        else
            field:default(0)
        end
        if f.decimals ~= nil then
            field:decimals(f.decimals)
        end
        if f.unit ~= nil then
            field:suffix(f.unit)
        end
    end

    -- display menu at footer
    if Page.longPage ~= nil then
        if Page.longPage == true then
            line = form.addLine("")
            rf2ethos.navigationButtons(LCD_W, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
        end
    end

    lcdNeedsInvalidate = true
end


-- display the list of known esc types
-- /scripts/RF2ETHOS/pages/esc.lua
function rf2ethos.openPageESC(idx, title, script)

	print("rf2ethos.openPageESC")

    mspDataLoaded = false
    uiState = uiStatus.mainMenu


    lastIdx = idx
    lastTitle = title
    lastScript = script
	
	ESC = {}


    local windowWidth, windowHeight = lcd.getWindowSize()
    local y = radio.buttonPaddingTop

    form.clear()

   line = form.addLine(title)

   buttonW = 100
   x = windowWidth - buttonW
   form.addTextButton(line, {x = x, y = radio.buttonPaddingTop, w = buttonW, h = radio.buttonHeight}, "MENU", function()
        ResetRates = false
		lastIdx = nil
		lastPage = nil
		lastSubPage = nil
		ESC_MODE = false
        rf2ethos.openMainMenu()
    end)  
   

    local ESCMenu = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages/" .. script))()

    local numPerRow = 2

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = (windowWidth - (padding * numPerRow) - padding - 5) / numPerRow
    -- local x = 0
	lc = 0
	for pidx, pvalue in ipairs(ESCMenu.pages) do
		if lc == 0 then
			line = form.addLine("")
			x = padding
		end

		if lc >= 1 then
			x = padding + (w + padding) * lc
		end

		form.addTextButton(line, {x = x, y = y, w = w, h = h}, pvalue.title, function()
				rf2ethos.openPageESCToolLoader(pvalue.folder)
		end)


		lc = lc + 1

		if lc == numPerRow then
			lc = 0
		end
	end



end


-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function rf2ethos.openPageESCToolLoader(folder)



	ESC_MFG = folder
	ESC_SCRIPT = nil
	ESC_MODE = true


    uiState = uiStatus.pages
    mspDataLoaded = false

    ESC.init = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ESC/" .. folder .. "/init.lua"))()
	

    Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ESC/" .. folder .. "/esc_info.lua"))()
    form.clear()

    --lastIdx = idx
    --lastTitle = title
    --lastScript = script

    lcdNeedsInvalidate = true

    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPageESCTool(folder)
    end

end



-- initialise menu for specific type of esc
-- basically we load libraries then read 
-- /scripts/RF2ETHOS/ESC/<TYPE>/pages.lua
function rf2ethos.openPageESCTool(folder)

	print("rf2ethos.openPageESCTool")

    ESC.init = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ESC/" .. folder .. "/init.lua"))()

	--mspDataLoaded = false
    --uiState = uiStatus.mainMenu
	uiState = uiStatus.pages

    local windowWidth, windowHeight = lcd.getWindowSize()


    local y = radio.buttonPaddingTop

    form.clear()

   line = form.addLine(lastTitle .. ' / ' .. ESC.init.toolName)

   buttonW = 100
   x = windowWidth - buttonW
   form.addTextButton(line, {x = x, y = radio.buttonPaddingTop, w = buttonW, h = radio.buttonHeight}, "MENU", function()
        ResetRates = false
		ESC_NOTREADYCOUNT = 0
		ESC_UNKNOWN = false
		lastIdx = nil
		lastPage = nil
		lastSubPage = nil
        rf2ethos.openPageESC(lastIdx, lastTitle, lastScript)
    end)  
   
    ESC.pages = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ESC/" .. folder .. "/pages.lua"))()

	if Page.escinfo then
		local model 	= Page.escinfo[1].t
		local version 	= Page.escinfo[2].t
		local fw 		= Page.escinfo[3].t
		
		if model == "" or version == "" then
			model = "UNKNOWN ESC"
		end
		
		line = form.addLine(model .. " " .. version .. " " .. fw)	
	end


    local numPerRow = 1

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = (windowWidth - (padding * numPerRow) - padding - 5) / numPerRow
    -- local x = 0
	lc = 0
	for pidx, pvalue in ipairs(ESC.pages) do
		if lc == 0 then
			line = form.addLine("")
			x = padding
		end

		if lc >= 1 then
			x = padding + (w + padding) * lc
		end

		field = form.addTextButton(line, {x = x, y = y, w = w, h = h}, pvalue.title, function()
				rf2ethos.openESCFormLoader(folder,pvalue.script)
		end)
		if ESC_UNKNOWN == true and DEBUG_BADESC_ENABLE == false then
			field:enable(false)
		end
		

		lc = lc + 1

		if lc == numPerRow then
			lc = 0
		end
	end

end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function rf2ethos.openESCFormLoader(folder,script)



	ESC_MFG = folder
	ESC_SCRIPT = script
	ESC_MODE = true


    uiState = uiStatus.pages
    mspDataLoaded = false
	
	

    Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/ESC/" .. folder .. "/PAGES/" .. script))()
    collectgarbage()

    form.clear()

    --lastIdx = idx
    --lastTitle = title
    --lastScript = script

    lcdNeedsInvalidate = true

    isLoading = true
	

	

    if environment.simulation == true then
        rf2ethos.openESCForm(folder, script)
    end

end

--
function rf2ethos.openESCForm(folder,script)



    local LCD_W, LCD_H = rf2ethos.getWindowSize()

    local fieldAR = {}
    uiState = uiStatus.pages
    longPage = false
	form.clear()

    local windowWidth, windowHeight = lcd.getWindowSize()
    local y = radio.buttonPaddingTop

    local w, h = lcd.getWindowSize()
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if radio.navButtonOffset ~= nil then
        colStart = colStart - radio.navButtonOffset
    end

    if radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = radio.buttonWidth
    end
    buttonH = radio.buttonHeight
    line = form.addLine(lastTitle .. ' / ' .. ESC.init.toolName .. ' / ' .. Page.title)
   
    rf2ethos.navigationButtonsEscForm(colStart, radio.buttonPaddingTop, buttonW, radio.buttonHeight)


	if Page.escinfo then
		local model 	= Page.escinfo[1].t
		local version 	= Page.escinfo[2].t
		local fw 		= Page.escinfo[3].t
		line = form.addLine(model .. " " .. version .. " " .. fw)	
	end

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
        rf2ethos.navigationButtonsEscForm(LCD_W, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
    end

    lcdNeedsInvalidate = true

end



function rf2ethos.openPageRATESLoader(idx, subpage, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages/" .. script))()
    collectgarbage()

    form.clear()

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    lcdNeedsInvalidate = true
    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPageRATES(idx, subpage, title, script)
    end

    print("Finished: rf2ethos.openPageRATES")
end

function rf2ethos.openPageRATES(idx, subpage, title, script)
    local LCD_W, LCD_H = rf2ethos.getWindowSize()

    uiState = uiStatus.pages

    longPage = false

    form.clear()

    fieldHeader(title)

    local numCols = #Page.cols
    local screenWidth = LCD_W - 10
    local padding = 10
    local paddingTop = radio.buttonPaddingTop
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
    for ri, rv in ipairs(Page.rows) do
        _G["RF2ETHOS_RATEROWS_" .. ri] = form.addLine(rv)
    end

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

            field = form.addNumberField(_G["RF2ETHOS_RATEROWS_" .. f.row], pos, minValue, maxValue, function()
                local value = rf2ethos.getFieldValue(f)
                return value
            end, function(value)
                f.value = rf2ethos.saveFieldValue(f, value)
                rf2ethos.saveValue(i)
            end)
            if f.default ~= nil then
                local default = f.default * decimalInc(f.decimals)
                if f.mult ~= nil then
                    default = math.floor(default * f.mult)
                end
                if f.scale ~= nil then
                    default = math.floor(default / f.scale)
                end
                field:default(default)
            else
                field:default(0)
            end
            if f.decimals ~= nil then
                field:decimals(f.decimals)
            end
            if f.unit ~= nil then
                field:suffix(f.unit)
            end
            if f.step ~= nil then
                field:step(f.step)
            end
        end
    end

    -- display menu at footer
    if Page.longPage ~= nil then
        if Page.longPage == true then
            line = form.addLine("")
            rf2ethos.navigationButtons(LCD_W, radio.buttonPaddingTop, buttonW, radio.buttonHeight)
        end
    end

    lcdNeedsInvalidate = true
end

local function getSection(id, sections)
    for i, v in ipairs(sections) do
        print(v)
        if id ~= nil then
            if v.section == id then
                return v
            end
        end
    end
end

function rf2ethos.openMainMenu()

    if tonumber(rf2ethos.sensorMakeNumber(environment.version)) < ETHOS_VERSION then
        return
    end

    mspDataLoaded = false
    uiState = uiStatus.mainMenu

    local numPerRow = 3

    local windowWidth, windowHeight = lcd.getWindowSize()

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = (windowWidth - (padding * numPerRow) - padding - 5) / numPerRow
    -- local x = 0

    local y = radio.buttonPaddingTop



   
	local MENU_EXPANSION = false
	local sc = 0
	local panel


	form.clear()
	

		
		
    for idx, value in ipairs(MainMenu.sections) do
	
	
	
	
		if MENU_EXPANSION ~= true then
			-- just a line with a title
			panel = form.addLine(value.title)
		else
			-- or an expansion panel
			panel = form.addExpansionPanel(value.title)
			if sc ==  0 then
				panel:open(true) 
			else
				panel:open(false) 
			end
		end
		sc = sc + 1


        lc = 0
        for pidx, pvalue in ipairs(MainMenu.pages) do
            if pvalue.section == value.section then
                if lc == 0 then
					if MENU_EXPANSION ~= true then
						line = form.addLine("")
					else
						line = form.addLine("",panel)
					end
                    x = padding
                end

                if lc >= 1 then
                    x = padding + (w + padding) * lc
                end

                form.addTextButton(line, {x = x, y = y, w = w, h = h}, pvalue.title, function()
                    if pvalue.script == "pids.lua" then
                        rf2ethos.openPagePIDLoader(pidx, pvalue.title, pvalue.script)
                    elseif pvalue.script == "servos.lua" then
                        rf2ethos.openPageSERVOSLoader(pidx, pvalue.title, pvalue.script)
                    elseif pvalue.script == "rates.lua" and pvalue.subpage == 1 then
                        rf2ethos.openPageRATESLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                    elseif pvalue.script == "esc.lua" then
                        rf2ethos.openPageESC(pidx, pvalue.title, pvalue.script)						
                    else
                        rf2ethos.openPageDefaultLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                        rf2ethos.openPageDefaultLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                    end
                end)

                lc = lc + 1

                if lc == numPerRow then
                    lc = 0
                end
            end
        end
    end
end

local function create()
    protocol = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/protocols.lua"))()
    radio = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/radios.lua"))().msp
    assert(rf2ethos.loadScriptRF2ETHOS(protocol.mspTransport))()
    assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/MSP/common.lua"))()

    sensor = sport.getSensor({primId = 0x32})
    rssiSensor = system.getSource("RSSI")
    if not rssiSensor then
        rssiSensor = system.getSource("RSSI 2.4G")
        if not rssiSensor then
            rssiSensor = system.getSource("RSSI 900M")
            if not rssiSensor then
                rssiSensor = system.getSource("Rx RSSI1")
                if not rssiSensor then
                    rssiSensor = system.getSource("Rx RSSI2")
                end
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
	
	if tonumber(rf2ethos.sensorMakeNumber(environment.version)) < 158 then
		print("< 158  : help functions disabled")
		ENABLE_HELP = false
	end
	

    MainMenu = assert(rf2ethos.loadScriptRF2ETHOS("/scripts/RF2ETHOS/pages.lua"))()

    -- force page to get pickup data as it loads in
    form.onWakeup(function()
        rf2ethos.wakeupForm()
    end)

    rf2ethos.openMainMenu()
end

local function close()
    -- print("Close")
	dialogOPEN = false	
	ESC_MODE = false
	ESC_MFG = nil
	ESC_SCRIPT = nil
    pageLoaded = 100
	displayHELP = nil
	displayHELPMsg = nil
	displayHELPQr = nil
    pageTitle = nil
    pageFile = nil
	exitAPP = false
	noRFMsg = false
    system.exit()
    return true
end

local icon = lcd.loadMask("/scripts/RF2ETHOS/RF.png")

local function init()
    system.registerSystemTool({event = event, paint = paint, name = name, icon = icon, create = create, wakeup = wakeup, close = close})
    --system.compile("/scripts/RF2ETHOS/main.lua")
end

return {init = init}
