local template = assert(rf2ethos.loadScriptRF2ETHOS(radio.template))()
local labels = {}
local fields = {}

fields[#fields + 1] = {t = "Mode", min = 0, max = 4, vals = {1}, table = {[0] = "OFF", "PASSTHROUGH", "STANDARD", "MODE1", "MODE2"}}
fields[#fields + 1] = {t = "Handover throttle%", min = 10, max = 50, unit = "%", default = 20, vals = {20}}
fields[#fields + 1] = {t = "Startup time", min = 0, max = 600, unit = "s", default = 200, vals = {2, 3}, decimals = 1, scale = 10}
fields[#fields + 1] = {t = "Spoolup time", min = 0, max = 600, unit = "s", default = 100, vals = {4, 5}, decimals = 1, scale = 10}
fields[#fields + 1] = {t = "Tracking time", min = 0, max = 100, unit = "s", default = 10, vals = {6, 7}, decimals = 1, scale = 10}
fields[#fields + 1] = {t = "Recovery time", min = 0, max = 100, unit = "s", default = 21, vals = {8, 9}, decimals = 1, scale = 10}

labels[#labels + 1] = {t = "Auto Rotation", label = "ar", inline_size = 40.6}
fields[#fields + 1] = {t = "Bailout", inline = 1, label = "ar", min = 0, max = 100, unit = "s", default = 0, vals = {16, 17}, decimals = 1, scale = 10}

labels[#labels + 1] = {t = "", label = "ar2", inline_size = 40.6}
fields[#fields + 1] = {t = "Timeout", inline = 1, label = "ar2", min = 0, max = 100, unit = "s", default = 0, vals = {14, 15}, decimals = 1, scale = 10}

labels[#labels + 1] = {t = "", label = "ar3", inline_size = 40.6}
fields[#fields + 1] = {t = "Min Entry", inline = 1, label = "ar3", min = 0, max = 100, unit = "s", default = 50, vals = {18, 19}, decimals = 1, scale = 10}

fields[#fields + 1] = {t = "Zero throttle Timeout", min = 0, max = 100, unit = "s", default = 30, vals = {10, 11}, decimals = 1, scale = 10}
fields[#fields + 1] = {t = "HS signal timeout", min = 0, max = 100, unit = "s", default = 10, vals = {12, 13}, decimals = 1, scale = 10}
fields[#fields + 1] = {t = "HS filter cutoff", min = 0, max = 250, unit = "Hz", default = 10, vals = {22}}
fields[#fields + 1] = {t = "Volt. filter cutoff", min = 0, max = 250, unit = "Hz", default = 5, vals = {21}}
fields[#fields + 1] = {t = "TTA bandwidth", min = 0, max = 250, unit = "Hz", default = 0, vals = {23}}
fields[#fields + 1] = {t = "Precomp bandwidth", min = 0, max = 250, unit = "Hz", default = 10, vals = {24}}

return {
    read = 142, -- MSP_GOVERNOR_CONFIG
    write = 143, -- MSP_SET_GOVERNOR_CONFIG
    title = "Governor",
    reboot = true,
    eepromWrite = true,
    minBytes = 24,
    labels = labels,
    fields = fields
}
