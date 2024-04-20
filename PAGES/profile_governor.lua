

local labels = {}
local fields = {}

fields[#fields + 1] = { t = "Full headspeed",          field=2, min = 0, max = 50000, default=1000,suffix="rpm",	vals = { 1, 2 }}
fields[#fields + 1] = { t = "PID master gain",         field=2, min = 0, max = 250, default=50,suffix=nil,			vals = { 3 } }
fields[#fields + 1] = { t = "P-gain",                  field=2, min = 0, max = 250, default=40,suffix=nil,			vals = { 4 } }
fields[#fields + 1] = { t = "I-gain",                  field=2, min = 0, max = 250, default=50,suffix=nil,			vals = { 5 } }
fields[#fields + 1] = { t = "D-gain",                  field=2, min = 0, max = 250, default=0,suffix=nil,			vals = { 6 } }
fields[#fields + 1] = { t = "F-gain",                  field=2, min = 0, max = 250, default=10,suffix=nil,			vals = { 7 } }
fields[#fields + 1] = { t = "Yaw precomp.",            field=2, min = 0, max = 250, default=0,suffix=nil,			vals = { 10 } }
fields[#fields + 1] = { t = "Cyclic precomp.",         field=2, min = 0, max = 250, default=40,suffix=nil,			vals = { 11 } }
fields[#fields + 1] = { t = "Col. precomp.",           field=2, min = 0, max = 250, default=100,suffix=nil,			vals = { 12 } }
fields[#fields + 1] = { t = "TTA gain",                field=2, min = 0, max = 250, defaut=0,suffix=nil,			vals = { 8 } }
fields[#fields + 1] = { t = "TTA limit",               field=2, min = 0, max = 250, default=20,suffix=nil,			vals = { 9 } }
fields[#fields + 1] = { t = "Max throttle",            field=2, min = 40, max = 100, default=100,suffix="%", 		vals = { 13 } }

return {
    read        = 148, -- MSP_GOVERNOR_PROFILE
    write       = 149, -- MSP_SET_GOVERNOR_PROFILE
    title       = "Profile - Governor",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 13,
    labels      = labels,
    fields      = fields,
}
