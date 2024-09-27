local app = {}

local arg = {...}

local config = arg[1]
local compile = arg[2]

local triggers = {}
triggers.exitAPP = false
triggers.noRFMsg = false
triggers.triggerSave = false
triggers.triggerReload = false
triggers.triggerReloadNoPrompt = false
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
triggers.mspBusy = false
triggers.disableRssiTimeout = false
triggers.timeIsSet = false


app.compile = compile


app.config = {}
app.config = config
app.config.tailMode = nil
app.config.swashMode = nil
app.config.activeProfile = nil
app.config.activeRateProfile = nil
app.config.servoCount = nil
app.config.servoOverride = nil

app.triggers = {}
app.triggers = triggers


app.ui = {}
app.ui = assert(loadfile(config.toolDir .. "lib/ui.lua"))(config, compile)

app.formFields = {}
app.formNavigationFields = {}
app.PageTmp = {}
app.Page = {}
app.saveTS = 0
app.lastPage = nil
app.lastSection = nil
app.lastIdx = nil
app.lastTitle = nil
app.lastScript = nil
app.gfx_buttons = {}
app.uiStatus = {init = 1, mainMenu = 2, pages = 3, confirm = 4}
app.pageStatus = {display = 1, editing = 2, saving = 3, eepromWrite = 4, rebooting = 5}
app.telemetryStatus = {ok = 1, noSensor = 2, noTelemetry = 3}
app.uiState = app.uiStatus.init
app.pageState = app.pageStatus.display
app.lastLabel = nil
app.NewRateTable = nil
app.RateTable = nil
app.fieldHelpTxt = nil
app.protocol = {}
app.protocolTransports = {}
app.radio = {}
app.sensor = {}
app.init = nil
app.guiIsRunning = false
app.wakeupSchedulerUI = os.clock()
app.wakeupSchedulerUIInit = false
app.wakeupSchedulerForm = os.clock()
app.wakeupSchedulerFormInit = false
app.menuLastSelected = {}
app.adjfunctions = nil

app.preferences = {}

app.audio = {}
app.audio.playDemo = false
app.audio.playConnecting = false
app.audio.playConnected = false
app.audio.playTimeout = false
app.audio.playSaving = false
app.audio.playLoading = false
app.audio.playEscPowerCycle = false
app.audio.playServoOverideDisable = false
app.audio.playServoOverideEnable = false
app.audio.playMixerOverideDisable = false
app.audio.playMixerOverideEnable = false
app.audio.playEraseFlash = false

app.dialogs = {}
app.dialogs.progress = false
app.dialogs.progressDisplay = false
app.dialogs.progressWatchDog = nil
app.dialogs.progressCounter = 0
app.dialogs.progressRateLimit = os.clock()
app.dialogs.progressRate = 0.2 -- how many times per second we can change dialog value

app.dialogs.progressESC = false
app.dialogs.progressDisplayEsc = false
app.dialogs.progressWatchDogESC = nil
app.dialogs.progressCounterESC = 0
app.dialogs.progressESCRateLimit = os.clock()
app.dialogs.progressESCRate = 2.5 -- how many times per second we can change dialog value

app.dialogs.save = false
app.dialogs.saveDisplay = false
app.dialogs.saveWatchDog = nil
app.dialogs.saveProgressCounter = 0
app.dialogs.saveRateLimit = os.clock()
app.dialogs.saveRate = 0.2 -- how many times per second we can change dialog value

app.dialogs.nolink = false
app.dialogs.nolinkDisplay = false
app.dialogs.nolinkValueCounter = 0
app.dialogs.nolinkRateLimit = os.clock()
app.dialogs.nolinkRate = 0.2 -- how many times per second we can change dialog value

app.dialogs.badversion = false
app.dialogs.badversionDisplay = false

app.config.saveTimeout = nil
app.config.requestTimeout = nil
app.config.maxRetries = nil
app.config.lcdWidth = nil
app.config.lcdHeight = nil
app.config.iconsizeParam = nil
app.config.ethosRunningVersion = nil

-- make the tx run with no fbl connected
if config.simulateOnTransmitter == true or system:getVersion().simulation == true then
    app.runningInSimulator = true
else
    app.runningInSimulator = system:getVersion().simulation
end

-- RETURN THE CURRENT RSSI SENSOR VALUE 
function app.getRSSI()
    if app.runningInSimulator == true or app.config.skipRssiSensorCheck == true then return 100 end

    if app.rssiSensor ~= nil then
    
        if app.rssiSensor:state() == true then
            local value = app.rssiSensor:value()
            return value
        else
            return 0
        end
    end
    return 0
