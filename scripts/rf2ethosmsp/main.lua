-- RotorFlight + ETHOS LUA configuration

local TOOL_NAME = "RF2ETHOSMSP"
local TOOL_DIR = "/scripts/rf2ethosmsp/"

local environment = system.getVersion()

local LUA_VERSION = "2.0.0 - 240625"
local ETHOS_VERSION = 1510
local ETHOS_VERSION_STR = "ETHOS < V1.5.10"

local DEBUG_MSP = false -- display msp messages
local DEBUG_MSPVALUES = false -- display values received from valid msp
local DEBUG_BADESC_ENABLE = false -- enable ability to get into esc menus even if not detected
local SIM_ENABLE_RSSI = false -- set this to true to enable debugging of msg boxes in sim mode

apiVersion = 0

-- placeholder tables to store button images
-- these need to be in main function to avoiud
-- ethose cleaning them up - with a resultant crash.
local gfx_buttons = {}
local esc_buttons = {}
local esctool_buttons = {}

-- tables used to determine the state of msp comms
local uiStatus = {init = 1, mainMenu = 2, pages = 3, confirm = 4}
local pageStatus = {display = 1, editing = 2, saving = 3, eepromWrite = 4, rebooting = 5}
local telemetryStatus = {ok = 1, noSensor = 2, noTelemetry = 3}


local uiState = uiStatus.init
local prevUiState
local pageState = pageStatus.display
-- local currentField = 1   - flag for deletion as dont believe used anymore

local telemetryState

local saveTS = 0
local saveRetries = 0
local saveTimeout
local saveMaxRetries
local saveFailed = false
local MainMenu
local Page
local init
local requestTimeout
local isSaving = false
local wasSaving = false
local wasReloading = false
local closinghelp = false
local linkUPTime
createForm = false

local lastLabel = nil
local NewRateTable
RateTable = nil
resetRates = nil
reloadRates = false

-- these globals need to be checked if they need to be globals
-- for a future play day!
defaultRateTable = 4 -- ACTUAL
isLoading = false
wasLoading = false
reloadServos = false

local exitAPP = false
local noRFMsg = false
local triggerSAVE = false
local triggerRELOAD = false
local triggerESCRELOAD = false
local triggerESCMAINMENU = false
local triggerESCLOADER = false
local escPowerCycle = false
local escPowerCycleAnimation
local escPowerCycleLoader = 0

local fieldHelpTxt = nil

local profileswitchLast
local rateswitchLast
local iconsizeParam

local mspDataLoaded = false

local LCD_W
local LCD_H

local lastPage
local lastSection = nil
local lastIdx = nil
local lastSubPage = nil
local lastTitle = nil
local lastScript = nil

local ESC_MODE = false
local ESC_MENUSTATE = 0
local ESC_MFG = nil
local ESC_SCRIPT = nil
local ESC_UNKNOWN = false
local ESC_NOTREADYCOUNT = 0

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

-- placeholders for external libs
protocol = nil
radio = nil
sensor = nil

assert(loadfile(TOOL_DIR .. "rf2ethosmsp.lua"))()
bit32 = assert(loadfile(TOOL_DIR .. "lib/bit32.lua"))()

utils = {}
utils = assert(loadfile(TOOL_DIR .. "lib/utils.lua"))()

local translations = {en = TOOL_NAME}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end


rf2ethosmsp.settingsSaved = function()
    -- check if this page requires writing to eeprom to save (most do)
    if Page and Page.eepromWrite then
        -- don't write again if we're already responding to earlier page.write()s
        if pageState ~= pageStatus.eepromWrite then
            pageState = pageStatus.eepromWrite
            rf2ethosmsp.mspQueue:add(mspEepromWrite)
        end
    elseif pageState ~= pageStatus.eepromWrite then
        -- If we're not already trying to write to eeprom from a previous save, then we're done.
        invalidatePages()
    end
    rf2ethosmsp.lcdNeedsInvalidate = true
end

local mspSaveSettings =
{
    processReply = function(self, buf)
        rf2ethosmsp.settingsSaved()
    end
}

