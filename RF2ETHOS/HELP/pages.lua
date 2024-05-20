data = {}

-- PIDS
data["pids"] = {}
data["pids"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pids.png"
data["pids"]["TEXT"] = {
				"Increase D, P, I in order until each wobbles, then back off.",
				"Set F for a good response in full stick flips and rolls.",
				"If necessary, tweak P:D ratio to set response damping to your liking.",
				"Increase O until wobbles occur when jabbing elevator at full collective, back off a bit.", 
				"Increase B if you want sharper response.",
				}

				

			
-- FLIGHT TUNING RATES
data["rates_1"] = {}
data["rates_1"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rates.png"
data["rates_1"]["TEXT"] = {
				"The purpose of rates are to change in flight sensitivity and rotation rates.",
				"The aim is usually to have several 'rates' that you can switch between during flight to change flight performance.",
				}



-- FLIGHT TUNING - MAIN ROTOR
data["profile_4"] = {}
data["profile_4"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/mainrotor.png"
data["profile_4"]["TEXT"] = {
				"Configure the mechanical behaviour of the main rotor",
				"Additional line",
				}


-- FLIGHT TUNING - TAIL ROTOR
data["profile_2"] = {}
data["profile_2"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/tailrotor.png"
data["profile_2"]["TEXT"] = {
				"Configure the mechanical behaviour of the tail rotor",
				"Additional line",				
				}						

-- FLIGHT TUNING - GOVERNOR
data["profile_governor"] = {}
data["profile_governor"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/governor.png"
data["profile_governor"]["TEXT"] = {
				"Set governor headspeed etc etc",
				"Additional line",				
				}	

-- ADVANCED TUNING - PID CONTROLLER
data["profile_1"] = {}
data["profile_1"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pidcontroller.png"
data["profile_1"]["TEXT"] = {
				"Configigure the PID controller",
				"Additional line",				
				}	

-- ADVANCED TUNING - PID BANDWIDTH
data["profile_3"] = {}
data["profile_3"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/pidbandwidth.png"
data["profile_3"]["TEXT"] = {
				"Configigure the PID BANDWIDTH controller",
				"Additional line",				
				}	

-- ADVANCED TUNING - AUTO LEVEL
data["profile_5"] = {}
data["profile_5"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/autolevel.png"
data["profile_5"]["TEXT"] = {
				"Auto level config",
				"Additional line",				
				}	

-- ADVANCED TUNING - RESCUE
data["profile_rescue"] = {}
data["profile_rescue"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rescue.png"
data["profile_rescue"]["TEXT"] = {
				"Auto level config",
				"Additional line",				
				}	

-- ADVANCED TUNING - RATES
data["rates_2"] = {}
data["rates_2"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/rates.png"
data["rates_2"]["TEXT"] = {
				"Advanced rates Configigure",
				"Additional line",				
				}	

-- HARDWARE - SERVO
data["servos"] = {}
data["servos"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/servos.png"
data["servos"]["TEXT"] = {
				"Adjust servo config",
				"Additional line",				
				}	

-- HARDWARE - MIXER
data["mixer"] = {}
data["mixer"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/mixer.png"
data["mixer"]["TEXT"] = {
				"Adjust mixer...",
				"Additional line",				
				}	

-- HARDWARE - ACCELEROMETER
data["accelerometer"] = {}
data["accelerometer"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/board-alignment.png"
data["accelerometer"]["TEXT"] = {
				"Adjust accelerometer..",
				"Additional line",				
				}	


-- HARDWARE - FILTERS
data["filters"] = {}
data["filters"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/filters.png"
data["filters"]["TEXT"] = {
				"Adjust filters... blah..",
				"Additional line",				
				}	

-- HARDWARE - GOVERNOR
data["governor"] = {}
data["governor"]["QRCODE"] = "/scripts/RF2ETHOS/HELP/QR/governor.png"
data["governor"]["TEXT"] = {
				"Adjust filters... blah..",
				"Additional line",				
				}	

--[[
-- HARDWARE - ESC
data["esc"] = {
				"Adjust esc.. blah..",
				"Additional line",				
				}					
]]--

-- TOOLS COPY PROFILES
--[[
data["copy_profiles"] = {
				"Copy profiles",
				"Additional line",				
				}					
]]--


return {
    data = data,
}