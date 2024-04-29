local template = assert(loadScript(radio.template))()

local labels = {}
local fields = {}

local gyroFilterType = {[0] = "NONE", "1ST", "2ND"}

labels[#labels + 1] = {t = "Gyro lowpass 1", label = 1}
fields[#fields + 1] = {t = "Filter type", label = 1, min = 0, max = #gyroFilterType, vals = {2}, table = gyroFilterType}
fields[#fields + 1] = {t = "Cutoff", label = 1, min = 0, max = 4000, unit = "Hz", default = 100, vals = {3, 4}}

labels[#labels + 1] = {t = "Gyro lowpass 1 dynamic", label = 2, type = 1}
fields[#fields + 1] = {t = "Min cutoff", label = 2, min = 0, max = 1000, unit = "Hz", vals = {16, 17}}
fields[#fields + 1] = {t = "Max cutoff", label = 2, min = 0, max = 1000, unit = "Hz", vals = {18, 19}}

labels[#labels + 1] = {t = "Gyro lowpass 2", label = 3}
fields[#fields + 1] = {t = "Filter type", label = 3, min = 0, max = #gyroFilterType, vals = {5}, table = gyroFilterType}
fields[#fields + 1] = {t = "Cutoff", label = 3, min = 0, max = 4000, unit = "Hz", vals = {6, 7}}

labels[#labels + 1] = {t = "Gyro notch 1", label = 4}
fields[#fields + 1] = {t = "Center", label = 4, min = 0, max = 4000, unit = "Hz", vals = {8, 9}}
fields[#fields + 1] = {t = "Cutoff", label = 4, min = 0, max = 4000, unit = "Hz", vals = {10, 11}}

labels[#labels + 1] = {t = "Gyro notch 2", label = 5}
fields[#fields + 1] = {t = "Center", label = 5, min = 0, max = 4000, unit = "Hz", vals = {12, 13}}
fields[#fields + 1] = {t = "Cutoff", label = 5, min = 0, max = 4000, unit = "Hz", vals = {14, 15}}

labels[#labels + 1] = {t = "Dynamic Notch Filters", label = 6}
fields[#fields + 1] = {t = "Count", label = 6, min = 0, max = 8, default = 4, vals = {20}}
fields[#fields + 1] = {t = "Q", label = 6, min = 10, max = 100, default = 200, vals = {21}, decimals = 1, scale = 10}
fields[#fields + 1] = {t = "Min Frequency", label = 6, min = 10, max = 200, default = 25, unit = "Hz", vals = {22, 23}}
fields[#fields + 1] = {t = "Max Frequency", label = 6, min = 100, max = 500, default = 245, unit = "Hz", vals = {24, 25}}

return {
    read = 92, -- MSP_FILTER_CONFIG
    write = 93, -- MSP_SET_FILTER_CONFIG
    eepromWrite = true,
    reboot = true,
    title = "Filters",
    minBytes = 25,
    labels = labels,
    fields = fields
}
