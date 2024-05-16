local template = assert(rf2ethos.loadScriptRF2ETHOS(radio.template))()

local labels = {}
local fields = {}

fields[#fields + 1] = {t = "ServoID (shown only for debug)", min = 0, max = 100, vals = {1}}
fields[#fields + 1] = {t = "Center", min = 50, max = 2250, default = 1500, vals = {2, 3}}
fields[#fields + 1] = {t = "Minimum", min = -1000, max = 1000, default = -700, vals = {4, 5}}
fields[#fields + 1] = {t = "Maximum", min = -1000, max = 1000, default = 700, vals = {6, 7}}

fields[#fields + 1] = {t = "Scale Negative", min = 100, max = 1000, default = 500, vals = {8, 9}}
fields[#fields + 1] = {t = "Scale Positive", min = 100, max = 1000, default = 500, vals = {10, 11}}

fields[#fields + 1] = {t = "Rate", min = 50, max = 5000, default = 333, unit = "Hz", vals = {12, 13}}
fields[#fields + 1] = {t = "Speed", min = 0, max = 60000, default = 0, unit = "ms", vals = {14, 15}}

return {
    read = 120, -- MSP_SERVO_CONFIGURATIONS
    write = 212, -- MSP_SET_SERVO_CONFIGURATION
    title = "Servos",
    reboot = false,
    eepromWrite = true,
    minBytes = 33,
    labels = labels,
    fields = fields,
    postRead = function(self)
        self.servoCount = self.values[1]
        if rf2ethos.lastServoCount ~= self.servoCount then
            rf2ethos.lastServoCount = self.servoCount
            createForm = true
            reloadServos = true
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
    setValues = function(self, servoIndex)
        self.values = {}
        self.values[1] = servoIndex - 1
        for i = 1, 16 do
            self.values[1 + i] = self.servoConfiguration[servoIndex][i]
        end
    end,
    servoChanged = function(self, servoIndex)
        rf2ethos.lastChangedServo = servoIndex
        self.setValues(self, rf2ethos.lastChangedServo)
        rf2ethos.dataBindFields()
    end
}
