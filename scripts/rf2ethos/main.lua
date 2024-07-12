-- RotorFlight + ETHOS LUA configuration

local config = {}
config.toolName = "RF2ETHOS"
config.toolDir = "/scripts/rf2ethos/"
config.debugLevel = 0  -- log level 0 = off, 1-5 = verbosity
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


rf2ethos = {}
rf2ethos = assert(loadfile(config.toolDir .. "lib/rf2ethos.lua"))()

rf2ethos.config = {}
rf2ethos.config = config

rf2ethos.triggers = {}
rf2ethos.triggers = triggers

rf2ethos.utils = {}
rf2ethos.utils = assert(loadfile(config.toolDir .. "lib/utils.lua"))()

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


local function rebootFc()

    rf2ethos.utils.log("Attempting to reboot the FC...")
    rf2ethos.pageState = rf2ethos.pageStatus.rebooting
    rf2ethos.mspQueue:add({
        command = 68, -- MSP_REBOOT
        processReply = function(self, buf)
            -- invalidatePages()
        end
    })
end

local mspEepromWrite = {
    command = 250, -- MSP_EEPROM_WRITE, fails when armed
    processReply = function(self, buf)
        if rf2ethos.Page.reboot then
            rebootFc()
        end
        if rf2ethos.mspQueue:isProcessed() then
            invalidatePages()
        end
    end,
    simulatorResponse = {}
}

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
        if rf2ethos.mspQueue:isProcessed() then
            invalidatePages()
        end
    end
end

local mspSaveSettings = {
    processReply = function(self, buf)

        rf2ethos.settingsSaved()
    end
}

local mspLoadSettings = {
    processReply = function(self, buf)

        rf2ethos.utils.log("rf2ethos.Page is processing reply for cmd " .. tostring(self.command) .. " len buf: " .. #buf .. " expected: " .. rf2ethos.Page.minBytes)

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
            mspSaveSettings.command = rf2ethos.Page.write
            mspSaveSettings.payload = payload
            mspSaveSettings.simulatorResponse = {}
            rf2ethos.mspQueue:add(mspSaveSettings)
        elseif type(rf2ethos.Page.write) == "function" then
            rf2ethos.Page.write(rf2ethos.Page)
        end

    end
end

local function invalidatePages()
    rf2ethos.Page = nil
    rf2ethos.pageState = rf2ethos.pageStatus.display
    rf2ethos.saveTS = 0
    collectgarbage()
end


local function requestPage()
    if not rf2ethos.Page.reqTS or rf2ethos.Page.reqTS + rf2ethos.protocol.pageReqTimeout <= os.clock() then
        rf2ethos.Page.reqTS = os.clock()
        if rf2ethos.Page.read then
            rf2ethos.readPage()
        end
    end
end

-- Ethos: when the RF1 and RF2 system tools are both installed, RF1 tries to call getRSSI in RF2 and gets stuck.
-- To avoid this, getRSSI is renamed in rf2ethos.
rf2ethos.getRSSI = function()
    -- rf2ethos.utils.log("getRSSI RF2")
    if config.environment.simulation == true then
        return 100
    end

    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rf2ethos.rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
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

function rf2ethos.getFieldValue(f)


	if f.value == nil then
		f.value = 0
	end
	if f.t == nil then
		f.t = "N/A"
	end

	rf2ethos.utils.log(f.t .. ":" .. f.value)


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

    if f.mult ~= nil then
        v = math.floor(v * f.mult + 0.5)
    end

    return v
end

function rf2ethos.saveValue(currentField)
    if config.environment.simulation == true then
        return
    end

    local f = rf2ethos.Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do
        rf2ethos.Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8)
    end
    if f.upd and rf2ethos.Page.values then
        f.upd(rf2ethos.Page)
    end
end

function rf2ethos.openPagehelp(helpdata, section)
    local txtData

    if section == "rates_1" then
        txtData = helpdata[section]["table"][rf2ethos.RateTable]
    else
        txtData = helpdata[section]["TEXT"]
    end
    local qr = config.toolDir .. helpdata[section]["qrCODE"]

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
        width = rf2ethos.config.lcdWidth,
        title = "Help - " .. rf2ethos.lastTitle,
        message = message,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
            local w = rf2ethos.config.lcdWidth
            local h = rf2ethos.config.lcdHeight
            local left = w * 0.75

            local qw = rf2ethos.radio.helpQrCodeSize
            local qh = rf2ethos.radio.helpQrCodeSize

            local qy = rf2ethos.radio.buttonPadding
            local qx = rf2ethos.config.lcdWidth - qw - rf2ethos.radio.buttonPadding / 2
            lcd.drawBitmap(qx, qy, bitmap, qw, qh)

        end,
        options = TEXT_LEFT
    })

end

