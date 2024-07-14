local labels = {}
local fields = {}
local escinfo = {}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "Scorpion ESC"}

fields[#fields + 1] = {t = "Protection Delay", min = 0, max = 5000, unit = "s", scale = 1000, vals = {mspHeaderBytes+41, mspHeaderBytes+42}}
fields[#fields + 1] = {t = "Cutoff Handling", min = 0, max = 10000, unit = "%", scale = 100, vals = {mspHeaderBytes+49, mspHeaderBytes+50}}

fields[#fields + 1] = {t = "Max Temperature", min = 0, max = 40000, unit = "°", scale = 100, vals = {mspHeaderBytes+45, mspHeaderBytes+46}}
fields[#fields + 1] = {t = "Max Current", min = 0, max = 30000, unit = "A", scale = 100, vals = {mspHeaderBytes+47, mspHeaderBytes+48}}
fields[#fields + 1] = {t = "Min Voltage", min = 0, max = 7000, unit = "v", decimals = 1, scale = 100, vals = {mspHeaderBytes+43, mspHeaderBytes+44}}
fields[#fields + 1] = {t = "Max Used", min = 0, max = 6000, unit = "Ah", scale = 100, vals = {mspHeaderBytes+51, mspHeaderBytes+52}}

return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot = false,
    title = "Limits",
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
