local pages = {}
local sections = {}
-- Rotorflight pages.

sections[#sections + 1] = {title = "Flight Tuning", section = 1}
pages[#pages + 1] = {title = "PIDs",  section = 1, script = "pids.lua", image="pids.png"}
pages[#pages + 1] = {title = "Rates", section = 1, subpage = 1, script = "rates.lua", image="rates.png"}
pages[#pages + 1] = {title = "Main Rotor", section = 1, subpage = 4, script = "profile.lua", image="mainrotor.png"}
pages[#pages + 1] = {title = "Tail Rotor", section = 1, subpage = 2, script = "profile.lua", image="tailrotor.png"}
pages[#pages + 1] = {title = "Governor", section = 1, script = "profile_governor.lua", image="governor.png"}

sections[#sections + 1] = {title = "Advanced", section = 2}
pages[#pages + 1] = {title = "PID Controller", section = 2, subpage = 1, script = "profile.lua", image="pids.png"}
pages[#pages + 1] = {title = "PID Bandwidth", section = 2, subpage = 3, script = "profile.lua", image="about.png"}
pages[#pages + 1] = {title = "Auto Level", section = 2, subpage = 5, script = "profile.lua", image="autolevel.png"}
pages[#pages + 1] = {title = "Rescue", section = 2, script = "profile_rescue.lua", image="rescue.png"}
pages[#pages + 1] = {title = "Rates", section = 2, subpage = 2, script = "rates.lua", image="rates.png"}


sections[#sections + 1] = {title = "Hardware", section = 4}
pages[#pages + 1] = {title = "Servos", section = 4, script = "servos.lua", image="servos.png"}
pages[#pages + 1] = {title = "Mixer", section = 4, script = "mixer.lua", image="mixer.png"}
pages[#pages + 1] = {title = "Accelerometer", section = 4, script = "accelerometer.lua", image="acc.png"}
pages[#pages + 1] = {title = "Filters", section = 4, script = "filters.lua", image="filters.png"}
pages[#pages + 1] = {title = "Governor", section = 4, script = "governor.lua", image="governor.png"}
pages[#pages + 1] = {title = "ESC", section = 4, script = "esc.lua", image="about.png"}



sections[#sections + 1] = {title = "Tools", section = 5}
pages[#pages + 1] = {title = "Copy profiles", section = 5, script = "copy_profiles.lua", image="copy.png"}
pages[#pages + 1] = {title = "Preferences", section = 5, script = "preferences.lua", image="about.png"}


return {pages = pages, sections = sections}
