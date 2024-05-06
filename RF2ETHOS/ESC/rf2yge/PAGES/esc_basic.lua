
local labels = {}
local fields = {}
local escinfo = {}

local escMode = { 
    [0] = "Free (Attention!)",
    "Heli Ext Governor", 
    "Heli Governor", 
    "Heli Governor Store", 
    "Aero Glider", 
    "Aero Motor", 
    "Aero F3A"
}

local direction = {
    [0] = "Normal", 
    "Reverse"
}

local cuttoff = {
    [0] = "Off",
    "Slow Down",
    "Cutoff"
}

local cuttoffVoltage = {
    [0] = "2.9 V",
    "3.0 V",
    "3.1 V",
    "3.2 V",
    "3.3 V",
    "3.4 V",
}



escinfo[#escinfo + 1] = { t = "---"}
escinfo[#escinfo + 1] = { t = "---"}
escinfo[#escinfo + 1] = { t = "---"}

labels[#labels + 1] = { t = "ESC", label="esc1", inline_size=40.6  }
fields[#fields + 1] = { t = "ESC Mode",               inline=1, label="esc1", min = 1, max = #escMode, vals = { 3, 4 }, table = escMode }

labels[#labels + 1] = { t = "", label="esc2", inline_size=40.6  }
fields[#fields + 1] = { t = "Direction",              inline=1, label="esc2", min = 0, max = 1, vals = { 53 }, table = direction }

labels[#labels + 1] = { t = "", label="esc3", inline_size=40.6  }
fields[#fields + 1] = { t = "BEC",                    inline=1, label="esc3", min = 55, max = 84, vals = { 5, 6 }, scale = 10 }

labels[#labels + 1] = { t = "Limits", label="limits1", inline_size=40.6  }
fields[#fields + 1] = { t = "Cutoff Handling",        inline=1, label="limits1", min = 0, max = #cuttoff, vals = { 17, 18 }, table = cuttoff }

labels[#labels + 1] = { t = "", label="limits2" , inline_size=40.6  }
fields[#fields + 1] = { t = "Cutoff Cell Voltage",    inline=1, label="limits2", min = 0, max = #cuttoffVoltage, vals = { 19, 20 }, table = cuttoffVoltage }

labels[#labels + 1] = { t = "", label="limits3" , inline_size=40.6   }
fields[#fields + 1] = { t = "Current Limit (A)",      inline=1, label="limits3", min = 1, max = 65500, scale = 100, mult = 100, vals = { 55, 56 } }

return {
    read        = 217, -- MSP_ESC_PARAMETERS
    write       = 218, -- MSP_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot      = false,
    title       = "Basic Setup",
    minBytes    = mspBytes,
    labels      = labels,
    fields      = fields,
	escinfo		= escinfo,

    svFlags     = 0,

    postLoad = function(self)
        -- esc type
        local l = self.escinfo[1]
        l.t = getEscTypeLabel(self.values)

        -- SN
        l = self.escinfo[2]
        l.t = getUInt(self, { 29, 30, 31, 32 })

        -- FW ver
        l = self.escinfo[3]
        l.t = string.format("%.5f", getUInt(self, { 25, 26, 27, 28 }) / 100000)

        -- direction
        -- save flags, changed bit will be applied in pre-save
        local f = self.fields[2]
        self.svFlags = getPageValue(self, f.vals[1])
        f.value = bit32.extract(f.value, escFlags.spinDirection)

        -- set BEC voltage max (8.4 or 12.3)
        f = self.fields[3]
        f.max = bit32.extract(self.svFlags, escFlags.bec12v) == 0 and 84 or 123
    end,

    preSave = function (self)
        -- direction
        -- apply bits to saved flags
        local f = self.fields[2]
        setPageValue(self, f.vals[1], bit32.replace(self.svFlags, f.value, escFlags.spinDirection))

        return self.values
    end,
}
