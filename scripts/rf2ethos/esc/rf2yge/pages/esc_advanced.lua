local labels = {}
local fields = {}
local escinfo = {}

local offOn = {"Off", "On"}

local startupResponse = {"Normal", "Smooth"}

local throttleResponse = {"Slow", "Medium", "Fast", "Custom (PC defined)"}

local motorTiming = {"Auto Normal", "Auto Efficient", "Auto Power", "Auto Extreme", "0 deg", "6 deg", "12 deg", "18 deg", "24 deg", "30 deg"}

local motorTimingToUI = {0, 4, 5, 6, 7, 8, 9, [16] = 0, [17] = 1, [18] = 2, [19] = 3}

local motorTimingFromUI = {0, 17, 18, 19, 1, 2, 3, 4, 5, 6}

local freewheel = {"Off", "Auto", "*unused*", "Always On"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "ESC"}

fields[#fields + 1] = {t = "Min Start Power", min = 0, max = 26, vals = {mspHeaderBytes + 47, mspHeaderBytes + 48}, unit = "%"}
fields[#fields + 1] = {t = "Max Start Power", min = 0, max = 31, vals = {mspHeaderBytes + 49, mspHeaderBytes + 50}, unit = "%"}
-- not sure this field exists?
-- fields[#fields + 1] = {t = "Startup Response", min = 0, max = #startupResponse, vals = {mspHeaderBytes+9, mspHeaderBytes+10}, table = startupResponse}
fields[#fields + 1] = {t = "Throttle Response", min = 0, max = #throttleResponse, tableIdxInc = -1, vals = {mspHeaderBytes + 15, mspHeaderBytes + 16}, table = throttleResponse}

fields[#fields + 1] = {t = "Motor Timing", min = 0, max = #motorTiming, tableIdxInc = -1, vals = {mspHeaderBytes + 7, mspHeaderBytes + 8}, table = motorTiming}
fields[#fields + 1] = {t = "Active Freewheel", min = 0, max = #freewheel, tableIdxInc = -1, vals = {mspHeaderBytes + 21, mspHeaderBytes + 22}, table = freewheel}
fields[#fields + 1] = {t = "F3C Autorotation", min = 0, max = 1, tableIdxInc = -1, vals = {mspHeaderBytes + 53}, table = offOn}

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
    simulatorResponse = {
        165, 0, 32, 0, 3, 0, 55, 0, 0, 0, 0, 0, 4, 0, 3, 0, 1, 0, 1, 0, 2, 0, 3, 0, 80, 3, 131, 148, 1, 0, 30, 170, 0, 0, 3, 0, 86, 4, 22, 3, 163, 15, 1, 0, 2, 0, 2, 0, 20, 0, 20, 0, 0, 0, 0, 0, 2,
        19, 2, 0, 20, 0, 22, 0, 0, 0
    },
    svTiming = 0,
    svFlags = 0,
    postLoad = function(self)
        local model = getEscTypeLabel(self.values)
        local version = getUInt(self, {29, 30, 31, 32})
        local firmware = string.format("%.5f", getUInt(self, {25, 26, 27, 28}) / 100000)
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

		rf2ethos.triggers.mspDataLoaded = true
    end,
    postRead = function(self)
        if self.values[1] ~= mspSignature then
            -- self.values = nil
            self.escinfo[1].t = ""
            self.escinfo[2].t = ""
            self.escinfo[2].t = ""
            rf2ethos.triggers.mspDataLoaded = true
            return
        end
    end
}
