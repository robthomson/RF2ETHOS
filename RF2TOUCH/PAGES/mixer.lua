local template = assert(loadScript(radio.template))()

local labels = {}
local fields = {}

labels[#labels + 1] = { t = "Swashplate",  label=1             }
fields[#fields + 1] = { t = "Geo correction",           label=1  ,min = -125,  max = 125,  vals = { 19 },decimals=1, scale = 5, step = 2 }
fields[#fields + 1] = { t = "Total pitch limit",        label=1  ,min = 0,     max = 3000, vals = { 10, 11 }, decimals=1, scale = 83.33333333333333, step = 1 }
fields[#fields + 1] = { t = "Phase angle",              label=1  ,min = -1800, max = 1800, vals = { 8, 9 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "TTA precomp",              label=1  ,min = 0,     max = 250,  vals = { 18 } }

labels[#labels + 1] = { t = "Swashplate link trims", label=2   }
fields[#fields + 1] = { t = "Roll trim %",              label=2  ,min = -1000, max = 1000, vals = { 12, 13 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Pitch trim %",             label=2  ,min = -1000, max = 1000, vals = { 14, 15 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Coll. trim %",             label=2  ,min = -1000, max = 1000, vals = { 16, 17 }, decimals=1, scale = 10 }

labels[#labels + 1] = { t = "Motorised tail",  label=3  }        
fields[#fields + 1] = { t = "Motor idle thr%",          label=3  ,min = 0,     max = 250,  vals = { 3 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Center trim",              label=3  ,min = -500,  max = 500,  vals = { 4,5 }, decimals=1, scale = 10 }

return {
    read        = 42, -- MSP_MIXER_CONFIG
    write       = 43, -- MSP_SET_MIXER_CONFIG
    eepromWrite = true,
    reboot      = false,
    title       = "Mixer",
    minBytes    = 19,
    labels      = labels,
    fields      = fields,
}
