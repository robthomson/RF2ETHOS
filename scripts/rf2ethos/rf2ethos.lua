rf2ethos = {}

local arg = {...}

local config = arg[1]
local compile = arg[2]

local triggers = {}
triggers.isLoading = false
triggers.wasLoading = false
triggers.closeProgress = false
triggers.exitAPP = false
triggers.noRFMsg = false
triggers.triggerSAVE = false
triggers.triggerRELOAD = false
triggers.triggerESCRELOAD = false
triggers.triggerESCMAINMENU = false
triggers.triggerESCLOADER = false
triggers.triggerMAINMENU = false
triggers.escPowerCycle = false
triggers.escPowerCycleAnimation = nil
triggers.escPowerCycleLoader = 0
triggers.mspDataLoaded = false
triggers.isSaving = false
triggers.wasSaving = false
triggers.wasReloading = false
triggers.closinghelp = false
triggers.saveFailed = false
triggers.telemetryState = nil
triggers.reloadRates = false
triggers.resetRates = nil
triggers.linkUPTime = nil
triggers.createForm = false
triggers.profileswitchLast = nil
triggers.rateswitchLast = nil
triggers.closeSave = false
triggers.badMspVersion = false
triggers.badMspVersionDisplay = false


rf2ethos = {}
rf2ethos.compile = compile

rf2ethos.wakeupSchedulerLow = os.clock()
rf2ethos.wakeupSchedulerMedium = os.clock()

rf2ethos.config = {}
rf2ethos.config = config

rf2ethos.triggers = {}
rf2ethos.triggers = triggers

rf2ethos.utils = {}
rf2ethos.utils = assert(compile.loadScript(config.toolDir .. "lib/utils.lua"))()

rf2ethos.ui = {}
rf2ethos.ui = assert(compile.loadScript(config.toolDir .. "lib/ui.lua"))()

rf2ethos.PageTmp = {}
rf2ethos.Page = {}
rf2ethos.saveTS = 0
rf2ethos.lastPage = nil
rf2ethos.lastSection = nil
rf2ethos.lastIdx = nil
rf2ethos.lastSubPage = nil
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
rf2ethos.escNotReadyCount = 0
rf2ethos.uiStatus = {init = 1, mainMenu = 2, pages = 3, confirm = 4}
rf2ethos.pageStatus = {display = 1, editing = 2, saving = 3, eepromWrite = 4, rebooting = 5}
rf2ethos.telemetryStatus = {ok = 1, noSensor = 2, noTelemetry = 3}
rf2ethos.uiState = rf2ethos.uiStatus.init
rf2ethos.prevUiState = nil
rf2ethos.pageState = rf2ethos.pageStatus.display
rf2ethos.lastLabel = nil
rf2ethos.NewRateTable = nil
rf2ethos.RateTable = nil
rf2ethos.fieldHelpTxt = nil
rf2ethos.protocol = {}
rf2ethos.protocol.msg = nil
rf2ethos.protocol.retry = 0
rf2ethos.radio = {}
rf2ethos.sensor = {}
rf2ethos.init = nil
rf2ethos.checkedVersion = false

rf2ethos.dialogs = {}
rf2ethos.dialogs.progress = false
rf2ethos.dialogs.progressDisplay = false
rf2ethos.dialogs.progressWatchDog = nil
rf2ethos.dialogs.progressCounter = 0

rf2ethos.dialogs.save = false
rf2ethos.dialogs.saveDisplay = false
rf2ethos.dialogs.saveWatchDog = nil
rf2ethos.dialogs.saveProgressCounter = 0

rf2ethos.dialogs.nolink = false
rf2ethos.dialogs.nolinkDisplay = false
rf2ethos.dialogs.nolinkValue = 0

rf2ethos.dialogs.badversion = false
rf2ethos.dialogs.badversionDisplay = false

rf2ethos.runningInSimulator = system:getVersion().simulation


rf2ethos.hourglass = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/hourglass.png")

-- Ethos: when the RF1 and RF2 system tools are both installed, RF1 tries to call getRSSI in RF2 and gets stuck.
-- To avoid this, getRSSI is renamed in rf2ethos.
rf2ethos.getRSSI = function()
    -- --rf2ethos.utils.log("getRSSI RF2")
    if rf2ethos.config.environment.simulation == true then return 100 end

    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rf2ethos.rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

