-- RotorFlight + ETHOS LUA configuration
local environment = system.getVersion()

local LUA_VERSION = "2.0 - 240229"
local ETHOS_VERSION = 1510
local ETHOS_VERSION_STR = "ETHOS < V1.5.10"

local DEBUG_msp = false				-- display msp messages
local DEBUG_mspVALUES = false  		-- display values received from valid msp
local DEBUG_BADESC_ENABLE = false  	-- enable ability to get into esc menus even if not detected

local SIM_ENABLE_RSSI = false	-- set this to true to enable debugging of msg boxes in sim mode


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
local wasReloading = false
local closinghelp = false
local linkUPTime
local SAVE_FAILED = false

local lastLabel = nil
local NewRateTable
RateTable = nil
ResetRates = nil
reloadRates = false

isLoading = false
wasLoading = false

local exitAPP = false
local noRFMsg = false
local triggerSAVE = false
local triggerESCRELOAD = false

local fieldHelpTxt = nil

local profileswitchLast
local rateswitchLast

local mspDataLoaded = false

local LCD_W
local LCD_H

reloadServos = false

defaultRateTable = 4 -- ACTUAL

local expPanelParam
local buttonsperrowParam

-- New variables for Ethos version
local screenTitle = nil
local lastEvent = nil
local enterEvent = nil
local enterEventTime
local callCreate = true
local lastPage
local lastSection = nil
local lastIdx = nil
local lastSubPage = nil
local lastTitle = nil
local lastScript = nil

local ESC_MODE = false
local ESC_MFG = nil
local ESC_SCRIPT = nil
local ESC_UNKNOWN = false	
local ESC_NOTREADYCOUNT = 0
		

protocol = nil
radio = nil
sensor = nil


local progressDialog = false
local progressDialogDisplay = false
local progressDialogWatchDog = nil

local saveDialog = false
local saveDialogDisplay = false
local saveDialogWatchDog = nil

local nolinkDialog = false
local nolinkDialogDisplay = false
local nolinkDialogValue = 0

local badversionDialog = false
local badversionDisplay = false


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
end



