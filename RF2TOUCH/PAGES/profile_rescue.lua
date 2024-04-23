local template = assert(loadScript(radio.template))()
local labels = {}
local fields = {}

--fields[#fields + 1] = { t = "Rescue mode enable",  min = 0, max = 2,     vals = { 1 }, table = { [0] = "Off", "On", "Alt hold" } }
fields[#fields + 1] = { t = "Rescue mode enable",    min = 0, max = 1, default=0,ftype="bool", type="1",     					vals = { 1 }, table = { [0] = "Off", "On" } }
fields[#fields + 1] = { t = "Flip to upright",       min = 0, max = 1, default=0,      					vals = { 2 }, table = { [0] = "No flip", "Flip" } }
fields[#fields + 1] = { t = "Pull-up collective",    min = 0, max = 1000, default=650, unit="%",type="1",  		vals = { 9,10 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Pull-up time",          min = 0, max = 250, default=50,    unit="s",   		vals = { 5 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Climb collective",      min = 0, max = 1000, default=450, unit="%",  			vals = { 11,12 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Climb time",            min = 0, max = 250, default=200, unit="s",  			vals = { 6 }, decimals=1,scale = 10 }
fields[#fields + 1] = { t = "Hover collective",      min = 0, max = 1000,default=350,unit="%",  			vals = { 13,14 }, decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Flip fail time",        min = 0, max = 250,default=100,unit="s",   			vals = { 7 }, decimals=1,scale = 10 }
fields[#fields + 1] = { t = "Exit time",             min = 0, max = 250,default=50,unit="s",   			vals = { 8 },decimals=1, scale = 10 }
fields[#fields + 1] = { t = "Rescue level gain",     min = 5, max = 250,default=40,unit=nil,   			vals = { 4 } }
fields[#fields + 1] = { t = "Rescue flip gain",      min = 5, max = 250,default=50,unit=nil,   			vals = { 3 } }
fields[#fields + 1] = { t = "Rescue max rate",       min = 1, max = 1000,default=250,unit="°/s",  		vals = { 25,26 } }
fields[#fields + 1] = { t = "Rescue max accel",      min = 1, max = 10000,default=2000,unit="°/s^2", 	vals = { 27,28 } }


return {
    read        = 146, -- MSP_RESCUE_PROFILE
    write       = 147, -- MSP_SET_RESCUE_PROFILE
    title       = "Profile - Rescue",
    reboot      = false,
    eepromWrite = true,
    minBytes    = 28,
    labels      = labels,
    fields      = fields,
	longPage	= true,
}
