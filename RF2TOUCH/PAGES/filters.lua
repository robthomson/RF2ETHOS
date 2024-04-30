local template = assert(loadScriptRF2TOUCH(radio.template))()

local labels = {}
local fields = {}

local gyroFilterType = {[0] = "NONE", "1ST", "2ND"}

labels[#labels + 1] = {t = "Gyro lowpass 1", label = "line1", inline_size=30}
fields[#fields + 1] = {t = "Filter type", label = "line1", inline=1, min = 0, max = #gyroFilterType, vals = {2}, table = gyroFilterType}

labels[#labels + 1] = {t = "", label = "line2", inline_size=30}
fields[#fields + 1] = {t = "Cutoff", label = "line2", inline=1, min = 0, max = 4000, unit = "Hz", default = 100, vals = {3, 4}}

labels[#labels + 1] = {t = "Gyro lowpass 1 dynamic", label = "line3", inline_size=30, type = 1}
fields[#fields + 1] = {t = "Min cutoff", label = "line3", inline=1, min = 0, max = 1000, unit = "Hz", vals = {16, 17}}

labels[#labels + 1] = {t = "", label = "line4", inline_size=30}
fields[#fields + 1] = {t = "Max cutoff", label = "line4",inline=1, min = 0, max = 1000, unit = "Hz", vals = {18, 19}}

labels[#labels + 1] = {t = "Gyro lowpass 2", label = "line5", inline_size=30}
fields[#fields + 1] = {t = "Filter type", label = "line5", inline=1, min = 0, max = #gyroFilterType, vals = {5}, table = gyroFilterType}

labels[#labels + 1] = {t = "", label = "line6", inline_size=30}
fields[#fields + 1] = {t = "Cutoff", label = "line6", inline=1, min = 0, max = 4000, unit = "Hz", vals = {6, 7}}

labels[#labels + 1] = {t = "Gyro notch 1", label = "line7", inline_size=12}
fields[#fields + 1] = {t = "Center", label = "line7", inline=2, min = 0, max = 4000, unit = "Hz", vals = {8, 9}}
fields[#fields + 1] = {t = "Cutoff", label = "line7", inline=1, min = 0, max = 4000, unit = "Hz", vals = {10, 11}}

labels[#labels + 1] = {t = "Gyro notch 2", label = "line9", inline_size=12}
fields[#fields + 1] = {t = "Center", label = "line9",inline = 2, min = 0, max = 4000, unit = "Hz", vals = {12, 13}}
fields[#fields + 1] = {t = "Cutoff", label = "line9", inline=1, min = 0, max = 4000, unit = "Hz", vals = {14, 15}}

labels[#labels + 1] = {t = "Dynamic Notch Filters", label = "line11",inline_size=12}
fields[#fields + 1] = {t = "Count", label = "line11", inline=2, min = 0, max = 8, default = 4, vals = {20}}
fields[#fields + 1] = {t = "Q", label = "line11",inline=1, min = 10, max = 100, default = 200, vals = {21}, decimals = 1, scale = 10}

labels[#labels + 1] = {t = "", label = "line12", inline_size=12}
fields[#fields + 1] = {t = "Min", label = "line12",inline = 2, min = 10, max = 200, default = 25, unit = "Hz", vals = {22, 23}}
fields[#fields + 1] = {t = "Max", label = "line12", inline = 1, min = 100, max = 500, default = 245, unit = "Hz", vals = {24, 25}}

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
