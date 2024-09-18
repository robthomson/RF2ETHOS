local labels = {}
local fields = {}

local folder = "flrtr"
local ESC = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/init.lua"))()
local mspHeaderBytes = ESC.mspHeaderBytes
local mspSignature = ESC.mspSignature

fields[#fields + 1] = {t = "ESC type", vals = {mspHeaderBytes + 1}}
fields[#fields + 1] = {t = "Current spec", vals = {mspHeaderBytes + 3, mspHeaderBytes + 2}}
fields[#fields + 1] = {t = "Hardware version", vals = {mspHeaderBytes + mspHeaderBytes + 18}}
fields[#fields + 1] = {t = "Throttle min [us]", vals = {mspHeaderBytes + 20, mspHeaderBytes + 19}}
fields[#fields + 1] = {t = "Throttle max [us]", vals = {mspHeaderBytes + 22, mspHeaderBytes + 21}}

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