end

-- RESET ALL VALUES TO DEFAULTS. FUNCTION IS CALLED WHEN THE CLOSE EVENT RUNS
function app.resetState()

    config.useCompiler = true
    app.config.useCompiler = true
    pageLoaded = 100
    pageTitle = nil
    pageFile = nil
    app.triggers.exitAPP = false
    app.triggers.noRFMsg = false
    app.dialogs.nolinkDisplay = false
    app.dialogs.nolinkValueCounter = 0
    app.triggers.telemetryState = nil
    app.triggers.badMspVersionDisplay = false
    app.triggers.badMspVersion = false
    app.dialogs.progressDisplayEsc = false
    ELRS_PAUSE_TELEMETRY = false
    CRSF_PAUSE_TELEMETRY = false
    --app.config.tailMode = nil
    --app.config.apiVersion = nil
    app.audio = {}
    --app.config.servoOverride = nil

end

-- CHECK IF THE PROFILE SWITCH HAS CHANGED STATE
function app.profileSwitchCheck()

    -- load and cache the switch on first run
    if app.config.profileswitchParamPreference == nil then
        app.config.profileswitchParamPreference = app.preferences.interface.profileSwitch
        local s = rf2ethos.utils.explode(app.config.profileswitchParamPreference, ",")
        app.config.profileswitchParam = system.getSource({category = s[1], member = s[2]})
    end
    -- store the last state
    if app.config.profileswitchParam ~= nil then app.triggers.profileswitchLast = app.config.profileswitchParam:value() end
end

-- CHECK IF THE RATE SWITCH HAS CHANGED STATE
function app.rateSwitchCheck()

    -- load and cache the switch on first run
    if app.config.rateswitchParamPreference == nil then
        app.config.rateswitchParamPreference = app.preferences.interface.rateSwitch
        local s = rf2ethos.utils.explode(app.config.rateswitchParamPreference, ",")
        app.config.rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    -- store the last state	
    if app.config.rateswitchParam ~= nil then app.triggers.rateswitchLast = app.config.rateswitchParam:value() end
end

-- SAVE FIELD VALUE FOR ETHOS FROM ETHOS FORMS INTO THE ACTUAL FORMAT THAT 
-- WILL BE TRANSMITTED OVER MSP
function app.saveValue(currentField)

    local f = app.Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do app.Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8) end
    if f.upd and app.Page.values then f.upd(app.Page) end
end

-- ITERATE OVER THE FIELD DATA AND UPDATE ALL VALUES FOR DISPLAY PURPOSES
function app.dataBindFields()
    if app.Page.fields then
        for i = 1, #app.Page.fields do

            if app.Page.values and #app.Page.values >= app.Page.minBytes then
                local f = app.Page.fields[i]
                if f.vals then
                    f.value = 0
                    for idx = 1, #f.vals do
                        local raw_val = app.Page.values[f.vals[idx]] or 0
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
        rf2ethos.utils.log("Unable to bind fields as app.Page.fields does not exist")
    end
end

-- GRAB THE SPORT TELEMETRY FRAME
function app.sportTelemetryPop()
    -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
    local frame = app.sensor:popFrame()
    if frame == nil then return nil, nil, nil, nil end
    -- physId = physical / remote sensor Id (aka sensorId)
    --   0x00 for FPORT, 0x1B for SmartPort
    -- primId = frame ID  (should be 0x32 for reply frames)
    -- appId = data Id
    return frame:physId(), frame:primId(), frame:appId(), frame:value()
end



-- RETURN CURRENT LCD SIZE
function app.getWindowSize()
    return lcd.getWindowSize()
end

-- INAVALIDATE THE PAGES VARIABLE. TYPICALLY CALLED AFTER WRITING MSP DATA
local function invalidatePages()
    app.Page = nil
    app.pageState = app.pageStatus.display
    app.saveTS = 0
    collectgarbage()
end