local mspLoadSettings =
{
    processReply = function(self, buf)
        print("Page is processing reply for cmd "..tostring(self.command).." len buf: "..#buf.." expected: "..Page.minBytes)
        Page.values = buf
        if Page.postRead then
            Page.postRead(Page)
        end
        rf2ethosmsp.dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
        end
		mspDataLoaded = true
    end
}

rf2ethosmsp.readPage = function()
    if type(Page.read) == "function" then
        Page.read(Page)
    else
        mspLoadSettings.command = Page.read
        mspLoadSettings.simulatorResponse = Page.simulatorResponse
        rf2ethosmsp.mspQueue:add(mspLoadSettings)
    end
end

local function saveSettings()
    if pageState ~= pageStatus.saving then
        pageState = pageStatus.saving

        if Page.values then
            local payload = Page.values
		
            mspSaveSettings.command = Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            rf2ethosmsp.mspQueue:add(mspSaveSettings)
        elseif type(Page.write) == "function" then
            Page.write(Page)
        end
    end
end

local function saveSettings()
    if pageState ~= pageStatus.saving then
        pageState = pageStatus.saving
        saveTS = os.clock()

        if Page.values then
            local payload = Page.values
			if ESC_MODE == true then
				payload[2] = 0
			end				
            mspSaveSettings.command = Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            rf2ethosmsp.mspQueue:add(mspSaveSettings)
        elseif type(Page.write) == "function" then
            Page.write(Page)
        end

    end
end



local mspEepromWrite =
{
    command = 250, -- MSP_EEPROM_WRITE, fails when armed
    processReply = function(self, buf)
        if Page.reboot then
            rebootFc()
        end
        invalidatePages()
    end,
    simulatorResponse = {}
}

local function rebootFc()
    print("Attempting to reboot the FC...")
    pageState = pageStatus.rebooting
    rf2ethosmsp.mspQueue:add({
        command = 68, -- MSP_REBOOT
        processReply = function(self, buf)
            invalidatePages()
        end
    })
end

local function invalidatePages()
    Page = nil
    pageState = pageStatus.display
    saveTS = 0
    collectgarbage()
end

function rf2ethosmsp.dataBindFields()

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
            if DEBUG_MSP == true then
                if ESC_MODE == true then
                    -- 1 extra byte - for esc signature?
                    print("Page is processing reply for cmd " .. tostring(cmd) .. " len rx_buf: " .. #rx_buf .. " expected: " .. (Page.minBytes + 1))
                else
                    print("Page is processing reply for cmd " .. tostring(cmd) .. " len rx_buf: " .. #rx_buf .. " expected: " .. Page.minBytes)
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
    elseif ESC_MODE == true and (cmd == Page.read and err) then
        if DEBUG_MSP == true then
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
        rf2ethosmsp.dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
            if DEBUG_MSP == true then
                print("Postload executed")
            end
        end
        mspDataLoaded = true
        ESC_UNKNOWN = false
        ESC_NOTREADYCOUNT = 0
		
		
    end

end

local function requestPage()
    if not Page.reqTS or Page.reqTS + rf2ethosmsp.protocol.pageReqTimeout <= os.clock() then
        Page.reqTS = os.clock()
        if Page.read then
            rf2ethosmsp.readPage()
        end
    end
end


-- Ethos: when the RF1 and RF2 system tools are both installed, RF1 tries to call getRSSI in RF2 and gets stuck.
-- To avoid this, getRSSI is renamed in rf2ethosmsp.
rf2ethosmsp.getRSSI = function()
    -- print("getRSSI RF2")
    if environment.simulation == true then
        return 100
    end

    if rf2ethosmsp.rssiSensor ~= nil and rf2ethosmsp.rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rf2ethosmsp.rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

local function updateTelemetryState()

    if not rf2ethosmsp.rssiSensor then
        telemetryState = telemetryStatus.noSensor
    elseif rf2ethosmsp.getRSSI() == 0 then
        telemetryState = telemetryStatus.noTelemetry
    else
        telemetryState = telemetryStatus.ok
    end
	

end

function rf2ethosmsp.getFieldValue(f)

    if DEBUG_MSPVALUES == true then
        print(f.t .. ":" .. f.value)
    end

    local v

    if f.value ~= nil then
        if f.decimals ~= nil then
            v = utils.round(f.value * utils.decimalInc(f.decimals))
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

function rf2ethosmsp.saveValue(currentField)
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

function rf2ethosmsp.openPagehelp(helpdata, section)
    local txtData

    if section == "rates_1" then
        txtData = helpdata[section]["table"][RateTable]
    else
        txtData = helpdata[section]["TEXT"]
    end
    local qr = TOOL_DIR .. helpdata[section]["qrCODE"]

    local message = ""

    -- wrap text because of image on right
    for k, v in ipairs(txtData) do
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
        width = LCD_W,
        title = "Help - " .. lastTitle,
        message = message,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
            local w = LCD_W
            local h = LCD_H
            local left = w * 0.75

            local qw = rf2ethosmsp.radio.helpQrCodeSize
            local qh = rf2ethosmsp.radio.helpQrCodeSize

            local qy = rf2ethosmsp.radio.buttonPadding
            local qx = LCD_W - qw - rf2ethosmsp.radio.buttonPadding / 2
            lcd.drawBitmap(qx, qy, bitmap, qw, qh)

        end,
        options = TEXT_LEFT
    })

end

-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)
    print("Event received:", category, value, x, y)
	

	
    -- close esc main type selection menu
    if ESC_MENUSTATE == 1 then
        if category == 5 or value == 35 then
            resetRates = false
            ESC_MODE = false
            ESC_MFG = nil
            ESC_SCRIPT = nil
            rf2ethosmsp.openMainMenu()			
            return true
        end
    end
    -- close esc pages menu
    if ESC_MENUSTATE == 2 then
        if category == 5 or value == 35 then
            resetRates = false
            ESC_MODE = true
            ESC_MFG = nil
            ESC_SCRIPT = nil
            rf2ethosmsp.openPageESC(lastIdx, lastTitle, lastScript)			
            return true
        end
    end
    -- close esc tool menu
    if ESC_MENUSTATE == 3 then
        if category == 5 or value == 35  then
            resetRates = false
            ESC_MODE = true
			ESC_SCRIPT = nil
            ESC_NOTREADYCOUNT = 0
            collectgarbage()
            rf2ethosmsp.openPageESCTool(ESC_MFG)
            return true
        end
    end

    if uiState == uiStatus.pages then
        if category == 5 or value == 35  then
            resetRates = false
            rf2ethosmsp.openMainMenu()
            return true
        end
        if value == 35 then
            resetRates = false
            rf2ethosmsp.openMainMenu()
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
    if tonumber(utils.makeNumber(environment.major .. environment.minor .. environment.revision)) < ETHOS_VERSION then
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

            if tonumber(utils.makeNumber(environment.major .. environment.minor .. environment.revision)) < 1590 then
                form.openDialog("Warning", ETHOS_VERSION_STR, buttons, 1)
            else
                form.openDialog({
                    width = LCD_W,
                    title = "Warning",
                    message = ETHOS_VERSION_STR,
                    buttons = buttons,
                    wakeup = function()
                    end,
                    paint = function()
                    end,
                    options = TEXT_LEFT
                })
            end

        end
    end
	

	-- ESC LOADER
	if triggerESCLOADER == true then
		if progressDialogDisplay ~= true then
			-- we will prob never hit this loop in reality
			progressDialogDisplay = true
			progressDialogWatchDog = os.clock()
			progressDialog = form.openProgressDialog("Searching...", "Please power cycle the esc")
			progressDialog:value(0)
			progressDialog:closeAllowed(false)	
		else
			-- this is where we should hit
			
			if escPowerCycleLoader <= 95 then
				progressDialog:message("Please power cycle the esc")
			else
				progressDialog:message("Aborting...")
			end
			progressDialog:value(escPowerCycleLoader)
			
			escPowerCycleLoader = escPowerCycleLoader + 1
			
			if escPowerCycleLoader == 100 then
				escPowerCycleLoader = 0
				progressDialog:close()
				triggerESCMAINMENU = true
			end

		
		end
	end
	

    -- capture profile switching and trigger a reload if needs be

	if Page ~= nil then
		if Page.refreshswitch == true then

				if lastPage ~= "rates.lua" then
					if profileswitchParam ~= nil then

						if profileswitchParam:value() ~= profileswitchLast then

							if progressDialogDisplay == true or saveDialogDisplay == true then
								-- switch has been toggled mid flow - this is bad.. clean upd
								if progressDialogDisplay == true then
									progressDialog:close()
								end
								if saveDialogDisplay == true then
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
				if lastPage == "rates.lua" then
					if rateswitchParam ~= nil then
						if rateswitchParam:value() ~= rateswitchLast then

							if progressDialogDisplay == true or saveDialogDisplay == true then
								-- switch has been toggled mid flow - this is bad.. clean upd
								if progressDialogDisplay == true then
									progressDialog:close()
								end
								if saveDialogDisplay == true then
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

		end
	end

    -- check telemetry state and overlay dialog if not linked
    if escPowerCycle == true then
        -- ESC MODE - WE NEVER TIME OUT AS DO A 'RETRY DIALOG' 
        -- AS SOME ESC NEED TO BE CONNECTING AS YOU POWER UP to
        -- INIT CONFIG MODE
    else
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
    end

    if triggerESCMAINMENU == true then
        triggerESCMAINMENU = false
        ESC_MODE = false
        escPowerCycle = false
        resetRates = false
        ESC_NOTREADYCOUNT = 0
        ESC_UNKNOWN = false
        lastIdx = nil
        lastPage = nil
        lastSubPage = nil

        rf2ethosmsp.openPageESC(lastIdx, lastTitle, lastScript)

    end

    -- some watchdogs to enable close buttons on save and progress if they time-out
    if saveDialogDisplay == true then
        if saveDialogWatchDog ~= nil then
            if (os.clock() - saveDialogWatchDog) > 20 then
                saveDialog:closeAllowed(true)
            end
        end
    end

    if escPowerCycle == true then
        -- ESC MODE - WE NEVER TIME OUT AS DO A 'RETRY DIALOG' 
        -- AS SOME ESC NEED TO BE CONNECTING AS YOU POWER UP to
        -- INIT CONFIG MODE
    else
        if progressDialogDisplay == true then
            if progressDialogWatchDog ~= nil then
                if (os.clock() - progressDialogWatchDog) > 20 then
                    progressDialog:message("Error.. we timed out")
                    progressDialog:closeAllowed(true)
                end
            end
        end
    end

    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
	updateTelemetryState()


	--[[
    if uiState == uiStatus.init then
        print("Init")
        local prevInit
        if init ~= nil then
            prevInit = init.t
        end
        init = init or assert(loadfile(TOOL_DIR .. "ui_init.lua"))()

        local initSuccess = init.f()

        -- print(initSuccess)

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
    else
	]]--
	if uiState == uiStatus.pages then
        if prevUiState ~= uiState then
            prevUiState = uiState
        end

        if pageState == pageStatus.saving then
            if (saveTS + rf2ethosmsp.protocol.saveTimeout) < os.clock() then
				
                if saveRetries < rf2ethosmsp.protocol.maxRetries then
                    saveSettings()
                else
                    -- Saving failed for some reason
                    saveFailed = true
                    saveDialog:message("Error - failed to write data")
                    saveDialog:closeAllowed(true)
                    invalidatePages()
                end
			
            end
        elseif pageState == pageStatus.eepromWrite then
            if (saveTS + rf2ethosmsp.protocol.saveTimeout) < os.clock() then
			               
				saveDialog:value(100)
				saveDialog:close()						   
				invalidatePages()		   
			else
				saveRetries = saveRetries + 1
            end
        end
        if not Page then
            if ESC_MODE == true then
                if ESC_SCRIPT ~= nil then
                    Page = assert(loadfile(TOOL_DIR .. "ESC/" .. ESC_MFG .. "/pages/" .. ESC_SCRIPT))()
                else
                    print("ESC_SCRIPT is not present so cannot load as expected")
                end
            else
                if lastPage ~= nil then
                    Page = assert(loadfile(TOOL_DIR .. "pages/" .. lastPage))()
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
	
    rf2ethosmsp.mspQueue:processQueue()

