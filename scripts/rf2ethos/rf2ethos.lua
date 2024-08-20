rf2ethos = {}

local arg = {...}

local config = arg[1]
local compile = arg[2]

local triggers = {}
triggers.exitAPP = false
triggers.noRFMsg = false
triggers.triggerSave = false
triggers.triggerReload = false
triggers.triggerReloadNoPrompt = false
triggers.triggerEscReload = false
triggers.triggerEscMainMenu = false
triggers.triggerEscLoader = false
triggers.triggerMainMenu = false
triggers.escPowerCycle = false
triggers.isReady = false
triggers.isSaving = false
triggers.isSavingFake = false
triggers.saveFailed = false
triggers.telemetryState = nil
triggers.profileswitchLast = nil
triggers.rateswitchLast = nil
triggers.closeSave = false
triggers.closeSaveFake = false
triggers.badMspVersion = false
triggers.badMspVersionDisplay = false
triggers.closeProgressLoader = false

rf2ethos = {}
rf2ethos.compile = compile


rf2ethos.config = {}
rf2ethos.config = config

rf2ethos.triggers = {}
rf2ethos.triggers = triggers

rf2ethos.utils = {}
rf2ethos.utils = assert(compile.loadScript(config.toolDir .. "lib/utils.lua"))()

rf2ethos.ui = {}
rf2ethos.ui = assert(compile.loadScript(config.toolDir .. "lib/ui.lua"))()

rf2ethos.formFields = {}
rf2ethos.formNavigationFields = {}
rf2ethos.PageTmp = {}
rf2ethos.Page = {}
rf2ethos.saveTS = 0
rf2ethos.lastPage = nil
rf2ethos.lastSection = nil
rf2ethos.lastIdx = nil
rf2ethos.lastTitle = nil
rf2ethos.lastScript = nil
rf2ethos.gfx_buttons = {}
rf2ethos.esc_buttons = {}
rf2ethos.esctool_buttons = {}
rf2ethos.escMode = false
rf2ethos.escMenuState = 0
rf2ethos.escManufacturer = nil
rf2ethos.escScript = nil
rf2ethos.escUnknown = false
rf2ethos.uiStatus = {init = 1, mainMenu = 2, pages = 3, confirm = 4}
rf2ethos.pageStatus = {display = 1, editing = 2, saving = 3, eepromWrite = 4, rebooting = 5}
rf2ethos.telemetryStatus = {ok = 1, noSensor = 2, noTelemetry = 3}
rf2ethos.uiState = rf2ethos.uiStatus.init
rf2ethos.pageState = rf2ethos.pageStatus.display
rf2ethos.lastLabel = nil
rf2ethos.NewRateTable = nil
rf2ethos.RateTable = nil
rf2ethos.fieldHelpTxt = nil
rf2ethos.protocol = {}
rf2ethos.radio = {}
rf2ethos.sensor = {}
rf2ethos.init = nil
rf2ethos.wakeupSchedulerUI = os.clock()
rf2ethos.wakeupSchedulerForm = os.clock()

rf2ethos.audio = {}
rf2ethos.audio.playDemo = false
rf2ethos.audio.playConnecting = false
rf2ethos.audio.playTimeout = false
rf2ethos.audio.playSaving = false
rf2ethos.audio.playLoading = false
rf2ethos.audio.playEscPowerCycle = false

rf2ethos.dialogs = {}
rf2ethos.dialogs.progress = false
rf2ethos.dialogs.progressDisplay = false
rf2ethos.dialogs.progressWatchDog = nil
rf2ethos.dialogs.progressCounter = 0

rf2ethos.dialogs.progressESC = false
rf2ethos.dialogs.progressDisplayEsc = false
rf2ethos.dialogs.progressWatchDogESC = nil
rf2ethos.dialogs.progressCounterESC = 0
rf2ethos.progressWatchDogESCRateLimit = os.clock()

rf2ethos.dialogs.save = false
rf2ethos.dialogs.saveDisplay = false
rf2ethos.dialogs.saveWatchDog = nil
rf2ethos.dialogs.saveProgressCounter = 0

rf2ethos.dialogs.nolink = false
rf2ethos.dialogs.nolinkDisplay = false
rf2ethos.dialogs.nolinkValue = 0

rf2ethos.dialogs.badversion = false
rf2ethos.dialogs.badversionDisplay = false

rf2ethos.config.saveTimeout = nil
rf2ethos.config.requestTimeout = nil
rf2ethos.config.maxRetries = nil
rf2ethos.config.lcdWidth = nil
rf2ethos.config.lcdHeight = nil
rf2ethos.config.iconsizeParam = nil

-- make the tx run with no fbl connected
if config.simulateOnTransmitter == true or system:getVersion().simulation == true then
	rf2ethos.runningInSimulator = true
else
	rf2ethos.runningInSimulator = system:getVersion().simulation
end

-- RETURN THE CURRENT RSSI SENSOR VALUE 
function rf2ethos.getRSSI()
    if rf2ethos.runningInSimulator == true then return 100 end

    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
        return rf2ethos.rssiSensor:value()
    end
    return 0
end

-- RESET ALL VALUES TO DEFAULTS. FUNCTION IS CALLED WHEN THE CLOSE EVENT RUNS
function rf2ethos.resetState()

    rf2ethos.escMode = false
    rf2ethos.triggers.escPowerCycle = false
    rf2ethos.escManufacturer = nil
    rf2ethos.escScript = nil
	config.useCompiler = true
	rf2ethos.config.useCompiler = true
    pageLoaded = 100
    pageTitle = nil
    pageFile = nil
    rf2ethos.triggers.exitAPP = false
    rf2ethos.triggers.noRFMsg = false
    rf2ethos.dialogs.nolinkDisplay = false
    rf2ethos.dialogs.nolinkValue = 0
    rf2ethos.triggers.telemetryState = nil
	rf2ethos.triggers.badMspVersionDisplay = false
	rf2ethos.triggers.badMspVersion = false
	rf2ethos.dialogs.progressDisplayEsc = false	
	ELRS_PAUSE_TELEMETRY = false

