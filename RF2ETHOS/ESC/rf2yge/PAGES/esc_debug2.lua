
local labels = {}
local fields = {}

labels[#labels + 1] = { t = "ESC Telemetry Frame",      ) }
fields[#fields + 1] = { t = "sync",                     ro = true, vals = { 1 } }
fields[#fields + 1] = { t = "version",                  ro = true, vals = { 2 } }
fields[#fields + 1] = { t = "frame_type",               ro = true, vals = { 3 } }
fields[#fields + 1] = { t = "frame_length",             ro = true, vals = { 4 } }
fields[#fields + 1] = { t = "seq",                      ro = true, vals = { 5 } }
fields[#fields + 1] = { t = "device",                   ro = true, vals = { 6 } }
fields[#fields + 1] = { t = "reserved",                 ro = true, vals = { 7 } }
fields[#fields + 1] = { t = "temperature",              ro = true, vals = { 8 } }
fields[#fields + 1] = { t = "voltage",                  ro = true, vals = { 9, 10 } }
fields[#fields + 1] = { t = "current",                  ro = true, vals = { 11,12 } }
fields[#fields + 1] = { t = "consumption",              ro = true, vals = { 13,14 } }
fields[#fields + 1] = { t = "rpm",                      ro = true, vals = { 15, 16 } }
fields[#fields + 1] = { t = "pwm",                      ro = true, vals = { 17 } }
fields[#fields + 1] = { t = "throttle",                 ro = true, vals = { 18 } }
fields[#fields + 1] = { t = "bec_voltage",              ro = true, vals = { 19, 20 } }
fields[#fields + 1] = { t = "bec_current",              ro = true, vals = { 21, 22 } }
fields[#fields + 1] = { t = "bec_temp",                 ro = true, vals = { 23 } }
fields[#fields + 1] = { t = "status1",                  ro = true, vals = { 24 } }
fields[#fields + 1] = { t = "cap_temp",                 ro = true, vals = { 25 } }
fields[#fields + 1] = { t = "aux_temp",                 ro = true, vals = { 26 } }
fields[#fields + 1] = { t = "status2",                  ro = true, vals = { 27 } }
fields[#fields + 1] = { t = "reserved1",                ro = true, vals = { 28 } }
fields[#fields + 1] = { t = "pidx",                     ro = true, vals = { 29, 30 } }
fields[#fields + 1] = { t = "pdata",                    ro = true, vals = { 31, 32 } }
fields[#fields + 1] = { t = "crc",                      ro = true, vals = { 33, 34 } }

return {
    read        = 229, -- MSP_ESC_DEBUG
    eepromWrite = false,
    reboot      = false,
    title       = "Debug Frame",
    minBytes    = mspHeaderBytes + 6,
    labels      = labels,
    fields      = fields,

    autoRefresh = 100,

    postRead = function (self)
        -- adjust databind for v2 frame
        if self.values[mspHeaderBytes + 2] < 3 then
            -- invalidate .seq and .device
            local f = self.fields[5]
            f.vals = nil
            f.value = "---"
            f = self.fields[6]
            f.vals = nil
            f.value = "---"
            -- offset remaining fields
            for fidx = 7, #self.fields do
                f = self.fields[fidx]
                if f.vals then
                    local vals = {}
                    for vidx = 1, #f.vals do
                        vals[vidx] = f.vals[vidx] - 2
                    end
                    f.vals = vals
                end
            end
        end
    end,

    postLoad = function (self)
        -- hex(sync)
        local f = self.fields[1]
        f.value = string.format("x%02X", f.value)

        -- hex(device)
        f = self.fields[6]
        if f.vals then
            f.value = string.format("x%02X", f.value)
        end

        -- hex(crc)
        f = self.fields[#self.fields]
        f.value = string.format("x%04X", f.value)
    end,
}
