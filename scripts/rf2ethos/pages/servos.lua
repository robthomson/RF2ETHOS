local labels = {}
local fields = {}

fields[#fields + 1] = {t = "ServoID (shown only for debug)", min = 0, max = 100, vals = {1}}
fields[#fields + 1] = {t = "Center", help = "servoMid", min = 50, max = 2250, default = 1500, vals = {2, 3}}
fields[#fields + 1] = {t = "Minimum", help = "servoMin", min = -1000, max = 1000, default = -700, vals = {4, 5}}
fields[#fields + 1] = {t = "Maximum", help = "servoMax", min = -1000, max = 1000, default = 700, vals = {6, 7}}

fields[#fields + 1] = {t = "Scale Negative", help = "servoScaleNeg", min = 100, max = 1000, default = 500, vals = {8, 9}}
fields[#fields + 1] = {t = "Scale Positive", help = "servoScalePos", min = 100, max = 1000, default = 500, vals = {10, 11}}

fields[#fields + 1] = {t = "Rate", help = "servoRate", min = 50, max = 5000, default = 333, unit = "Hz", vals = {12, 13}}
fields[#fields + 1] = {t = "Speed", help = "servoSpeed", min = 0, max = 60000, default = 0, unit = "ms", vals = {14, 15}}

return {
    read = 120, -- msp_SERVO_CONFIGURATIONS
    write = 212, -- msp_SET_SERVO_CONFIGURATION
    title = "Servos",
    reboot = false,
    eepromWrite = true,
    minBytes = 33,
    labels = labels,
    fields = fields,
    simulatorResponse = {
        4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0, 120, 5,
        212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
    },
    postRead = function(self)
        rf2ethos.utils.log("postRead")
        self.servoCount = self.values[1]
        if rf2ethos.lastServoCount ~= self.servoCount then
            rf2ethos.lastServoCount = self.servoCount
        end
        -- self.fields[1].max = servoCount - 1
        self.servoConfiguration = {}
        for i = 1, self.servoCount do
            self.servoConfiguration[i] = {}
            for j = 1, 16 do
                self.servoConfiguration[i][j] = self.values[1 + (i - 1) * 16 + j]
            end
        end
        if rf2ethos.lastChangedServo == nil then
            rf2ethos.lastChangedServo = 1
        end
        self.setValues(self, rf2ethos.lastChangedServo)
        self.minBytes = 1 + 16
    end,
    postLoad = function(self)
        rf2ethos.utils.log("postLoad")
    end,
    setValues = function(self, servoIndex)
        rf2ethos.utils.log("setValues")
        self.values = {}
        self.values[1] = servoIndex - 1
        for i = 1, 16 do
            self.values[1 + i] = self.servoConfiguration[servoIndex][i]
        end
    end,
    servoChanged = function(self, servoIndex)
        rf2ethos.utils.log("servoChanged")
        rf2ethos.lastChangedServo = servoIndex
        self.setValues(self, rf2ethos.lastChangedServo)
        rf2ethos.dataBindFields()
    end
}