-- ISSUE AN MSP COMNMAND TO REBOOT THE FBL UNIT
local function rebootFc()

    app.pageState = app.pageStatus.rebooting
    app.mspQueue:add({
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
        if app.Page.reboot then
            rebootFc()
        else
            invalidatePages()
        end
        app.triggers.closeSave = true
    end,
    simulatorResponse = {}
}

-- SAVE ALL SETTINGS 
function app.settingsSaved()

    -- check if this page requires writing to eeprom to save (most do)
    if app.Page and app.Page.eepromWrite then
        -- don't write again if we're already responding to earlier page.write()s
        if app.pageState ~= app.pageStatus.eepromWrite then
            app.pageState = app.pageStatus.eepromWrite
            app.mspQueue:add(mspEepromWrite)
        end
    elseif app.pageState ~= app.pageStatus.eepromWrite then
        -- If we're not already trying to write to eeprom from a previous save, then we're done.
        invalidatePages()
        app.triggers.closeSave = true

    end
end

-- WRAPPER FUNCTION USED TO TRIGGER SAVE SETTINGS
local mspSaveSettings = {
    processReply = function(self, buf)
        app.settingsSaved()
    end
}

-- WRAPPER FUNCTION USED TO TRIGGER LOAD SETTINGS
local mspLoadSettings = {
    processReply = function(self, buf)

        if app.Page.minBytes == nil then app.Page.minBytes = 0 end
        rf2ethos.utils.log("app.Page is processing reply for cmd " .. tostring(self.command) .. " len buf: " .. #buf .. " expected: " .. app.Page.minBytes)
        if app.Page ~= nil then
            app.Page.values = buf
            if app.Page.postRead then app.Page.postRead(app.Page) end
            app.dataBindFields()
            if app.Page.postLoad then app.Page.postLoad(app.Page) end
            rf2ethos.utils.log("app.triggers.isReady")
        else
            rf2ethos.utils.log("app.triggers.isReady app.Page is nil?")
        end

    end
}

-- READ AN MSP PAGE
function app.readPage()
    if type(app.Page.read) == "function" then
        app.Page.read(app.Page)
    else
        mspLoadSettings.command = app.Page.read
        mspLoadSettings.simulatorResponse = app.Page.simulatorResponse
        app.mspQueue:add(mspLoadSettings)
    end
end

-- SAVE ALL SETTINGS 
local function saveSettings()

    if app.pageState ~= app.pageStatus.saving then
        app.pageState = app.pageStatus.saving
        app.saveTS = os.clock()

        if app.Page.values then
            local payload = app.Page.values

            if app.Page.preSave then payload = app.Page.preSave(app.Page) end
            if app.Page.preSavePayload then payload = app.Page.preSavePayload(payload) end

            if app.config.mspTxRxDebug == true or app.config.logEnable == true then

                local logData = "Saving:        {" .. rf2ethos.utils.joinTableItems(payload, ", ") .. "}"

                rf2ethos.utils.log(logData)

                if app.config.mspTxRxDebug == true then print(logData) end

            end

            mspSaveSettings.command = app.Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            app.mspQueue:add(mspSaveSettings)
            app.mspQueue.errorHandler = function()
                print("Save failed")
                app.triggers.saveFailed = true
            end
        elseif type(app.Page.write) == "function" then
            app.Page.write(app.Page)
        end

    end
end

-- REQUEST A PAGE OVER MSP. THIS RUNS ON MOST CLOCK CYCLES WHEN DATA IS BEING REQUESTED
local function requestPage()

    if not app.Page.reqTS or app.Page.reqTS + app.protocol.pageReqTimeout <= os.clock() then
        app.Page.reqTS = os.clock()
        if app.Page.read then app.readPage() end
    end
end

-- UPDATE CURRENT TELEMETRY STATE - RUNS MOST CLOCK CYCLES
function app.updateTelemetryState()

   
    if app.runningInSimulator ~= true then
        if not app.rssiSensor then
            app.triggers.telemetryState = app.telemetryStatus.noSensor
        elseif app.getRSSI() == 0 then
            app.triggers.telemetryState = app.telemetryStatus.noTelemetry
        else
            app.triggers.telemetryState = app.telemetryStatus.ok
        end
    else
        app.triggers.telemetryState = app.telemetryStatus.ok
    end

end

-- PAINT.  HOOK INTO PAINT FUNCTION TO ALLOW lcd FUNCTIONS TO BE USED
-- NOTE. this function will only be called if lcd.refesh is triggered. it is not a wakeup function
function app.paint()

    -- run the modules paint function if it exists
    if app.Page ~= nil then if app.Page.paint then app.Page.paint(app.Page) end end
end

-- MAIN WAKEUP FUNCTION. THIS SIMPLY FARMS OUT AT DIFFERING SCHEDULES TO SUB FUNCTIONS
function app.wakeup(widget)

    app.guiIsRunning = true

    -- keep cpu load down by running UI at reduced interval
    local now = os.clock()
    if (now - app.wakeupSchedulerUI) >= 0.02 or app.wakeupSchedulerUIInit == true then
        app.wakeupSchedulerUI = now
        app.wakeupUI()
        app.wakeupSchedulerUIInit = false
    end

    -- keep cpu load down by running Form at reduced interval
    local now = os.clock()
    if (now - app.wakeupSchedulerForm) >= 0.025 or app.wakeupSchedulerFormInit == true then
        app.wakeupSchedulerForm = now
        app.wakeupForm()
        app.wakeupSchedulerFormInit = false
    end


end
       



-- WAKEUPFORM.  RUN A FUNCTION CALLED wakeup THAT IS RETURNED WHEN REQUESTING A PAGE
-- THIS ESSENTIALLY GIVES US A TIMER THAT CAN BE USED BY A PAGE THAT HAS LOADED TO
-- HANDLE BACKGROUND PROCESSING
function app.wakeupForm()
    if app.Page ~= nil and app.uiState == app.uiStatus.pages then
        if app.Page.wakeup then
            -- run the pages wakeup function if it exists
            app.Page.wakeup(app.Page)
        end
    end
end

-- WAKUP UI.  UI RUNS AT LOWER INTERVAL, TO SAVE CPU POWER.
-- THE GUTS OF ETHOS FORMS IS HANDLED WITHIN THIS FUNCTION
function app.wakeupUI()

    -- exit app called : quick abort
    -- as we dont need to run the rest of the stuff
    if app.triggers.exitAPP == true then
        app.triggers.exitAPP = false
        form.invalidate()
        system.exit()
        return
    end

    -- close progress loader.  this essentially just accelerates 
    -- the close of the progress bar once the data is loaded.
    -- so if not yet at 100%.. it says.. move there quickly
    if app.triggers.closeProgressLoader == true then
        if app.dialogs.progressCounter <= 100 then
            app.dialogs.progressCounter = app.dialogs.progressCounter + 10
            if app.dialogs.progress ~= nil then app.ui.progessDisplayValue(app.dialogs.progressCounter) end
        end

        if app.dialogs.progressCounter >= 101 then
            app.dialogs.progressWatchDog = nil
            app.dialogs.progressDisplay = false
            if app.dialogs.progress ~= nil then app.ui.progessDisplayClose() end
            app.dialogs.progressCounter = 0
            app.triggers.closeProgressLoader = false
        end
    end

    -- close save loader.  this essentially just accelerates 
    -- the close of the progress bar once the data is loaded.
    -- so if not yet at 100%.. it says.. move there quickly
    if app.triggers.closeSave == true then
        app.triggers.isSaving = false

        if app.mspQueue:isProcessed() then
            if (app.dialogs.saveProgressCounter > 40 and app.dialogs.saveProgressCounter <= 80) then
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 10
            else
                app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 5
            end
        end

        if app.dialogs.save ~= nil then app.ui.progessDisplaySaveValue(app.dialogs.saveProgressCounter) end

        if app.dialogs.saveProgressCounter >= 100 and app.mspQueue:isProcessed() then
            app.triggers.closeSave = false
            app.dialogs.saveProgressCounter = 0
            app.dialogs.saveDisplay = false
            app.dialogs.saveWatchDog = nil
            if app.dialogs.save ~= nil then
                app.ui.progessDisplaySaveClose()

                if app.config.reloadOnSave == true then app.triggers.triggerReloadNoPrompt = true end

            end
        end
    end

    -- close progress loader when in sim.  
    -- the simulator cannot save - so we fake the whole process
    if app.triggers.closeSaveFake == true then
        app.triggers.isSaving = false

        app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 10

        if app.dialogs.save ~= nil then app.ui.progessDisplaySaveValue(app.dialogs.saveProgressCounter) end

        if app.dialogs.saveProgressCounter >= 100 then
            app.triggers.closeSaveFake = false
            app.dialogs.saveProgressCounter = 0
            app.dialogs.saveDisplay = false
            app.dialogs.saveWatchDog = nil
            app.ui.progessDisplaySaveClose()
        end
    end

    -- profile switching - trigger a reload if needs be when the switch is toggled

    if app.Page ~= nil and app.Page.refreshswitch == true and app.uiState == app.uiStatus.pages then

        -- capture profile switching and of rates pages
        if app.lastPage == "rates.lua" or app.lastPage == "rates_advanced.lua" or app.lastPage == "select_profile.lua" then
            if app.config.rateswitchParam ~= nil then
                if app.config.rateswitchParam:value() ~= app.triggers.rateswitchLast then

                    if app.ui.progressDisplay() then
                        -- switch has been toggled mid flow - this is bad.. clean upd
                        form.clear()
                        app.triggers.triggerReloadNoPrompt = true

                    else
                        -- trigger RELOAD
                        app.triggers.rateswitchLast = app.config.rateswitchParam:value()
                        app.triggers.triggerReloadNoPrompt = true
                        return true
                    end

                end
            end
            -- capture switching of all profile pages - excluding rates	
        else
            if app.config.profileswitchParam ~= nil then

                if app.config.profileswitchParam:value() ~= app.triggers.profileswitchLast then

                    if app.ui.progressDisplay() then
                        -- switch has been toggled mid flow - this is bad.. clean upd
                        form.clear()
                        app.triggers.triggerReloadNoPrompt = true
                    else
                        -- trigger RELOAD
                        app.triggers.profileswitchLast = app.config.profileswitchParam:value()
                        app.triggers.triggerReloadNoPrompt = true
                        return true

                    end

                end
            end
        end
    end

    -- if we do not have a telemetry link then we need to show a connecting dialog box.
    -- this runs at all times except when we are displaying the esc search box.  we then
    -- supress this one and display a different one as timeouts and process is different
    if app.triggers.telemetryState ~= 1 and app.triggers.disableRssiTimeout == false then

        if app.dialogs.progress then app.ui.progessDisplayClose() end
        if app.dialogs.save then app.ui.progessDisplaySaveClose() end

        if app.dialogs.nolinkDisplay == false then app.ui.progessNolinkDisplay() end
    end

    -- this is directly related to the loop above.  if the progress box is visible we then wait for a telemetry link
    -- to be established - and associated msp version checks to finish. all the while incremeting the loader
    -- until we time out.
    -- if (app.dialogs.nolinkDisplay == true or app.triggers.telemetryState == 1) and app.dialogs.progressDisplayEsc ~= true then
    if (app.dialogs.nolinkDisplay == true) and app.triggers.disableRssiTimeout == false then
        if app.triggers.telemetryState == 1 then
            app.dialogs.nolinkValueCounter = app.dialogs.nolinkValueCounter + 20
        else
            app.dialogs.nolinkValueCounter = app.dialogs.nolinkValueCounter + 10
        end

        if app.dialogs.nolinkValueCounter >= 101 then

            if app.config.apiVersion == nil and app.getRSSI() ~= 0 then
                app.ui.progessNolinkDisplayClose()
                app.dialogs.nolinkValueCounter = 0
                app.dialogs.nolinkDisplay = false
            else
                app.ui.progessNolinkDisplayClose()
                app.dialogs.nolinkValueCounter = 0
                app.dialogs.nolinkDisplay = false

                if app.runningInSimulator ~= true then
                    if app.triggers.telemetryState ~= 1 then
                        app.audio.playTimeout = true
                        app.triggers.exitAPP = true
                    else
                        if app.triggers.badMspVersion ~= true then app.audio.playConnected = true end
                    end
                else
                    if app.triggers.badMspVersion ~= true then app.audio.playConnected = true end
                end
 
            end
        end
        app.ui.progessDisplayNoLinkValue(app.dialogs.nolinkValueCounter)
    end

    -- a watchdog to enable the close button when saving data if we exheed the save timout
    if app.config.watchdogParam ~= nil and app.config.watchdogParam ~= 1 then app.protocol.saveTimeout = app.config.watchdogParam end
    if app.dialogs.saveDisplay == true then
        if app.dialogs.saveWatchDog ~= nil then
            if (os.clock() - app.dialogs.saveWatchDog) > (tonumber(app.protocol.saveTimeout)) or (app.dialogs.saveProgressCounter > 100 and app.mspQueue:isProcessed()) then
                app.audio.playTimeout = true
                app.ui.progessDisplaySaveMessage("Error.. we timed out")
                app.ui.progessDisplaySaveCloseAllowed(true)
                app.dialogs.save:value(100)
                app.dialogs.saveProgressCounter = 0
                app.dialogs.saveDisplay = false
                app.triggers.isSaving = false

                app.Page = app.PageTmp
                app.PageTmp = {}
            end
        end
    end

    -- a watchdog to enable the close button on a progress box dialog when loading data from the fbl
    if app.dialogs.progressDisplay == true and app.dialogs.progressWatchDog ~= nil then

        -- if app.config.watchdogParam ~= nil and app.config.watchdogParam ~= 1 
        --	then app.protocol.pageReqTimeout = app.config.watchdogParam 
        -- end

        app.dialogs.progressCounter = app.dialogs.progressCounter + 2
        app.ui.progessDisplayValue(app.dialogs.progressCounter)

        if (os.clock() - app.dialogs.progressWatchDog) > (tonumber(app.protocol.pageReqTimeout)) then

            app.audio.playTimeout = true

            if app.dialogs.progress ~= nil then
                app.ui.progessDisplayMessage("Error.. we timed out")
                app.ui.progessDisplayCloseAllowed(true)
            end

            -- switch back to original page values
            app.Page = app.PageTmp
            app.PageTmp = {}
            app.dialogs.progressCounter = 0
            app.dialogs.progressDisplay = false
        end

    end

    -- a save was triggered - popup a box asking to save the data
    if app.triggers.triggerSave == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()

                    app.audio.playSaving = true

                    -- we have to fake a save dialog in sim as its not actually possible 
                    -- to save in sim!
                    if app.runningInSimulator ~= true then
                        app.PageTmp = {}
                        app.PageTmp = app.Page
                        app.triggers.isSaving = true
                        app.triggers.triggerSave = false
                        saveSettings()
                    else
                        -- when in sim we fake a save as not possible to really do
                        -- this involves tricking the progress dialog into thinking
                        app.triggers.isSavingFake = true
                        app.triggers.triggerSave = false
                    end
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    app.triggers.triggerSave = false
                    return true
                end
            }
        }
        local theTitle = "Save settings"
        local theMsg = "Save current page to flight controller"

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

        app.triggers.triggerSave = false
    end

    -- a reload that is pretty much instant with no prompt to ask them
    if app.triggers.triggerReloadNoPrompt == true then
        app.triggers.triggerReloadNoPrompt = false
        app.triggers.reload = true
    end

    -- a reload was triggered - popup a box asking for the reload to be done
    if app.triggers.triggerReload == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger RELOAD
                    app.triggers.reload = true
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

        app.triggers.triggerReload = false
    end

    -- show an error if msp version is bad
    if app.uiState == app.uiStatus.mainMenu and app.dialogs.nolinkDisplay == false then

        local apiVersionAsString = tostring(app.config.apiVersion)
        if not rf2ethos.utils.stringInArray(app.config.supportedMspApiVersion, apiVersionAsString) then
            app.triggers.badMspVersion = true
        else
            app.triggers.badMspVersion = false
        end

        if app.triggers.badMspVersion == true then
            local buttons = {
                {
                    label = "   OK   ",
                    action = function()
                        app.triggers.exitAPP = true
                        return true
                    end
                }
            }
            

            if app.triggers.badMspVersionDisplay == false then
                local message
                if app.backgroundMsp ~= true then
                   message = "Please enable the backround msp task."
                elseif app.getRSSI() == 0 then
                    message = "Unable to establish a link to the flight controller"
                elseif app.config.apiVersion ~= nil then
                    message = "This version of the Lua scripts \ncan't be used with the selected model (" .. app.config.apiVersion .. ")."
                else
                    message = "Unable to determine msp version in use."
                end

                app.triggers.badMspVersionDisplay = true
                form.openDialog({
                    width = nil,
                    title = "Error",
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
    if app.triggers.isSaving then
        app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 5
        if app.pageState >= app.pageStatus.saving then
            if app.dialogs.saveDisplay == false then
                app.triggers.saveFailed = false
                app.dialogs.saveProgressCounter = 0
                app.ui.progessDisplaySave()
                app.mspQueue.retryCount = 0
            end
            if app.pageState == app.pageStatus.saving then
                app.ui.progessDisplaySaveValue(app.dialogs.saveProgressCounter, "Saving data...")
            elseif app.pageState == app.pageStatus.eepromWrite then
                app.ui.progessDisplaySaveValue(app.dialogs.saveProgressCounter, "Saving data...")
            elseif app.pageState == app.pageStatus.rebooting then
                app.ui.progessDisplaySaveValue(app.dialogs.saveProgressCounter, "Rebooting...")
            end

        else
            app.triggers.isSaving = false
            app.dialogs.saveDisplay = false
            app.dialogs.saveWatchDog = nil
        end
    elseif app.triggers.isSavingFake == true then

        if app.dialogs.saveDisplay == false then
            app.triggers.saveFailed = false
            app.dialogs.saveProgressCounter = 0
            app.ui.progessDisplaySave()
            app.mspQueue.retryCount = 0
            app.triggers.closeSaveFake = true
            app.triggers.isSavingFake = false
        end
    end

    -- check we have telemetry
    app.updateTelemetryState()

    -- if we are on the home page - then ensure pages are invalidated
    if app.uiState == app.uiStatus.mainMenu then
        invalidatePages()
    else
        -- detect page data loaded and ready to move onto rendering the page
        if (app.triggers.isReady == true and app.mspQueue:isProcessed() and (app.Page and app.Page.values)) then
            app.triggers.isReady = false

            app.triggers.closeProgressLoader = true

        end
    end

    -- if we are viewing a page with form data then we need to run some stuff USED
    -- by the msp processing
    if app.uiState == app.uiStatus.pages then

        -- rebind fields if needed
        if app.pageState == app.pageStatus.saving then if (app.saveTS + app.protocol.saveTimeout) < os.clock() then app.dataBindFields() end end

        -- intercept and populate app.Page if its empty
        -- this simply catches scenarious where we save the page AND
        -- other parts of the script fail for the few ms where the app.Page
        -- var is not populated
        if not app.Page and app.PageTmp then app.Page = app.PageTmp end

        -- we have a page waiting to be retrieved - trigger a request page
        if app.Page ~= nil then if not (app.Page.values or app.triggers.isReady) and app.pageState == app.pageStatus.display then requestPage() end end

    end

    -- capture a reload request and load respective Page
    -- this needs to be done a little better as there is no need FOR
    -- all the menu case checks - we should just be able to do as a task
    -- when viewing the page
    if app.triggers.reload == true then
        app.ui.progessDisplay()
        app.triggers.reload = false

        app.ui.openPage(app.lastIdx, app.lastTitle, app.lastScript)

        app.profileSwitchCheck()
        app.rateSwitchCheck()
    end

    -- check if rate or profile switches have been toggled
    app.profileSwitchCheck()
    app.rateSwitchCheck()

    -- play audio
    -- alerts 
    if app.config.audioParam == 0 or app.config.audioParam == 1 then

        if app.audio.playEraseFlash == true then
            system.playFile(app.config.toolDir .. "sounds/ui/eraseflash.wav")
            app.audio.playEraseFlash = false
        end

        if app.audio.playConnected == true then
            system.playFile(app.config.toolDir .. "sounds/ui/connected.wav")
            app.audio.playConnected = false
        end

        if app.audio.playConnecting == true then
            system.playFile(app.config.toolDir .. "sounds/ui/connecting.wav")
            app.audio.playConnecting = false
        end

        if app.audio.playDemo == true then
            system.playFile(app.config.toolDir .. "sounds/ui/demo.wav")
            app.audio.playDemo = false
        end

        if app.audio.playTimeout == true then
            system.playFile(app.config.toolDir .. "sounds/ui/timeout.wav")
            app.audio.playTimeout = false
        end

        if app.audio.playEscPowerCycle == true then
            system.playFile(app.config.toolDir .. "sounds/ui/powercycleesc.wav")
            app.audio.playEscPowerCycle = false
        end

        if app.audio.playServoOverideEnable == true then
            system.playFile(app.config.toolDir .. "sounds/ui/soverideen.wav")
            app.audio.playServoOverideEnable = false
        end

        if app.audio.playServoOverideDisable == true then
            system.playFile(app.config.toolDir .. "sounds/ui/soveridedis.wav")
            app.audio.playServoOverideDisable = false
        end

        if app.audio.playMixerOverideEnable == true then
            system.playFile(app.config.toolDir .. "sounds/ui/moverideen.wav")
            app.audio.playMixerOverideEnable = false
        end

        if app.audio.playMixerOverideDisable == true then
            system.playFile(app.config.toolDir .. "sounds/ui/moveridedis.wav")
            app.audio.playMixerOverideDisable = false
        end

        if app.audio.playSaving == true and app.config.audioParam == 0 then
            system.playFile(app.config.toolDir .. "sounds/ui/saving.wav")
            app.audio.playSaving = false
        end

        if app.audio.playLoading == true and app.config.audioParam == 0 then
            system.playFile(app.config.toolDir .. "sounds/ui/loading.wav")
            app.audio.playLoading = false
        end

    else
        app.audio.playLoading = false
        app.audio.playSaving = false
        app.audio.playTimeout = false
        app.audio.playDemo = false
        app.audio.playConnecting = false
        app.audio.playConnected = false
        app.audio.playEscPowerCycle = false
        app.audio.playServoOverideDisable = false
        app.audio.playServoOverideEnable = false
    end

end



function app.create()

    app.ini = assert(loadfile(app.config.toolDir .. "lib/lip.lua"))()    
    app.preferences = app.ini.load(app.config.toolDir .. "/preferences.ini");   

    -- load msp timeout
    app.config.watchdogParam = app.preferences.advanced.watchdog
    if app.config.watchdogParam == nil or app.config.watchdogParam == "" then
        app.config.watchdogParam = math.floor(app.protocol.pageReqTimeout + (app.protocol.pageReqTimeout * 0.5))
    end
    


    --config.apiVersion = nil
    config.environment = system.getVersion()
    config.ethosRunningVersion = rf2ethos.utils.ethosVersion()
    

    app.config.lcdWidth, app.config.lcdHeight = rf2ethos.utils.getWindowSize()
    app.radio = assert(loadfile(app.config.toolDir .. "radios.lua"))().msp

    app.fieldHelpTxt = assert(loadfile(app.config.toolDir .. "help/fields.lua"))()

    app.uiState = app.uiStatus.init

    app.config.audioParam = app.preferences.interface.audio

    if system:getVersion().simulation == false then
        local simpref = app.preferences.advanced.demoSwitch
        local s = rf2ethos.utils.explode(simpref, ",")
        local simParam = system.getSource({category = s[1], member = s[2]})
        if tonumber(simParam:value()) == 100 then
            config.simulateOnTransmitter = true
            app.runningInSimulator = true
            print("RF2ETHOS: Running in Demo Mode")
            app.audio.playDemo = true
        else
            config.simulateOnTransmitter = false
            app.runningInSimulator = false
            app.audio.playDemo = false
        end
    end

    app.ui.openMainMenu()

    -- check the current version of ethos to ensure that it is valid.
    if app.config.ethosRunningVersion < config.ethosVersion then
        if app.dialogs.badversionDisplay == false then
            app.dialogs.badversionDisplay = true

            local buttons = {
                {
                    label = "EXIT",
                    action = function()
                        app.triggers.exitAPP = true
                        return true
                    end
                }
            }

            if tonumber(rf2ethos.utils.makeNumber(app.config.environment.major .. config.environment.minor .. config.environment.revision)) < 1590 then
                form.openDialog("Warning", config.ethosVersionString, buttons, 1)
            else
                form.openDialog({
                    width = app.config.lcdWidth,
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
function app.event(widget, category, value, x, y)

    -- print("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

    if value == EVT_VIRTUAL_PREV_LONG then
        print("Forcing exit")
        invalidatePages()
        system.exit()
        return 0
    end

    if app.Page ~= nil and (app.uiState == app.uiStatus.pages or app.uiState == app.uiStatus.mainMenu) then
        if app.Page.event then
            -- run the pages wakeup function if it exists
            return app.Page.event(widget, category, value, x, y)
        end
    end

    if app.uiState == app.uiStatus.pages then

        if category == 5 or value == 35 then
            if app.dialogs.progressDisplay == true then app.ui.progessDisplayClose() end
            if app.dialogs.saveDisplay == true then app.ui.progessDisplaySaveClose() end
            if app.Page.onNavMenu then app.Page.onNavMenu(app.Page) end
            app.ui.openMainMenu()
            return true
        end
        if value == 35 then
            if app.dialogs.progressDisplay == true then app.ui.progessDisplayClose() end
            if app.dialogs.saveDisplay == true then app.ui.progessDisplaySaveClose() end
            if app.Page.onNavMenu then app.Page.onNavMenu(app.Page) end
            app.ui.openMainMenu()
            return true
        end
        if value == KEY_ENTER_LONG then
            if app.dialogs.progressDisplay == true then app.ui.progessDisplayClose() end
            if app.dialogs.saveDisplay == true then app.ui.progessDisplaySaveClose() end
            app.triggers.triggerSave = true
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end

    end

    if app.uiState == app.uiStatus.MainMenu then
        if value == KEY_ENTER_LONG then
            if app.dialogs.progressDisplay == true then app.ui.progessDisplayClose() end
            if app.dialogs.saveDisplay == true then app.ui.progessDisplaySaveClose() end
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end
    end

    return false
end

function app.close()

    app.guiIsRunning = false

    if app.Page ~= nil and (app.uiState == app.uiStatus.pages or app.uiState == app.uiStatus.mainMenu) then
        if app.Page.close then
            app.Page.close()
        end
    end
    
    if app.dialogs.progress then app.ui.progessDisplayClose() end
    if app.dialogs.save then app.ui.progessDisplaySaveClose() end
    if app.dialogs.noLink then app.ui.progessNolinkDisplayClose() end
    invalidatePages()
    app.resetState()
    collectgarbage()
    system.exit()
    return true
end


return app