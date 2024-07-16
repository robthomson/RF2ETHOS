-- RotorFlight + ETHOS LUA configuration

local config = {}
config.toolName = "RF2ETHOS"
config.toolDir = "/scripts/rf2ethos/"
config.logEnable = true
config.ethosVersion = 1510
config.luaVersion = "2.0.0 - 240625"
config.ethosVersionString = "ETHOS < V1.5.10"
config.environment = system.getVersion()
config.saveTimeout = nil
config.maxRetries = nil
config.apiVersion = 0
config.defaultRateTable = 4 -- ACTUAL
config.requestTimeout = nil
config.lcdWidth = nil
config.lcdHeight = nil
config.iconsizeParam = nil

local triggers = {}
triggers.isLoading = false
triggers.wasLoading = false
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


rf2ethos = {}
rf2ethos = assert(loadfile(config.toolDir .. "lib/rf2ethos.lua"))()

rf2ethos.config = {}
rf2ethos.config = config

rf2ethos.triggers = {}
rf2ethos.triggers = triggers

rf2ethos.utils = {}
rf2ethos.utils = assert(loadfile(config.toolDir .. "lib/utils.lua"))()

rf2ethos.ui = {}
rf2ethos.ui = assert(loadfile(config.toolDir .. "lib/ui.lua"))()

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
rf2ethos.radio = {}
rf2ethos.sensor = {}

rf2ethos.dialogs = {}
rf2ethos.dialogs.progress = false
rf2ethos.dialogs.progressDisplay = false
rf2ethos.dialogs.progressWatchDog = nil

rf2ethos.dialogs.save = false
rf2ethos.dialogs.saveDisplay = false
rf2ethos.dialogs.saveWatchDog = nil
rf2ethos.dialogs.saveProgressCounter = 0

rf2ethos.dialogs.nolink = false
rf2ethos.dialogs.nolinkDisplay = false
rf2ethos.dialogs.nolinkValue = 0

rf2ethos.dialogs.badversion = false
rf2ethos.dialogs.badversionDisplay = false


local function invalidatePages()
    rf2ethos.Page = nil
    rf2ethos.pageState = rf2ethos.pageStatus.display
    rf2ethos.saveTS = 0
    collectgarbage()
end


local function rebootFc()

    --rf2ethos.utils.log("Attempting to reboot the FC...")
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
    end,
    simulatorResponse = {}
}


