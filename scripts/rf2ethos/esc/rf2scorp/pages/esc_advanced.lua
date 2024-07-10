local labels = {}
local fields = {}
local escinfo = {}

local onOff = {[0] = "On", "Off"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "Scorpion ESC"}

fields[#fields + 1] = {t = "Soft Start Time", unit = "s", min = 0, max = 60000, scale = 1000, vals = {mspHeaderBytes+61, mspHeaderBytes+62}}
fields[#fields + 1] = {t = "Runup Time", unit = "s", min = 0, max = 60000, scale = 1000, vals = {mspHeaderBytes+63, mspHeaderBytes+64}}
fields[#fields + 1] = {t = "Bailout", unit = "s", min = 0, max = 100000, scale = 1000, vals = {mspHeaderBytes+65, mspHeaderBytes+66}}

-- data types are IQ22 - decoded/encoded by FC - regual scaled integers here
fields[#fields + 1] = {t = "Gov Proportional", min = 30, max = 180, scale = 100, vals = {mspHeaderBytes+67, mspHeaderBytes+68, mspHeaderBytes+69, mspHeaderBytes+70}}
fields[#fields + 1] = {t = "Gov Integral", min = 150, max = 250, scale = 100, vals = {mspHeaderBytes+71, mspHeaderBytes+72, mspHeaderBytes+73, mspHeaderBytes+74}}

fields[#fields + 1] = {t = "Motor Startup Sound", min = 0, max = #onOff, vals = {mspHeaderBytes+53, mspHeaderBytes+54}, table = onOff}

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