function rf2ethos.dataBindFields()

    if Page.fields ~= nil and Page.values ~= nil then
	
		
	
        for i = 1, #Page.fields do


			if progressDialogDisplay == true then
				local percent = (i / #Page.fields) * 100
				progressDialog:value(percent)	
			end	

				
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
			if DEBUG_msp == true then
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
    elseif cmd == uiMsp.eepromWrite then
        if Page.reboot then
            rebootFc()
        end
        invalidatePages()
    elseif ESC_MODE == true and (cmd == Page.read and err)  then
		if DEBUG_msp == true then
			print("ESC not ready, waiting...")
		end
		ESC_NOTREADYCOUNT = ESC_NOTREADYCOUNT + 1
		if ESC_NOTREADYCOUNT >= 5 then
			ESC_UNKNOWN = true	
			mspDataLoaded = true				
		end

    elseif ESC_MODE == true and (cmd == Page.read and #rx_buf >= mspHeaderBytes and rx_buf[1] ~= mspSignature) then
		ESC_UNKNOWN = true
        mspDataLoaded = true		
		if DEBUG_msp == true then
			print("ESC not recognized")
		end
    elseif (cmd == Page.read) and (#rx_buf > 0) then
		if DEBUG_msp == true then
         print("processMspReply:  Page.read and non-zero rx_buf")
		end 
        Page.values = rx_buf
        if Page.postRead then
			if DEBUG_msp == true then
             print("Postread executed")
			end 
            Page.postRead(Page)
        end
        rf2ethos.dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
			if DEBUG_msp == true then
             print("Postload executed")
			end 
        end	
        mspDataLoaded = true
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

function rf2ethos.loadScriptrf2ethos(script)
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

	if DEBUG_mspVALUES == true then
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


function rf2ethos.openPagehelp(helpdata,section)
	local txtData

	if section == "rates_1" then
		txtData = helpdata[section]["table"][RateTable]
	else
		txtData = helpdata[section]["TEXT"]
	end	
	local qr = helpdata[section]["qrCODE"]


	local message = ""

	-- wrap text because of image on right
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

	
	
	
	local bitmap = lcd.loadBitmap(qr)
	
	form.openDialog({
	  width=LCD_W,
	  title="Help - " .. lastTitle,
	  message=message, 
	  buttons=buttons, 
	  wakeup=function()
			 end,  
	  paint=function() 
			  local w = LCD_W
			  local h = LCD_H
			  local left = w * 0.75

			  local qw = radio.helpQrCodeSize
			  local qh = radio.helpQrCodeSize
			
			  local qy = radio.buttonPadding			
			  local qx = LCD_W - qw - radio.buttonPadding/2
			  lcd.drawBitmap(qx,qy,bitmap,qw,qh)	


			end,
	  options=TEXT_LEFT
	})	
			
end


-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)
    print("Event received:", category, value, x, y)



	-- close esc main type selection menu
	if ESC_MODE == true and ESC_MFG == nil and ESC_SCRIPT == nil then
		if category == 5 then
				ResetRates = false
				rf2ethos.openMainMenu()
				ESC_MODE = false
				ESC_MFG = nil
				ESC_SCRIPT = nil
			return true		
		end		
	end
	-- close esc pages menu
	if ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT == nil then
		if category == 5 then
				ResetRates = false
				rf2ethos.openPageESC(lastIdx, lastTitle, lastScript)
				ESC_MODE = false
				ESC_MFG = nil
				ESC_SCRIPT = nil
			return true		
		end		
	end
	-- close esc pages menu
	if ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT ~= nil then
		if category == 5 then
				ResetRates = false
				rf2ethos.openPageESCToolLoader(ESC_MFG)
				ESC_MODE = false
				ESC_MFG = nil
				ESC_SCRIPT = nil
			return true		
		end		
	end	
	


	if uiState == uiStatus.pages then
		if category == 5 then
				ResetRates = false
				rf2ethos.openMainMenu()
			return true		
		end	
		if value == 35 then	
				ResetRates = false
				rf2ethos.openMainMenu()
			return true
		end
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


function rf2ethos.clearScreen()
	local w = LCD_W
	local h = LCD_H
    if isDARKMODE then
        lcd.color(lcd.RGB(40, 40, 40))
    else
        lcd.color(lcd.RGB(240, 240, 240))
    end
    lcd.drawFilledRectangle(0, 0, w, h)
end

-- WAKEUP:  Called every ~30-50ms by the main Ethos software loop
function wakeup(widget)


	-- exit app called : quick abort
	-- as we dont need to run the rest of the stuff
	if exitAPP == true then
		exitAPP = false
		form.invalidate()
		system.exit()
		return
	end
	

	-- ethos version
    if tonumber(rf2ethos.sensorMakeNumber(environment.major .. environment.minor .. environment.revision)) < ETHOS_VERSION then
		if badversionDisplay == false then
			badversionDisplay = true

			  local buttons = {
					{
						label = "EXIT",
						action = function()
							exitAPP = true
							return true
						end
					}
				}
				
				if tonumber(rf2ethos.sensorMakeNumber(environment.major .. environment.minor .. environment.revision)) < 1590 then	
					form.openDialog("Warning", ETHOS_VERSION_STR, buttons,1)
				else
					form.openDialog({
					  width=LCD_W,
					  title="Warning",
					  message=ETHOS_VERSION_STR , 
					  buttons=buttons, 
					  wakeup=function()
							 end,  
					  paint=function() 
							end,
					  options=TEXT_LEFT
					})				
				end

		end
    end	

	-- capture profile switching and trigger a reload if needs be

	if 
		(lastPage == "pids.lua" or 
		lastPage == "profile.lua" or
		lastPage == "profile_governor.lua" or
		lastPage == "profile_rescue.lua" ) and 
		ESC_MODE ~= true
		then
		if profileswitchParam ~= nil then
		
			if profileswitchParam:value() ~= profileswitchLast then
		
				if progressDialogDisplay ==  true or saveDialogDisplay == true then
					-- switch has been toggled mid flow - this is bad.. clean upd
					if progressDialogDisplay ==  true then
							progressDialog:close()
					end
					if saveDialogDisplay ==  true then
							saveDialog:close()
					end
					form.clear()
					wasReloading = true
					createForm = true							
					wasSaving = false
					wasLoading = false
					reloadRates = false
					reloadServos = false
				
				else
		
					profileswitchLast = profileswitchParam:value()
					-- trigger RELOAD
					print("Profile switch reload")
					if environment.simulation ~= true then
						wasReloading = true
						createForm = true							
						wasSaving = false
						wasLoading = false
						reloadRates = false
						reloadServos = false
					end
					return true
					
				end	
			end
		end
	end

	-- capture profile switching and trigger a reload if needs be
	if 
		lastPage == "rates.lua" and ESC_MODE ~= true
		then
		if rateswitchParam ~= nil then
			if rateswitchParam:value() ~= rateswitchLast then

				if progressDialogDisplay ==  true or saveDialogDisplay == true then
					-- switch has been toggled mid flow - this is bad.. clean upd
					if progressDialogDisplay ==  true then
							progressDialog:close()
					end
					if saveDialogDisplay ==  true then
							saveDialog:close()
					end
					form.clear()
					wasReloading = true
					createForm = true							
					wasSaving = false
					wasLoading = false
					reloadRates = false
					reloadServos = false
				else			
					rateswitchLast = rateswitchParam:value()

					-- trigger RELOAD
					print("Rate switch reload")
					if environment.simulation ~= true then
						wasSaving = false
						wasLoading = false
						reloadServos = false
						wasReloading = false
						
						createForm = true
						reloadRates = true
					end
					return true
				end	


			end
		end
	end	

	
	-- check telemetry state and overlay dialog if not linked
    if environment.simulation ~= true or SIM_ENABLE_RSSI == true then
        if telemetryState ~= 1 then
			if nolinkDialogDisplay == false then
				nolinkDialogDisplay = true
				noLinkDialog = form.openProgressDialog("Connecting", "Waiting for a link to the flight controller")
				noLinkDialog:closeAllowed(false)	
				noLinkDialog:value(0)	
				nolinkDialogValue = 0	
			end
        end

		if nolinkDialogDisplay == true or telemetryState == 1 then
		
			if telemetryState == 1 then
				nolinkDialogValue = nolinkDialogValue + 20
			else
				nolinkDialogValue = nolinkDialogValue + 1
			end
			if nolinkDialogValue > 100 then
				noLinkDialog:close()
				nolinkDialogValue = 0
				nolinkDialogDisplay = false
				if telemetryState ~= 1 then
					exitAPP = true
				end	
			end
			noLinkDialog:value(nolinkDialogValue)
		end			
    end	
	
	-- some watchdogs to enable close buttons on save and progress if they time-out
	if saveDialogDisplay == true then
		if saveDialogWatchDog ~= nil then
			if (os.clock() - saveDialogWatchDog) > 30 then
					saveDialog:closeAllowed(true)
			end	
		end	
	end

	if progressDialogDisplay == true then
		if progressDialogWatchDog ~= nil then
			if (os.clock() - progressDialogWatchDog) > 20 then
					progressDialog:message("Error.. we timed out")
					progressDialog:closeAllowed(true)
			end	
		end	
	end
	
	




    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    updateTelemetryState()

    if uiState == uiStatus.init then
        -- print("Init")
        local prevInit
        if init ~= nil then
            prevInit = init.t
        end
        init = init or assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ui_init.lua"))()

        local initSuccess = init.f()

        --print(initSuccess)

        if prevInit ~= init.t then
            -- Update initialization message
        end
        if not initSuccess then
            -- waiting on api version to finish successfully.
            return 0
        end
        init = nil
        invalidatePages()
        uiState = prevUiState or uiStatus.mainMenu
        prevUiState = nil
    elseif uiState == uiStatus.pages then
        if prevUiState ~= uiState then
            prevUiState = uiState
        end

        if pageState == pageStatus.saving then
            if (saveTS + saveTimeout) < os.clock() then
                if saveRetries < saveMaxRetries then
                    saveSettings()
                else
					-- Saving failed for some reason
					SAVE_FAILED = true
					saveDialog:message("Error - failed to write data")
                    saveDialog:closeAllowed(true)
                    invalidatePages()
                end
                -- drop through to processMspReply to send msp_SET and see if we've received a response to this yet.
            end
        elseif pageState == pageStatus.eepromWrite then
            if (saveTS + saveTimeout) < os.clock() then
                if saveRetries < saveMaxRetries then
                    eepromWrite()
                else
                    -- print("Failed to write to eeprom!")
                    invalidatePages()
                end
                -- drop through to processMspReply to send msp_SET and see if we've received a response to this yet.
            end
        end
        if not Page then
			if ESC_MODE == true then
				Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ESC/" .. ESC_MFG .. "/pages/" .. ESC_SCRIPT))()			
			else 
				if lastPage ~= nil then
				Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages/" .. lastPage))()
				end
				ESC_MFG = nil
				ESC_SCRIPT = nil
				ESC_MODE = false
			end	
            collectgarbage()
        end
		if Page ~= nil then
			if not Page.values and pageState == pageStatus.display then
				requestPage()
			end
		end	
    end

    mspProcessTxQ()
    processMspReply(mspPollReply())
    lastEvent = nil


	if createForm == true then
		if wasSaving == true or environment.simulation == true then
			rf2ethos.profileSwitchCheck()
			rf2ethos.rateSwitchCheck()
			wasSaving = false
			saveDialog:value(100)
			saveDialogDisplay = false
			saveDialogWatchDog = nil
			if SAVE_FAILED == false then
				saveDialog:close()	
				SAVE_FAILED = false
			end
			rf2ethos.resetServos() -- this must run after save settings		
			rf2ethos.resetCopyProfiles() -- this must run after save settings	
		elseif wasLoading == true or environment.simulation == true then
			wasLoading = false
			rf2ethos.profileSwitchCheck()
			rf2ethos.rateSwitchCheck()
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
		elseif wasReloading == true or environment.simulation == true then
				wasReloading = false
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
				rf2ethos.profileSwitchCheck()
				rf2ethos.rateSwitchCheck()
		elseif reloadRates == true or environment.simulation == true then
			rf2ethos.openPageRATESLoader(lastIdx, lastSubPage, lastTitle, lastScript)
		elseif reloadServos == true then
			if progressDialogDisplay == true then
				progressDialogWatchDog = nil
				progressDialogDisplay = false
				progressDialog:close()
			end
			rf2ethos.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
		else
			rf2ethos.openMainMenu()
		end
		createForm = false
	else
		createForm = false
	end

	if uiState ~= uiStatus.mainMenu then
		if environment.simulation == true or mspDataLoaded == true then
			mspDataLoaded = false
			isLoading = false
			wasLoading = true
			if environment.simulation ~= true then
				createForm = true
			end
		end
	end


    if isSaving then
        if pageState >= pageStatus.saving then
			if saveDialogDisplay == false then
				SAVE_FAILED = false
				saveDialogDisplay = true
				saveDialogWatchDog = os.clock()
				saveDialog = form.openProgressDialog("Saving...", "Saving data...")
				saveDialog:value(0)
				saveDialog:value(10)
				saveDialog:closeAllowed(false)
			end
            local saveMsg = ""
            if pageState == pageStatus.saving then
				saveDialog:value(50)
                saveDialog:message("Saving...")
                if saveRetries > 0 then
                    saveDialog:message("Retry #" .. string.format("%u", saveRetries))
                end
            elseif pageState == pageStatus.eepromWrite then
				saveDialog:value(80)
                saveDialog:message("Updating...")
                if saveRetries > 0 then
                    saveDialog:message("Updating...Retry #" .. string.format("%u", saveRetries))
					saveDialog:value(90)
                end
            elseif pageState == pageStatus.rebooting then
                saveMsg = saveDialog:message("Rebooting...")
            end

			
        else
            isSaving = false
			saveDialogDisplay = false
			saveDialogWatchDog = nil
        end		
    end


	-- trigger save
	if triggerSAVE == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    isSaving = true
                    wasSaving = true
					
					triggerSAVE = false
                    rf2ethos.resetRates()
                    rf2ethos.debugSave()
                    saveSettings()
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
					triggerSAVE = false
                    return true
                end
            }
        }
		form.openDialog({
		  width=nil,
		  title="SAVE SETTINGS TO FBL",
		  message="Save current page to flight controller", 
		  buttons=buttons, 
		  wakeup=function()
				 end,  
		  paint=function() 
				end,
		  options=TEXT_LEFT
		})		

		
		triggerSAVE = false
	end

	if triggerESCRELOAD == true then
		triggerESCRELOAD = false
		rf2ethos.openESCFormLoader(ESC_MFG,ESC_SCRIPT)
	end


    if telemetryState ~= 1 or (pageState >= pageStatus.saving) then
        -- we dont refresh as busy doing other stuff
        -- print("Form invalidation disabled....")
    else
        if (isSaving == false and wasSaving == false) or (isLoading == false and wasLoading == false) then
            --form.invalidate()
        end
    end	
	