if createForm == true then
	
        if wasLoading == true or environment.simulation == true then
            wasLoading = false
            rf2ethosmsp.profileSwitchCheck()
            rf2ethosmsp.rateSwitchCheck()
            if lastScript == "pids.lua" or lastIdx == 1 then
                rf2ethosmsp.openPagePID(lastIdx, lastTitle, lastScript)
            elseif lastScript == "rates.lua" and lastSubPage == 1 then
                rf2ethosmsp.openPageRATES(lastIdx, lastSubPage, lastTitle, lastScript)
            elseif lastScript == "servos.lua" then
                rf2ethosmsp.openPageSERVOS(lastIdx, lastTitle, lastScript)
            elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT == nil then
					rf2ethosmsp.openPageESCTool(ESC_MFG)
            elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT ~= nil then
                rf2ethosmsp.openESCForm(ESC_MFG, ESC_SCRIPT)
            else
                rf2ethosmsp.openPageDefault(lastIdx, lastSubPage, lastTitle, lastScript)
            end
        elseif wasReloading == true or environment.simulation == true then
            wasReloading = false
            if lastScript == "pids.lua" or lastIdx == 1 then
                rf2ethosmsp.openPagePIDLoader(lastIdx, lastTitle, lastScript)
            elseif lastScript == "rates.lua" and lastSubPage == 1 then
                rf2ethosmsp.openPageRATESLoader(lastIdx, lastSubPage, lastTitle, lastScript)
            elseif lastScript == "servos.lua" then
                rf2ethosmsp.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
            elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT == nil then
                rf2ethosmsp.openPageESCToolLoader(ESC_MFG)
            elseif ESC_MODE == true and ESC_MFG ~= nil and ESC_SCRIPT ~= nil then
                rf2ethosmsp.openESCFormLoader(ESC_MFG, ESC_SCRIPT)
            else
                rf2ethosmsp.openPageDefaultLoader(lastIdx, lastSubPage, lastTitle, lastScript)
            end
            rf2ethosmsp.profileSwitchCheck()
            rf2ethosmsp.rateSwitchCheck()
        elseif reloadRates == true or environment.simulation == true then
            rf2ethosmsp.openPageRATESLoader(lastIdx, lastSubPage, lastTitle, lastScript)
        elseif reloadServos == true then
            if progressDialogDisplay == true then
                progressDialogWatchDog = nil
                progressDialogDisplay = false
                progressDialog:close()
            end
            rf2ethosmsp.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
        else
            rf2ethosmsp.openMainMenu()
        end
		
        if wasSaving == true or environment.simulation == true then
            rf2ethosmsp.profileSwitchCheck()
            rf2ethosmsp.rateSwitchCheck()
            wasSaving = false
            saveDialog:value(100)
            saveDialogDisplay = false
            saveDialogWatchDog = nil
            if saveFailed == false then
                saveDialog:close()
                saveFailed = false
            end
            rf2ethosmsp.resetServos() -- this must run after save settings		
            rf2ethosmsp.resetCopyProfiles() -- this must run after save settings	
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
                saveFailed = false
                saveDialogDisplay = true
                saveDialogWatchDog = os.clock()
                saveDialog = form.openProgressDialog("Saving...", "Saving data...")
                saveDialog:value(0)
                saveDialog:value(10)
                saveDialog:closeAllowed(false)
				saveRetries = 0
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
                    rf2ethosmsp.resetRates()
                    rf2ethosmsp.debugSave()
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
		local theTitle
		local theMsg
		if ESC_MODE == true then
			theTitle = "SAVE SETTINGS TO ESC"
			theMsg = "Save current page to the speed controller"
		else
			theTitle = "SAVE SETTINGS TO FBL"
			theMsg = "Save current page to flight controller"
		end
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

        triggerSAVE = false
    end

    if triggerRELOAD == true then
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
            width = nil,
            title = "RELOAD",
            message = "Reload data from flight controller",
            buttons = buttons,
            wakeup = function()
            end,
            paint = function()
            end,
            options = TEXT_LEFT
        })

        triggerRELOAD = false
    end

    if triggerESCRELOAD == true then
        triggerESCRELOAD = false
        rf2ethosmsp.openESCFormLoader(ESC_MFG, ESC_SCRIPT)
    end

    if telemetryState ~= 1 or (pageState >= pageStatus.saving) then
        -- we dont refresh as busy doing other stuff
        -- print("Form invalidation disabled....")
    else
        if (isSaving == false and wasSaving == false) or (isLoading == false and wasLoading == false) then
            -- form.invalidate()
        end
    end

