local template = assert(loadScript(radio.template))()

local labels = {}
local fields = {}

--labels[#labels + 1] = { t = "Accelerometer trim",     x = x,          y = inc.y(lineSpacing) }
fields[#fields + 1] = { t = "Roll",                   min = -300, max = 300,default=0,unit="°", vals = { 3, 4 } }
fields[#fields + 1] = { t = "Pitch",                  min = -300, max = 300,default=0,unit="°", vals = { 1, 2 } }

return {
    read        = 240, -- MSP_ACC_TRIM
    write       = 239, -- MSP_SET_ACC_TRIM
    eepromWrite = true,
    reboot      = false,
    title       = "Accelerometer",
    minBytes    = 4,
    labels      = labels,
    fields      = fields,
}