end


local function convertPageValueTable(tbl,inc)
    local thetable = {}
	
	if inc == nil then
		inc = 0
	end
	
    if tbl[0] ~= nil then
        thetable[0] = {}
        thetable[0][1] = tbl[0]
        thetable[0][2] = 0
    end
    for idx, value in ipairs(tbl) do
        thetable[idx] = {}
        thetable[idx][1] = value
        thetable[idx][2] = idx + inc
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
	

	help =  assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/help/pages.lua"))()
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


	form.addTextButton(line, {x = x - (helpWidth + padding) - (w + padding)*3, y = y, w = w, h = h}, "MENU", function()
        ResetRates = false
        rf2ethos.openMainMenu()
    end)
    form.addTextButton(line, {x = x - (helpWidth + padding) - (w + padding)*2, y = y, w = buttonW, h = h}, "SAVE", function()
        triggerSAVE = true		
    end)	
    form.addTextButton(line, {x = x - (helpWidth + padding) - (w + padding), y = y, w = buttonW, h = h}, "RELOAD", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
					if environment.simulation ~= true then
						wasReloading = true
						createForm = true
						
						wasSaving = false
						wasLoading = false
						reloadRates = false
						reloadServos = false						
					end
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
		  width=nil,
		  title="RELOAD",
		  message="Reload data from flight controller", 
		  buttons=buttons, 
		  wakeup=function()
				 end,  
		  paint=function() 
				end,
		  options=TEXT_LEFT
		})		
    end)
	if helpWidth > 0 then
			form.addTextButton(line, {x = x - (helpWidth + padding), y = y, w = helpWidth, h = h}, "?", function()
				rf2ethos.openPagehelp(help.data,section)
			end)	
	end	
