
local labels = {}
local fields = {}

local gyroFilterType = { [0] = "NONE", "1ST", "2ND" }

labels[#labels + 1] = { t = "Gyro lowpass 1",            }
fields[#fields + 1] = { t = "Filter type",               field=2, label=1, min = 0, max = #gyroFilterType, vals = { 2 }, table = gyroFilterType }
fields[#fields + 1] = { t = "Cutoff",                    field=2, label=1, min = 0, max = 4000, vals = { 3, 4 } }

labels[#labels + 1] = { t = "Gyro lowpass 1 dynamic",    }
fields[#fields + 1] = { t = "Min cutoff",                field=2, label=2, min = 0, max = 1000, vals = { 16, 17 } }
fields[#fields + 1] = { t = "Max cutoff",                field=2, label=2, min = 0, max = 1000, vals = { 18, 19 } }

labels[#labels + 1] = { t = "Gyro lowpass 2",            }
fields[#fields + 1] = { t = "Filter type",               field=2, label=3, min = 0, max = #gyroFilterType, vals = { 5 }, table = gyroFilterType }
fields[#fields + 1] = { t = "Cutoff",                    field=2, label=3, min = 0, max = 4000, vals = { 6, 7 } }

labels[#labels + 1] = { t = "Gyro notch 1",              }
fields[#fields + 1] = { t = "Center",                    field=2, label=4, min = 0, max = 4000, vals = { 8, 9 } }
fields[#fields + 1] = { t = "Cutoff",                    field=2, label=4, min = 0, max = 4000, vals = { 10, 11 } }

labels[#labels + 1] = { t = "Gyro notch 2",              }
fields[#fields + 1] = { t = "Center",                    field=2, label=5, min = 0, max = 4000, vals = { 12, 13 } }
fields[#fields + 1] = { t = "Cutoff",                    field=2, label=5, min = 0, max = 4000, vals = { 14, 15 } }

labels[#labels + 1] = { t = "Dynamic Notch Filters",     }
fields[#fields + 1] = { t = "Count",                     field=2, label=6, min = 0, max = 8, vals = { 20 } }
fields[#fields + 1] = { t = "Q",                         field=2, label=6, min = 10, max = 100, vals = { 21 }, scale = 10 }
fields[#fields + 1] = { t = "Min Frequency",             field=2, label=6, min = 10, max = 200, vals = { 22, 23 } }
fields[#fields + 1] = { t = "Max Frequency",             field=2, label=6, min = 100, max = 500, vals = { 24, 25 } }

return {
    read        = 92, -- MSP_FILTER_CONFIG
    write       = 93, -- MSP_SET_FILTER_CONFIG
    eepromWrite = true,
    reboot      = true,
    title       = "Filters",
    minBytes    = 25,
    labels      = labels,
    fields      = fields,
}
