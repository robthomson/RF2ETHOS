local labels = {}
local fields = {}
local escinfo = {}

local offOn = {[0] = "Off", "On"}

local startupResponse = {[0] = "Normal", "Smooth"}

local throttleResponse = {[0] = "Slow", "Medium", "Fast", "Custom (PC defined)"}

local motorTiming = {[0] = "Auto Normal", "Auto Efficient", "Auto Power", "Auto Extreme", "0 deg", "6 deg", "12 deg", "18 deg", "24 deg", "30 deg"}

local motorTimingToUI = {[0] = 0, 4, 5, 6, 7, 8, 9, [16] = 0, [17] = 1, [18] = 2, [19] = 3}

local motorTimingFromUI = {[0] = 0, 17, 18, 19, 1, 2, 3, 4, 5, 6}

local freewheel = {[0] = "Off", "Auto", "*unused*", "Always On"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "ESC"}

fields[#fields + 1] = {t = "Min Start Power", min = 0, max = 26, vals = {mspHeaderBytes + 47, mspHeaderBytes + 48}, unit = "%"}
fields[#fields + 1] = {t = "Max Start Power", min = 0, max = 31, vals = {mspHeaderBytes + 49, mspHeaderBytes + 50}, unit = "%"}
-- not sure this field exists?
-- fields[#fields + 1] = {t = "Startup Response", min = 0, max = #startupResponse, vals = {mspHeaderBytes+9, mspHeaderBytes+10}, table = startupResponse}
fields[#fields + 1] = {t = "Throttle Response", min = 0, max = #throttleResponse, vals = {mspHeaderBytes + 15, mspHeaderBytes + 16}, table = throttleResponse}

fields[#fields + 1] = {t = "Motor Timing", min = 0, max = #motorTiming, vals = {mspHeaderBytes + 7, mspHeaderBytes + 8}, table = motorTiming}
fields[#fields + 1] = {t = "Active Freewheel", min = 0, max = #freewheel, vals = {mspHeaderBytes + 21, mspHeaderBytes + 22}, table = freewheel}
fields[#fields + 1] = {t = "F3C Autorotation", min = 0, max = 1, vals = {mspHeaderBytes + 53}, table = offOn}

escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}

local function bitExtract(value, field)
    return (value >> field) & 1
end

local function bitReplace(value, replaceValue, field)
    return value & ~(1 << field) | ((replaceValue & 1) << field)
end

return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot = false,
    title = "Advanced Setup",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,

    svTiming = 0,
    svFlags = 0,
    postLoad = function(self)
        local model = getEscTypeLabel(self.values)
        local version = getUInt(self, {29, 30, 31, 32})
        local firmware = string.format("%.5f", getUInt(self, {25, 26, 27, 28}) / 100000)
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

        -- motor timing
        -- local f = self.fields[5]
        -- self.svTiming = getPageValue(self, f.vals[2]) * 256 + getPageValue(self, f.vals[1])
        -- f.value = motorTimingToUI[self.svTiming] or 0

        -- F3C autorotation
        -- f = self.fields[7]
        -- self.svFlags = getPageValue(self, f.vals[1])
        -- f.value = bitExtract(f.value, escFlags.f3cAuto)
    end,

    preSave = function(self)

        -- motor timing
        -- f = self.fields[5]
        -- local value = motorTimingFromUI[f.value] or 0
        -- setPageValue(self, f.vals[1], value % 256)
        -- setPageValue(self, f.vals[2], math.floor(value / 256))

        -- F3C autorotation
        -- apply bits to saved flags
        -- f = self.fields[7]
        -- setPageValue(self, f.vals[1], bitReplace(self.svFlags, f.value, escFlags.f3cAuto))

        return self.values
    end
}
