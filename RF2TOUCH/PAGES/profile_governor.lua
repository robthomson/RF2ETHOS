local template = assert(loadScript(radio.template))()
local labels = {}
local fields = {}

fields[#fields + 1] = { t = "Full headspeed",          min = 0, max = 50000,default=1000,unit="rpm", vals = { 1, 2 }}
fields[#fields + 1] = { t = "PID master gain",         min = 0, max = 250,default=40, vals = { 3 } }
fields[#fields + 1] = { t = "P-gain",                  min = 0, max = 250,default=40, vals = { 4 } }
fields[#fields + 1] = { t = "I-gain",                  min = 0, max = 250,default=50, vals = { 5 } }
fields[#fields + 1] = { t = "D-gain",                  min = 0, max = 250,default=0, vals = { 6 } }
fields[#fields + 1] = { t = "F-gain",                  min = 0, max = 250,default=10, vals = { 7 } }
fields[#fields + 1] = { t = "Yaw precomp.",            min = 0, max = 250,default=0, vals = { 10 } }
fields[#fields + 1] = { t = "Cyclic precomp.",         min = 0, max = 250,default=40, vals = { 11 } }
fields[#fields + 1] = { t = "Col. precomp.",           min = 0, max = 250,default=100, vals = { 12 } }
fields[#fields + 1] = { t = "TTA gain",                min = 0, max = 250,default=0, vals = { 8 } }
fields[#fields + 1] = { t = "TTA limit",               min = 0, max = 250,default=20, vals = { 9 } }
fields[#fields + 1] = { t = "Max throttle",            min = 40, max = 100,default=100,unit="%", vals = { 13 } }

return {
    read        = 148, -- MSP_GOVERNOR_PROFILE
    write       = 149, -- MSP_SET_GOVERNOR_PROFILE
    title       = "Profile - Governor",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 13,
    labels      = labels,
    fields      = fields,
	longPage	= true
}