function rf2ethos.dataBindFields()
    for i = 1, #rf2ethos.Page.fields do

		-- display progress loader when retrieving data
        if rf2ethos.dialogs.progressDisplay == true then
            local percent = (i / #rf2ethos.Page.fields) * 100
			-- we have to stop this happening on esc as we handle this
			-- differently
            if rf2ethos.triggers.triggerESCLOADER ~= true then
                rf2ethos.dialogs.progress:value(percent)		
            end
        end

        if rf2ethos.Page.values and #rf2ethos.Page.values >= rf2ethos.Page.minBytes then
            local f = rf2ethos.Page.fields[i]
            if f.vals then
                f.value = 0
                for idx = 1, #f.vals do
                    --local raw_val = rf2ethos.Page.values[f.vals[idx]] or 0
					-- inject header bytes if we have
					local raw_val = rf2ethos.Page.values[f.vals[idx]] or 0
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
    end
end

local mspSaveSettings = {
    processReply = function(self, buf)
        rf2ethos.settingsSaved()
    end
}

local mspLoadSettings = {
    processReply = function(self, buf)

        --rf2ethos.utils.log("rf2ethos.Page is processing reply for cmd " .. tostring(self.command) .. " len buf: " .. #buf .. " expected: " .. rf2ethos.Page.minBytes)


        rf2ethos.Page.values = buf
        if rf2ethos.Page.postRead then
            rf2ethos.Page.postRead(rf2ethos.Page)
        end
        rf2ethos.dataBindFields()
        if rf2ethos.Page.postLoad then
            rf2ethos.Page.postLoad(rf2ethos.Page)
        end
        rf2ethos.utils.log("rf2ethos.triggers.mspDataLoaded")
        rf2ethos.triggers.mspDataLoaded = true

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
			
            if rf2ethos.Page.preSave then
                payload = rf2ethos.Page.preSave(rf2ethos.Page)
            end
            if rf2ethos.Page.alterPayload then  
                payload = rf2ethos.Page.alterPayload(payload)
            end				
			
            mspSaveSettings.command = rf2ethos.Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            rf2ethos.mspQueue:add(mspSaveSettings)
            rf2ethos.mspQueue.errorHandler = function()
                displayMessage = {
                    title = "Save error",
                    text = "Make sure your heli is disarmed."
                }
				print("Save failed")
				rf2ethos.triggers.saveFailed = true
            end
        elseif type(rf2ethos.Page.write) == "function" then
            rf2ethos.Page.write(rf2ethos.Page)
        end

    end
end

local function requestPage()
    if not rf2ethos.Page.reqTS or rf2ethos.Page.reqTS + rf2ethos.protocol.pageReqTimeout <= os.clock() then
        rf2ethos.Page.reqTS = os.clock()
        if rf2ethos.Page.read then
            rf2ethos.readPage()
        end
    end
end



local function updateTelemetryState()

    if not rf2ethos.rssiSensor then
        rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.noSensor
    elseif rf2ethos.getRSSI() == 0 then
        rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.noTelemetry
    else
        rf2ethos.triggers.telemetryState = rf2ethos.telemetryStatus.ok
    end

end


-- WAKEUP:  Called every ~30-50ms by the main Ethos software loop
function wakeup(widget)


    -- exit app called : quick abort
    -- as we dont need to run the rest of the stuff
    if rf2ethos.triggers.exitAPP == true then
        rf2ethos.triggers.exitAPP = false
        form.invalidate()
        system.exit()
        return
    end

	if rf2ethos.uiState == rf2ethos.uiStatus.mainMenu then
		invalidatePages()
	end

    -- ethos version
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
	
	if rf2ethos.triggers.closeSave == true then
	
		if (rf2ethos.dialogs.saveProgressCounter <= 100 ) then
			rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 30
		end
		rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)	
				
		if rf2ethos.dialogs.saveProgressCounter >= 100 then
			rf2ethos.triggers.closeSave = false
			rf2ethos.dialogs.saveProgressCounter = 0
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil			
			rf2ethos.dialogs.save:close()		
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

            if rf2ethos.triggers.escPowerCycleLoader <= 95 then
                rf2ethos.dialogs.progress:message("Please power cycle the esc")
            else
                rf2ethos.dialogs.progress:message("Aborting...")
            end
            rf2ethos.dialogs.progress:value(rf2ethos.triggers.escPowerCycleLoader)

            rf2ethos.triggers.escPowerCycleLoader = rf2ethos.triggers.escPowerCycleLoader + 0.5

			if rf2ethos.mspQueue:isProcessed() then
				requestPage()
			end
			

            if rf2ethos.triggers.escPowerCycleLoader >= 100 then
                rf2ethos.triggers.escPowerCycleLoader = 0
                rf2ethos.dialogs.progress:close()
                rf2ethos.triggers.triggerESCLOADER = false
                rf2ethos.triggers.triggerESCMAINMENU = true
            end
			
			

        end
    end

    -- capture profile switching and trigger a reload if needs be
    if rf2ethos.Page ~= nil and rf2ethos.uiState == rf2ethos.uiStatus.pages then
        if rf2ethos.Page.refreshswitch == true then

            if rf2ethos.lastPage ~= "rates.lua" then
                if profileswitchParam ~= nil then

                    if profileswitchParam:value() ~= rf2ethos.triggers.profileswitchLast then

                        if rf2ethos.dialogs.progressDisplay == true or rf2ethos.dialogs.saveDisplay == true then
                            -- switch has been toggled mid flow - this is bad.. clean upd
                            if rf2ethos.dialogs.progressDisplay == true then
                                rf2ethos.dialogs.progress:close()
                            end
                            if rf2ethos.dialogs.saveDisplay == true then
                                rf2ethos.dialogs.save:close()
                            end
                            form.clear()
                            rf2ethos.triggers.wasReloading = true
                            rf2ethos.triggers.createForm = true
                            rf2ethos.triggers.wasSaving = false
                            rf2ethos.triggers.wasLoading = false
                            rf2ethos.triggers.reloadRates = false

                        else

                            rf2ethos.triggers.profileswitchLast = profileswitchParam:value()
                            -- trigger RELOAD
                            --rf2ethos.utils.log("Profile switch reload")
                            if config.environment.simulation ~= true then
                                rf2ethos.triggers.wasReloading = true
                                rf2ethos.triggers.createForm = true
                                rf2ethos.triggers.wasSaving = false
                                rf2ethos.triggers.wasLoading = false
                                rf2ethos.triggers.reloadRates = false

                            end
                            return true

                        end
                    end
                end
            end

            -- capture profile switching and trigger a reload if needs be
            if rf2ethos.lastPage == "rates.lua" then
                if rateswitchParam ~= nil then
                    if rateswitchParam:value() ~= rf2ethos.triggers.rateswitchLast then

                        if rf2ethos.dialogs.progressDisplay == true or rf2ethos.dialogs.saveDisplay == true then
                            -- switch has been toggled mid flow - this is bad.. clean upd
                            if rf2ethos.dialogs.progressDisplay == true then
                                rf2ethos.dialogs.progress:close()
                            end
                            if rf2ethos.dialogs.saveDisplay == true then
                                rf2ethos.dialogs.save:close()
                            end
                            form.clear()
                            rf2ethos.triggers.wasReloading = true
                            rf2ethos.triggers.createForm = true
                            rf2ethos.triggers.wasSaving = false
                            rf2ethos.triggers.wasLoading = false
                            rf2ethos.triggers.reloadRates = false

                        else
                            rf2ethos.triggers.rateswitchLast = rateswitchParam:value()

                            -- trigger RELOAD
                            --rf2ethos.utils.log("Rate switch reload")
                            if config.environment.simulation ~= true then
                                rf2ethos.triggers.wasSaving = false
                                rf2ethos.triggers.wasLoading = false

                                rf2ethos.triggers.wasReloading = false

                                rf2ethos.triggers.createForm = true
                                rf2ethos.triggers.reloadRates = true
                            end
                            return true
                        end

                    end
                end
            end

        end
    end

    -- check telemetry state and overlay dialog if not linked
    if rf2ethos.triggers.escPowerCycle == true then
        -- ESC MODE - WE NEVER TIME OUT AS DO A 'RETRY DIALOG'
        -- AS SOME ESC NEED TO BE CONNECTING AS YOU POWER UP to
        -- INIT CONFIG MODE

    else
        if config.environment.simulation ~= true then
            if rf2ethos.triggers.telemetryState ~= 1 then
                if rf2ethos.dialogs.nolinkDisplay == false then
                    rf2ethos.dialogs.nolinkDisplay = true
                    noLinkDialog = form.openProgressDialog("Connecting", "Waiting for a link to the flight controller")
                    noLinkDialog:closeAllowed(false)
                    noLinkDialog:value(0)
                    rf2ethos.dialogs.nolinkValue = 0
                end
            end

            if rf2ethos.dialogs.nolinkDisplay == true or rf2ethos.triggers.telemetryState == 1 then

                if rf2ethos.triggers.telemetryState == 1 then
                    rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 20
                else
                    rf2ethos.dialogs.nolinkValue = rf2ethos.dialogs.nolinkValue + 1
                end
                if rf2ethos.dialogs.nolinkValue > 100 then
                    noLinkDialog:close()
                    rf2ethos.dialogs.nolinkValue = 0
                    rf2ethos.dialogs.nolinkDisplay = false
                    if rf2ethos.triggers.telemetryState ~= 1 then
                        rf2ethos.triggers.exitAPP = true
                    end
                end
                noLinkDialog:value(rf2ethos.dialogs.nolinkValue)
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

    -- some watchdogs to enable close buttons on save and progress if they time-out
    if rf2ethos.dialogs.saveDisplay == true then
        if rf2ethos.dialogs.saveWatchDog ~= nil then
			-- watchdog will always kick in 5s after protocol timeout settings
            if (os.clock() - rf2ethos.dialogs.saveWatchDog) > (rf2ethos.protocol.saveTimeout + 5) then
                rf2ethos.dialogs.save:closeAllowed(true)
            end
        end
    end


	if rf2ethos.dialogs.progressDisplay == true then
		if rf2ethos.dialogs.progressWatchDog ~= nil then
		
			if rf2ethos.triggers.escPowerCycle == true then
				if (os.clock() - rf2ethos.dialogs.progressWatchDog) > (rf2ethos.protocol.pageReqTimeout + 30) then
					rf2ethos.dialogs.progress:message("Error.. we timed out")
					rf2ethos.dialogs.progress:closeAllowed(true)
				end
			else
				if (os.clock() - rf2ethos.dialogs.progressWatchDog) > (rf2ethos.protocol.pageReqTimeout + 5) then
						rf2ethos.dialogs.progress:message("Error.. we timed out")
						rf2ethos.dialogs.progress:closeAllowed(true)	
				end
			end
			
		end
	end



    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    updateTelemetryState()


    if rf2ethos.uiState == rf2ethos.uiStatus.pages then
        if rf2ethos.prevUiState ~= rf2ethos.uiState then
            rf2ethos.prevUiState = rf2ethos.uiState
        end

        if rf2ethos.pageState == rf2ethos.pageStatus.saving then
            if (rf2ethos.saveTS + rf2ethos.protocol.saveTimeout) < os.clock() then
				--invalidatePages()
				rf2ethos.dataBindFields()
            end
        end
        if not rf2ethos.Page then
            if rf2ethos.escMode == true then
                if rf2ethos.escScript ~= nil then
                    rf2ethos.Page = assert(loadfile(rf2ethos.config.toolDir .. "esc/" .. rf2ethos.escManufacturer .. "/pages/" .. rf2ethos.escScript))()
                else
                    --rf2ethos.utils.log("rf2ethos.escScript is not present so cannot load as expected")
                end
            else
                if rf2ethos.lastPage ~= nil then
                    rf2ethos.Page = assert(loadfile(rf2ethos.config.toolDir .. "pages/" .. rf2ethos.lastPage))()
                end
                rf2ethos.escManufacturer = nil
                rf2ethos.escScript = nil
                rf2ethos.escMode = false
            end
            collectgarbage()
        end
		if rf2ethos.Page ~= nil then
			if not (rf2ethos.Page.values) and rf2ethos.pageState == rf2ethos.pageStatus.display then
				requestPage()
			end
		end	
    end

    if rf2ethos.uiState ~= rf2ethos.uiStatus.mainMenu then
        if rf2ethos.config.environment.simulation == true or (rf2ethos.triggers.mspDataLoaded == true and rf2ethos.mspQueue:isProcessed() and (rf2ethos.Page.values)) then
            rf2ethos.triggers.mspDataLoaded = false
            rf2ethos.triggers.isLoading = false
            rf2ethos.triggers.wasLoading = true
            if config.environment.simulation ~= true then
                rf2ethos.triggers.createForm = true
            end
        end
    end
	
    if rf2ethos.triggers.createForm == true and rf2ethos.mspQueue:isProcessed() then

        if (rf2ethos.triggers.wasSaving == true) or config.environment.simulation == true then

            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
			
            rf2ethos.triggers.wasSaving = false
           
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
            
			if rf2ethos.triggers.saveFailed == false then
				-- mark save complete so we can speed up progress dialog for	
				rf2ethos.triggers.closeSave = true
            end

		
        elseif (rf2ethos.triggers.wasLoading == true) or config.environment.simulation == true then
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
        elseif rf2ethos.triggers.wasReloading == true or config.environment.simulation == true then
            rf2ethos.triggers.wasReloading = false
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
        elseif rf2ethos.triggers.reloadRates == true or config.environment.simulation == true then
            rf2ethos.ui.openPageRATESLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
        else
            rf2ethos.ui.openMainMenu()
        end

        rf2ethos.triggers.createForm = false
    else
        rf2ethos.triggers.createForm = false
    end


    if rf2ethos.triggers.isSaving then

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
                rf2ethos.dialogs.save:message("Saving...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.eepromWrite then
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
                rf2ethos.dialogs.save:message("Saving...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.rebooting then
                saveMsg = rf2ethos.dialogs.save:message("Rebooting...")
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter)
                if rf2ethos.dialogs.saveProgressCounter >= 100 then
                    rf2ethos.dialogs.save:close()
                    invalidatePages()
                    rf2ethos.triggers.wasReloading = true
                    rf2ethos.triggers.createForm = true
                    rf2ethos.triggers.wasSaving = false
                    rf2ethos.triggers.wasLoading = false
                    rf2ethos.triggers.reloadRates = false

                end
            end
			rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 5
		
        else
            rf2ethos.triggers.isSaving = false
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
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
                    if config.environment.simulation ~= true then
                        rf2ethos.triggers.wasReloading = true
                        rf2ethos.triggers.createForm = true

                        rf2ethos.triggers.wasSaving = false
                        rf2ethos.triggers.wasLoading = false
                        rf2ethos.triggers.reloadRates = false

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

        rf2ethos.triggers.triggerRELOAD = false
    end

    if rf2ethos.triggers.triggerESCRELOAD == true then
        rf2ethos.triggers.triggerESCRELOAD = false
        rf2ethos.openESCFormLoader(rf2ethos.escManufacturer, rf2ethos.escScript)
    end
	

    -- this needs to run on every wakeup event.
    rf2ethos.mspQueue:processQueue()

end


local function create()

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
                        if not rf2ethos.rssiSensor then
                            rf2ethos.rssiSensor = system.getSource("RSSI Ext")
                        end
                    end
                end
            end
        end
    end

    rf2ethos.config.lcdWidth, rf2ethos.config.lcdHeight = rf2ethos.utils.getWindowSize()
    rf2ethos.protocol = assert(loadfile(rf2ethos.config.toolDir .. "protocols.lua"))()
    rf2ethos.radio = assert(loadfile(rf2ethos.config.toolDir .. "radios.lua"))().msp
    rf2ethos.mspQueue = assert(loadfile(rf2ethos.config.toolDir .. "msp/mspQueue.lua"))()
    rf2ethos.mspQueue.maxRetries = rf2ethos.protocol.maxRetries
    rf2ethos.mspHelper = assert(loadfile(rf2ethos.config.toolDir .. "msp/mspHelper.lua"))()
    assert(loadfile(rf2ethos.protocol.mspTransport))()
    assert(loadfile(rf2ethos.config.toolDir .. "msp/common.lua"))()

    rf2ethos.fieldHelpTxt = assert(loadfile(rf2ethos.config.toolDir .. "help/fields.lua"))()

    rf2ethos.uiState = rf2ethos.uiStatus.init

    config.apiVersion = 0


    rf2ethos.ui.openMainMenu()

end

-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)

    --rf2ethos.utils.log("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

    if value == EVT_VIRTUAL_PREV_LONG then
        print("Forcing exit")
        invalidatePages()
        system.exit()
        return 0
    end

    -- close esc main type selection menu
    if rf2ethos.escMenuState == 1 then
        if category == 5 or value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
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
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
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
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
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
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
            rf2ethos.triggers.resetRates = false
            rf2ethos.ui.openMainMenu()
            return true
        end
        if value == 35 then
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
            rf2ethos.triggers.resetRates = false
            rf2ethos.ui.openMainMenu()
            return true
        end
        if value == KEY_ENTER_LONG then
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
            rf2ethos.triggers.triggerSAVE = true
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end

    end

    if rf2ethos.uiState == rf2ethos.uiStatus.MainMenu then
        if value == KEY_ENTER_LONG then
            if rf2ethos.dialogs.progressDisplay == true then
                rf2ethos.dialogs.progress:close()
            end
            if rf2ethos.dialogs.saveDisplay == true then
                rf2ethos.dialogs.save:close()
            end
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end
    end

    return false
end


local function close()
	invalidatePages()
    rf2ethos.resetState()
    system.exit()
    return true
end

local icon = lcd.loadMask(config.toolDir .. "RF.png")

local function init()
    system.registerSystemTool({event = event, name = config.toolName, icon = icon, create = create, wakeup = wakeup, close = close})
end

return {init = init}
