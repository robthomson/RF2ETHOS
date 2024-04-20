
local labels = {}
local fields = {}


fields[#fields + 1] = { t = "Mode",                field=0, min = 0,  max = 4,   default=0,   								vals = { 1 }, table = { [0]="OFF", "PASSTHROUGH", "STANDARD", "MODE1", "MODE2" }}
fields[#fields + 1] = { t = "Handover throttle%",  field=2, min = 10, max = 50,  default=20,suffix="%",  					vals = { 20 } }
fields[#fields + 1] = { t = "Startup time",        field=2, min = 0,  max = 600, default=20,suffix="s",  					vals = { 2,3 }, scale = 10}
fields[#fields + 1] = { t = "Spoolup time",        field=2, min = 0,  max = 600, default=100,suffix="s",  decimals = 1,   	vals = { 4,5 }, scale = 10}
fields[#fields + 1] = { t = "Tracking time",       field=2, min = 0,  max = 100, default=20,suffix="s",   decimals = 1,   	vals = { 6,7 }, scale = 10}
fields[#fields + 1] = { t = "Recovery time",       field=2, min = 0,  max = 100, default=20,suffix="s",   decimals = 1,   	vals = { 8,9 }, scale = 10}
fields[#fields + 1] = { t = "AR bailout time",     field=2, min = 0,  max = 100, default=0,suffix="s",    decimals = 1,   	vals = { 16,17 }, scale = 10}
fields[#fields + 1] = { t = "AR timeout",          field=2, min = 0,  max = 100, default=0,suffix="s",    decimals = 1,   	vals = { 14,15 }, scale = 10}
fields[#fields + 1] = { t = "AR min entry time",   field=2, min = 0,  max = 100, default=50,suffix="s",   decimals = 1,   	vals = { 18,19 }, scale = 10}
fields[#fields + 1] = { t = "Zero throttle TO",    field=2, min = 0,  max = 100, default=30,suffix="s",   decimals = 1,   	vals = { 10,11 }, scale = 10}
fields[#fields + 1] = { t = "HS signal timeout",   field=2, min = 0,  max = 100, default=10,suffix="s",   decimals = 1,   	vals = { 12,13 }, scale = 10}
fields[#fields + 1] = { t = "HS filter cutoff",    field=2, min = 0,  max = 250, default=10,suffix="Hz",     				vals = { 22 }}
fields[#fields + 1] = { t = "Volt. filter cutoff", field=2, min = 0,  max = 250, default=5,suffix="Hz", 					vals = { 21 }}
fields[#fields + 1] = { t = "TTA bandwidth",       field=2, min = 0,  max = 250, default=0,suffix="Hz", 					vals = { 23 }}
fields[#fields + 1] = { t = "Precomp bandwidth",   field=2, min = 0,  max = 250, default=10,suffix="Hz", 					vals = { 24 }}


return {
    read        = 142, -- MSP_GOVERNOR_CONFIG
    write       = 143, -- MSP_SET_GOVERNOR_CONFIG
    title       = "Governor",
    reboot      = true,
    eepromWrite = true,
    minBytes    = 24,
    labels      = labels,
    fields      = fields,
}