end


function rf2ethos.navigationButtonsEscForm(x, y, w, h)
    form.addTextButton(line, {x = x, y = y, w = w, h = h}, "MENU", function()
        ResetRates = false
		ESC_MODE = true
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
		form.openDialog({
		  width=nil,
		  title="SAVE SETTINGS TO ESC",
		  message="Save current page to ESC", 
		  buttons=buttons, 
		  wakeup=function()
				 end,  
		  paint=function() 
				end,
		  options=TEXT_LEFT
		})	

    end)
    form.addTextButton(line, {x = colStart + (buttonW + padding) * 2, y = y, w = buttonW, h = h}, "RELOAD", function()
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
					if environment.simulation ~= true then
						triggerESCRELOAD = true
					end
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
		  width=nil,
		  title="REFRESH",
		  message="Reload configuration from ESC", 
		  buttons=buttons, 
		  wakeup=function()
				 end,  
		  paint=function() 
				end,
		  options=TEXT_LEFT
		})	
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



	local w = LCD_W
	local h = LCD_H
    local colStart

    local padding = 5
    local fieldW = (w * inline_size) / 100

    local eX
    local eW = fieldW - padding
    local eH = radio.buttonHeight
    local eY = radio.buttonPaddingTop
    local posX
	lcd.font(FONT_STD)
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

