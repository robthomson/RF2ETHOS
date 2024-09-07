local pages = {}
local sections = {}
-- Rotorflight pages.

sections[#sections + 1] = {title = "Flight Tuning", section = 1}
pages[#pages + 1] = {title = "PIDs", section = 1, script = "pids.lua", image = "pids.png"}
pages[#pages + 1] = {title = "Rates", section = 1, script = "rates.lua", image = "rates.png"}
pages[#pages + 1] = {title = "Main Rotor", section = 1, script = "profile_mainrotor.lua", image = "mainrotor.png"}
pages[#pages + 1] = {title = "Tail Rotor", section = 1, script = "profile_tailrotor.lua", image = "tailrotor.png"}
pages[#pages + 1] = {title = "Governor", section = 1, script = "profile_governor.lua", image = "governor.png"}
pages[#pages + 1] = {title = "Trim", section = 1, script = "trim.lua", image = "trim.png"}

sections[#sections + 1] = {title = "Advanced", section = 2}
pages[#pages + 1] = {title = "PID Controller", section = 2, script = "profile_pidcontroller.lua", image = "pids-controller.png"}
pages[#pages + 1] = {title = "PID Bandwidth", section = 2, script = "profile_pidbandwidth.lua", image = "pids-bandwidth.png"}
pages[#pages + 1] = {title = "Auto Level", section = 2, script = "profile_autolevel.lua", image = "autolevel.png"}
pages[#pages + 1] = {title = "Rescue", section = 2, script = "profile_rescue.lua", image = "rescue.png"}
pages[#pages + 1] = {title = "Rates", section = 2, script = "rates_advanced.lua", image = "rates.png"}

sections[#sections + 1] = {title = "Hardware", section = 4}
pages[#pages + 1] = {title = "Servos", section = 4, script = "servos.lua", image = "servos.png"}
pages[#pages + 1] = {title = "Mixer", section = 4, script = "mixer.lua", image = "mixer.png"}
pages[#pages + 1] = {title = "Accelerometer", section = 4, script = "accelerometer.lua", image = "acc.png"}
pages[#pages + 1] = {title = "Filters", section = 4, script = "filters.lua", image = "filters.png"}
pages[#pages + 1] = {title = "Governor", section = 4, script = "governor.lua", image = "governor.png"}
pages[#pages + 1] = {title = "Esc", section = 4, script = "esc.lua", image = "esc.png"}

sections[#sections + 1] = {title = "Tools", section = 5}
pages[#pages + 1] = {title = "Copy profiles", section = 5, script = "copy_profiles.lua", image = "copy.png"}
pages[#pages + 1] = {title = "Profile", section = 5, script = "select_profile.lua", image = "select_profile.png"}
pages[#pages + 1] = {title = "Status", section = 5, script = "status.lua", image = "status.png"}
pages[#pages + 1] = {title = "Msp speed", section = 5, script = "msp_speed.lua", image = "msp_speed.png"}

sections[#sections + 1] = {title = "Setup", section = 6}
pages[#pages + 1] = {title = "Preferences", section = 6, script = "preferences.lua", image = "settings.png"}
pages[#pages + 1] = {title = "About", section = 6, script = "about.lua", image = "about.png"}

return {pages = pages, sections = sections}
