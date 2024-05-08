data = {}

-- PIDS
data["pids"] = {
				"Increase D, P, I in order until each wobbles, then back off.",
				"Set F for a good response in full stick flips and rolls.",
				"If necessary, tweak P:D ratio to set response damping to your liking.",
				"Increase O until wobbles occur when jabbing elevator at full collective, back off a bit.", 
				"Increase B if you want sharper response.",
				}

--[[				
-- FLIGHT TUNING RATES
data["rates_1"] = {
				"The purpose of rates are to change in flight sensitivity and rotation rates.",
				"The aim is usually to have several 'rates' that you can switch between during flight to change flight performance.",
				}

-- FLIGHT TUNING - MAIN ROTOR
data["profile_4"] = {
				"Configure the mechanical behaviour of the main rotor",
				"Additional line",
				}

-- FLIGHT TUNING - TAIL ROTOR
data["profile_2"] = {
				"Configure the mechanical behaviour of the tail rotor",
				"Additional line",				
				}						

-- FLIGHT TUNING - GOVERNOR
data["profile_governor"] = {
				"Set governor headspeed etc etc",
				"Additional line",				
				}	

-- ADVANCED TUNING - PID CONTROLLER
data["profile_1"] = {
				"Configigure the PID controller",
				"Additional line",				
				}	

-- ADVANCED TUNING - PID BANDWIDTH
data["profile_3"] = {
				"Configigure the PID BANDWIDTH controller",
				"Additional line",				
				}	

-- ADVANCED TUNING - AUTO LEVEL
data["profile_5"] = {
				"Auto level config",
				"Additional line",				
				}	

-- ADVANCED TUNING - RESCUE
data["profile_rescue"] = {
				"Auto level config",
				"Additional line",				
				}	

-- ADVANCED TUNING - RATES
data["rates_2"] = {
				"Advanced rates Configigure",
				"Additional line",				
				}	

-- HARDWARE - SERVO
data["servos"] = {
				"Adjust servo config",
				"Additional line",				
				}	

-- HARDWARE - MIXER
data["mixer"] = {
				"Adjust mixer...",
				"Additional line",				
				}	

-- HARDWARE - ACCELEROMETER
data["accelerometer"] = {
				"Adjust accelerometer..",
				"Additional line",				
				}	


-- HARDWARE - FILTERS
data["filters"] = {
				"Adjust filters... blah..",
				"Additional line",				
				}	

-- HARDWARE - GOVERNOR
data["governor"] = {
				"Adjust filters... blah..",
				"Additional line",				
				}	

-- HARDWARE - ESC
data["esc"] = {
				"Adjust esc.. blah..",
				"Additional line",				
				}					


-- TOOLS COPY PROFILES
data["copy_profiles"] = {
				"Copy profiles",
				"Additional line",				
				}					

]]--

return {
    data = data,
}