local labels = {}
local fields = {}

local folder = "flrtr"
local ESC = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/init.lua"))()
local mspHeaderBytes = ESC.mspHeaderBytes
local mspSignature = ESC.mspSignature

fields[#fields + 1] = {t = "ESC mode", vals = {mspHeaderBytes + 23}}
fields[#fields + 1] = {t = "Lithium batteries", vals = {mspHeaderBytes + 24}}
fields[#fields + 1] = {t = "Low voltage prot", vals = {mspHeaderBytes + 25}}
fields[#fields + 1] = {t = "Temp prot", vals = {mspHeaderBytes + 26}}
fields[#fields + 1] = {t = "BEC output", vals = {mspHeaderBytes + 27}}
fields[#fields + 1] = {t = "Timing angle", vals = {mspHeaderBytes + 28}}
fields[#fields + 1] = {t = "Motor direction", vals = {mspHeaderBytes + 29}}
fields[#fields + 1] = {t = "Starting torque", min = 0, max = 15, vals = {mspHeaderBytes + 30}}
fields[#fields + 1] = {t = "Response speed", min = 1, max = 50, vals = {mspHeaderBytes + 31}}
fields[#fields + 1] = {t = "Buzzer volume", vals = {mspHeaderBytes + 32}}
fields[#fields + 1] = {t = "Current gain", vals = {mspHeaderBytes + 33}}
fields[#fields + 1] = {t = "Fan control", vals = {mspHeaderBytes + 34}}

local foundEsc = false
local foundEscDone = false

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

return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot = false,
    title = "Advanced Setup",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,
    simulatorResponse = {115, 0, 0, 0, 150, 231, 79, 190, 216, 78, 29, 169, 244, 1, 0, 0, 1, 0, 2, 0, 4, 76, 7, 148, 0, 6, 30, 125, 0, 15, 0, 3, 15, 1, 20, 0, 10, 0, 0, 0, 0, 0, 0, 2, 73, 240},
    svTiming = 0,
    svFlags = 0,
    postLoad = postLoad,
    navButtons = {menu = true, save = true, reload = true, tool = false, help = false},
    onNavMenu = onNavMenu,
    event = event,
    pageTitle = "Esc / Fly Rotor / Advanced",
    headerLine = rf2ethos.escHeaderLineText
}