function rf2ethos.resetState()

    rf2ethos.escMode = false
    rf2ethos.triggers.escPowerCycle = false
    rf2ethos.escManufacturer = nil
    rf2ethos.triggers.resetRates = false
    rf2ethos.escScript = nil
    pageLoaded = 100
    pageTitle = nil
    pageFile = nil
    rf2ethos.triggers.exitAPP = false
    rf2ethos.triggers.noRFMsg = false
    rf2ethos.triggers.linkUPTime = nil
    rf2ethos.dialogs.nolinkDisplay = false
    rf2ethos.dialogs.nolinkValue = 0
    rf2ethos.triggers.telemetryState = nil
    rf2ethos.triggers.badMspVersionDisplay = false
    rf2ethos.triggers.badMspVersion = false
    ELRS_PAUSE_TELEMETRY = false

end

function rf2ethos.profileSwitchCheck()
	if rf2ethos.config.profileswitchParamPreference == nil then
		rf2ethos.config.profileswitchParamPreference = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/profileswitch")
        local s = rf2ethos.utils.explode(rf2ethos.config.profileswitchParamPreference, ",")
        rf2ethos.config.profileswitchParam = system.getSource({category = s[1], member = s[2]})
	end
    if rf2ethos.config.profileswitchParam ~= nil then
        rf2ethos.triggers.profileswitchLast = rf2ethos.config.profileswitchParam:value()
    end
end

function rf2ethos.rateSwitchCheck()
	if rf2ethos.config.rateswitchParamPreference == nil then
		rf2ethos.config.rateswitchParamPreference = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/rateswitch")
        local s = rf2ethos.utils.explode(rf2ethos.config.rateswitchParamPreference, ",")
        rf2ethos.config.rateswitchParam = system.getSource({category = s[1], member = s[2]})		
	end
    if rf2ethos.config.rateswitchParam ~= nil then
        rf2ethos.triggers.rateswitchLast = rf2ethos.config.rateswitchParam:value()
    end
end

function rf2ethos.getFieldValue(f)

    if f.value == nil then f.value = 0 end
    if f.t == nil then f.t = "N/A" end

    -- rf2ethos.utils.log(f.t .. ":" .. f.value)

    local v

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

function rf2ethos.saveValue(currentField)
    local f = rf2ethos.Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do rf2ethos.Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8) end
    if f.upd and rf2ethos.Page.values then f.upd(rf2ethos.Page) end
end

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

function rf2ethos.getRSSI()
    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rf2ethos.rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

function rf2ethos.startsWith(str, prefix)
    if #prefix > #str then return false end
    for i = 1, #prefix do if str:byte(i) ~= prefix:byte(i) then return false end end
    return true
end

function rf2ethos.getWindowSize()
    return lcd.getWindowSize()
    -- return 784, 406
    -- return 472, 288
    -- return 472, 240
end

function rf2ethos.log(str)
    rf2ethos.utils.log(str)
end

function rf2ethos.print(str)
    -- rf2ethos.utils.log(tostring(str))
end

-- when saving - we have to force a reload of data of copy-profiles due to way you

function rf2ethos.resetCopyProfiles()
    if rf2ethos.lastScript == "copy_profiles.lua" then
        -- invalidatePages
        -- rf2ethos.ui.openPageDefaultLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
        rf2ethos.triggers.wasReloading = true
        rf2ethos.triggers.createForm = true
        rf2ethos.triggers.wasSaving = false
        rf2ethos.triggers.wasLoading = false
        rf2ethos.triggers.reloadRates = false

    end
end

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

function rf2ethos.resetRates()
    if rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 2 then
        if rf2ethos.triggers.resetRates == true then
            rf2ethos.NewRateTable = rf2ethos.Page.fields[13].value

            local newTable = rf2ethos.utils.defaultRates(rf2ethos.NewRateTable)

            for k, v in pairs(newTable) do
                local f = rf2ethos.Page.fields[k]
                v = math.floor(v)
                for idx = 1, #f.vals do rf2ethos.Page.values[f.vals[idx]] = v >> ((idx - 1) * 8) end
            end
            rf2ethos.triggers.resetRates = false
        end
    end
end

local function invalidatePages()
    rf2ethos.Page = nil
    rf2ethos.pageState = rf2ethos.pageStatus.display
    rf2ethos.saveTS = 0
    collectgarbage()
end

local function rebootFc()

    -- rf2ethos.utils.log("Attempting to reboot the FC...")
    rf2ethos.pageState = rf2ethos.pageStatus.rebooting
    rf2ethos.mspQueue:add({
        command = 68, -- MSP_REBOOT
        processReply = function(self, buf)
            invalidatePages()
        end,
        simulatorResponse = {}
    })
end

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

