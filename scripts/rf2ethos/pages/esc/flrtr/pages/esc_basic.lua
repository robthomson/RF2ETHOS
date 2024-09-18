local labels = {}
local fields = {}

local folder = "flrtr"
local ESC = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/init.lua"))()
local mspHeaderBytes = ESC.mspHeaderBytes
local mspSignature = ESC.mspSignature

local flightMode = {"Helicopter","Fixed Wing"}
local govMode = {"External Governor","ESC Governor"}
local becVoltage = {"7.5","7.6","7.7","7.8","7.9",
                    "8.0","8.1","8.2","8.3","8.4","8.5","8.6","8.7","8.8","8.9",
                    "9.0","9.1","9.2","9.3","9.4","9.5","9.6","9.7","9.8","9.9",
                    "10.0","10.1","10.2","10.3","10.4","10.5","10.6","10.7","10.8","10.9",
                    "11.0","11.1","11.2","11.3","11.4","11.5","11.6","11.7","11.8","11.9",
                    "12.0"}
local motorDirection = {"CW","CCW"}

fields[#fields + 1] = {t = "ESC type", tablevals = {mspHeaderBytes + 1}, tableIdxInc = -1, table = flightMode}
fields[#fields + 1] = {t = "Governor", vals = {mspHeaderBytes + 23}, tableIdxInc = -1, table = govMode}
fields[#fields + 1] = {t = "Current spec", vals = {mspHeaderBytes + 3, mspHeaderBytes + 2}, unit="A"}
fields[#fields + 1] = {t = "Cell Count", vals = {mspHeaderBytes + 24}}
fields[#fields + 1] = {t = "BEC Voltage", vals = {mspHeaderBytes + 27}, tableIdxInc = -1, table = becVoltage, unit = "V"}
fields[#fields + 1] = {t = "Motor direction", vals = {mspHeaderBytes + 29}, tableIdxInc = -1, table = motorDirection}

--fields[#fields + 1] = {t = "Hardware version", vals = {mspHeaderBytes + mspHeaderBytes + 18}}  -- this val does not look correct.  regardless not in right place


function postLoad()
    rf2ethos.triggers.isReady = true
end

local function onNavMenu(self)
    rf2ethos.triggers.escToolEnableButtons = true
    rf2ethos.ui.openPage(pidx, folder, "esc_tool.lua")
end

local function event(widget, category, value, x, y)

    -- print("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

    if category == 5 or value == 35 then
        rf2ethos.ui.openPage(pidx, folder, "esc_tool.lua")
        return true
    end

    return false
end

local foundEsc = false
local foundEscDone = false
return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = false,
    reboot = false,
    title = "Basic Setup",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,
    simulatorResponse = {115, 0, 0, 0, 150, 231, 79, 190, 216, 78, 29, 169, 244, 1, 0, 0, 1, 0, 2, 0, 4, 76, 7, 148, 0, 6, 30, 125, 0, 15, 0, 3, 15, 1, 20, 0, 10, 0, 0, 0, 0, 0, 0, 2, 73, 240},
    svFlags = 0,
    postLoad = postLoad,
    navButtons = {menu = true, save = true, reload = true, tool = false, help = false},
    onNavMenu = onNavMenu,
    event = event,
    pageTitle = "Esc / Fly Rotor / Basic",
    headerLine = rf2ethos.escHeaderLineText
}