end

function rf2ethosmsp.navigationButtons(x, y, w, h)

    local helpWidth
    local section
    local page


    help = assert(loadfile(TOOL_DIR .. "help/pages.lua"))()
    section = string.gsub(lastScript, ".lua", "") -- remove .lua
    page = lastSubPage
    if page == nil then
        section = section
    else
        section = section .. '_' .. page
    end

    if help.data[section] then
        helpWidth = w - (w * 20) / 100
    else
        helpWidth = 0
    end

    field = form.addButton(line, {x = x - (helpWidth + padding) - (w + padding) * 3, y = y, w = w, h = h}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
			resetRates = false
            rf2ethosmsp.openMainMenu()
        end
    })
	field:focus()

    form.addButton(line, {x = x - (helpWidth + padding) - (w + padding) * 2, y = y, w = w, h = h}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            triggerSAVE = true
        end
    })

    form.addButton(line, {x = x - (helpWidth + padding) - (w + padding), y = y, w = w, h = h}, {
        text = "RELOAD",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            triggerRELOAD = true
        end
    })

    if helpWidth > 0 then

        form.addButton(line, {x = x - (helpWidth + padding), y = y, w = helpWidth, h = h}, {
            text = "?",
            icon = nil,
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethosmsp.openPagehelp(help.data, section)
            end
        })

    end

end

function rf2ethosmsp.navigationButtonsEscForm(x, y, w, h)




    local padding = 5
    local helpWidth = 0

    field = form.addButton(line, {x = x - w - padding - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            resetRates = false
            ESC_MODE = true
            ESC_NOTREADYCOUNT = 0
            collectgarbage()
            rf2ethosmsp.openPageESCTool(ESC_MFG)
        end
    })
	field:focus()

    form.addButton(line, {x = x - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
						ESC_NOTREADYCOUNT = 0
						triggerSAVE = true
        end
    })

    form.addButton(line, {x = x - w - padding, y = y, w = w, h = h}, {
        text = "RELOAD",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()

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
                width = nil,
                title = "REFRESH",
                message = "Reload configuration from ESC",
                buttons = buttons,
                wakeup = function()
                end,
                paint = function()
                end,
                options = TEXT_LEFT
            })

        end
    })

end

-- when saving - we have to force a reload of data of servos due to way you
-- write one servo - and essentially loose Pages
function rf2ethosmsp.resetServos()
    if lastScript == "servos.lua" then
        rf2ethosmsp.openPageSERVOSLoader(lastIdx, lastTitle, lastScript)
    end
end

-- when saving - we have to force a reload of data of copy-profiles due to way you
-- write one servo - and essentially loose Pages
function rf2ethosmsp.resetCopyProfiles()
    if lastScript == "copy_profiles.lua" then
        rf2ethosmsp.openPageDefaultLoader(lastIdx, lastSubPage, lastTitle, lastScript)
    end
end

function rf2ethosmsp.resetRates()
    if lastScript == "rates.lua" and lastSubPage == 2 then
        if resetRates == true then
            NewRateTable = Page.fields[13].value

            local newTable = utils.defaultRates(NewRateTable)

            for k, v in pairs(newTable) do
                local f = Page.fields[k]
                for idx = 1, #f.vals do
                    Page.values[f.vals[idx]] = v >> ((idx - 1) * 8)
                end
            end
            resetRates = false
        end
    end
end

function rf2ethosmsp.debugSave()
    -- this function runs before save action
    -- happens.  use it to do debug if needed

    -- if lastScript == "servos.lua" then

    --	Page.fields[1].value = currentServoID
    --    rf2ethosmsp.saveValue(currentServoID, 1)
    --    local f = Page.fields[1]

    --    print(f.value)

    --    for idx = 1, #f.vals do
    --    	Page.values[f.vals[idx]] = currentServoID >> ((idx - 1) * 8)
    --    end

    --    print(Page.fields[1].value)
    -- end

end

local function fieldChoice(f, i)
    if lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= lastSubPage then
            return
        end
    end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then

        if rf2ethosmsp.radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        local p = utils.getInlinePositions(f, Page)
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

    field = form.addChoiceField(line, posField, utils.convertPageValueTable(f.table, f.tableIdxInc), function()
        local value = rf2ethosmsp.getFieldValue(f)

        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then
            f.postEdit(Page)
        end
        f.value = rf2ethosmsp.saveFieldValue(f, value)
        rf2ethosmsp.saveValue(i)
    end)
end

function rf2ethosmsp.saveFieldValue(f, value)
    if value ~= nil then
        if f.decimals ~= nil then
            f.value = value / utils.decimalInc(f.decimals)
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