-- when saving - we have to force a reload of data of servos due to way you
-- write one servo - and essentially loose Pages
function rf2ethos.resetServos()
	if lastScript == "servos.lua" then	
		rf2ethos.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
	end
end

-- when saving - we have to force a reload of data of copy-profiles due to way you
-- write one servo - and essentially loose Pages
function rf2ethos.resetCopyProfiles()
	if lastScript == "copy_profiles.lua" then	
		rf2ethos.openPageDefaultLoader(lastIdx, lastSubPage, lastTitle, lastScript)
	end
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

    field = form.addChoiceField(line, posField, convertPageValueTable(f.table,f.tableIdxInc), function()
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
	
	if f.help ~= nil then
		if fieldHelpTxt[f.help]['t'] ~= nil then
			local helpTxt = fieldHelpTxt[f.help]['t']	
			field:help(helpTxt)
		end
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
	local w = LCD_W
	local h = LCD_H
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


function rf2ethos.loadPreference(preference)
	-- open preference file
	file = "/scripts/rf2ethos/preferences/" .. preference .. ".cfg"	

	print("Read Preference:  " .. file)

	local f
	f = io.open(file,"rb")
	if f ~= nil then
		--file exists
		local rData
		c = 0
		tc = 1
		rData = io.read(f,"l")
		io.close(f)		

		return rData
	end

end

function rf2ethos.storePreference(preference,value)
	-- open preference file
	file = "/scripts/rf2ethos/preferences/" .. preference .. ".cfg"	

	if value == nil then
		value = ""
	end

	if type(value) == "boolean" then
		if value == true then
			value = 0
		else
			value = 1
		end
	end
	
	if type(value) == "userdata" then
		value = value:name()
	end

	print("Write Preference: " .. file .. " [" .. value .. "]")
	
	file = "/scripts/rf2ethos/preferences/" .. preference .. ".cfg"	
	
	
	--then write current data
	local f
	f = io.open(file,'w')
	f:write(value .. "\n")
	io.close(f)

end


function rf2ethos.openPagePreferences()
    uiState = uiStatus.pages

    form.clear()

	local w = LCD_W
	local h = LCD_H
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
	
	local x = w

    line = form.addLine("Preferences")
	form.addTextButton(line, {x = x - (buttonW + padding)*1, y = radio.buttonPaddingTop, w = buttonW, h = buttonH}, "MENU", function()
        rf2ethos.openMainMenu()
    end)


	-- display all preference below
	local menu = form.addExpansionPanel("Main menu")
	menu:open(false) 
	
	
	expPanelParam = rf2ethos.loadPreference("expansionpanel")
	if expPanelParam == "0" then
		expPanelParam = true
	else
		expPanelParam = false
	end
	
		
    line = menu:addLine("Expansion panels")
    form.addBooleanField(
        line,
        nil,
        function()
            return expPanelParam
        end,
        function(newValue)
            expPanelParam = newValue
			rf2ethos.storePreference("expansionpanel",newValue)			
        end
    )	


	buttonsperrowParam = rf2ethos.loadPreference("buttonsperrow")
	if buttonsperrowParam == "" or buttonsperrowParam == nil then
		buttonsperrowParam = 3
	end	
    line = menu:addLine("Buttons per row")
    form.addChoiceField(
        line,
        nil,
        {
            {"1", 1}, 
			{"2", 2},
            {"3", 3},
            {"4", 4},
        },
        function()
            return buttonsperrowParam
        end,
        function(newValue)
            buttonsperrowParam = newValue
			rf2ethos.storePreference("buttonsperrow",newValue)		
        end
    )

	-- Switch commands
	local triggers = form.addExpansionPanel("Triggers")
	triggers:open(false) 
	
	
	-- PROFILE
	profileswitchParam = rf2ethos.loadPreference("profileswitch")
	if profileswitchParam ~= nil then
		local s = rf2ethos.explode (profileswitchParam, ",")
		profileswitchParam = system.getSource({category=s[1], member=s[2]})
	end

    line = triggers:addLine("Switch profile")	
    form.addSourceField(
		line, 
		nil, 
		function() 
				return profileswitchParam
		end, 
		function(newValue) 
				profileswitchParam = newValue 
				local member = profileswitchParam:member()
				local category = profileswitchParam:category()
				rf2ethos.storePreference("profileswitch",category..","..member)	
		end
	)

	rateswitchParam = rf2ethos.loadPreference("rateswitch")
	if rateswitchParam ~= nil then
		local s = rf2ethos.explode (rateswitchParam, ",")
		rateswitchParam = system.getSource({category=s[1], member=s[2]})
	end

    line = triggers:addLine("Switch rates")	
    form.addSourceField(
		line, 
		nil, 
		function() 
				return rateswitchParam
		end, 
		function(newValue) 
				rateswitchParam = newValue 
				local member = rateswitchParam:member()
				local category = rateswitchParam:category()
				rf2ethos.storePreference("rateswitch",category..","..member)	
		end
	)




end

function rf2ethos.explode (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

function rf2ethos.openPageDefaultLoader(idx, subpage, title, script)


    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages/" .. script))()
    collectgarbage()

	progressDialogDisplay = true
	progressDialogWatchDog = os.clock()
	progressDialog = form.openProgressDialog("Loading...", "Loading data from flight controller.")
	progressDialog:value(0)
	progressDialog:closeAllowed(false)

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    isLoading = true

    print("Finished: rf2ethos.openPageDefaultLoader")

    if environment.simulation == true then
        rf2ethos.openPageDefault(idx, subpage, title, script)
    end

end

function rf2ethos.openPageDefault(idx, subpage, title, script)

	
	if progressDialogDisplay == true then
		progressDialogWatchDog = nil
		progressDialogDisplay = false
		progressDialog:close()
	end


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


end

function rf2ethos.openPageSERVOSLoader(idx, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages/" .. script))()
    collectgarbage()

	progressDialogDisplay = true
	progressDialogWatchDog = os.clock()
	progressDialog = form.openProgressDialog("Loading...", "Loading data from flight controller.")
	progressDialog:value(0)
	progressDialog:closeAllowed(false)

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script

    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPageSERVOS(idx, title, script)
    end

    print("Finished: rf2ethos.openPageSERVOS")
end

function rf2ethos.openPageSERVOS(idx, title, script)

	if progressDialogDisplay == true then
		progressDialogWatchDog = nil
		progressDialogDisplay = false
		progressDialog:close()
	end

    reloadServos = false

    uiState = uiStatus.pages

    local numPerRow = 2

	local windowWidth = LCD_W
	local windowHeight = LCD_H
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
				if Page == nil then
                    wasReloading = true
                    createForm = true
				else 
					Page.fields[1].value = value
				end	
                return value
            end, function(value)			
                Page.servoChanged(Page, value)				
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
				if f.help ~= nil then
					if fieldHelpTxt[f.help]['t'] ~= nil then
						local helpTxt = fieldHelpTxt[f.help]['t']	
						field:help(helpTxt)
					end
				end				
            end
        end
    end

end

function rf2ethos.openPagePIDLoader(idx, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages/" .. script))()
    collectgarbage()

	progressDialogDisplay = true
	progressDialogWatchDog = os.clock()
	progressDialog = form.openProgressDialog("Loading...", "Loading data from flight controller.")
	progressDialog:value(0)
	progressDialog:closeAllowed(false)

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script
	lastPage = script

    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPagePID(idx, title, script)
    end

    print("Finished: rf2ethos.openPagePID")
end

function rf2ethos.openPagePID(idx, title, script)

	if progressDialogDisplay == true then
		progressDialogWatchDog = nil
		progressDialogDisplay = false
		progressDialog:close()
	end



    uiState = uiStatus.pages

    longPage = false

    form.clear()

    fieldHeader(title)
	local numCols
	if Page.cols ~= nil then
		numCols = #Page.cols
	else
		numCols = 6 
	end
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
        _G["rf2ethos_PIDROWS_" .. ri] = form.addLine(rv)
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

        field = form.addNumberField(_G["rf2ethos_PIDROWS_" .. f.row], pos, minValue, maxValue, function()
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
		if f.help ~= nil then
			if fieldHelpTxt[f.help]['t'] ~= nil then
				local helpTxt = fieldHelpTxt[f.help]['t']	
				field:help(helpTxt)
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


end


-- display the list of known esc types
-- /scripts/rf2ethos/pages/esc.lua
function rf2ethos.openPageESC(idx, title, script)

	print("rf2ethos.openPageESC")

    mspDataLoaded = false
    uiState = uiStatus.mainMenu


    lastIdx = idx
    lastTitle = title
    lastScript = script
	
	ESC = {}

	ESC_MODE=true

    local windowWidth = LCD_W
	local windowHeight = LCD_H

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
   

    local ESCMenu = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages/" .. script))()

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

	progressDialogDisplay = true
	progressDialogWatchDog = os.clock()
	progressDialog = form.openProgressDialog("Loading...", "Loading data from ESC")
	progressDialog:value(0)
	progressDialog:closeAllowed(false)

	ESC_MFG = folder
	ESC_SCRIPT = nil
	ESC_MODE = true


    uiState = uiStatus.pages
    mspDataLoaded = false

    ESC.init = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ESC/" .. folder .. "/init.lua"))()
	

    Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ESC/" .. folder .. "/esc_info.lua"))()
    --form.clear()

    --lastIdx = idx
    --lastTitle = title
    --lastScript = script


    isLoading = true

    if environment.simulation == true then
        rf2ethos.openPageESCTool(folder)
    end

end



-- initialise menu for specific type of esc
-- basically we load libraries then read 
-- /scripts/rf2ethos/ESC/<TYPE>/pages.lua
function rf2ethos.openPageESCTool(folder)

	print("rf2ethos.openPageESCTool")


	if progressDialogDisplay == true then
		progressDialogWatchDog = nil
		progressDialogDisplay = false
		progressDialog:close()
	end


    ESC.init = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ESC/" .. folder .. "/init.lua"))()

	--mspDataLoaded = false
    --uiState = uiStatus.mainMenu
	uiState = uiStatus.pages

    local windowWidth = LCD_W
	local windowHeight = LCD_H


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
   
    ESC.pages = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ESC/" .. folder .. "/pages.lua"))()

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
	
	

    Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/ESC/" .. folder .. "/pages/" .. script))()
    collectgarbage()

	progressDialogDisplay = true
	progressDialogWatchDog = os.clock()
	progressDialog = form.openProgressDialog("Loading...", "Loading data from flight controller.")
	progressDialog:value(0)
	progressDialog:closeAllowed(false)

    isLoading = true
	

	

    if environment.simulation == true then
        rf2ethos.openESCForm(folder, script)
    end

end

--
function rf2ethos.openESCForm(folder,script)

	if progressDialogDisplay == true then
		progressDialogWatchDog = nil
		progressDialogDisplay = false
		progressDialog:close()
	end


    local fieldAR = {}
    uiState = uiStatus.pages
    longPage = false
	form.clear()

    local windowWidth = LCD_W
	local windowHeight = LCD_H
    local y = radio.buttonPaddingTop

    local w = LCD_W
	local h = LCD_H
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



end



function rf2ethos.openPageRATESLoader(idx, subpage, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages/" .. script))()
    collectgarbage()

	progressDialogDisplay = true
	progressDialogWatchDog = os.clock()
	progressDialog = form.openProgressDialog("Loading...", "Loading data from flight controller.")
	progressDialog:value(0)
	progressDialog:closeAllowed(false)

    lastIdx = idx
    lastSubPage = subpage
    lastTitle = title
    lastScript = script
	lastPage = script

    isLoading = true


    if environment.simulation == true then
        rf2ethos.openPageRATES(idx, subpage, title, script)
    end

    print("Finished: rf2ethos.openPageRATESLoader")
end

function rf2ethos.openPageRATES(idx, subpage, title, script)



	if progressDialogDisplay == true then
		progressDialogWatchDog = nil
		progressDialogDisplay = false
		progressDialog:close()
	end


   if Page.fields then
		local v = Page.fields[13].value
		if v ~= nil then
			activeRateTable = math.floor(v)
		end

		if activeRateTable ~= nil then
			if activeRateTable ~= RateTable then
				RateTable = activeRateTable
				if progressDialogDisplay == true then
					progressDialogWatchDog = nil
					progressDialogDisplay = false
					progressDialog:close()
				end
				rf2ethos.openPageRATESLoader(idx, subpage, title, script)
				
			end
		end
    end


	rateswitchParam = rf2ethos.loadPreference("rateswitch")
	if rateswitchParam ~= nil then
		local s = rf2ethos.explode (rateswitchParam, ",")
		rateswitchParam = system.getSource({category=s[1], member=s[2]})
	end


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
        _G["rf2ethos_RATEROWS_" .. ri] = form.addLine(rv)
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

            field = form.addNumberField(_G["rf2ethos_RATEROWS_" .. f.row], pos, minValue, maxValue, function()
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
			if f.help ~= nil then
				if fieldHelpTxt[f.help]['t'] ~= nil then
					local helpTxt = fieldHelpTxt[f.help]['t']	
					field:help(helpTxt)
				end
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


	

end

local function getSection(id, sections)
    for i, v in ipairs(sections) do
        if id ~= nil then
            if v.section == id then
                return v
            end
        end
    end
end

function rf2ethos.openMainMenu()

    if tonumber(rf2ethos.sensorMakeNumber(environment.major .. environment.minor .. environment.revision)) < ETHOS_VERSION then
        return
    end

    mspDataLoaded = false
    uiState = uiStatus.mainMenu



    local numPerRow
	numPerRow = rf2ethos.loadPreference("buttonsperrow")
	if numPerRow == nil or numPerRow == "" then
		numPerRow = 3
	end
	if type(numPerRow) == "string" then
		numPerRow = tonumber(numPerRow)
	end

    local windowWidth = LCD_W
	local windowHeight = LCD_H

    local padding = radio.buttonPadding
    local h = radio.buttonHeight
    local w = (windowWidth - (padding * numPerRow) - padding - 5) / numPerRow
    -- local x = 0

    local y = radio.buttonPaddingTop

	local MENU_EXPANSION 
	
	local doExp = rf2ethos.loadPreference("expansionpanel")
	if doExp == "0" then
		MENU_EXPANSION = true
	else
		MENU_EXPANSION = false
	end
	local sc 
	local panel


	form.clear()
	
	_G["rf2ethosMenuPanels"] = {}	
    for idx, value in ipairs(MainMenu.sections) do
	
		local sc = value.section

		if MENU_EXPANSION ~= true then
			-- just a line with a title
			_G["rf2ethosMenuPanels"][sc] =  form.addLine(value.title)
		else
			-- or an expansion panel

			_G["rf2ethosMenuPanels"][sc] = form.addExpansionPanel(value.title)
			
			if lastSection == nil then
				if sc ==  1 then
					_G["rf2ethosMenuPanels"][sc]:open(true) 
				else
					_G["rf2ethosMenuPanels"][sc]:open(false) 
				end
			else
				if lastSection == sc then
					_G["rf2ethosMenuPanels"][sc]:open(true) 
				else
					_G["rf2ethosMenuPanels"][sc]:open(false) 
				end
			end
		end

        lc = 0
        for pidx, pvalue in ipairs(MainMenu.pages) do
            if pvalue.section == value.section then
                if lc == 0 then
					if MENU_EXPANSION ~= true then
						line = form.addLine("")
					else
						line = _G["rf2ethosMenuPanels"][sc]:addLine("",true)
					end
                    x = padding
                end

                if lc >= 0 then
                    x = (w + padding) * lc
                end


                form.addTextButton(line, {x = x, y = y, w = w, h = h}, pvalue.title, function()
				
					lastSection = value.section	
					
                    if pvalue.script == "pids.lua" then
                        rf2ethos.openPagePIDLoader(pidx, pvalue.title, pvalue.script)
                    elseif pvalue.script == "servos.lua" then
                        rf2ethos.openPageSERVOSLoader(pidx, pvalue.title, pvalue.script)
                    elseif pvalue.script == "rates.lua" and pvalue.subpage == 1 then
                        rf2ethos.openPageRATESLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                    elseif pvalue.script == "esc.lua" then
                        rf2ethos.openPageESC(pidx, pvalue.title, pvalue.script)		
					elseif pvalue.script == "preferences.lua" then
						rf2ethos.openPagePreferences()
                    else
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

function rf2ethos.profileSwitchCheck()
	profileswitchParam = rf2ethos.loadPreference("profileswitch")
	if profileswitchParam ~= nil then
		local s = rf2ethos.explode (profileswitchParam, ",")
		profileswitchParam = system.getSource({category=s[1], member=s[2]})
		profileswitchLast = profileswitchParam:value()
	end
end

function rf2ethos.rateSwitchCheck()
	rateswitchParam = rf2ethos.loadPreference("rateswitch")
	if rateswitchParam ~= nil then
		local s = rf2ethos.explode (rateswitchParam, ",")
		rateswitchParam = system.getSource({category=s[1], member=s[2]})
		rateswitchLast = rateswitchParam:value()
	end
end

local function create()

	LCD_W, LCD_H = rf2ethos.getWindowSize()

    protocol = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/protocols.lua"))()
    radio = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/radios.lua"))().msp
    assert(rf2ethos.loadScriptrf2ethos(protocol.mspTransport))()
    assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/msp/common.lua"))()
	
	fieldHelpTxt = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/help/fields.lua"))()

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
	
    MainMenu = assert(rf2ethos.loadScriptrf2ethos("/scripts/rf2ethos/pages.lua"))()

    rf2ethos.openMainMenu()

	
end

local function close()
	ESC_MODE = false
	ESC_MFG = nil
	ESC_SCRIPT = nil
    pageLoaded = 100
    pageTitle = nil
    pageFile = nil
	exitAPP = false
	noRFMsg = false
	linkUPTime = nil
	nolinkDialogDisplay = false
	nolinkDialogValue = 0
	telemetryState = nil
    system.exit()
    return true
end

local icon = lcd.loadMask("/scripts/rf2ethos/RF.png")

local function init()
    system.registerSystemTool({event = event, name = name, icon = icon, create = create, wakeup = wakeup, close = close})
end

return {init = init}
