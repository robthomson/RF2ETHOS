local labels = {}
local fields = {}

labels[#labels + 1] = {t = "ESC Parameters"}
fields[#fields + 1] = {t = "count", min = 0, max = 32, ro = true, vals = {1, 2}}
fields[#fields + 1] = {t = "Mode", min = -300, max = 300, ro = true, vals = {3, 4}}
fields[#fields + 1] = {t = "BEC", min = -300, max = 300, ro = true, vals = {5, 6}}
fields[#fields + 1] = {t = "Motor Timing", min = -300, max = 300, ro = true, vals = {7, 8}}
fields[#fields + 1] = {t = "Initial Torque", min = -300, max = 300, ro = true, vals = {9, 10}}
fields[#fields + 1] = {t = "P-Gain", min = 1, max = 10, ro = true, vals = {11, 12}}
fields[#fields + 1] = {t = "I-Gain", min = 1, max = 10, ro = true, vals = {13, 14}}
fields[#fields + 1] = {t = "Throttle Response", min = -300, max = 300, ro = true, vals = {15, 16}}
fields[#fields + 1] = {t = "Cutoff Type", min = -300, max = 300, ro = true, vals = {17, 18}}
fields[#fields + 1] = {t = "Cutoff Cell Voltage", min = -300, max = 300, ro = true, vals = {19, 20}}
fields[#fields + 1] = {t = "Active Freewheel", min = -300, max = 300, ro = true, vals = {21, 22}}
fields[#fields + 1] = {t = "ESC Type", min = -300, max = 300, ro = true, vals = {23, 24}}
fields[#fields + 1] = {t = "FW Version (LSW)", min = -300, max = 300, ro = true, vals = {25, 26}}
fields[#fields + 1] = {t = "FW Version (MSW)", min = -300, max = 300, ro = true, vals = {27, 28}}
fields[#fields + 1] = {t = "Serial No. (LSW)", min = -300, max = 300, ro = true, vals = {29, 30}}
fields[#fields + 1] = {t = "Serial No. (MSW)", min = -300, max = 300, ro = true, vals = {31, 32}}
fields[#fields + 1] = {t = "mAh Limit (x10mAh)", min = -300, max = 300, ro = true, vals = {33, 34}}
fields[#fields + 1] = {t = "Stick Zero (us)", min = 900, max = 1900, ro = true, vals = {35, 36}}
fields[#fields + 1] = {t = "Stick Range (us)", min = 600, max = 1500, ro = true, vals = {37, 38}}
fields[#fields + 1] = {t = "PWM Rate (us)", min = 300, max = 300, ro = true, vals = {39, 40}}
fields[#fields + 1] = {t = "Motor Pole Pairs", min = 1, max = 100, ro = true, vals = {41, 42}}
fields[#fields + 1] = {t = "Pinion Teeth", min = 1, max = 255, ro = true, vals = {43, 44}}
fields[#fields + 1] = {t = "Main Teeth", min = 1, max = 1800, ro = true, vals = {45, 46}}
fields[#fields + 1] = {t = "Min Start Power", min = 0, max = 26, ro = true, vals = {47, 48}}
fields[#fields + 1] = {t = "Max Start Power", min = 0, max = 31, ro = true, vals = {49, 50}}
fields[#fields + 1] = {t = "Telemetry Type", min = -300, max = 300, ro = true, vals = {51, 52}}
fields[#fields + 1] = {t = "Flags", min = -300, max = 300, ro = true, vals = {53, 54}}
fields[#fields + 1] = {t = "Batt Current Limit", min = 1, max = 655, ro = true, vals = {55, 56}}
fields[#fields + 1] = {t = "Soft Start", min = -300, max = 300, ro = true, vals = {57, 58}}
fields[#fields + 1] = {t = "Soft Run", min = -300, max = 300, ro = true, vals = {59, 60}}
fields[#fields + 1] = {t = "Soft Blend", min = -300, max = 300, ro = true, vals = {61, 62}}
fields[#fields + 1] = {t = "RPM/Throttle SetP.", min = -300, max = 300, ro = true, vals = {63, 64}}

return {
    read = 217, -- msp_ESC_PARAMETERS
    eepromWrite = false,
    reboot = false,
    title = "Debug",
    minBytes = mspBytes,
    labels = labels,
    fields = fields
}