local function fieldNumber(f, i)
    if lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= lastSubPage then
            return
        end
    end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethosmsp.radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        local p = utils.getInlinePositions(f, Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if rf2ethosmsp.radio.text == 2 then
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

    minValue = utils.scaleValue(f.min, f)
    maxValue = utils.scaleValue(f.max, f)
    if f.mult ~= nil then
        minValue = minValue * f.mult
        maxValue = maxValue * f.mult
    end

    if HideMe == true then
        -- posField = {x = 2000, y = 0, w = 20, h = 20}
    end

    field = form.addNumberField(line, posField, minValue, maxValue, function()
        local value = rf2ethosmsp.getFieldValue(f)

        return value
    end, function(value)
        if f.postEdit then
            f.postEdit(Page)
        end

        f.value = rf2ethosmsp.saveFieldValue(f, value)
        rf2ethosmsp.saveValue(i)
    end)

    if f.default ~= nil then
        local default = f.default * utils.decimalInc(f.decimals)
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
    if rf2ethosmsp.radio.navButtonOffset ~= nil then
        colStart = colStart - rf2ethosmsp.radio.navButtonOffset
    end

    if rf2ethosmsp.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethosmsp.radio.menuButtonWidth
    end
    buttonH = rf2ethosmsp.radio.navbuttonHeight

    line = form.addLine(title)
    rf2ethosmsp.navigationButtons(w, rf2ethosmsp.radio.linePaddingTop, buttonW, buttonH)
end

function rf2ethosmsp.openPagePreferences(idx,title,script)
	uiState = uiStatus.pages
    mspDataLoaded = false

	
    lastIdx = idx
    lastSubPage = nil
    lastTitle = title
    lastScript = script
    isLoading = false
	Page = nil

    form.clear()

    local w = LCD_W
    local h = LCD_H
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethosmsp.radio.navButtonOffset ~= nil then
        colStart = colStart - rf2ethosmsp.radio.navButtonOffset
    end

    if rf2ethosmsp.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethosmsp.radio.buttonWidth
    end
    buttonH = rf2ethosmsp.radio.navbuttonHeight

    local x = w

    line = form.addLine("Preferences")

    field = form.addButton(line, {x = x - (buttonW + padding) * 1, y = rf2ethosmsp.radio.linePaddingTop, w = buttonW, h = buttonH}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            lastIdx = nil
            lastPage = nil
            lastSubPage = nil
            ESC_MODE = false		
            rf2ethosmsp.openMainMenu()
        end
    })
	field:focus()

    iconsizeParam = utils.loadPreference(TOOL_DIR .. "/preferences/iconsize")
    if iconsizeParam == nil or iconsizeParam == "" then
        iconsizeParam = 1
    end
    line = form.addLine("Button style")
    form.addChoiceField(line, nil, {{"Text", 0}, {"Small image", 1}, {"Large images", 2}}, function()
        return iconsizeParam
    end, function(newValue)
        iconsizeParam = newValue
        utils.storePreference(TOOL_DIR .. "/preferences/iconsize", iconsizeParam)
    end)

    -- PROFILE
    profileswitchParam = utils.loadPreference(TOOL_DIR .. "/preferences/profileswitch")
    if profileswitchParam ~= nil then
        local s = utils.explode(profileswitchParam, ",")
        profileswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = form.addLine("Switch profile")
    form.addSourceField(line, nil, function()
        return profileswitchParam
    end, function(newValue)
        profileswitchParam = newValue
        local member = profileswitchParam:member()
        local category = profileswitchParam:category()
        utils.storePreference(TOOL_DIR .. "/preferences/profileswitch", category .. "," .. member)
    end)

    rateswitchParam = utils.loadPreference(TOOL_DIR .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = form.addLine("Switch rates")
    form.addSourceField(line, nil, function()
        return rateswitchParam
    end, function(newValue)
        rateswitchParam = newValue
        local member = rateswitchParam:member()
        local category = rateswitchParam:category()
        utils.storePreference(TOOL_DIR .. "/preferences/rateswitch", category .. "," .. member)
    end)

end

function rf2ethosmsp.openPageDefaultLoader(idx, subpage, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(loadfile(TOOL_DIR .. "pages/" .. script))()
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

    print("Finished: rf2ethosmsp.openPageDefaultLoader")

    if environment.simulation == true then
        rf2ethosmsp.openPageDefault(idx, subpage, title, script)
    end

end

function rf2ethosmsp.openPageDefault(idx, subpage, title, script)



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


    if progressDialogDisplay == true then
        progressDialogWatchDog = nil
        progressDialogDisplay = false
        progressDialog:close()
    end

end

function rf2ethosmsp.openPageSERVOSLoader(idx, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(loadfile(TOOL_DIR .. "pages/" .. script))()
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
        rf2ethosmsp.openPageSERVOS(idx, title, script)
    end

    print("Finished: rf2ethosmsp.openPageSERVOS")
end

function rf2ethosmsp.openPageSERVOS(idx, title, script)



    reloadServos = false

    uiState = uiStatus.pages

    local numPerRow = 2

    local windowWidth = LCD_W
    local windowHeight = LCD_H
    local padding = rf2ethosmsp.radio.buttonPadding
    local h = rf2ethosmsp.radio.navbuttonHeight
    local w = ((windowWidth) / numPerRow) - (padding * numPerRow - 1)

    local y = rf2ethosmsp.radio.linePaddingTop

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
            field = form.addChoiceField(line, nil, utils.convertPageValueTable(servoTable), function()
                value = rf2ethosmsp.lastChangedServo
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
                    local value = rf2ethosmsp.getFieldValue(f)
                    return value
                end, function(value)
                    f.value = rf2ethosmsp.saveFieldValue(f, value)
                    rf2ethosmsp.saveValue(i)
                end)
                if f.default ~= nil then
                    local default = f.default * utils.decimalInc(f.decimals)
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


    if progressDialogDisplay == true then
        progressDialogWatchDog = nil
        progressDialogDisplay = false
        progressDialog:close()
    end

end

function rf2ethosmsp.openPagePIDLoader(idx, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(loadfile(TOOL_DIR .. "pages/" .. script))()
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
        rf2ethosmsp.openPagePID(idx, title, script)
    end

    print("Finished: rf2ethosmsp.openPagePID")
end

function rf2ethosmsp.openPagePID(idx, title, script)


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
    local paddingTop = rf2ethosmsp.radio.linePaddingTop
    local h = rf2ethosmsp.radio.navbuttonHeight
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
        _G["rf2ethosmsp_PIDROWS_" .. ri] = form.addLine(rv)
    end

    for i = 1, #Page.fields do
        local f = Page.fields[i]
        local l = Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        minValue = f.min * utils.decimalInc(f.decimals)
        maxValue = f.max * utils.decimalInc(f.decimals)
        if f.mult ~= nil then
            minValue = minValue * f.mult
            maxValue = maxValue * f.mult
        end

        field = form.addNumberField(_G["rf2ethosmsp_PIDROWS_" .. f.row], pos, minValue, maxValue, function()
            local value = rf2ethosmsp.getFieldValue(f)
            return value
        end, function(value)
            f.value = rf2ethosmsp.saveFieldValue(f, value)
            rf2ethosmsp.saveValue(i)
        end)
        if f.default ~= nil then
            local default = f.default * utils.decimalInc(f.decimals)
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

    if progressDialogDisplay == true then
        progressDialogWatchDog = nil
        progressDialogDisplay = false
        progressDialog:close()
    end


end

function rf2ethosmsp.openPageESC(idx, title, script)

	print("openPageESC")
	
	ESC_MENUSTATE = 1

    if tonumber(utils.makeNumber(environment.major .. environment.minor .. environment.revision)) < ETHOS_VERSION then
        return
    end

    mspDataLoaded = false
    uiState = uiStatus.mainMenu
    escPowerCycle = false

    form.clear()

    lastIdx = idx
    lastTitle = title
    lastScript = script

    ESC = {}

    ESC_MODE = true

    -- size of buttons
    iconsizeParam = utils.loadPreference(TOOL_DIR .. "/preferences/iconsize")
    if iconsizeParam == nil or iconsizeParam == "" then
        iconsizeParam = 1
    else
        iconsizeParam = tonumber(iconsizeParam)
    end

    local windowWidth = LCD_W
    local windowHeight = LCD_H
    local padding = rf2ethosmsp.radio.buttonPadding

    local sc
    local panel

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW

    field = form.addButton(line, {x = x, y = rf2ethosmsp.radio.linePaddingTop, w = buttonW, h = rf2ethosmsp.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            lastIdx = nil
            lastPage = nil
            lastSubPage = nil
            ESC_MODE = false
            rf2ethosmsp.openMainMenu()
        end
    })
	field:focus()

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    if iconsizeParam == 0 then
        padding = rf2ethosmsp.radio.buttonPaddingSmall
        buttonW = (LCD_W - padding) / rf2ethosmsp.radio.buttonsPerRow - padding
        buttonH = rf2ethosmsp.radio.navbuttonHeight
        numPerRow = rf2ethosmsp.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if iconsizeParam == 1 then

        padding = rf2ethosmsp.radio.buttonPaddingSmall
        buttonW = rf2ethosmsp.radio.buttonWidthSmall
        buttonH = rf2ethosmsp.radio.buttonHeightSmall
        numPerRow = rf2ethosmsp.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if iconsizeParam == 2 then

        padding = rf2ethosmsp.radio.buttonPadding
        buttonW = rf2ethosmsp.radio.buttonWidth
        buttonH = rf2ethosmsp.radio.buttonHeight
        numPerRow = rf2ethosmsp.radio.buttonsPerRow
    end

    local ESCMenu = assert(loadfile(TOOL_DIR .. "pages/" .. script))()

    local lc = 0
	local bx = 0

    for pidx, pvalue in ipairs(ESCMenu.pages) do

        if lc == 0 then
            if iconsizeParam == 0 then
                y = form.height() + rf2ethosmsp.radio.buttonPaddingSmall
            end
            if iconsizeParam == 1 then
                y = form.height() + rf2ethosmsp.radio.buttonPaddingSmall
            end
            if iconsizeParam == 2 then
                y = form.height() + rf2ethosmsp.radio.buttonPadding
            end
        end

        if lc >= 0 then
            bx = (buttonW + padding) * lc
        end

        if iconsizeParam ~= 0 then
            if esc_buttons[pidx] == nil then
                esc_buttons[pidx] = lcd.loadMask(TOOL_DIR .. "gfx/esc/" .. pvalue.image)
            end
        else
            esc_buttons[pidx] = nil
        end

        form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = esc_buttons[pidx],
            options = FONT_S,
            paint = function()

            end,
            press = function()
                rf2ethosmsp.openPageESCToolLoader(pvalue.folder)
            end
        })

        lc = lc + 1

        if lc == numPerRow then
            lc = 0
        end

    end

end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function rf2ethosmsp.openPageESCToolLoader(folder)

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

    ESC.init = assert(loadfile(TOOL_DIR .. "ESC/" .. folder .. "/init.lua"))()
    escPowerCycle = ESC.init.powerCycle

    Page = assert(loadfile(TOOL_DIR .. "ESC/" .. folder .. "/esc_info.lua"))()

    isLoading = true

    if environment.simulation == true then
        rf2ethosmsp.openPageESCTool(folder)
    end

end

-- initialise menu for specific type of esc
-- basically we load libraries then read 
-- /scripts/rf2ethosmsp/ESC/<TYPE>/pages.lua
function rf2ethosmsp.openPageESCTool(folder)



    print("rf2ethosmsp.openPageESCTool")
	
	ESC_MENUSTATE = 2



    --ESC.init = assert(loadfile(TOOL_DIR .. "ESC/" .. folder .. "/init.lua"))()
    --escPowerCycle = ESC.init.powerCycle

	if escPowerCycle == true then
		uiState = uiStatus.pages
		triggerESCLOADER = true
	else	
		uiState = uiStatus.MainMenu
	end

    local windowWidth = LCD_W
    local windowHeight = LCD_H

    local y = rf2ethosmsp.radio.linePaddingTop

    form.clear()

    line = form.addLine(lastTitle .. ' / ' .. ESC.init.toolName)

    buttonW = 100
    local x = windowWidth - buttonW

    field = form.addButton(line, {x = x, y = rf2ethosmsp.radio.linePaddingTop, w = buttonW, h = rf2ethosmsp.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            triggerESCMAINMENU = true
        end
    })
	field:focus()

    ESC.pages = assert(loadfile(TOOL_DIR .. "ESC/" .. folder .. "/pages.lua"))()

    if Page.escinfo then
        local model = Page.escinfo[1].t
        local version = Page.escinfo[2].t
        local fw = Page.escinfo[3].t

        if model == "" then
            model = "UNKNOWN ESC"
			ESC_UNKNOWN = true
		else
			ESC_UNKNOWN = false
        end

        if escPowerCycle == true and model == "UNKNOWN ESC" then

            if escPowerCycleAnimation == nil or escPowerCycleAnimation == "-" or escPowerCycleAnimation == "" then
                escPowerCycleAnimation = "+"
            else
                escPowerCycleAnimation = "-"
            end

            line = form.addLine("")
            form.addStaticText(line, {x = 0, y = rf2ethosmsp.radio.linePaddingTop, w = LCD_W, h = rf2ethosmsp.radio.buttonHeight}, "Please power cycle the speed controller " .. escPowerCycleAnimation)

        else
			triggerESCLOADER = false
            line = form.addLine("")
            form.addStaticText(line, {x = 0, y = rf2ethosmsp.radio.linePaddingTop, w = LCD_W, h = rf2ethosmsp.radio.buttonHeight}, model .. " " .. version .. " " .. fw)
			
        end
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- size of buttons
    iconsizeParam = utils.loadPreference(TOOL_DIR .. "/preferences/iconsize")
	
    if iconsizeParam == nil or iconsizeParam == "" then
        iconsizeParam = 1
    else
        iconsizeParam = tonumber(iconsizeParam)
    end

    -- TEXT ICONS
    if iconsizeParam == 0 then
        padding = rf2ethosmsp.radio.buttonPaddingSmall
        buttonW = (LCD_W - padding) / rf2ethosmsp.radio.buttonsPerRow - padding
        buttonH = rf2ethosmsp.radio.navbuttonHeight
        numPerRow = rf2ethosmsp.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if iconsizeParam == 1 then

        padding = rf2ethosmsp.radio.buttonPaddingSmall
        buttonW = rf2ethosmsp.radio.buttonWidthSmall
        buttonH = rf2ethosmsp.radio.buttonHeightSmall
        numPerRow = rf2ethosmsp.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if iconsizeParam == 2 then

        padding = rf2ethosmsp.radio.buttonPadding
        buttonW = rf2ethosmsp.radio.buttonWidth
        buttonH = rf2ethosmsp.radio.buttonHeight
        numPerRow = rf2ethosmsp.radio.buttonsPerRow
    end

    local lc = 0
	local bx = 0

    for pidx, pvalue in ipairs(ESC.pages) do

        if lc == 0 then
            if iconsizeParam == 0 then
                y = form.height() + rf2ethosmsp.radio.buttonPaddingSmall
            end
            if iconsizeParam == 1 then
                y = form.height() + rf2ethosmsp.radio.buttonPaddingSmall
            end
            if iconsizeParam == 2 then
                y = form.height() + rf2ethosmsp.radio.buttonPadding
            end
        end

        if lc >= 0 then
            bx = (buttonW + padding) * lc
        end

        if iconsizeParam ~= 0 then
            if esctool_buttons[pvalue.image] == nil then
                esctool_buttons[pvalue.image] = lcd.loadMask(TOOL_DIR .. "gfx/esc/" .. pvalue.image)
            end
        else
            esctool_buttons[pvalue.image] = nil
        end

		print("x = ".. bx..", y = ".. y..", w = ".. buttonW.. ", h = ".. buttonH)
        field = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = esctool_buttons[pvalue.image],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethosmsp.openESCFormLoader(folder, pvalue.script)
            end
        })
		
		if ESC_UNKNOWN == true and DEBUG_BADESC_ENABLE == false then
			field:enable(false)
		end		

        lc = lc + 1

        if lc == numPerRow then
            lc = 0
        end

    end

    if progressDialogDisplay == true and triggerESCLOADER ~= true then
        progressDialogWatchDog = nil
        progressDialogDisplay = false
        progressDialog:close()
    end


