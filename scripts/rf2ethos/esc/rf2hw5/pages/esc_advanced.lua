local labels = {}
local fields = {}
local escinfo = {}

local restartTime = {"1s", "1.5s", "2s", "2.5s", "3s"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "Governor", label = "gov", inline_size = 13.4}
fields[#fields + 1] = {t = "P-Gain", inline = 2, label = "gov", min = 0, max = 9, vals = {mspHeaderBytes + 70}}
fields[#fields + 1] = {t = "I-Gain", inline = 1, label = "gov", min = 0, max = 9, vals = {mspHeaderBytes + 71}}

labels[#labels + 1] = {t = "Soft Start", label = "start", inline_size = 40.6}
fields[#fields + 1] = {t = "Startup Time", inline = 1, label = "start", units = "s", min = 4, max = 25, vals = {mspHeaderBytes + 69}}

labels[#labels + 1] = {t = "", label = "start2", inline_size = 40.6}
fields[#fields + 1] = {t = "Restart Time", inline = 1, label = "start2", units = "s", tableIdxInc = -1, min = 0, max = #restartTime, vals = {mspHeaderBytes + 73}, table = restartTime}

labels[#labels + 1] = {t = "", label = "start3", inline_size = 40.6}
fields[#fields + 1] = {t = "Auto Restart", inline = 1, label = "start3", units = "s", min = 0, max = 90, vals = {mspHeaderBytes + 72}}

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
    simulatorResponse = {
        253, 0, 32, 32, 32, 80, 76, 45, 48, 52, 46, 49, 46, 48, 50, 32, 32, 32, 72, 87, 49, 49, 48, 54, 95, 86, 49, 48, 48, 52, 53, 54, 78, 66, 80, 108, 97, 116, 105, 110, 117, 109, 95, 86, 53, 32,
        32, 32, 32, 32, 80, 108, 97, 116, 105, 110, 117, 109, 32, 86, 53, 32, 32, 32, 32, 0, 0, 0, 3, 0, 11, 6, 5, 25, 1, 0, 0, 24, 0, 0, 2
    },
    postLoad = function(self)
        local model = getText(self, 49, 64)
        local version = getText(self, 17, 32)
        local firmware = getText(self, 1, 16)
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

        -- Startup Time
        f = self.fields[3]
        f.value = f.value + 4
    end,
    postRead = function(self)
        -- rf2ethos.utils.log("postRead")
        if self.values[1] ~= mspSignature then
            -- rf2ethos.utils.log("Invalid ESC signature detected.")
            self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
            rf2ethos.triggers.mspDataLoaded = true
        end
    end,
    preSave = function(self)

        self.values[2] = 0 -- save cmd

        -- Startup Time
        -- local f = self.fields[3]
        -- rf2ethos.PageValue(self, 69, f.value - 4)
        -- return self.values
    end
}
