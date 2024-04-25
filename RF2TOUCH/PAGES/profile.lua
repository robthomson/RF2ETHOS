local template = assert(loadScript(radio.template))()

local labels = {}
local fields = {}


-- pid controller settings =
--labels[#labels + 1] = { subpage=1,t = "Error decay ground", t2="Ground Error Decay", label=1      }
	fields[#fields + 1] = { subpage=1,t = "Error decay ground",                   min = 0, max = 250,unit="s",default=250, vals = { 2 }, decimals=1, scale = 10 }

labels[#labels + 1] = { subpage=1,t = "Error decay cyclic", t2="Cyclic Error Decay", label=2       }
	fields[#fields + 1] = { subpage=1,t = "Time", inline=1,                   label=2, min = 0, max = 250,unit="s",default=180, vals = { 3 },decimals=1, scale = 10 }
	fields[#fields + 1] = { subpage=1,t = "Limit",inline=2,                   label=2, min = 0, max = 250,unit="°",default=20, vals = { 5 } }

labels[#labels + 1] = { subpage=1,t = "Error decay yaw", t2="Yaw Error Decay", label=3         }
	fields[#fields + 1] = { subpage=1,t = "Time",  inline=1,                   label=3,min = 0, max = 250,unit="s", vals = { 4 },decimals=1,scale = 10 }
	fields[#fields + 1] = { subpage=1,t = "Limit",  inline=2,                  label=3,min = 0, max = 250,unit="°", vals = { 6 } }

labels[#labels + 1] = { subpage=1,t = "Error limit", label=4             }
	fields[#fields + 1] = { subpage=1,t = "Roll", inline=3,                    label=4, min = 0, max = 180,default=30,unit="°", vals = { 8 } }
	fields[#fields + 1] = { subpage=1,t = "Pitch",  inline=1,                  label=4, min = 0, max = 180,default=30,unit="°", vals = { 9 } }
	fields[#fields + 1] = { subpage=1,t = "Yaw",  inline=2,                    label=4, min = 0, max = 180,default=45,unit="°", vals = { 10 } }

labels[#labels + 1] = { subpage=1,t = "Offset limit", label=5              }
	fields[#fields + 1] = { subpage=1,t = "Roll", inline=1,                    label=5, min = 0, max = 180,default=45,unit="°", vals = { 37 } }
	fields[#fields + 1] = { subpage=1,t = "Pitch", inline=2,                  label=5, min = 0, max = 180,default=45,unit="°", vals = { 38 } }
	fields[#fields + 1] = { subpage=1,t = "Error rotation",          min = 0, max = 1, vals = { 7 }, table = { [0] = "OFF", "ON" } }
	labels[#labels + 1] = { subpage=1,t = "I-term relax", label=6              }
	fields[#fields + 1] = { subpage=1,t = "Type",       			   label=6,min = 0, max = 2, vals = { 17 }, table = { [0] = "OFF", "RP", "RPY" } }
labels[#labels + 1] = { subpage=1,t = "        Cut-off point", label=15              }
	fields[#fields + 1] = { subpage=1,t = "R",inline=3,         label=15,min = 1, max = 100,default=10, vals = { 18 } }
	fields[#fields + 1] = { subpage=1,t = "P",inline=1,         label=15,min = 1, max = 100,default=10, vals = { 19 } }
	fields[#fields + 1] = { subpage=1,t = "Y",inline=2,         label=15,min = 1, max = 100,default=15, vals = { 20 } }


-- tail rotor settings
--labels[#labels + 1] = { subpage=2,t = "Yaw",  label=7                     }
	fields[#fields + 1] = { subpage=2,t = "CW stop gain",            xlabel=7,min = 25, max = 250,default=100, vals = { 21 } }
	fields[#fields + 1] = { subpage=2,t = "CCW stop gain",           xlabel=7,min = 25, max = 250,default=100, vals = { 22 } }
	fields[#fields + 1] = { subpage=2,t = "Precomp Cutoff",          xlabel=7,min = 0, max = 250,default=5,unit="Hz", vals = { 23 } }
	fields[#fields + 1] = { subpage=2,t = "Cyclic FF gain",          xlabel=7,min = 0, max = 250,default=30, vals = { 24 } }
	fields[#fields + 1] = { subpage=2,t = "Col. FF gain" ,         	xlabel=7,min = 0, max = 250,default=0, vals = { 25 } }
	fields[#fields + 1] = { subpage=2,t = "Col. imp FF gain",        xlabel=7,min = 0, max = 250,default=0, vals = { 26 } }
	fields[#fields + 1] = { subpage=2,t = "Col. imp FF decay",       xlabel=7,min = 0, max = 250,default=25, vals = { 27 } }

labels[#labels + 1] = { subpage=4,t = "Collective Pitch Compensation", label=8, type=1                  }
	fields[#fields + 1] = { subpage=4,t = "Gain", 			label=8,  min = 0, max = 250,default=0, vals = { 28 } }


-- pid controller bandwidth
labels[#labels + 1] = { subpage=3,t = "PID Controller Bandwidth", label=9,  type=1        }
	fields[#fields + 1] = { subpage=3,t = "R bandwidth",             label=9,min = 0, max = 250,default=50, vals = { 11 } }
	fields[#fields + 1] = { subpage=3,t = "P bandwidth",             label=9,min = 0, max = 250,default=50, vals = { 12 } }
	fields[#fields + 1] = { subpage=3,t = "Y bandwidth",             label=9,min = 0, max = 250,default=100, vals = { 13 } }
	fields[#fields + 1] = { subpage=3,t = "R D-term cut-off",        label=9,min = 0, max = 250,default=15, vals = { 14 } }
	fields[#fields + 1] = { subpage=3,t = "P D-term cut-off",        label=9,min = 0, max = 250,default=15, vals = { 15 } }
	fields[#fields + 1] = { subpage=3,t = "Y D-term cut-off",        label=9,min = 0, max = 250,default=20, vals = { 16 } }
	fields[#fields + 1] = { subpage=3,t = "R B-term cut-off",        label=9,min = 0, max = 250,default=15, vals = { 39 } }
	fields[#fields + 1] = { subpage=3,t = "P B-term cut-off",        label=9,min = 0, max = 250,default=15, vals = { 40 } }
	fields[#fields + 1] = { subpage=3,t = "Y B-term cut-off",        label=9,min = 0, max = 250,default=20, vals = { 41 } }


-- main rotor settings
labels[#labels + 1] = { subpage=4,t = "Cyclic Cross coupling", label=10          }
	fields[#fields + 1] = { subpage=4,t = "Gain",                    label=10, min = 0, max = 250,default=25, vals = { 34 } }
	fields[#fields + 1] = { subpage=4,t = "Ratio",                   label=10,min = 0, max = 200,default=0,unit="%", vals = { 35 } }
	fields[#fields + 1] = { subpage=4,t = "Cutoff",                  label=10,min = 1, max = 250,default=15,unit="Hz", vals = { 36 } }

-- auto leveling settings
labels[#labels + 1] = { subpage=5,t = "Acro trainer", label=11            }
	fields[#fields + 1] = { subpage=5,t = "Leveling gain",           label=11, min = 25, max = 255,default=75, vals = { 32 } }
	fields[#fields + 1] = { subpage=5,t = "Maximum angle",           label=11, min = 10, max = 80,default=20,unit="°", vals = { 33 } }

labels[#labels + 1] = { subpage=5,t = "Angle mode", label=12              }
	fields[#fields + 1] = { subpage=5,t = "Leveling gain",           label=12, min = 0, max = 200,default=40, vals = { 29 } }
	fields[#fields + 1] = { subpage=5,t = "Maximum angle",           label=12, min = 10, max = 90,default=55,unit="°", vals = { 30 } }

labels[#labels + 1] = { subpage=5,t = "Horizon mode", label=13             }
	fields[#fields + 1] = { subpage=5,t = "Leveling gain",           label=13, min = 0, max = 200,default=40, vals = { 31 } }

return {
    read        = 94, -- MSP_PID_PROFILE
    write       = 95, -- MSP_SET_PID_PROFILE
    title       = "Profile - Advanced",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 41,
    labels      = labels,
    fields      = fields,
	longPage	= true,
}
