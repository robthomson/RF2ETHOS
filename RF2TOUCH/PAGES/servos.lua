local template = assert(loadScript(radio.template))()

local labels = {}
local fields = {}

fields[#fields + 1] = { t = "Servo",         min = 0, max = 7, vals = { 1 }, table = { [0] = "ELEVATOR", "CYCL L", "CYCL R", "TAIL" }, postEdit = function(self) self.servoChanged(self) end }
fields[#fields + 1] = { t = "Center",        min = 50, max = 2250,default=1500, vals = { 2,3 } }
fields[#fields + 1] = { t = "Min",           min = -1000, max = 1000,default=-700, vals = { 4,5 } }
fields[#fields + 1] = { t = "Max",           min = -1000, max = 1000,default=700, vals = { 6,7 } }
fields[#fields + 1] = { t = "Scale neg",     min = 100, max = 1000,default=500, vals = { 8,9 } }
fields[#fields + 1] = { t = "Scale pos",     min = 100, max = 1000,default=500, vals = { 10,11 } }
fields[#fields + 1] = { t = "Rate",          min = 50, max = 5000,default=333,unit="Hz", vals = { 12,13 } }
fields[#fields + 1] = { t = "Speed",         min = 0, max = 60000,default=0,unit="ms", vals = { 14,15 } }

return {
    read        = 120, -- MSP_SERVO_CONFIGURATIONS
    write       = 212, -- MSP_SET_SERVO_CONFIGURATION
    title       = "Servos",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 33,
    labels      = labels,
    fields      = fields,
    postRead = function(self)
        local servoCount = self.values[1]
        self.fields[1].max = servoCount - 1
        self.servoConfiguration = {}
        for i = 1, servoCount do
            self.servoConfiguration[i] = {}
            for j = 1, 16 do
                self.servoConfiguration[i][j] = self.values[1 + (i - 1) * 16 + j]
            end
        end
        if rfglobals.lastChangedServo == nil then
            rfglobals.lastChangedServo = 1
        end
        self.setValues(self, rfglobals.lastChangedServo)
        self.minBytes = 1 + 16
    end,
    setValues = function(self, servoIndex)
        self.values = {}
        self.values[1] = servoIndex - 1
        for i = 1, 16 do
            self.values[1 + i] = self.servoConfiguration[servoIndex][i]
        end
    end,
    servoChanged = function(self)
        rfglobals.lastChangedServo = self.values[1] + 1
        self.setValues(self, rfglobals.lastChangedServo)
        dataBindFields()  -- calling this throws an error due to variable scope not coming across.  what to do?
    end
}
