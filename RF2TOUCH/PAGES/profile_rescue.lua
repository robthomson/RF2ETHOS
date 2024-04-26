local template = assert(loadScript(radio.template))()
local labels = {}
local fields = {}

--fields[#fields + 1] = { t = "Rescue mode enable",  min = 0, max = 2,     vals = { 1 }, table = { [0] = "Off", "On", "Alt hold" } }
fields[#fields + 1] = { t = "Rescue mode enable",    min = 0, max = 1, default=0,ftype="bool", type="1",     					vals = { 1 }, table = { [0] = "Off", "On" } }
fields[#fields + 1] = { t = "Flip to upright",       min = 0, max = 1, default=0,      					vals = { 2 }, table = { [0] = "No flip", "Flip" } }

labels[#labels + 1] = { subpage=1,t = "Pull-up", label="pullup"      }
	fields[#fields + 1] = { t = "Collective",    		 inline=2,label="pullup",min = 0, max = 1000, default=650, unit="%",type="1",  		vals = { 9,10 }, scale = 10 }
	fields[#fields + 1] = { t = "Time",          inline=1,label="pullup",min = 0, max = 250, default=50,    unit="s",   		vals = { 5 }, decimals=1, scale = 10 }

labels[#labels + 1] = { subpage=1,t = "Climb", label="climb"      }
fields[#fields + 1] = { t = "Collective",      inline=2,label="climb", min = 0, max = 1000, default=450, unit="%",  			vals = { 11,12 }, scale = 10 }
fields[#fields + 1] = { t = "Time",            inline=1,label="climb", min = 0, max = 250, default=200, unit="s",  			vals = { 6 }, decimals=1,scale = 10 }

labels[#labels + 1] = { subpage=1,t = "Hover", label="hover"       }
fields[#fields + 1] = { t = "Collective",      inline=2,label="hover",min = 0, max = 1000,default=350,unit="%",  			vals = { 13,14 }, decimals=1, scale = 10 }

labels[#labels + 1] = { subpage=1,t = "Flip", label="flip" ,inline_size=15     }
fields[#fields + 1] = { t = "Fail time",        inline=2,label="flip",min = 0, max = 250,default=100,unit="s",   			vals = { 7 }, decimals=1,scale = 10 }
fields[#fields + 1] = { t = "Exit time",        inline=1,label="flip",min = 0, max = 250,default=50,unit="s",   			vals = { 8 },decimals=1, scale = 10 }

labels[#labels + 1] = { subpage=1,t = "Gains", label="rescue" ,inline_size=10     }
fields[#fields + 1] = { t = "Level",      inline=4,label="rescue",min = 5, max = 250,default=40,unit=nil,   			vals = { 4 } }
fields[#fields + 1] = { t = "Flip",       inline=3,label="rescue",min = 5, max = 250,default=50,unit=nil,   			vals = { 3 } }
fields[#fields + 1] = { t = "Rate",       inline=2,label="rescue",min = 1, max = 1000,default=250,unit="°/s",  		vals = { 25,26 } }
fields[#fields + 1] = { t = "Accel",      inline=1,label="rescue",min = 1, max = 10000,default=2000,unit="°/s^2", 	vals = { 27,28 } }


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
