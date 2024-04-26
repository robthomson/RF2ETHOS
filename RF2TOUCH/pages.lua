local pages = {}
local sections = {}
-- Rotorflight pages.


sections[#sections + 1] = {title = "Flight Tuning" , section=1,open=true}
	pages[#pages + 1] = { title = "PIDs", section=1, script = "pids.lua" }
	pages[#pages + 1] = { title = "Rates",section=1, script = "rates.lua" }	
	pages[#pages + 1] = { title = "Main Rotor", section=1, subpage=4,script = "profile.lua" }
	pages[#pages + 1] = { title = "Tail Rotor", section=1, subpage=2,script = "profile.lua" }
	pages[#pages + 1] = { title = "Governor", section=1,  script = "profile_governor.lua" }


sections[#sections + 1] = {title = "Advanced" , section=2,open=true}
	pages[#pages + 1] = { title = "PID Controller", section=2, subpage=1,script = "profile.lua" }
	pages[#pages + 1] = { title = "PID Bandwidth", section=2, subpage=3,script = "profile.lua" }
	pages[#pages + 1] = { title = "Auto Level", section=2, subpage=5,script = "profile.lua" }
	pages[#pages + 1] = { title = "Rescue", section=2, script = "profile_rescue.lua" }



sections[#sections + 1] = {title = "Hardware", section=4,open=false }
	pages[#pages + 1] = { title = "Servos", section=4,  script = "servos.lua" }
	pages[#pages + 1] = { title = "Mixer", section=4, script = "mixer.lua" }	
	pages[#pages + 1] = { title = "Accelerometer",section=4,  script = "accelerometer.lua" }
	pages[#pages + 1] = { title = "Filters", section=4, script = "filters.lua" }
	pages[#pages + 1] = { title = "Governor", section=4, script = "governor.lua" }

sections[#sections + 1] = {title = "Tools",section=5,open=false }
	pages[#pages + 1] = { title = "Copy profiles", section=5, script = "copy_profiles.lua" }

return {
	pages = pages,
	sections = sections
}