function rf2ethos.dataBindFields()
    if rf2ethos.Page.fields then

        for i = 1, #rf2ethos.Page.fields do

            if rf2ethos.Page.values and #rf2ethos.Page.values >= rf2ethos.Page.minBytes then
                local f = rf2ethos.Page.fields[i]
                if f.vals then
                    f.value = 0
                    for idx = 1, #f.vals do
                        -- local raw_val = rf2ethos.Page.values[f.vals[idx]] or 0
                        -- inject header bytes if we have
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

rf2ethos.settingsSaved = function()
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

local mspSaveSettings = {
    processReply = function(self, buf)
        rf2ethos.settingsSaved()
    end
}

local mspLoadSettings = {
    processReply = function(self, buf)

        -- rf2ethos.utils.log("rf2ethos.Page is processing reply for cmd " .. tostring(self.command) .. " len buf: " .. #buf .. " expected: " .. rf2ethos.Page.minBytes)
        if rf2ethos.Page ~= nil then
            rf2ethos.Page.values = buf
            if rf2ethos.Page.postRead then rf2ethos.Page.postRead(rf2ethos.Page) end
            rf2ethos.dataBindFields()
            if rf2ethos.Page.postLoad then rf2ethos.Page.postLoad(rf2ethos.Page) end
            rf2ethos.utils.log("rf2ethos.triggers.mspDataLoaded")
        else
            rf2ethos.utils.log("rf2ethos.triggers.mspDataLoaded rf2ethos.Page is nil?")
        end

    end
}

rf2ethos.readPage = function()
    if type(rf2ethos.Page.read) == "function" then
        rf2ethos.Page.read(rf2ethos.Page)
    else
        mspLoadSettings.command = rf2ethos.Page.read
        mspLoadSettings.simulatorResponse = rf2ethos.Page.simulatorResponse
        rf2ethos.mspQueue:add(mspLoadSettings)
    end
end

local function saveSettings()

    if rf2ethos.pageState ~= rf2ethos.pageStatus.saving then
        rf2ethos.pageState = rf2ethos.pageStatus.saving
        rf2ethos.saveTS = os.clock()

        if rf2ethos.Page.values then
            local payload = rf2ethos.Page.values

            if rf2ethos.Page.preSave then payload = rf2ethos.Page.preSave(rf2ethos.Page) end
            if rf2ethos.Page.alterPayload then payload = rf2ethos.Page.alterPayload(payload) end

            mspSaveSettings.command = rf2ethos.Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            rf2ethos.mspQueue:add(mspSaveSettings)
            rf2ethos.mspQueue.errorHandler = function()
                displayMessage = {title = "Save error", text = "Make sure your heli is disarmed."}
                print("Save failed")
                rf2ethos.triggers.saveFailed = true
            end
        elseif type(rf2ethos.Page.write) == "function" then
            rf2ethos.Page.write(rf2ethos.Page)
        end

    end
end

local function requestPage()
	if rf2ethos.Page ~= nil then
		if not rf2ethos.Page.reqTS or rf2ethos.Page.reqTS + rf2ethos.protocol.pageReqTimeout <= os.clock() then
			rf2ethos.Page.reqTS = os.clock()
			if rf2ethos.Page.read then rf2ethos.readPage() end
		end
	end	
end

local function updateTelemetryState()

    if config.environment.simulation ~= true then
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

-- WAKEUP:  Called every ~30-50ms by the main Ethos software loop
function rf2ethos.wakeup(widget)

	local now = os.clock()

	-- low priority tasks
	rf2ethos.wakeupHighPriority()

	-- medium priority tasks
	if (now - rf2ethos.wakeupSchedulerMedium) >= 0.3 then	
		rf2ethos.wakeupSchedulerMedium = now
		rf2ethos.wakeupMediumPriority()
	end		

	-- low priority tasks
	if (now - rf2ethos.wakeupSchedulerLow) >= 0.5 then	
		rf2ethos.wakeupSchedulerLow = now
		rf2ethos.wakeupLowPriority()
	end	

end

function rf2ethos.wakeupHighPriority(widget)

	-- this needs to run on every wakeup event.
    rf2ethos.mspQueue:processQueue()
	
	-- elrs telem pausing
    if rf2ethos.dialogs.progressDisplay == true or rf2ethos.dialogs.saveDisplay == true or rf2ethos.dialogs.nolinkDisplay == true then
        ELRS_PAUSE_TELEMETRY = true
    else
        ELRS_PAUSE_TELEMETRY = false
    end
	
end

function rf2ethos.wakeupMediumPriority(widget)

    -- exit app called : quick abort
    -- as we dont need to run the rest of the stuff
    if rf2ethos.triggers.exitAPP == true then
        rf2ethos.triggers.exitAPP = false
        form.invalidate()
        system.exit()
        return
    end

   -- check telemetry state and overlay dialog if not linked
    if rf2ethos.triggers.escPowerCycle == true then
        -- ESC MODE - WE NEVER TIME OUT AS DO A 'RETRY DIALOG'
        -- AS SOME ESC NEED TO BE CONNECTING AS YOU POWER UP to
        -- INIT CONFIG MODE

    else
        if rf2ethos.triggers.telemetryState ~= 1 then
            if rf2ethos.dialogs.nolinkDisplay == false then
                rf2ethos.dialogs.nolinkDisplay = true
				if rf2ethos.config.progressDialogStyle == 1 then
					noLinkDialog = form.openProgressDialog("Connecting", "Connecting")
					noLinkDialog:closeAllowed(false)
					noLinkDialog:value(0)
				end
                rf2ethos.dialogs.nolinkValue = 0

                -- check msp version of fbl
                rf2ethos.init = rf2ethos.init or assert(compile.loadScript(rf2ethos.config.toolDir .. "ui_init.lua"))()
                rf2ethos.init.f()
            end
        end

        if rf2ethos.dialogs.nolinkDisplay == true then

            if rf2ethos.triggers.telemetryState == 1 then
                if rf2ethos.config.apiVersion ~= nil then
                    rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 30
                else
                    rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 10
                end
            else
                rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 5
            end

            if rf2ethos.dialogs.nolinkValue >= 100 and rf2ethos.mspQueue:isProcessed() then

                if rf2ethos.init.f() == false and rf2ethos.getRSSI() ~= 0 then
					if rf2ethos.config.progressDialogStyle == 1 then
						noLinkDialog:close()
					end
                    rf2ethos.dialogs.nolinkValue = 0
                    rf2ethos.dialogs.nolinkDisplay = false
                    rf2ethos.triggers.badMspVersion = true
                else
					if rf2ethos.config.progressDialogStyle == 1 then
						noLinkDialog:close()
					end
                    rf2ethos.dialogs.nolinkValue = 0
                    rf2ethos.dialogs.nolinkDisplay = false
                    rf2ethos.triggers.badMspVersion = false
                    if config.environment.simulation ~= true then if rf2ethos.triggers.telemetryState ~= 1 then rf2ethos.triggers.exitAPP = true end end
                end
            end

			if rf2ethos.config.progressDialogStyle == 1 then
				noLinkDialog:value(rf2ethos.dialogs.nolinkValue)
			end
		
            
        end
    end


    if rf2ethos.uiState == rf2ethos.uiStatus.mainMenu and rf2ethos.escMode == false then
        if rf2ethos.triggers.badMspVersion == true then
            local buttons = {
                {
                    label = "   OK   ",
                    action = function()
                        rf2ethos.triggers.exitAPP = true
                        return true
                    end
                }
            }

            if rf2ethos.triggers.badMspVersionDisplay == false then
                rf2ethos.triggers.badMspVersionDisplay = true
                form.openDialog({
                    width = nil,
                    title = "MSP Error",
                    message = rf2ethos.init.t,
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



    if rf2ethos.triggers.closeSave == true then
        rf2ethos.triggers.isSaving = false

        if rf2ethos.mspQueue:isProcessed() then
            if (rf2ethos.dialogs.saveProgressCounter > 40 and rf2ethos.dialogs.saveProgressCounter <= 80) then
                rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 10
            else
                rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 5
            end
        end
 

		if rf2ethos.config.progressDialogStyle == 1 then
			rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
		end


        if rf2ethos.dialogs.saveProgressCounter >= 100 and rf2ethos.mspQueue:isProcessed() then
		
            system.playFile(rf2ethos.config.toolDir .. "sounds/save.wav")
	
            rf2ethos.triggers.closeSave = false
            rf2ethos.dialogs.saveProgressCounter = 0
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
			if rf2ethos.config.progressDialogStyle == 1 then
				rf2ethos.dialogs.save:close()
			else
				-- only if we was a page reload
				--rf2ethos.triggers.wasReloading = true
				--rf2ethos.triggers.createForm = true
				--rf2ethos.triggers.wasSaving = false
				--rf2ethos.triggers.wasLoading = false
				--rf2ethos.triggers.reloadRates = false			
			end
        end
    end

    -- ESC LOADER
    if rf2ethos.triggers.triggerESCLOADER == true then
        if rf2ethos.dialogs.progressDisplay ~= true then

            rf2ethos.dialogs.progressDisplay = true
            rf2ethos.dialogs.progressWatchDog = os.clock()
            rf2ethos.dialogs.progress = form.openProgressDialog("Searching...", "Please power cycle the esc")
            rf2ethos.dialogs.progress:value(0)
            rf2ethos.dialogs.progress:closeAllowed(false)
        else
            -- this is where we should hit
			rf2ethos.triggers.closeProgress = false
			
            if rf2ethos.triggers.escPowerCycleLoader <= 95 then
				if config.progressDialogStyle == 1 then
                rf2ethos.dialogs.progress:message("Please power cycle the esc")
				end
            else
				if config.progressDialogStyle == 1 then
					rf2ethos.dialogs.progress:message("Aborting...")
				end
            end

			if config.progressDialogStyle == 1 then
				rf2ethos.dialogs.progress:value(rf2ethos.triggers.escPowerCycleLoader)
			end

            rf2ethos.triggers.escPowerCycleLoader = rf2ethos.triggers.escPowerCycleLoader + 1

            if rf2ethos.mspQueue:isProcessed() then requestPage() end

            if rf2ethos.triggers.escPowerCycleLoader >= 100 then
                rf2ethos.triggers.escPowerCycleLoader = 0
				if config.progressDialogStyle == 1 then
					rf2ethos.dialogs.progress:close()
				end
                rf2ethos.triggers.triggerESCLOADER = false
                rf2ethos.triggers.triggerESCMAINMENU = true
				rf2ethos.triggers.closeProgress = true
            end

        end
    end

    -- capture profile switching and trigger a reload if needs be
    if rf2ethos.Page ~= nil and rf2ethos.uiState == rf2ethos.uiStatus.pages then
        if rf2ethos.Page.refreshswitch == true then

            if rf2ethos.lastPage ~= "rates.lua" then
                if rf2ethos.config.profileswitchParam ~= nil then

                    if rf2ethos.config.profileswitchParam:value() ~= rf2ethos.triggers.profileswitchLast then

                        if rf2ethos.dialogs.progressDisplay == true or rf2ethos.dialogs.saveDisplay == true then
                            -- switch has been toggled mid flow - this is bad.. clean upd
                            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
                            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
                            rf2ethos.ui.showProgressDialog()
							form.clear()
                            rf2ethos.triggers.wasReloading = true
                            rf2ethos.triggers.createForm = true
                            rf2ethos.triggers.wasSaving = false
                            rf2ethos.triggers.wasLoading = false
                            rf2ethos.triggers.reloadRates = false

                        else

                            rf2ethos.triggers.profileswitchLast = rf2ethos.config.profileswitchParam:value()
                            -- trigger RELOAD
                            -- rf2ethos.utils.log("Profile switch reload")
							rf2ethos.ui.showProgressDialog()
							rf2ethos.triggers.wasReloading = true
							rf2ethos.triggers.createForm = true
							rf2ethos.triggers.wasSaving = false
							rf2ethos.triggers.wasLoading = false
							rf2ethos.triggers.reloadRates = false
                            return true

                        end
                    end
                end
            end

            -- capture profile switching and trigger a reload if needs be
            if rf2ethos.lastPage == "rates.lua" then
                if rf2ethos.config.rateswitchParam ~= nil then
                    if rf2ethos.config.rateswitchParam:value() ~= rf2ethos.triggers.rateswitchLast then

                        if rf2ethos.dialogs.progressDisplay == true or rf2ethos.dialogs.saveDisplay == true then
                            -- switch has been toggled mid flow - this is bad.. clean upd
                            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
                            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
                            rf2ethos.ui.showProgressDialog()
                            rf2ethos.triggers.wasReloading = true
                            rf2ethos.triggers.createForm = true
                            rf2ethos.triggers.wasSaving = false
                            rf2ethos.triggers.wasLoading = false
                            rf2ethos.triggers.reloadRates = false

                        else
                            rf2ethos.triggers.rateswitchLast = rf2ethos.config.rateswitchParam:value()

                            -- trigger RELOAD
                            -- rf2ethos.utils.log("Rate switch reload")
							rf2ethos.ui.showProgressDialog()
							rf2ethos.triggers.wasSaving = false
							rf2ethos.triggers.wasLoading = false

							rf2ethos.triggers.wasReloading = false

							rf2ethos.triggers.createForm = true
							rf2ethos.triggers.reloadRates = true
                            return true
                        end

                    end
                end
            end

        end
    end

    if rf2ethos.triggers.triggerESCMAINMENU == true then
        rf2ethos.triggers.triggerESCMAINMENU = false
        rf2ethos.escMode = false
        rf2ethos.triggers.escPowerCycle = false
        rf2ethos.triggers.resetRates = false
        rf2ethos.escNotReadyCount = 0
        rf2ethos.escUnknown = false
        rf2ethos.lastIdx = nil
        rf2ethos.lastPage = nil
        rf2ethos.lastSubPage = nil
        invalidatePages()

        rf2ethos.ui.openPageESC(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)

    end


    if rf2ethos.dialogs.progressDisplay == true then

        if rf2ethos.triggers.isLoading == true then
            rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 10
			if rf2ethos.config.progressDialogStyle == 1 then
				rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)
			end	
        end

		
		if rf2ethos.triggers.closeProgress == true then

            if rf2ethos.dialogs.progressCounter < 50 then
                rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 40
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)
				end
            elseif rf2ethos.dialogs.progressCounter > 50 and rf2ethos.dialogs.progressCounter <= 90 then
                rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 30
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)
				end
            else
				rf2ethos.dialogs.progressCounter = rf2ethos.dialogs.progressCounter + 10
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.progress:value(rf2ethos.dialogs.progressCounter)
				end
            end

            -- close once we reach 100%
            if rf2ethos.dialogs.progressCounter >= 100 then
                rf2ethos.dialogs.progressCounter = 0
                triggers.closeProgress = false
                rf2ethos.dialogs.progressWatchDog = nil
                rf2ethos.dialogs.progressDisplay = false
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.progress:close()
				end
            end
        end

        
   -- else 
			--if rf2ethos.triggers.isLoading ~= true then
			--if rf2ethos.triggers.mspDataLoaded == true then
			--	print("here")
			--	rf2ethos.triggers.closeProgress = true
			--	rf2ethos.dialogs.progressDisplay = false
			--end
	end			

    if rf2ethos.uiState == rf2ethos.uiStatus.pages then
        if rf2ethos.prevUiState ~= rf2ethos.uiState then rf2ethos.prevUiState = rf2ethos.uiState end

        if rf2ethos.pageState == rf2ethos.pageStatus.saving then
            if (rf2ethos.saveTS + rf2ethos.protocol.saveTimeout) < os.clock() then
                -- invalidatePages()
                rf2ethos.dataBindFields()
            end
        end
        if not rf2ethos.Page then
            if rf2ethos.escMode == true then
                if rf2ethos.escScript ~= nil then
                    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "esc/" .. rf2ethos.escManufacturer .. "/pages/" .. rf2ethos.escScript))()
                else
                    -- rf2ethos.utils.log("rf2ethos.escScript is not present so cannot load as expected")
                end
            else
                if rf2ethos.lastPage ~= nil then rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. rf2ethos.lastPage))() end
                rf2ethos.escManufacturer = nil
                rf2ethos.escScript = nil
                rf2ethos.escMode = false
            end
            collectgarbage()
        end
        if rf2ethos.Page ~= nil then if not (rf2ethos.Page.values or rf2ethos.triggers.mspDataLoaded) and rf2ethos.pageState == rf2ethos.pageStatus.display then requestPage() end end

    end

    if rf2ethos.uiState ~= rf2ethos.uiStatus.mainMenu then
        if rf2ethos.config.environment.simulation == true or (rf2ethos.triggers.mspDataLoaded == true and rf2ethos.mspQueue:isProcessed() and (rf2ethos.Page.values)) then
        --if (rf2ethos.triggers.mspDataLoaded == true and rf2ethos.mspQueue:isProcessed() and (rf2ethos.Page.values)) then
            rf2ethos.triggers.mspDataLoaded = false
            rf2ethos.triggers.isLoading = false
            rf2ethos.triggers.wasLoading = true
            -- if config.environment.simulation ~= true then 
            rf2ethos.triggers.createForm = true
            -- end
        end
    end

    -- if rf2ethos.triggers.createForm == true and rf2ethos.mspQueue:isProcessed() then
    if rf2ethos.triggers.createForm == true then
        if (rf2ethos.triggers.wasSaving == true) then

            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()

            rf2ethos.triggers.wasSaving = false

            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil

            if rf2ethos.triggers.saveFailed == false then
                -- rf2ethos.dialogs.save:message("Saving... [done]")
                -- mark save complete so we can speed up progress dialog for	
				
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.triggers.closeSave = true
				end

                -- switch back in the PageTmp
                rf2ethos.Page = rf2ethos.PageTmp
                rf2ethos.PageTmp = {}

            end

        elseif (rf2ethos.triggers.wasLoading == true) then
            rf2ethos.triggers.wasLoading = false
            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
            if rf2ethos.lastScript == "pids.lua" or rf2ethos.lastIdx == 1 then
                rf2ethos.ui.openPagePID(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 1 then
                rf2ethos.ui.openPageRATES(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "servos.lua" then
                rf2ethos.ui.openPageSERVOS(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript == nil then
                rf2ethos.ui.openPageESCTool(rf2ethos.escManufacturer)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript ~= nil then
                rf2ethos.openESCForm(rf2ethos.escManufacturer, rf2ethos.escScript)
            else
                rf2ethos.ui.openPageDefault(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            end
			rf2ethos.triggers.closeProgress = true
        elseif rf2ethos.triggers.wasReloading == true then
            rf2ethos.triggers.wasReloading = false
			rf2ethos.ui.showProgressDialog()
            if rf2ethos.lastScript == "pids.lua" or rf2ethos.lastIdx == 1 then
                rf2ethos.ui.openPagePIDLoader(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 1 then
                rf2ethos.ui.openPageRATESLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "servos.lua" then
                rf2ethos.ui.openPageSERVOSLoader(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript == nil then
                rf2ethos.ui.openPageESCToolLoader(rf2ethos.escManufacturer)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript ~= nil then
                rf2ethos.openESCFormLoader(rf2ethos.escManufacturer, rf2ethos.escScript)
            else
                rf2ethos.ui.openPageDefaultLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            end
            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
        elseif rf2ethos.triggers.reloadRates == true then
            rf2ethos.ui.openPageRATESLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
        else
            rf2ethos.ui.openMainMenu()
        end

        rf2ethos.triggers.createForm = false
    else
        rf2ethos.triggers.createForm = false
    end

    if rf2ethos.triggers.isSaving  then
        rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 5
        if rf2ethos.pageState >= rf2ethos.pageStatus.saving then
            if rf2ethos.dialogs.saveDisplay == false then
                rf2ethos.triggers.saveFailed = false
                rf2ethos.dialogs.saveProgressCounter = 0
                rf2ethos.dialogs.saveDisplay = true
                rf2ethos.dialogs.saveWatchDog = os.clock()
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.save = form.openProgressDialog("Saving...", "Saving data...")
					rf2ethos.dialogs.save:value(0)
					rf2ethos.dialogs.save:closeAllowed(false)
				end	
                rf2ethos.mspQueue.retryCount = 0
            end
            local saveMsg = ""
            if rf2ethos.pageState == rf2ethos.pageStatus.saving then
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
				end	
            elseif rf2ethos.pageState == rf2ethos.pageStatus.eepromWrite then
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
				end	
                -- rf2ethos.dialogs.save:message("Writing to eeprom...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.rebooting then
				if rf2ethos.config.progressDialogStyle == 1 then
					rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
				end
            end

        else
            rf2ethos.triggers.isSaving = false
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
        end
    elseif rf2ethos.triggers.wasSaving == true then
        rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 5
		if rf2ethos.config.progressDialogStyle == 1 then
			rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
		end	
    end

 

		
end

function rf2ethos.wakeupLowPriority(widget)

	
    -- check ethos version
	if rf2ethos.checkedVersion == false then
		rf2ethos.checkedVersion = true
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

    -- save dialog watchdog
    if rf2ethos.config.watchdogParam ~= nil and rf2ethos.config.watchdogParam ~= 1 then rf2ethos.protocol.saveTimeout = rf2ethos.config.watchdogParam end
    if rf2ethos.dialogs.saveDisplay == true then
        if rf2ethos.dialogs.saveWatchDog ~= nil then
            if (os.clock() - rf2ethos.dialogs.saveWatchDog) > (rf2ethos.protocol.saveTimeout + rf2ethos.config.watchDogTimeout) then 
				rf2ethos.dialogs.save:closeAllowed(true) 
				rf2ethos.dialogs.progress:message("Error.. we timed out")
				-- switch back to original page values
				rf2ethos.Page = rf2ethos.PageTmp
				rf2ethos.PageTmp = {}
				rf2ethos.triggers.isLoading = false
				rf2ethos.triggers.wasLoading = false
				rf2ethos.dialogs.progressCounter = 0	
				rf2ethos.triggers.isSaving = false
				rf2ethos.pageState = rf2ethos.pageStatus.display
			end
        end
    end

	--progress dialog watchdog
    if rf2ethos.dialogs.progressDisplay == true then
		if rf2ethos.dialogs.progressWatchDog ~= nil then

            if rf2ethos.config.watchdogParam ~= 1 then rf2ethos.protocol.pageReqTimeout = rf2ethos.config.watchdogParam end

            if rf2ethos.triggers.escPowerCycle == true then
                if (os.clock() - rf2ethos.dialogs.progressWatchDog) > (rf2ethos.protocol.pageReqTimeout + (rf2ethos.config.watchDogTimeout * 3)) then
					if rf2ethos.config.progressDialogStyle == 1 then
						rf2ethos.dialogs.progress:message("Error.. we timed out")
						rf2ethos.dialogs.progress:closeAllowed(true)
					end
                    -- switch back to original page values
                    rf2ethos.Page = rf2ethos.PageTmp
                    rf2ethos.PageTmp = {}
                    rf2ethos.triggers.isLoading = false
                    rf2ethos.triggers.wasLoading = false
                    rf2ethos.dialogs.progressCounter = 0
                end
            else
                if (os.clock() - rf2ethos.dialogs.progressWatchDog) > (rf2ethos.protocol.pageReqTimeout + rf2ethos.config.watchDogTimeout) then
					if rf2ethos.config.progressDialogStyle == 1 then
						rf2ethos.dialogs.progress:message("Error.. we timed out")
						rf2ethos.dialogs.progress:closeAllowed(true)
					end
                    -- switch back to original page values
                    rf2ethos.Page = rf2ethos.PageTmp
                    rf2ethos.PageTmp = {}
                    rf2ethos.triggers.isLoading = false
                    rf2ethos.triggers.wasLoading = false
                    rf2ethos.dialogs.progressCounter = 0
                end
            end

        end
	end	

   -- trigger save
    if rf2ethos.triggers.triggerSAVE == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()

                    -- store current rf2ethos.Page in rf2ethos.PageTmp for later use
                    -- to stop has having to do a 'reload' of the page.
                    rf2ethos.PageTmp = {}
                    rf2ethos.PageTmp = rf2ethos.Page

                    rf2ethos.triggers.isSaving = true
                    rf2ethos.triggers.wasSaving = true

                    rf2ethos.triggers.triggerSAVE = false
                    rf2ethos.resetRates()
                    saveSettings()
                    return true

                end
            }, {
                label = "CANCEL",
                action = function()
                    rf2ethos.triggers.triggerSAVE = false
                    return true
                end
            }
        }
        local theTitle
        local theMsg
        if rf2ethos.escMode == true then
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

        rf2ethos.triggers.triggerSAVE = false
    end

    if rf2ethos.triggers.triggerRELOAD == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
                    rf2ethos.triggers.wasReloading = true
                    rf2ethos.triggers.createForm = true

                    rf2ethos.triggers.wasSaving = false
                    rf2ethos.triggers.wasLoading = false
                    rf2ethos.triggers.reloadRates = false

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

        rf2ethos.triggers.triggerRELOAD = false
    end

    if rf2ethos.triggers.triggerESCRELOAD == true then
        rf2ethos.triggers.triggerESCRELOAD = false
        rf2ethos.openESCFormLoader(rf2ethos.escManufacturer, rf2ethos.escScript)
    end
	


   -- Process outgoing TX packets and check for incoming frames
    -- Process outgoing TX packets and check for incoming frames
    updateTelemetryState()
end

function rf2ethos.paint()

end


function rf2ethos.create()

	rf2ethos.LCD_W,rf2ethos.LCD_H = lcd.getWindowSize()

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

    rf2ethos.ui.openMainMenu()

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
            rf2ethos.triggers.resetRates = false
            rf2ethos.escMode = false
            rf2ethos.escManufacturer = nil
            rf2ethos.escScript = nil
            rf2ethos.ui.openMainMenu()
            return true
        end
    end
    -- close esc pages menu
    if rf2ethos.escMenuState == 2 then
        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.triggers.resetRates = false
            rf2ethos.escMode = true
            rf2ethos.escManufacturer = nil
            rf2ethos.escScript = nil
            rf2ethos.ui.openPageESC(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            return true
        end
    end
    -- close esc tool menu
    if rf2ethos.escMenuState == 3 then
        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.triggers.resetRates = false
            rf2ethos.escMode = true
            rf2ethos.escScript = nil
            rf2ethos.escNotReadyCount = 0
            collectgarbage()
            rf2ethos.ui.openPageESCTool(rf2ethos.escManufacturer)
            return true
        end
    end

    if rf2ethos.uiState == rf2ethos.uiStatus.pages then

        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.triggers.resetRates = false
            rf2ethos.ui.openMainMenu()
            return true
        end
        if value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.triggers.resetRates = false
            rf2ethos.ui.openMainMenu()
            return true
        end
        if value == KEY_ENTER_LONG then
            if rf2ethos.dialogs.progressDisplay == true then rf2ethos.dialogs.progress:close() end
            if rf2ethos.dialogs.saveDisplay == true then rf2ethos.dialogs.save:close() end
            rf2ethos.triggers.triggerSAVE = true
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
    invalidatePages()
    rf2ethos.resetState()
    system.exit()
    return true
end

return rf2ethos
