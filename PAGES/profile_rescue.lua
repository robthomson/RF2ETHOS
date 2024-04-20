
local labels = {}
local fields = {}


fields[#fields + 1] = { t = "Rescue mode enable",    field=0, min = 0, max = 1, default=0,     					vals = { 1 }, table = { [0] = "Off", "On" } }
fields[#fields + 1] = { t = "Flip to upright",       field=0, min = 0, max = 1, default=0,     					vals = { 2 }, table = { [0] = "No flip", "Flip" } }
fields[#fields + 1] = { t = "Pull-up collective",    field=2, min = 0, max = 1000, default=650,suffix="%",		vals = { 9,10 }, mult = 10, scale = 10 }
fields[#fields + 1] = { t = "Pull-up time",          field=2, min = 0, max = 250, default=5,suffix="s",  		vals = { 5 }, scale = 10 }
fields[#fields + 1] = { t = "Climb collective",      field=2, min = 0, max = 1000, default=450,suffix="%", 		vals = { 11,12 }, mult = 10, scale = 10}
fields[#fields + 1] = { t = "Climb time",            field=2, min = 0, max = 250,  default=2,suffix="s",		vals = { 6 }, scale = 10 }
fields[#fields + 1] = { t = "Hover collective",      field=2, min = 0, max = 1000, default=350,suffix="%", 		vals = { 13,14 }, mult = 10, scale = 10}
fields[#fields + 1] = { t = "Flip fail time",        field=2, min = 0, max = 250, default=1,suffix="s",			vals = { 7 }, scale = 10 }
fields[#fields + 1] = { t = "Exit time",             field=2, min = 0, max = 250, default=5,suffix="s",			vals = { 8 }, scale = 10 }
fields[#fields + 1] = { t = "Rescue level gain",     field=2, min = 5, max = 250, default=40,suffix=nil,		vals = { 4 } }
fields[#fields + 1] = { t = "Rescue flip gain",      field=2, min = 5, max = 250, default=50,suffix=nil,		vals = { 3 } }
fields[#fields + 1] = { t = "Rescue max rate",       field=2, min = 1, max = 1000, default=250,suffix="°/s",	vals = { 25,26 }, mult = 10}
fields[#fields + 1] = { t = "Rescue max accel",      field=2, min = 1, max = 10000,default=2000,suffix="°/s^2",	vals = { 27,28 }, mult = 10 }


return {
    read        = 146, -- MSP_RESCUE_PROFILE
    write       = 147, -- MSP_SET_RESCUE_PROFILE
    title       = "Profile - Rescue",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 28,
    labels      = labels,
    fields      = fields,
}
