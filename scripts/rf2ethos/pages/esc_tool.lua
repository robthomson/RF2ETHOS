local pages = {}

local mspSignature
local mspHeaderBytes
local mspBytes
local simulatorResponse
local escDetails = {}
local foundESC = false
local foundESCupdateTag = false
local showPowerCycleLoader = false
local showPowerCycleLoaderInProgress = false
local ESC
local powercycleLoader
local powercycleLoaderCounter = 0
local powercycleLoaderRateLimit = 2
local showPowerCycleLoaderFinished = false

local modelField
local versionField
local firmwareField

local findTimeoutClock = os.clock()
local findTimeout = math.floor(rf2ethos.msp.protocol.pageReqTimeout * 0.5)

local modelLine
local modelText
local modelTextPos = {x = 0, y = rf2ethos.app.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.app.radio.navbuttonHeight}

local function getESCDetails()
        local message = {
                command = 217, -- MSP_STATUS
                processReply = function(self, buf)

                        if buf[1] == mspSignature then

                                escDetails.model = ESC.getEscModel(buf)
                                escDetails.version = ESC.getEscVersion(buf)
                                escDetails.firmware = ESC.getEscFirmware(buf)

                                foundESC = true

                        end

                end,
                simulatorResponse = simulatorResponse
        }

        rf2ethos.msp.mspQueue:add(message)
end

local function openPage(pidx, title, script)

        rf2ethos.app.lastIdx = pidx
        rf2ethos.app.lastTitle = title
        rf2ethos.app.lastScript = script

        local folder = title

        ESC = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/init.lua"))()

        mspSignature = ESC.mspSignature
        mspHeaderBytes = ESC.mspHeaderBytes
        mspBytes = ESC.mspBytes
        simulatorResponse = ESC.simulatorResponse

        rf2ethos.app.formFields = {}
        rf2ethos.formLines = {}
        -- rf2ethos.utils.log("ui.openPageEscTool")

        local windowWidth = rf2ethos.config.lcdWidth
        local windowHeight = rf2ethos.config.lcdHeight

        local y = rf2ethos.app.radio.linePaddingTop

        form.clear()

        line = form.addLine("Esc" .. ' / ' .. ESC.toolName)

        buttonW = 100
        local x = windowWidth - buttonW

        rf2ethos.app.formNavigationFields['menu'] = form.addButton(line, {x = x - buttonW - 5, y = rf2ethos.app.radio.linePaddingTop, w = buttonW, h = rf2ethos.app.radio.navbuttonHeight}, {
                text = "MENU",
                icon = nil,
                options = FONT_S,
                paint = function()
                end,
                press = function()
                        rf2ethos.app.ui.openPage(pidx, "Esc", "esc.lua")

                end
        })
        rf2ethos.app.formNavigationFields['menu']:focus()

        rf2ethos.app.formNavigationFields['refresh'] = form.addButton(line, {x = x, y = rf2ethos.app.radio.linePaddingTop, w = buttonW, h = rf2ethos.app.radio.navbuttonHeight}, {
                text = "RELOAD",
                icon = nil,
                options = FONT_S,
                paint = function()
                end,
                press = function()
                        -- rf2ethos.app.ui.openPage(pidx, folder, "esc_tool.lua")
                        rf2ethos.app.Page = nil
                        local foundESC = false
                        local foundESCupdateTag = false
                        local showPowerCycleLoader = false
                        local showPowerCycleLoaderInProgress = false
                        rf2ethos.app.triggers.triggerReload = true
                end
        })
        rf2ethos.app.formNavigationFields['menu']:focus()

        ESC.pages = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/pages.lua"))()

        modelLine = form.addLine("")
        modelText = form.addStaticText(modelLine, modelTextPos, "")

        local buttonW
        local buttonH
        local padding
        local numPerRow

        -- size of buttons
        rf2ethos.config.iconsizeParam = rf2ethos.app.preferences.interface.iconSize

        if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
                rf2ethos.config.iconsizeParam = 1
        else
                rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
        end

        -- TEXT ICONS
        if rf2ethos.config.iconsizeParam == 0 then
                padding = rf2ethos.app.radio.buttonPaddingSmall
                buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.app.radio.buttonsPerRow - padding
                buttonH = rf2ethos.app.radio.navbuttonHeight
                numPerRow = rf2ethos.app.radio.buttonsPerRow
        end
        -- SMALL ICONS
        if rf2ethos.config.iconsizeParam == 1 then

                padding = rf2ethos.app.radio.buttonPaddingSmall
                buttonW = rf2ethos.app.radio.buttonWidthSmall
                buttonH = rf2ethos.app.radio.buttonHeightSmall
                numPerRow = rf2ethos.app.radio.buttonsPerRowSmall
        end
        -- LARGE ICONS
        if rf2ethos.config.iconsizeParam == 2 then

                padding = rf2ethos.app.radio.buttonPadding
                buttonW = rf2ethos.app.radio.buttonWidth
                buttonH = rf2ethos.app.radio.buttonHeight
                numPerRow = rf2ethos.app.radio.buttonsPerRow
        end

        local lc = 0
        local bx = 0

        if rf2ethos.app.gfx_buttons["esctool"] == nil then rf2ethos.app.gfx_buttons["esctool"] = {} end
        if rf2ethos.app.menuLastSelected["esctool"] == nil then rf2ethos.app.menuLastSelected["esctool"] = 1 end

        for pidx, pvalue in ipairs(ESC.pages) do

                if lc == 0 then
                        if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
                        if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.app.radio.buttonPaddingSmall end
                        if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.app.radio.buttonPadding end
                end

                if lc >= 0 then bx = (buttonW + padding) * lc end

                if rf2ethos.config.iconsizeParam ~= 0 then
                        if rf2ethos.app.gfx_buttons["esctool"][pvalue.image] == nil then rf2ethos.app.gfx_buttons["esctool"][pvalue.image] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/esc/" .. pvalue.image) end
                else
                        rf2ethos.app.gfx_buttons["esctool"][pvalue.image] = nil
                end

                -- rf2ethos.utils.log("x = " .. bx .. ", y = " .. y .. ", w = " .. buttonW .. ", h = " .. buttonH)
                rf2ethos.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                        text = pvalue.title,
                        icon = rf2ethos.app.gfx_buttons["esctool"][pvalue.image],
                        options = FONT_S,
                        paint = function()
                        end,
                        press = function()
                                rf2ethos.app.menuLastSelected["esctool"] = pidx
                                rf2ethos.app.ui.progessDisplay()

                                -- rf2ethos.app.ui.openPage(pidx, folder, "esc_form.lua",pvalue.script)
                                rf2ethos.app.ui.openPage(pidx, title, "esc/" .. folder .. "/pages/" .. pvalue.script)

                        end
                })

                if rf2ethos.app.menuLastSelected["esctool"] == pidx then rf2ethos.app.formFields[pidx]:focus() end

                if rf2ethos.app.triggers.escToolEnableButtons == true then
                        rf2ethos.app.formFields[pidx]:enable(true)
                else
                        rf2ethos.app.formFields[pidx]:enable(false)
                end

                lc = lc + 1

                if lc == numPerRow then lc = 0 end

        end

        rf2ethos.app.triggers.escToolEnableButtons = false
        getESCDetails()

