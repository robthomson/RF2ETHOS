
local labels = {}
local fields = {}

local startupPower = {
    [0] = "level-1",
    "level-2",
    "level-3",
    "level-4",
    "level-5",
    "level-6",
    "level-7",
}

local enabledDisabled = {
    [0] = "Enabled",
    "Disabled",
}

local brakeType = { 
    [0] = "Disabled",
    "Normal",
    "Proportional",
    "Reverse"
}

labels[#labels + 1] = { t = "ESC",                    }


labels[#labels + 1] = { t = "Motor",                   }
fields[#fields + 1] = { t = "Timing",                 min = 0, max = 30, vals = { 76 } }
fields[#fields + 1] = { t = "Startup Power",          min = 0, max = #startupPower, vals = { 79 }, table = startupPower }
fields[#fields + 1] = { t = "Active Freewheel",       min = 0, max = #enabledDisabled, vals = { 78 }, table = enabledDisabled }

fields[#fields + 1] = { t = "Brake Type",             min = 0, max = #brakeType, vals = { 74 }, table = brakeType }
fields[#fields + 1] = { t = "Brake Force %",          min = 0, max = 100, vals = { 75 } }

return {
    read        = 217, -- MSP_ESC_PARAMETERS
    write       = 218, -- MSP_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot      = false,
    title       = "Other Settings",
    minBytes    = mspBytes,
    labels      = labels,
    fields      = fields,

    postLoad = function(self)
        -- esc type
        local l = self.labels[1]
        -- local type = getText(self, 33, 48)
        local name = getText(self, 49, 64)
        l.t = name

        -- HW ver
        l = self.labels[2]
        l.t = getText(self, 17, 32)

        -- FW ver
        l = self.labels[3]
        l.t = getText(self, 1, 16)
    end,
}
