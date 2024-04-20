
local labels = {}
local fields = {}

--1
labels[#labels + 1] = { t = "Error decay ground"       }
fields[#fields + 1] = { t = "Time",                    field=2,label=1, min = 0, max = 250, vals = { 2 }, scale = 10 }

--2
labels[#labels + 1] = { t = "Error decay cyclic"     }
fields[#fields + 1] = { t = "Time",                    field=2,label=2,min = 0, max = 250, vals = { 3 }, scale = 10 }
fields[#fields + 1] = { t = "Limit",                   field=2,label=2,min = 0, max = 250, vals = { 5 } }

--3
labels[#labels + 1] = { t = "Error decay yaw"        }
fields[#fields + 1] = { t = "Time",                    field=2,label=3,min = 0, max = 250, vals = { 4 }, scale = 10 }
fields[#fields + 1] = { t = "Limit",                   field=2,label=3,min = 0, max = 250, vals = { 6 } }

--4
labels[#labels + 1] = { t = "Error limit",           }
fields[#fields + 1] = { t = "Roll",                    field=2,label=4,min = 0, max = 180, vals = { 8 } }
fields[#fields + 1] = { t = "Pitch",                   field=2,label=4,min = 0, max = 180, vals = { 9 } }
fields[#fields + 1] = { t = "Yaw",                     field=2,label=4,min = 0, max = 180, vals = { 10 } }


-- 5
labels[#labels + 1] = { t = "Offset limit"          }
fields[#fields + 1] = { t = "Roll",                    field=2,label=5,min = 0, max = 180, vals = { 37 } }
fields[#fields + 1] = { t = "Pitch",                   field=2,label=5,min = 0, max = 180, vals = { 38 } }

fields[#fields + 1] = { t = "Error rotation",          field=0,min = 0, max = 1, vals = { 7 }, table = { [0] = "OFF", "ON" } }

labels[#labels + 1] = { t = "I-term relax"          }
fields[#fields + 1] = { t = "Type",				       field=0,label=6,min = 0, max = 2, vals = { 17 }, table = { [0] = "OFF", "RP", "RPY" } }

fields[#fields + 1] = { t = "Cut-off point R",         field=2,label=6,min = 1, max = 100, vals = { 18 } }
fields[#fields + 1] = { t = "Cut-off point P",         field=2,label=6,min = 1, max = 100, vals = { 19 } }
fields[#fields + 1] = { t = "Cut-off point Y",         field=2,label=6,min = 1, max = 100, vals = { 20 } }


-- 6
labels[#labels + 1] = { t = "Yaw"                     }
fields[#fields + 1] = { t = "CW stop gain",            field=2,label=7,min = 25, max = 250, vals = { 21 } }
fields[#fields + 1] = { t = "CCW stop gain",           field=2,label=7,min = 25, max = 250, vals = { 22 } }
fields[#fields + 1] = { t = "Precomp Cutoff",          field=2,label=7,min = 0, max = 250, vals = { 23 } }
fields[#fields + 1] = { t = "Cyclic FF gain",          field=2,label=7,min = 0, max = 250, vals = { 24 } }
fields[#fields + 1] = { t = "Col. FF gain",            field=2,label=7,min = 0, max = 250, vals = { 25 } }
fields[#fields + 1] = { t = "Col. imp FF gain",        field=2,label=7,min = 0, max = 250, vals = { 26 } }
fields[#fields + 1] = { t = "Col. imp FF decay",       field=2,label=7,min = 0, max = 250, vals = { 27 } }


-- 7
labels[#labels + 1] = { t = "Pitch"           }
fields[#fields + 1] = { t = "Col. FF gain",            field=2,label=8, min = 0, max = 250, vals = { 28 } }


-- 8
labels[#labels + 1] = { t = "PID Controller"           }
fields[#fields + 1] = { t = "R bandwidth",             field=2,label=9,min = 0, max = 250, vals = { 11 } }
fields[#fields + 1] = { t = "P bandwidth",             field=2,label=9,min = 0, max = 250, vals = { 12 } }
fields[#fields + 1] = { t = "Y bandwidth",             field=2,label=9,min = 0, max = 250, vals = { 13 } }
fields[#fields + 1] = { t = "R D-term cut-off",        field=2,label=9,min = 0, max = 250, vals = { 14 } }
fields[#fields + 1] = { t = "P D-term cut-off",        field=2,label=9,min = 0, max = 250, vals = { 15 } }
fields[#fields + 1] = { t = "Y D-term cut-off",        field=2,label=9,min = 0, max = 250, vals = { 16 } }
fields[#fields + 1] = { t = "R B-term cut-off",        field=2,label=9,min = 0, max = 250, vals = { 39 } }
fields[#fields + 1] = { t = "P B-term cut-off",        field=2,label=9,min = 0, max = 250, vals = { 40 } }
fields[#fields + 1] = { t = "Y B-term cut-off",        field=2,label=9,min = 0, max = 250, vals = { 41 } }

labels[#labels + 1] = { t = "Cross coupling"        }
fields[#fields + 1] = { t = "Gain",                    field=2,label=10,min = 0, max = 250, vals = { 34 } }
fields[#fields + 1] = { t = "Ratio",                   field=2,label=10,min = 0, max = 200, vals = { 35 } }
fields[#fields + 1] = { t = "Cutoff",                  field=2,label=10,min = 1, max = 250, vals = { 36 } }

labels[#labels + 1] = { t = "Acro trainer"          }
fields[#fields + 1] = { t = "Leveling gain",           field=2,label=11,min = 25, max = 255, vals = { 32 } }
fields[#fields + 1] = { t = "Maximum angle",           field=2,label=11,min = 10, max = 80, vals = { 33 } }

labels[#labels + 1] = { t = "Angle mode"             }
fields[#fields + 1] = { t = "Leveling gain",           field=2,label=12,min = 0, max = 200, vals = { 29 } }
fields[#fields + 1] = { t = "Maximum angle",           field=2,label=12,min = 10, max = 90, vals = { 30 } }

labels[#labels + 1] = { t = "Horizon mode"          }
fields[#fields + 1] = { t = "Leveling gain",           field=2,label=13,min = 0, max = 200, vals = { 31 } }

return {
    read        = 94, -- MSP_PID_PROFILE
    write       = 95, -- MSP_SET_PID_PROFILE
    title       = "Profile",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 41,
    labels      = labels,
    fields      = fields,
}
