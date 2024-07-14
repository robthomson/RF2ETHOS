local labels = {}
local fields = {}
local escinfo = {}

labels[#labels + 1] = {t = "ESC Parameters"}
labels[#labels + 1] = {t = "fw-ver"}

labels[#labels + 1] = {t = "hw-ver"}

labels[#labels + 1] = {t = "type"}

labels[#labels + 1] = {t = "name"}

fields[#fields + 1] = {t = "dummy field", min = 0, max = 0, vals = {100000}}

escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}

return {
    read = 217, -- msp_ESC_PARAMETERS
    eepromWrite = false,
    reboot = false,
    title = "Debug",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,
	simulatorResponse = {165, 0, 32, 0, 3, 0, 55, 0, 0, 0, 0, 0, 4, 0, 3, 0, 1, 0, 1, 0, 2, 0, 3, 0, 80, 3, 131, 148, 1, 0, 30, 170, 0, 0, 3, 0, 86, 4, 22, 3, 163, 15, 1, 0, 2, 0, 2, 0, 20, 0, 20, 0, 0, 0, 0, 0, 2, 19, 2, 0, 20, 0, 22, 0, 0, 0},
    postRead = function(self)
        if self.values[1] ~= mspSignature then
            -- self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
			rf2ethos.triggers.mspDataLoaded = true
            return
        end
    end,
    postLoad = function(self)

        if self.values[1] ~= mspSignature then
            -- self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
            return
        else
            local model = getEscTypeLabel(self.values)
            local version = getUInt(self, {29, 30, 31, 32})
            local firmware = string.format("%.5f", getUInt(self, {25, 26, 27, 28}) / 100000)
            self.escinfo[1].t = model
            self.escinfo[2].t = version
            self.escinfo[3].t = firmware
        end

    end
}
