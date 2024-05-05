
local labels = {}
local fields = {}
local escinfo = {}

local startupPower = {
    [0] = "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
}

local enabledDisabled = {
    [0] = "Enabled",
    "Disabled",
}

local brakeType = { 
    [0] = "Disabled",
    "Normal",
    "Proportional",
    "Reverse"
}

escinfo[#escinfo + 1] = { t = "---"}
escinfo[#escinfo + 1] = { t = "---"}
escinfo[#escinfo + 1] = { t = "---"}

labels[#labels + 1] = { t = "Motor",  label="motor1", inline_size=40.6                }
fields[#fields + 1] = { t = "Timing",                 inline=1, label="motor1", min = 0, max = 30, vals = { 76 } }

labels[#labels + 1] = { t = "",  label="motor2", inline_size=40.6                }
fields[#fields + 1] = { t = "Startup Power",          inline=1,label="motor2", min = 0, max = #startupPower, vals = { 79 }, table = startupPower }

labels[#labels + 1] = { t = "",  label="motor3", inline_size=40.6                }
fields[#fields + 1] = { t = "Active Freewheel",       inline=1, label="motor3", min = 0, max = #enabledDisabled, vals = { 78 }, table = enabledDisabled }

labels[#labels + 1] = { t = "Brake",  label="brake1", inline_size=40.6                  }
fields[#fields + 1] = { t = "Brake Type",             inline=1, label="brake1", min = 0, max = #brakeType, vals = { 74 }, table = brakeType }

labels[#labels + 1] = { t = "",  label="brake2", inline_size=40.6                }
fields[#fields + 1] = { t = "Brake Force %",          inline=1, label="brake2", min = 0, max = 100, vals = { 75 } }

return {
    read        = 217, -- MSP_ESC_PARAMETERS
    write       = 218, -- MSP_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot      = false,
    title       = "Other Settings",
    minBytes    = mspBytes,
    labels      = labels,
    fields      = fields,
	escinfo		= escinfo,

    postLoad = function(self)
		local model = getText(self, 49, 64)
		local version = getText(self, 17, 32)
		local firmware = getText(self, 1, 16)			
		self.escinfo[1].t = model
		self.escinfo[2].t = version	
		self.escinfo[3].t = firmware
    end,
}