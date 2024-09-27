local fields = {}
local labels = {}

local version = rf2ethos.config.Version
local ethosVersion = rf2ethos.config.environment.major .. "." .. rf2ethos.config.environment.minor .. "." .. rf2ethos.config.environment.revision
local apiVersion = rf2ethos.config.apiVersion

local supportedMspVersion = ""
for i, v in ipairs(rf2ethos.config.supportedMspApiVersion) do
    if i == 1 then
        supportedMspVersion = v
    else
        supportedMspVersion = supportedMspVersion .. "," .. v
    end
end

if rf2ethos.config.useCompiler == true then
    compilation = "ON"
else
    compilation = "OFF"
end

if rf2ethos.runningInSimulator == true then
    simulation = "ON"
else
    simulation = "OFF"
end

local displayType = 3
local disableType = true
local displayPos
if rf2ethos.config.ethosRunningVersion >= 1516 then
    displayType = 0
    disableType = false
    
    local w, h = rf2ethos.utils.getWindowSize()
    local buttonW = 100
    local buttonWs = buttonW - (buttonW * 20) / 100
    local x = w - 15    
  
    displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = rf2ethos.app.radio.linePaddingTop, w = 300, h = rf2ethos.app.radio.navbuttonHeight}
end 
fields[1] = {t = "Version", value = version, type = displayType, disable = disableType, position = displayPos}
fields[2] = {t = "Ethos Version", value = ethosVersion, type = displayType, disable = disableType, position = displayPos}
fields[3] = {t = "MSP Version", value = apiVersion, type = displayType, disable = disableType, position = displayPos}
fields[4] = {t = "MSP Transport", value = string.upper(rf2ethos.protocol.mspProtocol), type = displayType, disable = disableType, position = displayPos}
fields[5] = {t = "Supported MSP Versions", value = supportedMspVersion, type = displayType, disable = disableType, position = displayPos}
fields[6] = {t = "Compilation", value = compilation, type = displayType, disable = disableType, position = displayPos}
fields[7] = {t = "Simulation", value = simulation, type = displayType, disable = disableType, position = displayPos}

function readMSP()
    rf2ethos.app.triggers.isReady = true
    rf2ethos.app.triggers.closeProgressLoader = true
end

function onToolMenu()

    local opener =
        "Rotorflight is an Opensource project. Contribution from other like minded people, keen to assist in making this software even better is welcomed and encouraged. You do not have to be a hardcore programmer to help"
    local credits =
        "Notable contributers to both the rotorflight firmware and this software are:  Petri Mattila, Egon Lubbers, Rob Thomson, Rob Gayle, Phil Kaighin, Robert Burrow, Keith Williams, Bertrand Songis, Venbs Zhou... and many more who have spent hours testing and providing feedback!"
    local license =
        "You may copy, distribute and modify the software as long as you track changes/dates in source files. Any modifications to or software including (via compiler) GPL-licensed code must also be made available under the GPL along with build & install instructions."

    local message = opener .. "\r\n\r\n" .. credits .. "\r\n\r\n" .. license .. "\r\n\r\n"

    local buttons = {
        {
            label = "CLOSE",
            action = function()
                return true
            end
        }
    }

    form.openDialog({
        width = rf2ethos.config.lcdWidth,
        title = "Credits",
        message = message,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
        end,
        options = TEXT_LEFT
    })

end

return {
    read = readMSP,
    write = nil,
    title = "Status",
    reboot = false,
    eepromWrite = false,
    minBytes = 0,
    wakeup = wakeup,
    labels = labels,
    fields = fields,
    refreshswitch = false,
    simulatorResponse = {},
    onToolMenu = onToolMenu,
    navButtons = {menu = true, save = false, reload = false, tool = true, help = true}
}
