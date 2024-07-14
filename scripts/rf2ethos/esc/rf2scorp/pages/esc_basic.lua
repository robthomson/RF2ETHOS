local labels = {}
local fields = {}
local escinfo = {}

local escMode = {"Heli Governor", "Heli Governor (stored)", "VBar Governor", "External Governor", "Airplane mode", "Boat mode", "Quad mode"}

local rotation = {"CCW", "CW"}

local becVoltage = {"5.1 V", "6.1 V", "7.3 V", "8.3 V", "Disabled"}

local teleProtocol = {"Standard", "VBar", "Jeti Exbus", "Unsolicited", "Futaba SBUS"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "Scorpion ESC"}

fields[#fields + 1] = {t = "ESC Mode", min = 0, max = #escMode, vals = {mspHeaderBytes + 33, mspHeaderBytes + 34}, tableIdxInc = -1,table = escMode}
fields[#fields + 1] = {t = "Rotation", min = 0, max = #rotation, vals = {mspHeaderBytes + 37, mspHeaderBytes + 38}, tableIdxInc = -1,table = rotation}
fields[#fields + 1] = {t = "BEC Voltage", min = 0, max = #becVoltage, vals = {mspHeaderBytes + 35, mspHeaderBytes + 36}, tableIdxInc = -1,table = becVoltage}

-- not a good idea to allow this to be changed
--fields[#fields + 1] = {t = "Telemetry Protocol", min = 0, max = #teleProtocol, vals = {mspHeaderBytes + 39, mspHeaderBytes + 40}, tableIdxInc = -1,table = teleProtocol}

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
	simulatorResponse = {83, 128, 84, 114, 105, 98, 117, 110, 117, 115, 32, 69, 83, 67, 45, 54, 83, 45, 56, 48, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 3, 0, 3, 0, 1, 0, 3, 0, 136, 19, 22, 3, 16, 39, 64, 31, 136, 19, 0, 0, 1, 0, 7, 2, 0, 6, 63, 0, 160, 15, 64, 31, 208, 7, 100, 0, 0, 0, 200, 0, 0, 0, 1, 0, 0, 0, 200, 250, 0, 0},
    svFlags = 0,
    postRead = function(self)
        if self.values[1] ~= mspSignature then
            self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
			rf2ethos.triggers.mspDataLoaded = true
            return
        end
    end,
    postLoad = function(self)
        local model = getEscType(self)
        local version = "v" .. getUInt(self, {59, 60})
        local firmware = string.format("%08X", getUInt(self, {55, 56, 57, 58}))
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware
    end,
    alterPayload = function(payload)
		payload[2] = 0
		return payload
	end	
}