end


-- CHECK IF THE PROFILE SWITCH HAS CHANGED STATE
function rf2ethos.profileSwitchCheck()

	-- load and cache the switch on first run
	if rf2ethos.config.profileswitchParamPreference == nil then
		rf2ethos.config.profileswitchParamPreference = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/profileswitch")
		local s = rf2ethos.utils.explode(rf2ethos.config.profileswitchParamPreference, ",")
		rf2ethos.config.profileswitchParam = system.getSource({category = s[1], member = s[2]})
	end	
	-- store the last state
    if rf2ethos.config.profileswitchParam ~= nil then
        rf2ethos.triggers.profileswitchLast = rf2ethos.config.profileswitchParam:value()
    end
end

-- CHECK IF THE RATE SWITCH HAS CHANGED STATE
function rf2ethos.rateSwitchCheck()

	-- load and cache the switch on first run
	if rf2ethos.config.rateswitchParamPreference == nil then
		rf2ethos.config.rateswitchParamPreference = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/rateswitch")
        local s = rf2ethos.utils.explode(rf2ethos.config.rateswitchParamPreference, ",")
        rf2ethos.config.rateswitchParam = system.getSource({category = s[1], member = s[2]})		
	end
	
	-- store the last state	
    if rf2ethos.config.rateswitchParam ~= nil then
        rf2ethos.triggers.rateswitchLast = rf2ethos.config.rateswitchParam:value()
    end
end

-- GET FIELD VALUE FOR ETHOS FORMS.  FUNCTION TAKES THE VALUE AND APPLIES RULES BASED
-- ON THE PARAMETERS ON THE rf2ethos.pages TABLE
function rf2ethos.getFieldValue(f)

    local v

    if f.value == nil then f.value = 0 end
    if f.t == nil then f.t = "N/A" end
	
    if f.value ~= nil then
        if f.decimals ~= nil then
            v = rf2ethos.utils.round(f.value * rf2ethos.utils.decimalInc(f.decimals))
        else
            v = f.value
        end
    else
        v = 0
    end

    if f.mult ~= nil then v = math.floor(v * f.mult + 0.5) end

    return v
end

-- SAVE FIELD VALUE FOR ETHOS FORMS.  FUNCTION TAKES THE VALUE AND APPLIES RULES BASED
-- ON THE PARAMETERS ON THE rf2ethos.pages TABLE
function rf2ethos.saveFieldValue(f, value)
    if value ~= nil then
        if f.decimals ~= nil then
            f.value = value / rf2ethos.utils.decimalInc(f.decimals)
        else
            f.value = value
        end
        if f.postEdit then f.postEdit(rf2ethos.Page) end
    end

    if f.mult ~= nil then f.value = f.value / f.mult end

    return f.value
end

-- SAVE FIELD VALUE FOR ETHOS FROM ETHOS FORMS INTO THE ACTUAL FORMAT THAT 
-- WILL BE TRANSMITTED OVER MSP
function rf2ethos.saveValue(currentField)

    local f = rf2ethos.Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do rf2ethos.Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8) end
    if f.upd and rf2ethos.Page.values then f.upd(rf2ethos.Page) end
end

-- ITERATE OVER THE FIELD DATA AND UPDATE ALL VALUES FOR DISPLAY PURPOSES
function rf2ethos.dataBindFields()
	if rf2ethos.Page.fields then
		for i = 1, #rf2ethos.Page.fields do

			if rf2ethos.Page.values and #rf2ethos.Page.values >= rf2ethos.Page.minBytes then
				local f = rf2ethos.Page.fields[i]
				if f.vals then
					f.value = 0
					for idx = 1, #f.vals do
						local raw_val = rf2ethos.Page.values[f.vals[idx]] or 0
						raw_val = raw_val << ((idx - 1) * 8)
						f.value = f.value | raw_val
					end
					local bits = #f.vals * 8
					if f.min and f.min < 0 and (f.value & (1 << (bits - 1)) ~= 0) then f.value = f.value - (2 ^ bits) end
					f.value = f.value / (f.scale or 1)
				end
			end
		end
	else
		rf2ethos.utils.log("Unable to bind fields as rf2ethos.Page.fields does not exist")
	end	
end

-- GRAB THE SPORT TELEMETRY FRAME
function rf2ethos.sportTelemetryPop()
    -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
    local frame = rf2ethos.sensor:popFrame()
    if frame == nil then return nil, nil, nil, nil end
    -- physId = physical / remote sensor Id (aka sensorId)
    --   0x00 for FPORT, 0x1B for SmartPort
    -- primId = frame ID  (should be 0x32 for reply frames)
    -- appId = data Id
    return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

-- PUSH THE TELEMETRY FRAME
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
    return rf2ethos.sensor:pushFrame({physId = sensorId, primId = frameId, appId = dataId, value = value})
end

-- RETURN CURRENT LCD SIZE
function rf2ethos.getWindowSize()
    return lcd.getWindowSize()
end

-- INAVALIDATE THE PAGES VARIABLE. TYPICALLY CALLED AFTER WRITING MSP DATA
local function invalidatePages()
    rf2ethos.Page = nil
    rf2ethos.pageState = rf2ethos.pageStatus.display
    rf2ethos.saveTS = 0
    collectgarbage()
end

-- ISSUE AN MSP COMNMAND TO REBOOT THE FBL UNIT
local function rebootFc()

    rf2ethos.pageState = rf2ethos.pageStatus.rebooting
    rf2ethos.mspQueue:add({
        command = 68, -- MSP_REBOOT
        processReply = function(self, buf)
            invalidatePages()
        end,
        simulatorResponse = {}
    })
end

