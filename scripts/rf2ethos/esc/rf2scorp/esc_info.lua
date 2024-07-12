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
    postRead = function(self)
        rf2ethos.utils.log("postRead")
        if self.values[1] ~= mspSignature then
            rf2ethos.utils.log("Invalid ESC signature detected.")
            self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
        end
    end,
    postLoad = function(self)
        rf2ethos.utils.log("postLoad")
        if not self.values then
            return
        end
        local model = getEscType(self)
        local version = "v" .. getUInt(self, {59, 60})
        local firmware = string.format("%08X", getUInt(self, {55, 56, 57, 58}))

        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

    end
}
