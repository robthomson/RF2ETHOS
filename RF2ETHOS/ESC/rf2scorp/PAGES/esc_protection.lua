
local labels = {}
local fields = {}


labels[#labels + 1] = { t = "Scorpion ESC",            }


fields[#fields + 1] = { t = "Protection Delay (s)",   min = 0, max = 5000, scale = 1000, mult = 100, vals = { 41, 42 } }
fields[#fields + 1] = { t = "Cutoff Handling (%)",    min = 0, max = 10000, scale = 100, mult = 100, vals = { 49, 50 } }

fields[#fields + 1] = { t = "Max Temperature (C)",    min = 0, max = 40000, scale = 100, mult = 100, vals = { 45, 46 } }
fields[#fields + 1] = { t = "Max Current (A)",        min = 0, max = 30000, scale = 100, mult = 100, vals = { 47, 48 } }
fields[#fields + 1] = { t = "Min Voltage (V)",        min = 0, max = 7000, scale = 100, mult = 100, vals = { 43, 44 } }
fields[#fields + 1] = { t = "Max Used (Ah)",          min = 0, max = 6000, scale = 100, mult = 100, vals = { 51, 52 } }

return {
    read        = 217, -- MSP_ESC_PARAMETERS
    write       = 218, -- MSP_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot      = false,
    title       = "Limits",
    minBytes    = mspBytes,
    labels      = labels,
    fields      = fields,

    svFlags     = 0,

    postLoad = function(self)
        -- esc type
        local l = self.labels[1]
        l.t = getEscType(self)

        -- SN
        l = self.labels[2]
        l.t = string.format("%08X", getUInt(self, { 55, 56, 57, 58 }))

        -- FW version
        l = self.labels[3]
        l.t = "v"..getUInt(self, { 59, 60 })
    end,
}