end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function rf2ethosmsp.openESCFormLoader(folder, script)

	print("rf2ethosmsp.openESCFormLoader")

    ESC_MFG = folder
    ESC_SCRIPT = script
    ESC_MODE = true

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(loadfile(TOOL_DIR .. "ESC/" .. folder .. "/pages/" .. script))()
    collectgarbage()

    progressDialogDisplay = true
    progressDialogWatchDog = os.clock()
    progressDialog = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    progressDialog:value(0)
    progressDialog:closeAllowed(false)

    isLoading = true

    if environment.simulation == true then
        rf2ethosmsp.openESCForm(folder, script)
    end

end

--
function rf2ethosmsp.openESCForm(folder, script)

	print("rf2ethosmsp.openESCForm")

	ESC_MENUSTATE = 3

    local fieldAR = {}
    uiState = uiStatus.pages
    longPage = false
    form.clear()

    local windowWidth = LCD_W
    local windowHeight = LCD_H
    local y = rf2ethosmsp.radio.linePaddingTop

    local w = LCD_W
    local h = LCD_H
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethosmsp.radio.navButtonOffset ~= nil then
        colStart = colStart - rf2ethosmsp.radio.navButtonOffset
    end

    if rf2ethosmsp.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethosmsp.radio.buttonWidth
    end
    buttonH = rf2ethosmsp.radio.navbuttonHeight
    line = form.addLine(lastTitle .. ' / ' .. ESC.init.toolName .. ' / ' .. Page.title)

    rf2ethosmsp.navigationButtonsEscForm(LCD_W, rf2ethosmsp.radio.linePaddingTop, buttonW, rf2ethosmsp.radio.navbuttonHeight)

    if Page.escinfo then
        local model = Page.escinfo[1].t
        local version = Page.escinfo[2].t
        local fw = Page.escinfo[3].t
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

    if progressDialogDisplay == true then
        progressDialogWatchDog = nil
        progressDialogDisplay = false
        progressDialog:close()
    end

