local labels = {}
local fields = {}
local escinfo = {}

local escMode = {[0] = "Heli Governor", "Heli Governor (stored)", "VBar Governor", "External Governor", "Airplane mode", "Boat mode", "Quad mode"}

local rotation = {[0] = "CCW", "CW"}

local becVoltage = {[0] = "5.1 V", "6.1 V", "7.3 V", "8.3 V", "Disabled"}

local teleProtocol = {[0] = "Standard", "VBar", "Jeti Exbus", "Unsolicited", "Futaba SBUS"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "Scorpion ESC"}

fields[#fields + 1] = {t = "ESC Mode", min = 0, max = #escMode, vals = {33, 34}, table = escMode}
fields[#fields + 1] = {t = "Rotation", min = 0, max = #rotation, vals = {37, 38}, table = rotation}
fields[#fields + 1] = {t = "BEC Voltage", min = 0, max = #becVoltage, vals = {35, 36}, table = becVoltage}

fields[#fields + 1] = {t = "Telemetry Protocol", min = 0, max = #teleProtocol, vals = {39, 40}, table = teleProtocol}

return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot = false,
    title = "Basic Setup",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,

    svFlags = 0,

    postLoad = function(self)

        local model = getEscType(self)
        local version = "v" .. getUInt(self, {59, 60})
        local firmware = string.format("%08X", getUInt(self, {55, 56, 57, 58}))
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

    end
}