-- ISSUE AN MSP COMMAND TO TELL THE FBL TO WRITE THE DATA TO EPPROM
local mspEepromWrite = {
    command = 250, -- MSP_EEPROM_WRITE, fails when armed
    processReply = function(self, buf)
        if rf2ethos.Page.reboot then
            rebootFc()
        else
            invalidatePages()
        end
		rf2ethos.triggers.closeSave = true
    end,
    simulatorResponse = {}
}


-- SAVE ALL SETTINGS 
function rf2ethos.settingsSaved()

    -- check if this page requires writing to eeprom to save (most do)
    if rf2ethos.Page and rf2ethos.Page.eepromWrite then
        -- don't write again if we're already responding to earlier page.write()s
        if rf2ethos.pageState ~= rf2ethos.pageStatus.eepromWrite then
            rf2ethos.pageState = rf2ethos.pageStatus.eepromWrite
            rf2ethos.mspQueue:add(mspEepromWrite)
        end
    elseif rf2ethos.pageState ~= rf2ethos.pageStatus.eepromWrite then
        -- If we're not already trying to write to eeprom from a previous save, then we're done.
        invalidatePages()
		rf2ethos.triggers.closeSave = true

    end
end

-- WRAPPER FUNCTION USED TO TRIGGER SAVE SETTINGS
local mspSaveSettings = {
    processReply = function(self, buf)
        rf2ethos.settingsSaved()
    end
}