-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)

    rf2ethos.utils.log("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

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
            rf2ethos.openMainMenu()
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
            rf2ethos.openPageESC(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
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
            rf2ethos.openPageESCTool(rf2ethos.escManufacturer)
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
            rf2ethos.openMainMenu()
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
            rf2ethos.openMainMenu()
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

    -- ethos version
    if tonumber(rf2ethos.utils.makeNumber(config.environment.major .. config.environment.minor .. config.environment.revision)) < config.ethosVersion then
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

            if tonumber(rf2ethos.utils.makeNumber(config.environment.major .. config.environment.minor .. config.environment.revision)) < 1590 then
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

            rf2ethos.triggers.escPowerCycleLoader = rf2ethos.triggers.escPowerCycleLoader + 1

            if rf2ethos.triggers.escPowerCycleLoader >= 100 then
                rf2ethos.triggers.escPowerCycleLoader = 0
                rf2ethos.dialogs.progress:close()
                rf2ethos.triggers.triggerESCLOADER = false
                rf2ethos.triggers.triggerESCMAINMENU = true
            end

        end
    end

    -- capture profile switching and trigger a reload if needs be

    if rf2ethos.Page ~= nil then
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
                            rf2ethos.utils.log("Profile switch reload")
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
                            rf2ethos.utils.log("Rate switch reload")
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

        rf2ethos.openPageESC(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)

    end

    -- some watchdogs to enable close buttons on save and progress if they time-out
    if rf2ethos.dialogs.saveDisplay == true then
        if rf2ethos.dialogs.saveWatchDog ~= nil then
            if (os.clock() - rf2ethos.dialogs.saveWatchDog) > 20 then
                rf2ethos.dialogs.save:closeAllowed(true)
            end
        end
    end

    if rf2ethos.triggers.escPowerCycle == true then
        -- ESC MODE - WE NEVER TIME OUT AS DO A 'RETRY DIALOG'
        -- AS SOME ESC NEED TO BE CONNECTING AS YOU POWER UP to
        -- INIT CONFIG MODE
    else
        if rf2ethos.dialogs.progressDisplay == true then
            if rf2ethos.dialogs.progressWatchDog ~= nil then
                if (os.clock() - rf2ethos.dialogs.progressWatchDog) > 30 then
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
                if rf2ethos.mspQueue.retryCount < rf2ethos.protocol.maxRetries then
                    saveSettings()
                    rf2ethos.mspQueue.retryCount = rf2ethos.mspQueue.retryCount + 1

                else
                    -- Saving failed for some reason
                    rf2ethos.triggers.saveFailed = true
                    rf2ethos.dialogs.save:message("Error - failed to write data")
                    rf2ethos.dialogs.save:closeAllowed(true)
                    invalidatePages()
                end

            end
        elseif rf2ethos.pageState == rf2ethos.pageStatus.eepromWrite then
            if (rf2ethos.saveTS + rf2ethos.protocol.saveTimeout) < os.clock() then
                rf2ethos.dialogs.save:value(100)
                rf2ethos.dialogs.save:close()
                if rf2ethos.mspQueue:isProcessed() then
                    invalidatePages()
                end
            else
                rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 1
            end
        end
        if not rf2ethos.Page then
            if rf2ethos.escMode == true then
                if rf2ethos.escScript ~= nil then
                    rf2ethos.Page = assert(loadfile(config.toolDir .. "esc/" .. rf2ethos.escManufacturer .. "/pages/" .. rf2ethos.escScript))()
                else
                    rf2ethos.utils.log("rf2ethos.escScript is not present so cannot load as expected")
                end
            else
                if rf2ethos.lastPage ~= nil then
                    rf2ethos.Page = assert(loadfile(config.toolDir .. "pages/" .. rf2ethos.lastPage))()
                end
                rf2ethos.escManufacturer = nil
                rf2ethos.escScript = nil
                rf2ethos.escMode = false
            end
            collectgarbage()
        end
        -- if rf2ethos.Page ~= nil then
        --    if not rf2ethos.Page.values and rf2ethos.pageState == rf2ethos.pageStatus.display then
        --        requestPage()
        --    end
        -- end
        if not (rf2ethos.Page.values or rf2ethos.Page.isReady) and rf2ethos.pageState == rf2ethos.pageStatus.display then
            requestPage()
        end
    end

    if rf2ethos.triggers.createForm == true and rf2ethos.mspQueue:isProcessed() then

        if rf2ethos.triggers.wasSaving == true or config.environment.simulation == true then

            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
            rf2ethos.triggers.wasSaving = false
            rf2ethos.dialogs.save:value(100)
            rf2ethos.dialogs.saveDisplay = false
            rf2ethos.dialogs.saveWatchDog = nil
            if rf2ethos.triggers.saveFailed == false then
                rf2ethos.dialogs.save:close()
                rf2ethos.triggers.saveFailed = false
            end
            -- rf2ethos.resetServos() -- this must run after save settings
            -- rf2ethos.resetCopyProfiles() -- this must run after save settings

            -- switch back the rf2ethos.Page var to avoid having a page refresh!
            rf2ethos.Page = rf2ethos.PageTmp

        elseif (rf2ethos.triggers.wasLoading == true) or config.environment.simulation == true then
            rf2ethos.triggers.wasLoading = false
            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
            if rf2ethos.lastScript == "pids.lua" or rf2ethos.lastIdx == 1 then
                rf2ethos.openPagePID(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 1 then
                rf2ethos.openPageRATES(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "servos.lua" then
                rf2ethos.openPageSERVOS(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript == nil then
                rf2ethos.openPageESCTool(rf2ethos.escManufacturer)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript ~= nil then
                rf2ethos.openESCForm(rf2ethos.escManufacturer, rf2ethos.escScript)
            else
                rf2ethos.openPageDefault(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            end
        elseif rf2ethos.triggers.wasReloading == true or config.environment.simulation == true then
            rf2ethos.triggers.wasReloading = false
            if rf2ethos.lastScript == "pids.lua" or rf2ethos.lastIdx == 1 then
                rf2ethos.openPagePIDLoader(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 1 then
                rf2ethos.openPageRATESLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.lastScript == "servos.lua" then
                rf2ethos.openPageSERVOSLoader(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript == nil then
                rf2ethos.openPageESCToolLoader(rf2ethos.escManufacturer)
            elseif rf2ethos.escMode == true and rf2ethos.escManufacturer ~= nil and rf2ethos.escScript ~= nil then
                rf2ethos.openESCFormLoader(rf2ethos.escManufacturer, rf2ethos.escScript)
            else
                rf2ethos.openPageDefaultLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
            end
            rf2ethos.profileSwitchCheck()
            rf2ethos.rateSwitchCheck()
        elseif rf2ethos.triggers.reloadRates == true or config.environment.simulation == true then
            rf2ethos.openPageRATESLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
        else
            rf2ethos.openMainMenu()
        end

        rf2ethos.triggers.createForm = false
    else
        rf2ethos.triggers.createForm = false
    end

    if rf2ethos.uiState ~= rf2ethos.uiStatus.mainMenu then
        if config.environment.simulation == true or (rf2ethos.triggers.mspDataLoaded == true and rf2ethos.mspQueue:isProcessed()) then
            rf2ethos.triggers.mspDataLoaded = false
            rf2ethos.triggers.isLoading = false
            rf2ethos.triggers.wasLoading = true
            if config.environment.simulation ~= true then
                rf2ethos.triggers.createForm = true
            end
        end
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
                rf2ethos.dialogs.save:message("Saving...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.eepromWrite then
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter * 4)
                rf2ethos.dialogs.save:message("Saving...")
            elseif rf2ethos.pageState == rf2ethos.pageStatus.rebooting then
                saveMsg = rf2ethos.dialogs.save:message("Rebooting...")
                rf2ethos.dialogs.save:value(rf2ethos.dialogs.saveProgressCounter * 4)
                rf2ethos.dialogs.saveProgressCounter = rf2ethos.dialogs.saveProgressCounter + 1

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
                    rf2ethos.debugSave()
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

    if rf2ethos.triggers.telemetryState ~= 1 or (rf2ethos.pageState >= rf2ethos.pageStatus.saving) then
        -- we dont refresh as busy doing other stuff
        -- rf2ethos.utils.log("Form invalidation disabled....")
    else
        if (rf2ethos.triggers.isSaving == false and rf2ethos.triggers.wasSaving == false) or (rf2ethos.triggers.isLoading == false and rf2ethos.triggers.wasLoading == false) then
            -- form.invalidate()
        end
    end

    -- this needs to run on every wakeup event.
    rf2ethos.mspQueue:processQueue()

end

function rf2ethos.navigationButtons(x, y, w, h)

    local helpWidth
    local section
    local page

    help = assert(loadfile(config.toolDir .. "help/pages.lua"))()
    section = string.gsub(rf2ethos.lastScript, ".lua", "") -- remove .lua
    page = rf2ethos.lastSubPage
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
            rf2ethos.triggers.resetRates = false
            rf2ethos.openMainMenu()
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
            rf2ethos.triggers.triggerSAVE = true
        end
    })

    form.addButton(line, {x = x - (helpWidth + padding) - (w + padding), y = y, w = w, h = h}, {
        text = "RELOAD",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.triggerRELOAD = true
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
                rf2ethos.openPagehelp(help.data, section)
            end
        })

    end

end

function rf2ethos.navigationButtonsEscForm(x, y, w, h)

    local padding = 5
    local helpWidth = 0

    field = form.addButton(line, {x = x - w - padding - w - padding - w - padding, y = y, w = w, h = h}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.resetRates = false
            rf2ethos.escMode = true
            rf2ethos.escNotReadyCount = 0
            collectgarbage()
            rf2ethos.openPageESCTool(rf2ethos.escManufacturer)
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
            rf2ethos.escNotReadyCount = 0
            rf2ethos.triggers.triggerSAVE = true
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
                        if config.environment.simulation ~= true then
                            rf2ethos.triggers.triggerESCRELOAD = true
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
-- write one servo - and essentially loose rf2ethos.Pages
--[[
function rf2ethos.resetServos()
    if rf2ethos.lastScript == "servos.lua" then
        rf2ethos.openPageSERVOSLoader(rf2ethos.lastIdx, rf2ethos.lastTitle, rf2ethos.lastScript)
    end
end
]] --

-- when saving - we have to force a reload of data of copy-profiles due to way you

function rf2ethos.resetCopyProfiles()
    if rf2ethos.lastScript == "copy_profiles.lua" then
        -- invalidatePages
        -- rf2ethos.openPageDefaultLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
        rf2ethos.triggers.wasReloading = true
        rf2ethos.triggers.createForm = true
        rf2ethos.triggers.wasSaving = false
        rf2ethos.triggers.wasLoading = false
        rf2ethos.triggers.reloadRates = false

    end
end

function rf2ethos.resetRates()
    if rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 2 then
        if rf2ethos.triggers.resetRates == true then
            rf2ethos.NewRateTable = rf2ethos.Page.fields[13].value

            local newTable = rf2ethos.utils.defaultRates(rf2ethos.NewRateTable)

            for k, v in pairs(newTable) do
                local f = rf2ethos.Page.fields[k]
                for idx = 1, #f.vals do
                    rf2ethos.Page.values[f.vals[idx]] = v >> ((idx - 1) * 8)
                end
            end
            rf2ethos.triggers.resetRates = false
        end
    end
end

function rf2ethos.debugSave()
    -- this function runs before save action
    -- happens.  use it to do debug if needed

    -- if rf2ethos.lastScript == "servos.lua" then

    --	rf2ethos.Page.fields[1].value = currentServoID
    --    rf2ethos.saveValue(currentServoID, 1)
    --    local f = rf2ethos.Page.fields[1]

    --    rf2ethos.utils.log(f.value)

    --    for idx = 1, #f.vals do
    --    	rf2ethos.Page.values[f.vals[idx]] = currentServoID >> ((idx - 1) * 8)
    --    end

    --    rf2ethos.utils.log(rf2ethos.Page.fields[1].value)
    -- end

end

local function fieldChoice(f, i)
    if rf2ethos.lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= rf2ethos.lastSubPage then
            return
        end
    end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then

        if rf2ethos.radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
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

    field = form.addChoiceField(line, posField, rf2ethos.utils.convertPageValueTable(f.table, f.tableIdxInc), function()
        local value = rf2ethos.getFieldValue(f)

        return value
    end, function(value)
        -- we do this hook to allow rates to be reset
        if f.postEdit then
            f.postEdit(rf2ethos.Page)
        end
        f.value = rf2ethos.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)
end

function rf2ethos.saveFieldValue(f, value)
    if value ~= nil then
        if f.decimals ~= nil then
            f.value = value / rf2ethos.utils.decimalInc(f.decimals)
        else
            f.value = value
        end
        if f.postEdit then
            f.postEdit(rf2ethos.Page)
        end
    end

    if f.mult ~= nil then
        f.value = f.value / f.mult
    end

    return f.value
end

local function fieldNumber(f, i)
    if rf2ethos.lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= rf2ethos.lastSubPage then
            return
        end
    end

    if f.inline ~= nil and f.inline >= 1 and f.label ~= nil then
        if rf2ethos.radio.text == 2 then
            if f.t2 ~= nil then
                f.t = f.t2
            end
        end

        local p = rf2ethos.utils.getInlinePositions(f, rf2ethos.Page)
        posText = p.posText
        posField = p.posField

        field = form.addStaticText(line, posText, f.t)
    else
        if rf2ethos.radio.text == 2 then
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

    minValue = rf2ethos.utils.scaleValue(f.min, f)
    maxValue = rf2ethos.utils.scaleValue(f.max, f)
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
            f.postEdit(rf2ethos.Page)
        end

        f.value = rf2ethos.saveFieldValue(f, value)
        rf2ethos.saveValue(i)
    end)

    if f.default ~= nil then
        local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
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
        if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
            local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
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
    if rf2ethos.lastSubPage ~= nil and f.subpage ~= nil then
        if f.subpage ~= rf2ethos.lastSubPage then
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

        if f.label ~= rf2ethos.lastLabel then
            if label.type == nil then
                label.type = 0
            end

            formLineCnt = formLineCnt + 1
            line = form.addLine(labelName)
            form.addStaticText(line, nil, "")

            rf2ethos.lastLabel = f.label
        end
    else
        labelID = nil
    end
end

local function fieldHeader(title)
    local w = rf2ethos.config.lcdWidth
    local h = rf2ethos.config.lcdHeight
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.radio.navButtonOffset ~= nil then
        colStart = colStart - rf2ethos.radio.navButtonOffset
    end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.menuButtonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight

    line = form.addLine(title)
    rf2ethos.navigationButtons(w, rf2ethos.radio.linePaddingTop, buttonW, buttonH)
end

function rf2ethos.openPagePreferences(idx, title, script)
    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = nil
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.triggers.isLoading = false
    rf2ethos.Page = nil

    form.clear()

    local w = rf2ethos.config.lcdWidth
    local h = rf2ethos.config.lcdHeight
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.radio.navButtonOffset ~= nil then
        colStart = colStart - rf2ethos.radio.navButtonOffset
    end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.buttonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight

    local x = w

    line = form.addLine("Preferences")

    field = form.addButton(line, {x = x - (buttonW + padding) * 1, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = buttonH}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.lastIdx = nil
            rf2ethos.lastPage = nil
            rf2ethos.lastSubPage = nil
            rf2ethos.escMode = false
            rf2ethos.openMainMenu()
        end
    })
    field:focus()

    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/iconsize")
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    end
    line = form.addLine("Button style")
    form.addChoiceField(line, nil, {{"Text", 0}, {"Small image", 1}, {"Large images", 2}}, function()
        return rf2ethos.config.iconsizeParam
    end, function(newValue)
        rf2ethos.config.iconsizeParam = newValue
        rf2ethos.utils.storePreference(config.toolDir .. "/preferences/iconsize", rf2ethos.config.iconsizeParam)
    end)

    -- PROFILE
    profileswitchParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/profileswitch")
    if profileswitchParam ~= nil then
        local s = rf2ethos.utils.explode(profileswitchParam, ",")
        profileswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = form.addLine("Switch profile")
    form.addSourceField(line, nil, function()
        return profileswitchParam
    end, function(newValue)
        profileswitchParam = newValue
        local member = profileswitchParam:member()
        local category = profileswitchParam:category()
        rf2ethos.utils.storePreference(config.toolDir .. "/preferences/profileswitch", category .. "," .. member)
    end)

    rateswitchParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = rf2ethos.utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    line = form.addLine("Switch rates")
    form.addSourceField(line, nil, function()
        return rateswitchParam
    end, function(newValue)
        rateswitchParam = newValue
        local member = rateswitchParam:member()
        local category = rateswitchParam:category()
        rf2ethos.utils.storePreference(config.toolDir .. "/preferences/rateswitch", category .. "," .. member)
    end)

end

function rf2ethos.openPageDefaultLoader(idx, subpage, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(loadfile(config.toolDir .. "pages/" .. script))()
    collectgarbage()

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    rf2ethos.dialogs.progress:value(0)
    rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    rf2ethos.triggers.isLoading = true

    rf2ethos.utils.log("Finished: rf2ethos.openPageDefaultLoader")

    if config.environment.simulation == true then
        rf2ethos.openPageDefault(idx, subpage, title, script)
    end

end

function rf2ethos.openPageDefault(idx, subpage, title, script)

    local fieldAR = {}

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    longPage = false

    form.clear()

    rf2ethos.lastPage = script

    fieldHeader(title)

    formLineCnt = 0

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
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

    if rf2ethos.dialogs.progressDisplay == true then
        rf2ethos.dialogs.progressWatchDog = nil
        rf2ethos.dialogs.progressDisplay = false
        rf2ethos.dialogs.progress:close()
    end

end

function rf2ethos.openPageSERVOSLoader(idx, title, script)

    rf2ethos.utils.log("openrf2ethos.openPageSERVOSLoader")

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(loadfile(config.toolDir .. "pages/" .. script))()
    collectgarbage()

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    rf2ethos.dialogs.progress:value(0)
    rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    rf2ethos.triggers.isLoading = true

    if config.environment.simulation == true then
        rf2ethos.openPageSERVOS(idx, title, script)
    end

    rf2ethos.utils.log("Finished: rf2ethos.openPageSERVOS")
end

function rf2ethos.openPageSERVOS(idx, title, script)

    rf2ethos.utils.log("openrf2ethos.openPageSERVOS")

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    local numPerRow = 2

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local padding = rf2ethos.radio.buttonPadding
    local h = rf2ethos.radio.navbuttonHeight
    local w = ((windowWidth) / numPerRow) - (padding * numPerRow - 1)

    local y = rf2ethos.radio.linePaddingTop

    longPage = false

    form.clear()

    rf2ethos.lastPage = script

    fieldHeader(title)

    -- we add a servo selector that is not part of msp table
    -- this is done as a selector - to pass a servoID on refresh
    if rf2ethos.Page.servoCount == 3 then
        servoTable = {"ELEVATOR", "CYCLIC LEFT", "CYCLIC RIGHT"}
    else
        servoTable = {"ELEVATOR", "CYCLIC LEFT", "CYCLIC RIGHT", "TAIL"}
    end

    -- we can now loop throught pages to get values
    formLineCnt = 0
    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageValue = f
        local pageIdx = i
        local currentField = i

        if i == 1 then
            line = form.addLine("Servo")
            field = form.addChoiceField(line, nil, rf2ethos.utils.convertPageValueTable(servoTable), function()
                value = rf2ethos.lastChangedServo
                if rf2ethos.Page == nil then
                    rf2ethos.triggers.wasReloading = true
                    rf2ethos.triggers.createForm = true
                else
                    rf2ethos.Page.fields[1].value = value
                end
                return value
            end, function(value)
                rf2ethos.Page.servoChanged(rf2ethos.Page, value)
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
                    local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
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
                    if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                        local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                        field:help(helpTxt)
                    end
                end
            end
        end
    end

    if rf2ethos.dialogs.progressDisplay == true then
        rf2ethos.dialogs.progressWatchDog = nil
        rf2ethos.dialogs.progressDisplay = false
        rf2ethos.dialogs.progress:close()
    end

end

function rf2ethos.openPagePIDLoader(idx, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(loadfile(config.toolDir .. "pages/" .. script))()
    collectgarbage()

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    rf2ethos.dialogs.progress:value(0)
    rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.lastPage = script

    rf2ethos.triggers.isLoading = true

    if config.environment.simulation == true then
        rf2ethos.openPagePID(idx, title, script)
    end

    rf2ethos.utils.log("Finished: rf2ethos.openPagePID")
end

function rf2ethos.openPagePID(idx, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    longPage = false

    form.clear()

    fieldHeader(title)
    local numCols
    if rf2ethos.Page.cols ~= nil then
        numCols = #rf2ethos.Page.cols
    else
        numCols = 6
    end
    local screenWidth = rf2ethos.config.lcdWidth - 10
    local padding = 10
    local paddingTop = rf2ethos.radio.linePaddingTop
    local h = rf2ethos.radio.navbuttonHeight
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
        local colLabel = rf2ethos.Page.cols[loc]
        pos = {x = posX, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    for ri, rv in ipairs(rf2ethos.Page.rows) do
        _G["rf2ethosmsp_PIDROWS_" .. ri] = form.addLine(rv)
    end

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        minValue = f.min * rf2ethos.utils.decimalInc(f.decimals)
        maxValue = f.max * rf2ethos.utils.decimalInc(f.decimals)
        if f.mult ~= nil then
            minValue = minValue * f.mult
            maxValue = maxValue * f.mult
        end

        field = form.addNumberField(_G["rf2ethosmsp_PIDROWS_" .. f.row], pos, minValue, maxValue, function()
            local value = rf2ethos.getFieldValue(f)
            return value
        end, function(value)
            f.value = rf2ethos.saveFieldValue(f, value)
            rf2ethos.saveValue(i)
        end)
        if f.default ~= nil then
            local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
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
            if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                field:help(helpTxt)
            end
        end
    end

    if rf2ethos.dialogs.progressDisplay == true then
        rf2ethos.dialogs.progressWatchDog = nil
        rf2ethos.dialogs.progressDisplay = false
        rf2ethos.dialogs.progress:close()
    end

end

function rf2ethos.openPageESC(idx, title, script)

    rf2ethos.utils.log("openrf2ethos.PageESC")

    rf2ethos.escMenuState = 1

    if tonumber(rf2ethos.utils.makeNumber(config.environment.major .. config.environment.minor .. config.environment.revision)) < config.ethosVersion then
        return
    end

    rf2ethos.triggers.mspDataLoaded = false
    rf2ethos.uiState = rf2ethos.uiStatus.mainMenu
    rf2ethos.triggers.escPowerCycle = false

    form.clear()

    rf2ethos.lastIdx = idx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

    ESC = {}

    rf2ethos.escMode = true

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/iconsize")
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local padding = rf2ethos.radio.buttonPadding

    local sc
    local panel

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW

    field = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.lastIdx = nil
            rf2ethos.lastPage = nil
            rf2ethos.lastSubPage = nil
            rf2ethos.escMode = false
            rf2ethos.openMainMenu()
        end
    })
    field:focus()

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end

    local ESCMenu = assert(loadfile(config.toolDir .. "pages/" .. script))()

    local lc = 0
    local bx = 0

    for pidx, pvalue in ipairs(ESCMenu.pages) do

        if lc == 0 then
            if rf2ethos.config.iconsizeParam == 0 then
                y = form.height() + rf2ethos.radio.buttonPaddingSmall
            end
            if rf2ethos.config.iconsizeParam == 1 then
                y = form.height() + rf2ethos.radio.buttonPaddingSmall
            end
            if rf2ethos.config.iconsizeParam == 2 then
                y = form.height() + rf2ethos.radio.buttonPadding
            end
        end

        if lc >= 0 then
            bx = (buttonW + padding) * lc
        end

        if rf2ethos.config.iconsizeParam ~= 0 then
            if rf2ethos.esc_buttons[pidx] == nil then
                rf2ethos.esc_buttons[pidx] = lcd.loadMask(config.toolDir .. "gfx/esc/" .. pvalue.image)
            end
        else
            rf2ethos.esc_buttons[pidx] = nil
        end

        form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.esc_buttons[pidx],
            options = FONT_S,
            paint = function()

            end,
            press = function()
                rf2ethos.openPageESCToolLoader(pvalue.folder)
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
function rf2ethos.openPageESCToolLoader(folder)

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from ESC")
    rf2ethos.dialogs.progress:value(0)
    rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.escManufacturer = folder
    rf2ethos.escScript = nil
    rf2ethos.escMode = true

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    ESC.init = assert(loadfile(config.toolDir .. "ESC/" .. folder .. "/init.lua"))()
    rf2ethos.triggers.escPowerCycle = ESC.init.powerCycle

    rf2ethos.Page = assert(loadfile(config.toolDir .. "ESC/" .. folder .. "/esc_info.lua"))()

    rf2ethos.triggers.isLoading = true

    if config.environment.simulation == true then
        rf2ethos.openPageESCTool(folder)
    end

end

-- initialise menu for specific type of esc
-- basically we load libraries then read
-- /scripts/rf2ethosmsp/ESC/<TYPE>/pages.lua
function rf2ethos.openPageESCTool(folder)

    rf2ethos.utils.log("rf2ethos.openPageESCTool")

    rf2ethos.escMenuState = 2

    if rf2ethos.triggers.escPowerCycle == true then
        rf2ethos.uiState = rf2ethos.uiStatus.pages
        rf2ethos.triggers.triggerESCLOADER = true
    else
        rf2ethos.uiState = rf2ethos.uiStatus.MainMenu
    end

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight

    local y = rf2ethos.radio.linePaddingTop

    form.clear()

    line = form.addLine(rf2ethos.lastTitle .. ' / ' .. ESC.init.toolName)

    buttonW = 100
    local x = windowWidth - buttonW

    field = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.triggers.triggerESCMAINMENU = true
        end
    })
    field:focus()

    ESC.pages = assert(loadfile(config.toolDir .. "ESC/" .. folder .. "/pages.lua"))()

    if rf2ethos.Page.escinfo then
        local model = rf2ethos.Page.escinfo[1].t
        local version = rf2ethos.Page.escinfo[2].t
        local fw = rf2ethos.Page.escinfo[3].t

        if model == "" then
            model = "UNKNOWN ESC"
            rf2ethos.escUnknown = true
        else
            rf2ethos.escUnknown = false
        end

        if rf2ethos.triggers.escPowerCycle == true and model == "UNKNOWN ESC" then

            if rf2ethos.triggers.escPowerCycleAnimation == nil or rf2ethos.triggers.escPowerCycleAnimation == "-" or rf2ethos.triggers.escPowerCycleAnimation == "" then
                rf2ethos.triggers.escPowerCycleAnimation = "+"
            else
                rf2ethos.triggers.escPowerCycleAnimation = "-"
            end

            line = form.addLine("")
            form.addStaticText(line, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.buttonHeight}, "Please power cycle the speed controller " .. rf2ethos.triggers.escPowerCycleAnimation)

        else
            rf2ethos.triggers.triggerESCLOADER = false
            line = form.addLine("")
            form.addStaticText(line, {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.buttonHeight}, model .. " " .. version .. " " .. fw)

        end
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/iconsize")

    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end

    local lc = 0
    local bx = 0

    for pidx, pvalue in ipairs(ESC.pages) do

        if lc == 0 then
            if rf2ethos.config.iconsizeParam == 0 then
                y = form.height() + rf2ethos.radio.buttonPaddingSmall
            end
            if rf2ethos.config.iconsizeParam == 1 then
                y = form.height() + rf2ethos.radio.buttonPaddingSmall
            end
            if rf2ethos.config.iconsizeParam == 2 then
                y = form.height() + rf2ethos.radio.buttonPadding
            end
        end

        if lc >= 0 then
            bx = (buttonW + padding) * lc
        end

        if rf2ethos.config.iconsizeParam ~= 0 then
            if rf2ethos.esctool_buttons[pvalue.image] == nil then
                rf2ethos.esctool_buttons[pvalue.image] = lcd.loadMask(config.toolDir .. "gfx/esc/" .. pvalue.image)
            end
        else
            rf2ethos.esctool_buttons[pvalue.image] = nil
        end

        rf2ethos.utils.log("x = " .. bx .. ", y = " .. y .. ", w = " .. buttonW .. ", h = " .. buttonH)
        field = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.esctool_buttons[pvalue.image],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                rf2ethos.openESCFormLoader(folder, pvalue.script)
            end
        })

        if rf2ethos.escUnknown == true then
            field:enable(false)
        end

        lc = lc + 1

        if lc == numPerRow then
            lc = 0
        end

    end

    if rf2ethos.dialogs.progressDisplay == true and rf2ethos.triggers.triggerESCLOADER ~= true then
        rf2ethos.dialogs.progressWatchDog = nil
        rf2ethos.dialogs.progressDisplay = false
        rf2ethos.dialogs.progress:close()
    end

end

-- preload the page for the specic module of esc and display
-- a then pass on to the actual form display function
function rf2ethos.openESCFormLoader(folder, script)

    rf2ethos.utils.log("rf2ethos.openESCFormLoader")

    rf2ethos.escManufacturer = folder
    rf2ethos.escScript = script
    rf2ethos.escMode = true

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(loadfile(config.toolDir .. "ESC/" .. folder .. "/pages/" .. script))()
    collectgarbage()

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    rf2ethos.dialogs.progress:value(0)
    rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.triggers.isLoading = true

    if config.environment.simulation == true then
        rf2ethos.openESCForm(folder, script)
    end

end

--
function rf2ethos.openESCForm(folder, script)

    rf2ethos.utils.log("rf2ethos.openESCForm")

    rf2ethos.escMenuState = 3

    local fieldAR = {}
    rf2ethos.uiState = rf2ethos.uiStatus.pages
    longPage = false
    form.clear()

    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight
    local y = rf2ethos.radio.linePaddingTop

    local w = rf2ethos.config.lcdWidth
    local h = rf2ethos.config.lcdHeight
    -- column starts at 59.4% of w
    padding = 5
    colStart = math.floor((w * 59.4) / 100)
    if rf2ethos.radio.navButtonOffset ~= nil then
        colStart = colStart - rf2ethos.radio.navButtonOffset
    end

    if rf2ethos.radio.buttonWidth == nil then
        buttonW = (w - colStart) / 3 - padding
    else
        buttonW = rf2ethos.radio.buttonWidth
    end
    buttonH = rf2ethos.radio.navbuttonHeight
    line = form.addLine(rf2ethos.lastTitle .. ' / ' .. ESC.init.toolName .. ' / ' .. rf2ethos.Page.title)

    rf2ethos.navigationButtonsEscForm(rf2ethos.config.lcdWidth, rf2ethos.radio.linePaddingTop, buttonW, rf2ethos.radio.navbuttonHeight)

    if rf2ethos.Page.escinfo then
        local model = rf2ethos.Page.escinfo[1].t
        local version = rf2ethos.Page.escinfo[2].t
        local fw = rf2ethos.Page.escinfo[3].t
        line = form.addLine(model .. " " .. version .. " " .. fw)
    end

    formLineCnt = 0

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
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

    if rf2ethos.dialogs.progressDisplay == true then
        rf2ethos.dialogs.progressWatchDog = nil
        rf2ethos.dialogs.progressDisplay = false
        rf2ethos.dialogs.progress:close()
    end

end

function rf2ethos.openPageRATESLoader(idx, subpage, title, script)

    rf2ethos.uiState = rf2ethos.uiStatus.pages
    rf2ethos.triggers.mspDataLoaded = false

    rf2ethos.Page = assert(loadfile(config.toolDir .. "pages/" .. script))()
    collectgarbage()

    rf2ethos.dialogs.progressDisplay = true
    rf2ethos.dialogs.progressWatchDog = os.clock()
    rf2ethos.dialogs.progress = form.openProgressDialog("Loading...", "Loading data from flight controller.")
    rf2ethos.dialogs.progress:value(0)
    rf2ethos.dialogs.progress:closeAllowed(false)

    rf2ethos.lastIdx = idx
    rf2ethos.lastSubPage = subpage
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.lastPage = script

    rf2ethos.triggers.isLoading = true

    if config.environment.simulation == true then
        rf2ethos.openPageRATES(idx, subpage, title, script)
    end

    rf2ethos.utils.log("Finished: rf2ethos.openPageRATESLoader")
end

function rf2ethos.openPageRATES(idx, subpage, title, script)

    if rf2ethos.Page.fields then
        local v = rf2ethos.Page.fields[13].value
        if v ~= nil then
            activerf2ethos.RateTable = math.floor(v)
        end

        if activerf2ethos.RateTable ~= nil then
            if activerf2ethos.RateTable ~= rf2ethos.RateTable then
                rf2ethos.RateTable = activerf2ethos.RateTable
                if rf2ethos.dialogs.progressDisplay == true then
                    rf2ethos.dialogs.progressWatchDog = nil
                    rf2ethos.dialogs.progressDisplay = false
                    rf2ethos.dialogs.progress:close()
                end
                rf2ethos.openPageRATESLoader(idx, subpage, title, script)

            end
        end
    end

    rateswitchParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = rf2ethos.utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
    end

    rf2ethos.uiState = rf2ethos.uiStatus.pages

    longPage = false

    form.clear()

    fieldHeader(title)

    local numCols = #rf2ethos.Page.cols
    local screenWidth = rf2ethos.config.lcdWidth - 10
    local padding = 10
    local paddingTop = rf2ethos.radio.linePaddingTop
    local h = rf2ethos.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine(rf2ethos.Page.rTableName)

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = rf2ethos.Page.cols[loc]
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
    for ri, rv in ipairs(rf2ethos.Page.rows) do
        _G["rf2ethosmsp_RATEROWS_" .. ri] = form.addLine(rv)
    end

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageIdx = i
        local currentField = i

        if f.subpage == 1 then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * rf2ethos.utils.decimalInc(f.decimals)
            maxValue = f.max * rf2ethos.utils.decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end

            field = form.addNumberField(_G["rf2ethosmsp_RATEROWS_" .. f.row], pos, minValue, maxValue, function()
                local value = rf2ethos.getFieldValue(f)
                return value
            end, function(value)
                f.value = rf2ethos.saveFieldValue(f, value)
                rf2ethos.saveValue(i)
            end)
            if f.default ~= nil then
                local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
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
                if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                    local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                    field:help(helpTxt)
                end
            end
        end
    end

    if rf2ethos.dialogs.progressDisplay == true then
        rf2ethos.dialogs.progressWatchDog = nil
        rf2ethos.dialogs.progressDisplay = false
        rf2ethos.dialogs.progress:close()
    end

end

function rf2ethos.openMainMenu()

	local MainMenu = assert(loadfile(config.toolDir .. "pages.lua"))()

    if tonumber(rf2ethos.utils.makeNumber(config.environment.major .. config.environment.minor .. config.environment.revision)) < config.ethosVersion then
        return
    end

    -- clear all nav vars
    rf2ethos.lastIdx = nil
    rf2ethos.lastSubPage = nil
    rf2ethos.lastTitle = nil
    rf2ethos.lastScript = nil
    rf2ethos.lastPage = nil

    -- reset page to nil as should be nil on this page
    -- rf2ethos.Page = nil

    rf2ethos.triggers.mspDataLoaded = false
    rf2ethos.uiState = rf2ethos.uiStatus.mainMenu
    rf2ethos.triggers.escPowerCycle = false
    rf2ethos.escMenuState = 0

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/iconsize")
    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
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
                    if rf2ethos.config.iconsizeParam == 0 then
                        y = form.height() + rf2ethos.radio.buttonPaddingSmall
                    end
                    if rf2ethos.config.iconsizeParam == 1 then
                        y = form.height() + rf2ethos.radio.buttonPaddingSmall
                    end
                    if rf2ethos.config.iconsizeParam == 2 then
                        y = form.height() + rf2ethos.radio.buttonPadding
                    end
                end

                if lc >= 0 then
                    x = (buttonW + padding) * lc
                end

                if rf2ethos.config.iconsizeParam ~= 0 then
                    if rf2ethos.gfx_buttons[pidx] == nil then
                        rf2ethos.gfx_buttons[pidx] = lcd.loadMask(config.toolDir .. "gfx/menu/" .. pvalue.image)
                    end
                else
                    rf2ethos.gfx_buttons[pidx] = nil
                end

                form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                    text = pvalue.title,
                    icon = rf2ethos.gfx_buttons[pidx],
                    options = FONT_S,
                    paint = function()

                    end,
                    press = function()
                        if pvalue.script == "pids.lua" then
                            rf2ethos.openPagePIDLoader(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "servos.lua" then
                            rf2ethos.openPageSERVOSLoader(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "rates.lua" and pvalue.subpage == 1 then
                            rf2ethos.openPageRATESLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
                        elseif pvalue.script == "esc.lua" then
                            rf2ethos.openPageESC(pidx, pvalue.title, pvalue.script)
                        elseif pvalue.script == "preferences.lua" then
                            rf2ethos.openPagePreferences(pidx, pvalue.title, pvalue.script)
                        else
                            rf2ethos.openPageDefaultLoader(pidx, pvalue.subpage, pvalue.title, pvalue.script)
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

function rf2ethos.profileSwitchCheck()
    profileswitchParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/profileswitch")
    if profileswitchParam ~= nil then
        local s = rf2ethos.utils.explode(profileswitchParam, ",")
        profileswitchParam = system.getSource({category = s[1], member = s[2]})
        rf2ethos.triggers.profileswitchLast = profileswitchParam:value()
    end
end

function rf2ethos.rateSwitchCheck()
    rateswitchParam = rf2ethos.utils.loadPreference(config.toolDir .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = rf2ethos.utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
        rf2ethos.triggers.rateswitchLast = rateswitchParam:value()
    end
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

    rf2ethos.protocol = assert(loadfile(config.toolDir .. "protocols.lua"))()
    rf2ethos.radio = assert(loadfile(config.toolDir .. "radios.lua"))().msp
    rf2ethos.mspQueue = assert(loadfile(config.toolDir .. "msp/mspQueue.lua"))()
    rf2ethos.mspQueue.maxRetries = rf2ethos.protocol.maxRetries
    rf2ethos.mspHelper = assert(loadfile(config.toolDir .. "msp/mspHelper.lua"))()
    assert(loadfile(rf2ethos.protocol.mspTransport))()
    assert(loadfile(config.toolDir .. "msp/common.lua"))()

    rf2ethos.fieldHelpTxt = assert(loadfile(config.toolDir .. "help/fields.lua"))()

    -- Initial var setting
    -- rf2ethos.config.saveTimeout = rf2ethos.protocol.saveTimeout
    -- rf2ethos.config.maxRetries = rf2ethos.protocol.rf2ethos.config.maxRetries
    -- rf2ethos.config.requestTimeout = rf2ethos.protocol.pageReqTimeout
    rf2ethos.uiState = rf2ethos.uiStatus.init
 
    config.apiVersion = 0


    rf2ethos.openMainMenu()

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

end

local function close()
    rf2ethos.resetState()
    system.exit()
    return true
end

local icon = lcd.loadMask(config.toolDir .. "RF.png")

local function init()
    system.registerSystemTool({event = event, name = config.toolName, icon = icon, create = create, wakeup = wakeup, close = close})
end

return {init = init}
