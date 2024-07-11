
local labels = {}
local fields = {}

-- labels[#labels + 1] = { t = "Accelerometer trim",     x = x,          y = inc.y(lineSpacing) }
fields[#fields + 1] = {t = "Roll", help = "accelerometerTrim", min = -300, max = 300, default = 0, unit = "°", vals = {3, 4}}
fields[#fields + 1] = {t = "Pitch", help = "accelerometerTrim", min = -300, max = 300, default = 0, unit = "°", vals = {1, 2}}

return {
    read = 240, -- msp_ACC_TRIM
    write = 239, -- msp_SET_ACC_TRIM
    eepromWrite = true,
	simulatorResponse = { 0, 0, 0, 0 },
    reboot = false,
    title = "Accelerometer",
    minBytes = 4,
    labels = labels,
    fields = fields,
	postRead = function(self)
		print("postRead")
	end,
    postLoad = function(self)
		print("postLoad")
    end	
}
