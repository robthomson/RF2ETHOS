local template = assert(loadScriptRF2TOUCH(radio.template))()
local labels = {}
local fields = {}

fields[#fields + 1] = {t = "Full headspeed", min = 0, max = 50000, default = 1000, unit = "rpm", vals = {1, 2}}
fields[#fields + 1] = {t = "PID master gain", min = 0, max = 250, default = 40, vals = {3}}

labels[#labels + 1] = {subpage = 1, t = "Gains", label = 1, inline_size = 10}
fields[#fields + 1] = {t = "P", inline = 4, label = 1, min = 0, max = 250, default = 40, vals = {4}}
fields[#fields + 1] = {t = "I", inline = 3, label = 1, min = 0, max = 250, default = 50, vals = {5}}
fields[#fields + 1] = {t = "D", inline = 2, label = 1, min = 0, max = 250, default = 0, vals = {6}}
fields[#fields + 1] = {t = "F", inline = 1, label = 1, min = 0, max = 250, default = 10, vals = {7}}

labels[#labels + 1] = {subpage = 1, t = "Precomp", label = 2}
fields[#fields + 1] = {t = "Yaw", inline = 3, label = 2, min = 0, max = 250, default = 0, vals = {10}}
fields[#fields + 1] = {t = "Cyc", inline = 2, label = 2, min = 0, max = 250, default = 40, vals = {11}}
fields[#fields + 1] = {t = "Col", inline = 1, label = 2, min = 0, max = 250, default = 100, vals = {12}}

labels[#labels + 1] = {subpage = 1, t = "Tail Torque Assist", label = 3}
fields[#fields + 1] = {t = "Gain", inline = 2, label = 3, min = 0, max = 250, default = 0, vals = {8}}
fields[#fields + 1] = {t = "Limit", inline = 1, label = 3, min = 0, max = 250, default = 20, unit = "%", vals = {9}}

fields[#fields + 1] = {t = "Max throttle", min = 40, max = 100, default = 100, unit = "%", vals = {13}}

return {
    read = 148, -- MSP_GOVERNOR_PROFILE
    write = 149, -- MSP_SET_GOVERNOR_PROFILE
    title = "Profile - Governor",
    reboot = false,
    eepromWrite = true,
    minBytes = 13,
    labels = labels,
    fields = fields
}
