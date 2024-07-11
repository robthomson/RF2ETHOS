local labels = {}
local fields = {}
local escinfo = {}

local restartTime = {[0] = "1s", "1.5s", "2s", "2.5s", "3s"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "Governor", label = "gov", inline_size = 13.4}
fields[#fields + 1] = {t = "P-Gain", inline = 2, label = "gov", min = 0, max = 9, vals = {mspHeaderBytes + 70}}
fields[#fields + 1] = {t = "I-Gain", inline = 1, label = "gov", min = 0, max = 9, vals = {mspHeaderBytes + 71}}

labels[#labels + 1] = {t = "Soft Start", label = "start", inline_size = 40.6}
fields[#fields + 1] = {t = "Startup Time", inline = 1, label = "start", units = "s", min = 4, max = 25, vals = {mspHeaderBytes + 69}}

labels[#labels + 1] = {t = "", label = "start2", inline_size = 40.6}
fields[#fields + 1] = {t = "Restart Time", inline = 1, label = "start2", units = "s", min = 0, max = #restartTime, vals = {mspHeaderBytes + 73}, table = restartTime}

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
        print("postRead")
        if self.values[1] ~= mspSignature then
            print("Invalid ESC signature detected.")
            self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
        end
    end,
    preSave = function(self)

        self.values[2] = 0 -- save cmd

        -- Startup Time
        local f = self.fields[3]
        setPageValue(self, 69, f.value - 4)
        return self.values
    end
}
