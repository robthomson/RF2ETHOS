
local labels = {}
local fields = {}



labels[#labels + 1] = { t = "P"	}
fields[#fields + 1] = { t = "Roll",             	field=2, label=1, min = 0, max = 1000, vals = { 1,2 } }
fields[#fields + 1] = { t = "Pitch",             field=2, label=1, min = 0, max = 1000, vals = { 9,10 } }
fields[#fields + 1] = { t = "Yaw",              	field=2, label=1, min = 0, max = 1000, vals = { 17,18 } }


labels[#labels + 1] = { t = "I" }
fields[#fields + 1] = { t = "Roll",              field=2, label=2, min = 0, max = 1000, vals = { 3,4 } }
fields[#fields + 1] = { t = "Pitch",             field=2, label=2, min = 0, max = 1000, vals = { 11,12 } }
fields[#fields + 1] = { t = "Yaw",             	field=2, label=2, min = 0, max = 1000, vals = { 19,20 } }


labels[#labels + 1] = { t = "O" }
fields[#fields + 1] = { t = "Roll",             	field=2, label=3, min = 0, max = 1000, vals = { 31,32 } }
fields[#fields + 1] = { t = "Pitch",             field=2, label=3, min = 0, max = 1000, vals = { 33,34 } }


labels[#labels + 1] = { t = "D" }
fields[#fields + 1] = { t = "Roll",             	field=2, label=4, min = 0, max = 1000, vals = { 5,6 } }
fields[#fields + 1] = { t = "Pitch",             field=2, label=4, min = 0, max = 1000, vals = { 13,14 } }
fields[#fields + 1] = { t = "Yaw",             	field=2, label=4, min = 0, max = 1000, vals = { 21,22 } }


labels[#labels + 1] = { t = "F" }
fields[#fields + 1] = { t = "Roll",             	field=2, label=5, min = 0, max = 1000, vals = { 7,8 } }
fields[#fields + 1] = { t = "Pitch",             field=2, label=5, min = 0, max = 1000, vals = { 15,16 } }
fields[#fields + 1] = { t = "Yaw",             	field=2, label=5, min = 0, max = 1000, vals = { 23,24 } }


labels[#labels + 1] = { t = "B" }
fields[#fields + 1] = { t = "Roll",             	field=2, label=6, min = 0, max = 1000, vals = { 25,26 } }
fields[#fields + 1] = { t = "Pitch",             field=2, label=6, min = 0, max = 1000, vals = { 27,28 } }
fields[#fields + 1] = { t = "Yaw",            	field=2, label=6, min = 0, max = 1000, vals = { 29,30 } }

return {
    read        = 112, -- MSP_PID_TUNING
    write       = 202, -- MSP_SET_PID_TUNING
    title       = "PIDs",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 34,
    labels      = labels,
    fields      = fields,
}