-- WRAPPER FUNCTION USED TO TRIGGER LOAD SETTINGS
local mspLoadSettings = {
    processReply = function(self, buf)
		
		if rf2ethos.Page.minBytes == nil then
			rf2ethos.Page.minBytes = 0
		end
        rf2ethos.utils.log("rf2ethos.Page is processing reply for cmd " .. tostring(self.command) .. " len buf: " .. #buf .. " expected: " .. rf2ethos.Page.minBytes)
		if rf2ethos.Page ~= nil then
			rf2ethos.Page.values = buf
			if rf2ethos.Page.postRead then rf2ethos.Page.postRead(rf2ethos.Page) end
			rf2ethos.dataBindFields()
			if rf2ethos.Page.postLoad then 
				rf2ethos.Page.postLoad(rf2ethos.Page) 
			end					
			rf2ethos.utils.log("rf2ethos.triggers.isReady")
		else
			rf2ethos.utils.log("rf2ethos.triggers.isReady rf2ethos.Page is nil?")
		end

    end
}

-- READ AN MSP PAGE
function rf2ethos.readPage()
    if type(rf2ethos.Page.read) == "function" then
        rf2ethos.Page.read(rf2ethos.Page)
    else
        mspLoadSettings.command = rf2ethos.Page.read
        mspLoadSettings.simulatorResponse = rf2ethos.Page.simulatorResponse
        rf2ethos.mspQueue:add(mspLoadSettings)
    end
end


-- SAVE ALL SETTINGS 
local function saveSettings()

    if rf2ethos.pageState ~= rf2ethos.pageStatus.saving then
        rf2ethos.pageState = rf2ethos.pageStatus.saving
        rf2ethos.saveTS = os.clock()

        if rf2ethos.Page.values then
            local payload = rf2ethos.Page.values

            if rf2ethos.Page.preSave then 
				payload = rf2ethos.Page.preSave(rf2ethos.Page) 
			end
            if rf2ethos.Page.preSavePayload then 
				payload = rf2ethos.Page.preSavePayload(payload) 
			end
			
			
			if rf2ethos.config.mspTxRxDebug == true or rf2ethos.config.logEnable == true then

				local logData = "Saving:        {" .. rf2ethos.utils.joinTableItems(payload, ", ") .. "}"

				rf2ethos.utils.log(logData)
				
				if rf2ethos.config.mspTxRxDebug == true then
						print(logData)
				end
				
			end	
			
			
            mspSaveSettings.command = rf2ethos.Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            rf2ethos.mspQueue:add(mspSaveSettings)
            rf2ethos.mspQueue.errorHandler = function()	
                print("Save failed")
                rf2ethos.triggers.saveFailed = true
            end
        elseif type(rf2ethos.Page.write) == "function" then
            rf2ethos.Page.write(rf2ethos.Page)
        end

    end
end

-- REQUEST A PAGE OVER MSP. THIS RUNS ON MOST CLOCK CYCLES WHEN DATA IS BEING REQUESTED
local function requestPage()
    if not rf2ethos.Page.reqTS or rf2ethos.Page.reqTS + rf2ethos.protocol.pageReqTimeout <= os.clock() then
        rf2ethos.Page.reqTS = os.clock()
        if rf2ethos.Page.read then rf2ethos.readPage() end
    end
end

-- UPDATE CURRENT TELEMETRY STATE - RUNS MOST CLOCK CYCLES
function rf2ethos.updateTelemetryState()


	if rf2ethos.runningInSimulator ~= true then
		if not rf2ethos.rssiSensor then
			rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.noSensor
		elseif rf2ethos.getRSSI() == 0 then
			rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.noTelemetry
		else
			rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.ok
		end
	else
		rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.ok
	end

end

-- PAINT.  HOOK INTO PAINT FUNCTION TO ALLOW lcd FUNCTIONS TO BE USED
-- NOTE. this function will only be called if lcd.refesh is triggered. it is not a wakeup function
function rf2ethos.paint()

	-- run the modules paint function if it exists
	if rf2ethos.Page ~= nil then
		if rf2ethos.Page.paint then
			rf2ethos.Page.paint(rf2ethos.Page)
		end
	end
end


-- MAIN WAKEUP FUNCTION. THIS SIMPLY FARMS OUT AT DIFFERING SCHEDULES TO SUB FUNCTIONS
function rf2ethos.wakeup(widget)

    -- every 0.01 to ensure msp timings work
    rf2ethos.mspQueue:processQueue()

	--keep cpu load down by running UI at reduced interval
	local now = os.clock()
	if (now - rf2ethos.wakeupSchedulerUI) >= 0.1 then	
		rf2ethos.wakeupSchedulerUI = now
		rf2ethos.wakeupUI()
	end	

	--keep cpu load down by running Form at reduced interval
	local now = os.clock()
	if (now - rf2ethos.wakeupSchedulerForm) >= 0.2 then	
		rf2ethos.wakeupSchedulerForm = now
		rf2ethos.wakeupForm()
	end	


end

-- WAKEUPFORM.  RUN A FUNCTION CALLED wakeup THAT IS RETURNED WHEN REQUESTING A PAGE
-- THIS ESSENTIALLY GIVES US A TIMER THAT CAN BE USED BY A PAGE THAT HAS LOADED TO
-- HANDLE BACKGROUND PROCESSING
function rf2ethos.wakeupForm()
    if rf2ethos.Page ~= nil and rf2ethos.uiState == rf2ethos.uiStatus.pages then
		if rf2ethos.Page.wakeup then
			-- run the pages wakeup function if it exists
			rf2ethos.Page.wakeup(rf2ethos.Page)
		end
	end
end

-- WAKUP UI.  UI RUNS AT LOWER INTERVAL, TO SAVE CPU POWER.
-- THE GUTS OF ETHOS FORMS IS HANDLED WITHIN THIS FUNCTION
function rf2ethos.wakeupUI()

    -- exit app called : quick abort
    -- as we dont need to run the rest of the stuff
    if rf2ethos.triggers.exitAPP == true then
        rf2ethos.triggers.exitAPP = false
        form.invalidate()
        system.exit()
        return
    end

	-- close progress loader.  this essentially just accelerates 
	-- the close of the progress bar once the data is loaded.
	-- so if not yet at 100%.. it says.. move there quickly
	if rf2ethos.triggers.closeProgressLoader == true then
		if rf2ethos.dialogs.progressCounter <= 100 then
			rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 20
			if rf2ethos.dialogs.progress ~= nil then
				rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)
			end
		end
	
		if rf2ethos.dialogs.progressCounter >= 120 then
			rf2ethos.dialogs.progressWatchDog = nil
			rf2ethos.dialogs.progressDisplay = false
			if rf2ethos.dialogs.progress ~= nil then
				rf2ethos.dialogs.progress:close()	
			end
			rf2ethos.dialogs.progressCounter = 0
			rf2ethos.triggers.closeProgressLoader = false
		end
	end

	-- close esc progress loader.  this essentially just instant closes the
	-- esc loader when dealing with esc that require a power cycle to connect.
	if rf2ethos.triggers.closeProgressLoaderESC == true then
			rf2ethos.dialogs.progressESC:close()
	end	

	-- make the ui go to the main page of the esc in the event that theMsg
	-- trigger is received.
    if rf2ethos.triggers.triggerEscMainMenu == true then
        rf2ethos.triggers.triggerEscMainMenu = false
        rf2ethos.escMode = false
        rf2ethos.triggers.escPowerCycle = false
        rf2ethos.escNotReadyCount = 0
        rf2ethos.escUnknown = false
        rf2ethos.lastIdx = nil
        rf2ethos.lastPage = nil
        invalidatePages()

        rf2ethos.ui.openPageEsc(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)

    end

	-- close save loader.  this essentially just accelerates 
	-- the close of the progress bar once the data is loaded.
	-- so if not yet at 100%.. it says.. move there quickly
    if rf2ethos.triggers.closeSave == true then
		rf2ethos.triggers.isSaving = false

		if rf2ethos.mspQueue:isProcessed() then
			if (rf2ethos.dialogs.saveProgressCounter > 40 and rf2ethos.dialogs.saveProgressCounter <= 80) then 
				rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 10
			else
				rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 5 		
			end
		end	
		
		if rf2ethos.dialogs.save ~= nil then
			rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
		end

        if rf2ethos.dialogs.saveProgressCounter >= 100 and rf2ethos.mspQueue:isProcessed() then
            rf2ethos.triggers.closeSave = false
            rf2ethos.dialogs.saveProgressCounter = 0
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
			if rf2ethos.dialogs.save ~= nil then
				rf2ethos.dialogs.save:close()		

				if rf2ethos.config.reloadOnSave == true then
					rf2ethos.triggers.triggerReloadNoPrompt = true
				end	
				
			end			
        end
    end

	-- close progress loader when in sim.  
	-- the simulator cannot save - so we fake the whole process
    if rf2ethos.triggers.closeSaveFake == true then
		rf2ethos.triggers.isSaving = false

		rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 10		

		if rf2ethos.dialogs.save ~= nil then
			rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
		end

        if rf2ethos.dialogs.saveProgressCounter >= 100 then
            rf2ethos.triggers.closeSaveFake = false
            rf2ethos.dialogs.saveProgressCounter = 0
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
			rf2ethos.dialogs.save:close()						
        end
    end

	
    -- profile switching - trigger a reload if needs be when the switch is toggled
	
    if rf2ethos.Page ~= nil and rf2ethos.Page.refreshswitch == true and rf2ethos.uiState == rf2ethos.uiStatus.pages then
	
		-- capture profile switching and of rates pages
		if rf2ethos.lastPage == "rates.lua" or rf2ethos.lastPage == "rates_advanced.lua" then
			if rf2ethos.config.rateswitchParam ~= nil then
				if rf2ethos.config.rateswitchParam:value() ~= rf2ethos.triggers.rateswitchLast then

					if rf2ethos.ui.progressDisplay() then
						-- switch has been toggled mid flow - this is bad.. clean upd
						form.clear()
						rf2ethos.triggers.triggerReloadNoPrompt = true

					else
						-- trigger RELOAD
						rf2ethos.triggers.rateswitchLast = rf2ethos.config.rateswitchParam:value()							
						rf2ethos.triggers.triggerReloadNoPrompt = true
						return true
					end

				end
			end
		-- capture switching of all profile pages - excluding rates	
		else
			if rf2ethos.config.profileswitchParam ~= nil then

				if rf2ethos.config.profileswitchParam:value() ~= rf2ethos.triggers.profileswitchLast then

					
					if rf2ethos.ui.progressDisplay() then
						-- switch has been toggled mid flow - this is bad.. clean upd
						form.clear()
						rf2ethos.triggers.triggerReloadNoPrompt = true
					else				
						-- trigger RELOAD
						rf2ethos.triggers.profileswitchLast = rf2ethos.config.profileswitchParam:value()
						rf2ethos.triggers.triggerReloadNoPrompt = true
						return true

					end
					
				end
			end
		end			
    end

    -- if we do not have a telemetry link then we need to show a connecting dialog box.
	-- this runs at all times except when we are displaying the esc search box.  we then
	-- supress this one and display a different one as timeouts and process is different
	if rf2ethos.triggers.telemetryState ~= 1 and rf2ethos.dialogs.progressDisplayEsc ~= true then
	
		if rf2ethos.dialogs.progress then
			rf2ethos.dialogs.progress:close()
		end
		if rf2ethos.dialogs.save then
			rf2ethos.dialogs.save:close()
		end
	
		if rf2ethos.dialogs.nolinkDisplay == false then
			rf2ethos.dialogs.nolinkDisplay = true
			noLinkDialog = form.openProgressDialog("Connecting", "Connecting")
			noLinkDialog:closeAllowed(false)
			noLinkDialog:value(0)
			rf2ethos.dialogs.nolinkValue = 0

			rf2ethos.audio.playConnecting = true

		
			
			-- check msp version of fbl
			rf2ethos.init = rf2ethos.init or assert(compile.loadScript(rf2ethos.config.toolDir .."ui_init.lua"))()
			rf2ethos.init.f()
		end
	end

	-- this is directly related to the loop above.  if the progress box is visible we then wait for a telemetry link
	-- to be established - and associated msp version checks to finish. all the while incremeting the loader
	-- until we time out.
	if (rf2ethos.dialogs.nolinkDisplay == true or rf2ethos.triggers.telemetryState == 1) and rf2ethos.dialogs.progressDisplayEsc ~= true then

		if rf2ethos.triggers.telemetryState == 1 then
			if rf2ethos.config.apiVersion ~= nil then
				rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 15
			else
				rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 5
			end
		else
			rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 1
		end

		
		if rf2ethos.dialogs.nolinkValue >= 100 and rf2ethos.mspQueue:isProcessed() then
		
			if rf2ethos.init.f() == false and rf2ethos.getRSSI() ~= 0  then
				noLinkDialog:close()
				rf2ethos.dialogs.nolinkValue = 0
				rf2ethos.dialogs.nolinkDisplay = false
				rf2ethos.triggers.badMspVersion = true
			else 
				noLinkDialog:close()
				rf2ethos.dialogs.nolinkValue = 0
				rf2ethos.dialogs.nolinkDisplay = false
				rf2ethos.triggers.badMspVersion = false
				if rf2ethos.runningInSimulator ~= true then				
					if rf2ethos.triggers.telemetryState ~= 1 then 
							rf2ethos.audio.playTimeout = true
							rf2ethos.triggers.exitAPP = true 
					end
				end	
			end
		end
		noLinkDialog:value(rf2ethos.dialogs.nolinkValue)
	end

    -- a watchdog to enable the close button when saving data if we exheed the save timout
    if rf2ethos.config.watchdogParam ~= nil and rf2ethos.config.watchdogParam ~= 1 then rf2ethos.protocol.saveTimeout = rf2ethos.config.watchdogParam end
    if rf2ethos.dialogs.saveDisplay == true then
        if rf2ethos.dialogs.saveWatchDog ~= nil then
            if (os.clock() - rf2ethos.dialogs.saveWatchDog) > (tonumber(rf2ethos.protocol.saveTimeout)) then rf2ethos.dialogs.save:closeAllowed(true) end
        end
    end

	-- a watchdog to enable the close button on a progress box dialog when loading data from the fbl
    if rf2ethos.dialogs.progressDisplay == true and rf2ethos.dialogs.progressWatchDog ~= nil then
	
		if rf2ethos.config.watchdogParam ~= nil and rf2ethos.config.watchdogParam ~= 1 then 
			rf2ethos.protocol.pageReqTimeout = rf2ethos.config.watchdogParam 
		end
		
		if rf2ethos.dialogs.progressCounter <= 40 then
			rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 10
			rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)	
		else
			rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 5
			rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)	
		end

		if rf2ethos.triggers.escPowerCycle == true then
			if (os.clock() - rf2ethos.dialogs.progressWatchDog) > (tonumber(rf2ethos.protocol.pageReqTimeout) + 30) then
				if rf2ethos.dialogs.progress ~= nil then
					rf2ethos.dialogs.progress:message("Error.. we timed out")
					rf2ethos.dialogs.progress:closeAllowed(true)
				end
								
				--switch back to original page values
				rf2ethos.Page = rf2ethos.PageTmp
				rf2ethos.PageTmp = {}
				rf2ethos.dialogs.progressCounter = 0 
				rf2ethos.dialogs.progressDisplay = false
			end
		else
			if (os.clock() - rf2ethos.dialogs.progressWatchDog) > (tonumber(rf2ethos.protocol.pageReqTimeout)) then

				rf2ethos.audio.playTimeout = true
				
				if rf2ethos.dialogs.progress ~= nil then
					rf2ethos.dialogs.progress:message("Error.. we timed out")
					rf2ethos.dialogs.progress:closeAllowed(true)
				end
		
				--switch back to original page values
				rf2ethos.Page = rf2ethos.PageTmp
				rf2ethos.PageTmp = {}		
				rf2ethos.dialogs.progressCounter = 0 
				rf2ethos.dialogs.progressDisplay = false
			end
		end
    end
	
	-- a progress loader that is used when searching for a speed controller
	-- this functionality is triggered only when an esc requires a power cycle to initialise
	if rf2ethos.triggers.escPowerCycle == true and rf2ethos.escUnknown == true then

			if rf2ethos.dialogs.progressDisplayEsc ~= true then

				rf2ethos.dialogs.progressDisplayEsc = true
				rf2ethos.dialogs.progressWatchDogESC = os.clock()
				rf2ethos.dialogs.progressESC = form.openProgressDialog("Searching...", "Please power cycle the esc")
				
				rf2ethos.audio.playEscPowerCycle = true				
				
				if rf2ethos.dialogs.progressESC ~= nil then
					rf2ethos.dialogs.progressESC:value(0)
					rf2ethos.dialogs.progressESC:closeAllowed(false)
				end
			else
		
				if rf2ethos.mspQueue:isProcessed() then 
					requestPage() 
				end
	
				-- we rate limit the progress to keep things low cpu	
				if (os.clock() - rf2ethos.progressWatchDogESCRateLimit) >= 1.5 then

					rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/"..rf2ethos.escManufacturer.."/esc_info.lua"))()
					collectgarbage()				
				
					rf2ethos.dialogs.progressCounterESC = rf2ethos.dialogs.progressCounterESC + 2				
					rf2ethos.progressWatchDogESCRateLimit = os.clock()					
					rf2ethos.dialogs.progressESC:value(rf2ethos.dialogs.progressCounterESC)
				end

				if rf2ethos.Page.escinfo then
					local model = rf2ethos.Page.escinfo[1].t	
					if model ~= "" then
						rf2ethos.triggers.closeProgressLoaderESC = true
					end
				end


				if rf2ethos.dialogs.progressCounterESC >= 100 then
					rf2ethos.dialogs.progressCounterESC = 0
					if rf2ethos.dialogs.progressESC ~= nil then
					
						rf2ethos.audio.playTimeout = true

						if rf2ethos.PageTmp ~= nil then
							rf2ethos.Page = rf2ethos.PageTmp
						end	
											
						rf2ethos.dialogs.progressESC:close()
						rf2ethos.dialogs.progressDisplayEsc = false			
						rf2ethos.triggers.escPowerCycle	= false					
					end	
					rf2ethos.triggers.triggerEscLoader = false

				end

			end

	end

    -- a save was triggered - popup a box asking to save the data
    if rf2ethos.triggers.triggerSave == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()

					rf2ethos.audio.playSaving = true
		
					-- we have to fake a save dialog in sim as its not actually possible 
					-- to save in sim!
					if rf2ethos.runningInSimulator ~= true then
						rf2ethos.PageTmp = {}
						rf2ethos.PageTmp = rf2ethos.Page
						rf2ethos.triggers.isSaving = true
						rf2ethos.triggers.triggerSave = false							
						saveSettings()
					else
						 -- when in sim we fake a save as not possible to really do
						 -- this involves tricking the progress dialog into thinking
						 rf2ethos.triggers.isSavingFake = true
						 rf2ethos.triggers.triggerSave = false
					end
					return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    rf2ethos.triggers.triggerSave = false
                    return true
                end
            }
        }
        local theTitle
        local theMsg
        if rf2ethos.escMode == true then
            theTitle = "Save settings"
            theMsg = "Save current page to the speed controller"
        else
            theTitle = "Save settings"
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

		rf2ethos.triggers.triggerSave = false
    end

	-- a reload that is pretty much instant with no prompt to ask them
	if rf2ethos.triggers.triggerReloadNoPrompt == true then
		rf2ethos.triggers.triggerReloadNoPrompt = false
		rf2ethos.triggers.reload = true
	end

	-- a reload was triggered - popup a box asking for the reload to be done
    if rf2ethos.triggers.triggerReload == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
					rf2ethos.triggers.reload = true
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
            title = "Reload",
            message = "Reload data from flight controller",
            buttons = buttons,
            wakeup = function()
            end,
            paint = function()
            end,
            options = TEXT_LEFT
        })

        rf2ethos.triggers.triggerReload = false
    end

	-- and esc reload was triggered
    if rf2ethos.triggers.triggerEscReload == true then
        rf2ethos.triggers.triggerEscReload = false
		rf2ethos.ui.progessDisplay()
        rf2ethos.openESCFormInit(rf2ethos.escManufacturer, rf2ethos.escScript)
    end

	-- show an error if msp version is bad
	if rf2ethos.uiState == rf2ethos.uiStatus.mainMenu and rf2ethos.escMode == false then
		if rf2ethos.triggers.badMspVersion == true  then
			local buttons = {
				{
					label = "   OK   ",
					action = function()
						rf2ethos.triggers.exitAPP = true
						return true
					end
				}
			}
				
			if rf2ethos.triggers.badMspVersionDisplay == false  then
				local message
				if rf2ethos.config.apiVersion ~= 0 then
					message = rf2ethos.init.t
				else
					message = "Unable to determine msp version in use."
				end

				rf2ethos.triggers.badMspVersionDisplay = true
				form.openDialog({
					width = nil,
					title = "MSP Error",
					message = message,
					buttons = buttons,
					wakeup = function()
					end,
					paint = function()
					end,
					options = TEXT_LEFT
				})		
			end	

			return
		end
	end

	-- a save was triggered - lets display a progress box
    if rf2ethos.triggers.isSaving then
		rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 5
        if rf2ethos.pageState >= rf2ethos.pageStatus.saving then
            if rf2ethos.dialogs.saveDisplay == false then
                rf2ethos.triggers.saveFailed = false
                rf2ethos.dialogs.saveProgressCounter = 0
                rf2ethos.dialogs.saveDisplay = true
                rf2ethos.dialogs.saveWatchDog = os.clock()
                rf2ethos.dialogs.save = form.openProgressDialog("Saving...", "Saving data...")
                rf2ethos.dialogs.save:value(0)
                rf2ethos.dialogs.save:closeAllowed(false)
                rf2ethos.mspQueue.retryCount = 0
            end
            local saveMsg = ""
            if rf2ethos.pageState == rf2ethos.pageStatus.saving then
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
                rf2ethos.dialogs.save:message("Saving data...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.eepromWrite then
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
                --rf2ethos.dialogs.save:message("Writing to eeprom...")
				rf2ethos.dialogs.save:message("Saving data...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.rebooting then
                saveMsg = rf2ethos.dialogs.save:message("Rebooting...")
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
            end
            
        else
            rf2ethos.triggers.isSaving = false
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
        end
	elseif rf2ethos.triggers.isSavingFake == true then	
	
			if rf2ethos.dialogs.saveDisplay == false then
                rf2ethos.triggers.saveFailed = false
                rf2ethos.dialogs.saveProgressCounter = 0
                rf2ethos.dialogs.saveDisplay = true
                rf2ethos.dialogs.saveWatchDog = os.clock()
                rf2ethos.dialogs.save = form.openProgressDialog("Saving...", "Saving data...")
                rf2ethos.dialogs.save:value(0)
                rf2ethos.dialogs.save:closeAllowed(false)
                rf2ethos.mspQueue.retryCount = 0
				rf2ethos.triggers.closeSaveFake = true
				rf2ethos.triggers.isSavingFake = false
            end	
    end

	-- check we have telemetry
    rf2ethos.updateTelemetryState()

	-- if we are on the home page - then ensure pages are invalidated
    if rf2ethos.uiState == rf2ethos.uiStatus.mainMenu  then 
		invalidatePages() 
	else 
		-- detect page data loaded and ready to move onto rendering the page
		if (rf2ethos.triggers.isReady == true and rf2ethos.mspQueue:isProcessed() and (rf2ethos.Page.values)) then
            rf2ethos.triggers.isReady = false

			rf2ethos.triggers.closeProgressLoader = true
			
        end
    end

	-- if we are viewing a page with form data then we need to run some stuff USED
	-- by the msp processing
    if rf2ethos.uiState == rf2ethos.uiStatus.pages then
	

		-- rebind fields if needed
        if rf2ethos.pageState == rf2ethos.pageStatus.saving then
            if (rf2ethos.saveTS + rf2ethos.protocol.saveTimeout) < os.clock() then
                rf2ethos.dataBindFields()
            end
        end
		
		
		-- intercept and populate rf2ethos.Page if its empty
		-- this simply catches scenarious where we save the page AND
		-- other parts of the script fail for the few ms where the rf2ethos.Page
		-- var is not populated
		if not rf2ethos.Page and rf2ethos.PageTmp then
			rf2ethos.Page = rf2ethos.PageTmp
		end
		
		-- we have a page waiting to be retrieved - trigger a request page
		if rf2ethos.Page ~= nil then
			if not (rf2ethos.Page.values or rf2ethos.triggers.isReady) and rf2ethos.pageState == rf2ethos.pageStatus.display then 
				requestPage() 
			end 
		end
		
    end

	-- capture a reload request and load respective Page
	-- this needs to be done a little better as there is no need FOR
	-- all the menu case checks - we should just be able to do as a task
	-- when viewing the page
	if rf2ethos.triggers.reload == true then
			rf2ethos.ui.progessDisplay()
            rf2ethos.triggers.reload = false
            if rf2ethos.lastScript == "pids.lua" or rf2ethos.lastIdx == 1 then
                rf2ethos.ui.openPagePid(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "rates.lua" then
                rf2ethos.ui.openPageRates(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "servos.lua" then
                rf2ethos.ui.openPageServos(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript == nil then
                rf2ethos.ui.openPageEscTool(rf2ethos.escManufacturer)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript ~= nil then
                rf2ethos.openESCForm(rf2ethos.escManufacturer, rf2ethos.escScript)
            else
                rf2ethos.ui.openPageDefault(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            end
            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
	end
	
	-- check if rate or profile switches have been toggled
	rf2ethos.profileSwitchCheck()
	rf2ethos.rateSwitchCheck()	
	
	-- play audio
	--alerts 
	if rf2ethos.config.audioParam == 0 or rf2ethos.config.audioParam == 1 then

		if rf2ethos.audio.playConnecting == true then
			system.playFile(rf2ethos.config.toolDir .. "sounds/connecting.wav")
			rf2ethos.audio.playConnecting = false
		end		

		if rf2ethos.audio.playDemo == true then
			system.playFile(rf2ethos.config.toolDir .. "sounds/demo.wav")
			rf2ethos.audio.playDemo = false
		end		

		if rf2ethos.audio.playTimeout == true then
			system.playFile(rf2ethos.config.toolDir .. "sounds/timeout.wav")
			rf2ethos.audio.playTimeout = false
		end	

		if rf2ethos.audio.playEscPowerCycle == true then
			system.playFile(rf2ethos.config.toolDir .. "sounds/powercycleesc.wav")
			rf2ethos.audio.playEscPowerCycle = false
		end	
		
		if rf2ethos.audio.playSaving == true and rf2ethos.config.audioParam == 0 then
			system.playFile(rf2ethos.config.toolDir .. "sounds/saving.wav")
			rf2ethos.audio.playSaving = false
		end	

		if rf2ethos.audio.playLoading == true and rf2ethos.config.audioParam == 0 then
			system.playFile(rf2ethos.config.toolDir .. "sounds/loading.wav")
			rf2ethos.audio.playLoading = false
		end	
	else
		rf2ethos.audio.playLoading = false
		rf2ethos.audio.playSaving = false
		rf2ethos.audio.playTimeout = false
		rf2ethos.audio.playDemo = false
		rf2ethos.audio.playConnecting = false
		rf2ethos.audio.playEscPowerCycle = false
	end	





end

function rf2ethos.create()

    rf2ethos.sensor = sport.getSensor({primId = 0x32})
    rf2ethos.rssiSensor = system.getSource("RSSI")
    if not rf2ethos.rssiSensor then
        rf2ethos.rssiSensor = system.getSource("RSSI 2.4G")
        if not rf2ethos.rssiSensor then
            rf2ethos.rssiSensor = system.getSource("RSSI 900M")
            if not rf2ethos.rssiSensor then
                rf2ethos.rssiSensor = system.getSource("Rx RSSI1")
                if not rf2ethos.rssiSensor then
                    rf2ethos.rssiSensor = system.getSource("Rx RSSI2")
                    if not rf2ethos.rssiSensor then
                        rf2ethos.rssiSensor = system.getSource("RSSI Int")
                        if not rf2ethos.rssiSensor then rf2ethos.rssiSensor = system.getSource("RSSI Ext") end
                    end
                end
            end
        end
    end

    -- load msp timeout
    rf2ethos.config.watchdogParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/watchdog")
    if rf2ethos.config.watchdogParam == nil or rf2ethos.config.watchdogParam == "" then rf2ethos.config.watchdogParam = 15 end

    rf2ethos.config.lcdWidth, rf2ethos.config.lcdHeight = rf2ethos.utils.getWindowSize()
    rf2ethos.protocol = assert(compile.loadScript(rf2ethos.config.toolDir .. "protocols.lua"))()
    rf2ethos.radio = assert(compile.loadScript(rf2ethos.config.toolDir .. "radios.lua"))().msp
    rf2ethos.mspQueue = assert(compile.loadScript(rf2ethos.config.toolDir .. "msp/mspQueue.lua"))()
    rf2ethos.mspQueue.maxRetries = rf2ethos.protocol.maxRetries
    rf2ethos.mspHelper = assert(compile.loadScript(rf2ethos.config.toolDir .. "msp/mspHelper.lua"))()
    assert(compile.loadScript(rf2ethos.config.toolDir .. rf2ethos.protocol.mspTransport))()
    assert(compile.loadScript(rf2ethos.config.toolDir .. "msp/common.lua"))()

    rf2ethos.fieldHelpTxt = assert(compile.loadScript(rf2ethos.config.toolDir .. "help/fields.lua"))()

    rf2ethos.uiState = rf2ethos.uiStatus.init

    config.apiVersion = 0
	config.environment = system.getVersion()


    rf2ethos.config.audioParam = tonumber(rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/audio"))



	if system:getVersion().simulation == false then
		local simpref = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir  .. "/preferences/demoswitch")
		local s = rf2ethos.utils.explode(simpref, ",")
		local simParam = system.getSource({category = s[1], member = s[2]})
		if tonumber(simParam:value()) == 100  then
			config.simulateOnTransmitter = true
			rf2ethos.runningInSimulator = true
			print("RF2ETHOS: Running in Demo Mode")
			rf2ethos.audio.playDemo = true
		else
			config.simulateOnTransmitter = false
			rf2ethos.runningInSimulator = false
			rf2ethos.audio.playDemo = false
		end
	end


    rf2ethos.ui.openMainMenu()


    -- check the current version of ethos to ensure that it is valid.
    if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. config.environment.minor .. config.environment.revision)) < config.ethosVersion then
        if rf2ethos.dialogs.badversionDisplay == false then
            rf2ethos.dialogs.badversionDisplay = true

            local buttons = {
                {
                    label = "EXIT",
                    action = function()
                        rf2ethos.triggers.exitAPP = true
                        return true
                    end
                }
            }

            if tonumber(rf2ethos.utils.makeNumber(rf2ethos.config.environment.major .. config.environment.minor .. config.environment.revision)) < 1590 then
                form.openDialog("Warning", config.ethosVersionString, buttons, 1)
            else
                form.openDialog({
                    width = rf2ethos.config.lcdWidth,
                    title = "Warning",
                    message = config.ethosVersionString,
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

end

-- EVENT:  Called for button presses, scroll events, touch events, etc.
function rf2ethos.event(widget, category, value, x, y)

   -- print("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

    if value == EVT_VIRTUAL_PREV_LONG then
        print("Forcing exit")
        invalidatePages()
        system.exit()
        return 0
    end

	

    -- close esc main type selection menu
    if rf2ethos.escMenuState == 1 then
        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.escMode = false
            rf2ethos.escManufacturer = nil
            rf2ethos.escScript = nil
			rf2ethos.dialogs.progressDisplayEsc = false
            rf2ethos.ui.openMainMenu()
            return true
        end
    end
    -- close esc pages menu
    if rf2ethos.escMenuState == 2 then
        if category == 5 or value == 35 then
            if rf2ethos.triggers.escPowerCycle == true then 
				rf2ethos.dialogs.progressCounterESC = 99
				return true
			else
				if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
				if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
				rf2ethos.escMode = true
				rf2ethos.escManufacturer = nil
				rf2ethos.escScript = nil
				rf2ethos.ui.openPageEsc(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
				return true
			end
        end
    end
    -- close esc tool menu
    if rf2ethos.escMenuState == 3 then
        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.escMode = true
            rf2ethos.escScript = nil
            collectgarbage()
            rf2ethos.ui.openPageEscTool(rf2ethos.escManufacturer)
            return true
        end
    end

    if rf2ethos.uiState == rf2ethos.uiStatus.pages then

        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.ui.openMainMenu()
            return true
        end
        if value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.ui.openMainMenu()
            return true
        end
        if value == KEY_ENTER_LONG then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.triggers.triggerSave = true
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end

    end

    if rf2ethos.uiState == rf2ethos.uiStatus.MainMenu then
        if value == KEY_ENTER_LONG then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end
    end

    return false
end

function rf2ethos.close()
	if rf2ethos.dialogs.progress then
		rf2ethos.dialogs.progress:close()
	end
	if rf2ethos.dialogs.save then
		rf2ethos.dialogs.save:close()
	end
	if rf2ethos.dialogs.progressESC then
		rf2ethos.dialogs.progressESC:close()
	end
	if noLinkDialog then
		noLinkDialog:close()
	end
    invalidatePages()
    rf2ethos.resetState()
    system.exit()
    return true
end

return rf2ethos