end

local function wakeup()

        -- enable the form
        if foundESC == true and foundESCupdateTag == false then
                foundESCupdateTag = true

                if escDetails.model ~= nil and escDetails.model ~= nil and escDetails.firmware ~= nil then
                        local text = escDetails.model .. " " .. escDetails.version .. " " .. escDetails.firmware
                        rf2ethos.escHeaderLineText = text
                        modelText = form.addStaticText(modelLine, modelTextPos, text)
                end

                for i, v in ipairs(rf2ethos.app.formFields) do rf2ethos.app.formFields[i]:enable(true) end

                if ESC.powerCycle == true and showPowerCycleLoader == true then
                        powercycleLoader:close()
                        powercycleLoaderCounter = 0
                        showPowerCycleLoaderInProgress = false
                        showPowerCycleLoader = false
                        showPowerCycleLoaderFinished = true
                        rf2ethos.app.triggers.isReady = true
                end

                rf2ethos.app.triggers.closeProgressLoader = true

        end

        if showPowerCycleLoaderFinished == false and foundESCupdateTag == false and showPowerCycleLoader == false and
                ((findTimeoutClock <= os.clock() - findTimeout) or rf2ethos.app.dialogs.progressCounter >= 101) then
                rf2ethos.app.ui.progessDisplayClose()
                rf2ethos.app.dialogs.progressDisplay = false
                rf2ethos.app.triggers.isReady = true

                if ESC.powerCycle ~= true then modelText = form.addStaticText(modelLine, modelTextPos, "UNKNOWN") end

                if ESC.powerCycle == true then showPowerCycleLoader = true end

        end

        if showPowerCycleLoaderInProgress == true then

                local now = os.clock()
                if (now - powercycleLoaderRateLimit) >= 2 then

                        getESCDetails()

                        powercycleLoaderRateLimit = now
                        powercycleLoaderCounter = powercycleLoaderCounter + 5
                        powercycleLoader:value(powercycleLoaderCounter)

                        if powercycleLoaderCounter >= 100 then
                                powercycleLoader:close()
                                modelText = form.addStaticText(modelLine, modelTextPos, "UNKNOWN")
                                showPowerCycleLoaderInProgress = false
                                rf2ethos.app.triggers.disableRssiTimeout = false
                                showPowerCycleLoader = false
                                rf2ethos.app.audio.playTimeout = true
                                showPowerCycleLoaderFinished = true
                                rf2ethos.app.triggers.isReady = false
                        end

                end

        end

        if showPowerCycleLoader == true then
                if showPowerCycleLoaderInProgress == false then
                        showPowerCycleLoaderInProgress = true
                        rf2ethos.app.audio.playEscPowerCycle = true
                        rf2ethos.app.triggers.disableRssiTimeout = true
                        powercycleLoader = form.openProgressDialog("Searching...", "Please power cycle the speed controller...")
                        powercycleLoader:value(0)
                        powercycleLoader:closeAllowed(false)
                end
        end

end

local function event(widget, category, value, x, y)

        -- print("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

        if category == 5 or value == 35 then
                if powercycleLoader then powercycleLoader:close() end
                rf2ethos.app.ui.openPage(pidx, "Esc", "esc.lua")
                return true
        end

        return false
end

return {title = "ESC", openPage = openPage, wakeup = wakeup, event = event}
