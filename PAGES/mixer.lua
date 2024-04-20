
local labels = {}
local fields = {}

labels[#labels + 1] = { t = "Swashplate",                }
fields[#fields + 1] = { t = "Geo correction",           field=2, label=1, min = -125,  max = 125,  vals = { 19 }, scale = 5 }
fields[#fields + 1] = { t = "Total pitch limit",        field=2, label=1, min = 0,     max = 3000, vals = { 10, 11 }, scale = 83.33333333333333, mult = 8.3333333333333 }
fields[#fields + 1] = { t = "Phase angle",              field=2, label=1, min = -1800, max = 1800, vals = { 8, 9 }, scale = 10, mult = 5 }
fields[#fields + 1] = { t = "TTA precomp",              field=2, label=1, min = 0,     max = 250,  vals = { 18 } }

labels[#labels + 1] = { t = "Swashplate link trims",     }
fields[#fields + 1] = { t = "Roll trim %",              field=2, label=2, min = -1000, max = 1000, vals = { 12, 13 }, scale = 10 }
fields[#fields + 1] = { t = "Pitch trim %",             field=2, label=2, min = -1000, max = 1000, vals = { 14, 15 }, scale = 10 }
fields[#fields + 1] = { t = "Coll. trim %",             field=2, label=2, min = -1000, max = 1000, vals = { 16, 17 }, scale = 10 }

labels[#labels + 1] = { t = "Motorised tail",            }
fields[#fields + 1] = { t = "Motor idle thr%",          field=2, label=3, min = 0,     max = 250,  vals = { 3 }, scale = 10 }
fields[#fields + 1] = { t = "Center trim",              field=2, label=3, min = -500,  max = 500,  vals = { 4,5 }, scale = 10 }

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