end

function rf2ethosmsp.openPageRATESLoader(idx, subpage, title, script)

    uiState = uiStatus.pages
    mspDataLoaded = false

    Page = assert(loadfile(TOOL_DIR .. "pages/" .. script))()
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
        rf2ethosmsp.openPageRATES(idx, subpage, title, script)
    end

    print("Finished: rf2ethosmsp.openPageRATESLoader")
end

function rf2ethosmsp.openPageRATES(idx, subpage, title, script)



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
                rf2ethosmsp.openPageRATESLoader(idx, subpage, title, script)

            end
        end
    end

    rateswitchParam = utils.loadPreference(TOOL_DIR .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    uiState = uiStatus.pages

    longPage = false

    form.clear()

    fieldHeader(title)

    local numCols = #Page.cols
    local screenWidth = LCD_W - 10
    local padding = 10
    local paddingTop = rf2ethosmsp.radio.linePaddingTop
    local h = rf2ethosmsp.radio.navbuttonHeight
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
        _G["rf2ethosmsp_RATEROWS_" .. ri] = form.addLine(rv)
    end

    for i = 1, #Page.fields do
        local f = Page.fields[i]
        local l = Page.labels
        local pageIdx = i
        local currentField = i

        if f.subpage == 1 then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * utils.decimalInc(f.decimals)
            maxValue = f.max * utils.decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end

            field = form.addNumberField(_G["rf2ethosmsp_RATEROWS_" .. f.row], pos, minValue, maxValue, function()
                local value = rf2ethosmsp.getFieldValue(f)
                return value
            end, function(value)
                f.value = rf2ethosmsp.saveFieldValue(f, value)
                rf2ethosmsp.saveValue(i)
            end)
            if f.default ~= nil then
                local default = f.default * utils.decimalInc(f.decimals)
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

    if progressDialogDisplay == true then
        progressDialogWatchDog = nil
        progressDialogDisplay = false
        progressDialog:close()
    end

end

function rf2ethosmsp.openMainMenu()

    if tonumber(utils.makeNumber(environment.major .. environment.minor .. environment.revision)) < ETHOS_VERSION then
        return
    end

	-- clear all nav vars
    lastIdx = nil
    lastSubPage = nil
    lastTitle = nil
    lastScript = nil
    lastPage = nil
	
	

	-- reset page to nil as should be nil on this page
	Page = nil

    mspDataLoaded = false
    uiState = uiStatus.mainMenu
    escPowerCycle = false
	ESC_MENUSTATE = 0

    -- size of buttons
    iconsizeParam = utils.loadPreference(TOOL_DIR .. "/preferences/iconsize")
    if iconsizeParam == nil or iconsizeParam == "" then
        iconsizeParam = 1
    else
        iconsizeParam = tonumber(iconsizeParam)
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    if iconsizeParam == 0 then
        padding = rf2ethosmsp.radio.buttonPaddingSmall
        buttonW = (LCD_W - padding) / rf2ethosmsp.radio.buttonsPerRow - padding
        buttonH = rf2ethosmsp.radio.navbuttonHeight
        numPerRow = rf2ethosmsp.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if iconsizeParam == 1 then

        padding = rf2ethosmsp.radio.buttonPaddingSmall
        buttonW = rf2ethosmsp.radio.buttonWidthSmall
        buttonH = rf2ethosmsp.radio.buttonHeightSmall
        numPerRow = rf2ethosmsp.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if iconsizeParam == 2 then

        padding = rf2ethosmsp.radio.buttonPadding
        buttonW = rf2ethosmsp.radio.buttonWidth
        buttonH = rf2ethosmsp.radio.buttonHeight
        numPerRow = rf2ethosmsp.radio.buttonsPerRow
    end

    local sc
    local panel

    form.clear()

    for idx, value in ipairs(MainMenu.sections) do

        local sc = value.section

        form.addLine(value.title)

        lc = 0
        for pidx, pvalue in ipairs(MainMenu.pages) do
            if pvalue.section == value.section then

                if lc == 0 then
                    if iconsizeParam == 0 then
                        y = form.height() + rf2ethosmsp.radio.buttonPaddingSmall
                    end
                    if iconsizeParam == 1 then
                        y = form.height() + rf2ethosmsp.radio.buttonPaddingSmall
                    end
                    if iconsizeParam == 2 then
                        y = form.height() + rf2ethosmsp.radio.buttonPadding
                    end
                end

                if lc >= 0 then
                    x = (buttonW + padding) * lc
                end

                if iconsizeParam ~= 0 then
                    if gfx_buttons[pidx] == nil then
                        gfx_buttons[pidx] = lcd.loadMask(TOOL_DIR .. "gfx/menu/" .. pvalue.image)
                    end
                else
                    gfx_buttons[pidx] = nil
                end

                form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                    text = pvalue.title,
                    icon = gfx_buttons[pidx],
                    options = FONT_S,
                    paint = function()

                    end,
                    press = function()
                        if pvalue.script == "pids.lua" then
                            rf2ethosmsp.openPagePIDLoader(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "servos.lua" then
                            rf2ethosmsp.openPageSERVOSLoader(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "rates.lua" and pvalue.subpage == 1 then
                            rf2ethosmsp.openPageRATESLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                        elseif pvalue.script == "esc.lua" then
                            rf2ethosmsp.openPageESC(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "preferences.lua" then
                            rf2ethosmsp.openPagePreferences(pidx, pvalue.title, pvalue.script)
                        else
                            rf2ethosmsp.openPageDefaultLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                        end
                    end
                })

                lc = lc + 1

                if lc == numPerRow then
                    lc = 0
                end
            end
        end

    end
end

function rf2ethosmsp.profileSwitchCheck()
    profileswitchParam = utils.loadPreference(TOOL_DIR .. "/preferences/profileswitch")
    if profileswitchParam ~= nil then
        local s = utils.explode(profileswitchParam, ",")
        profileswitchParam = system.getSource({category = s[1], member = s[2]})
        profileswitchLast = profileswitchParam:value()
    end
end

function rf2ethosmsp.rateSwitchCheck()
    rateswitchParam = utils.loadPreference(TOOL_DIR .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
        rateswitchLast = rateswitchParam:value()
    end
end

local function create()

    rf2ethosmsp.sensor = sport.getSensor({primId=0x32})
    rf2ethosmsp.rssiSensor = system.getSource("RSSI")
    if not rf2ethosmsp.rssiSensor then
        rf2ethosmsp.rssiSensor = system.getSource("RSSI 2.4G")
        if not rf2ethosmsp.rssiSensor then
            rf2ethosmsp.rssiSensor = system.getSource("RSSI 900M")
            if not rf2ethosmsp.rssiSensor then
                rf2ethosmsp.rssiSensor = system.getSource("Rx RSSI1")
                if not rf2ethosmsp.rssiSensor then
                    rf2ethosmsp.rssiSensor = system.getSource("Rx RSSI2")
                end
            end
        end
    end

    LCD_W, LCD_H = utils.getWindowSize()

    rf2ethosmsp.protocol = assert(loadfile(TOOL_DIR .. "protocols.lua"))()
    rf2ethosmsp.radio = assert(loadfile(TOOL_DIR .. "radios.lua"))().msp
    rf2ethosmsp.mspQueue = assert(loadfile(TOOL_DIR .. "msp/mspQueue.lua"))()
    rf2ethosmsp.mspQueue.maxRetries = rf2ethosmsp.protocol.maxRetries
    rf2ethosmsp.mspHelper = assert(loadfile(TOOL_DIR .. "msp/mspHelper.lua"))()
    assert(loadfile(rf2ethosmsp.protocol.mspTransport))()
    assert(loadfile(TOOL_DIR .. "msp/common.lua"))()
	

    fieldHelpTxt = assert(loadfile(TOOL_DIR .. "help/fields.lua"))()


    -- Initial var setting
    saveTimeout = rf2ethosmsp.protocol.saveTimeout
    saveMaxRetries = rf2ethosmsp.protocol.saveMaxRetries
    requestTimeout = rf2ethosmsp.protocol.pageReqTimeout
    uiState = uiStatus.init
    init = nil
    apiVersion = 0

    MainMenu = assert(loadfile(TOOL_DIR .. "pages.lua"))()

    rf2ethosmsp.openMainMenu()

end

function rf2ethosmsp.resetState()

		ESC_MODE = false
		escPowerCycle = false
		ESC_MFG = nil
		resetRates = false
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

end

local function close()
	rf2ethosmsp.resetState()
    system.exit()
    return true
end

local icon = lcd.loadMask(TOOL_DIR .. "RF.png")

local function init()
    system.registerSystemTool({event = event, name = name, icon = icon, create = create, wakeup = wakeup, close = close})
end

return {init = init}
