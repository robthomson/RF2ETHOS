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

    svFlags = 0,

    postLoad = function(self)

        local model = getEscType(self)
        local version = "v" .. getUInt(self, {59, 60})
        local firmware = string.format("%08X", getUInt(self, {55, 56, 57, 58}))
        if self.values[1] ~= mspSignature then 
            --self.values = nil
			self.escinfo[1].t = ""		
			self.escinfo[2].t = ""
			self.escinfo[2].t = ""			
            return
		else
			self.escinfo[1].t = model
			self.escinfo[2].t = version
			self.escinfo[3].t = firmware		
        end	

    end
}
