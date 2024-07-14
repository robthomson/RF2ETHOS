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
	simulatorResponse = { 253, 0, 32, 32, 32, 80, 76, 45, 48, 52, 46, 49, 46, 48, 50, 32, 32, 32, 72, 87, 49, 49, 48, 54, 95, 86, 49, 48, 48, 52, 53, 54, 78, 66, 80, 108, 97, 116, 105, 110, 117, 109, 95, 86, 53, 32, 32, 32, 32, 32, 80, 108, 97, 116, 105, 110, 117, 109, 32, 86, 53, 32, 32, 32, 32, 0, 0, 0, 3, 0, 11, 6, 5, 25, 1, 0, 0, 24, 0, 0, 2 },
    postRead = function(self)
        --rf2ethos.utils.log("postRead")
        if self.values[1] ~= mspSignature then
            --rf2ethos.utils.log("Invalid ESC signature detected.")
            self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
			rf2ethos.triggers.mspDataLoaded = true
        end
    end,
    postLoad = function(self)

        local model = getText(self, 49, 64)
        local version = getText(self, 17, 32)
        local firmware = getText(self, 1, 16)
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

    end
}
