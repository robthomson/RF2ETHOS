local labels = {}
local fields = {}
local escinfo = {}

local escMode = {"Free (Attention!)", "Heli Ext Governor", "Heli Governor", "Heli Governor Store", "Aero Glider", "Aero Motor", "Aero F3A"}

local direction = {"Normal", "Reverse"}

local cuttoff = {"Off", "Slow Down", "Cutoff"}

local cuttoffVoltage = {"2.9 V", "3.0 V", "3.1 V", "3.2 V", "3.3 V", "3.4 V"}

escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}
escinfo[#escinfo + 1] = {t = "---"}

labels[#labels + 1] = {t = "ESC", label = "esc1", inline_size = 40.6}
fields[#fields + 1] = {t = "ESC Mode", inline = 1, label = "esc1", min = 1, max = #escMode, vals = {mspHeaderBytes + 3, mspHeaderBytes + 4}, tableIdxInc = -1, table = escMode}

labels[#labels + 1] = {t = "", label = "esc2", inline_size = 40.6}
fields[#fields + 1] = {t = "Direction", inline = 1, label = "esc2", min = 0, max = 1, vals = {mspHeaderBytes + 53}, tableIdxInc = -1, table = direction}

labels[#labels + 1] = {t = "", label = "esc3", inline_size = 40.6}
fields[#fields + 1] = {t = "BEC", inline = 1, label = "esc3", unit = "v", min = 55, max = 84, vals = {mspHeaderBytes + 5, mspHeaderBytes + 6}, scale = 10, decimals = 1}

labels[#labels + 1] = {t = "Limits", label = "limits1", inline_size = 40.6}
fields[#fields + 1] = {t = "Cutoff Handling", inline = 1, label = "limits1", min = 0, max = #cuttoff, vals = {mspHeaderBytes + 17, mspHeaderBytes + 18}, tableIdxInc = -1, table = cuttoff}

labels[#labels + 1] = {t = "", label = "limits2", inline_size = 40.6}
fields[#fields + 1] = {
    t = "Cutoff Cell Voltage",
    inline = 1,
    label = "limits2",
    min = 0,
    max = #cuttoffVoltage,
    vals = {mspHeaderBytes + 19, mspHeaderBytes + 20},
    tableIdxInc = -1,
    table = cuttoffVoltage
}

-- need to work current limit out - disable for now
-- labels[#labels + 1] = {t = "", label = "limits3", inline_size = 40.6}
-- fields[#fields + 1] = {t = "Current Limit", units = "A", inline = 1, label = "limits3", min = 1, max = 65500, decimals = 2, vals = {mspHeaderBytes+55, mspHeaderBytes+56}}

escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}

function bitReplace(value, replaceValue, field)
    return value & ~(1 << field) | ((replaceValue & 1) << field)
end

return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot = false,
    title = "Basic Setup",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,
    simulatorResponse = {
        165, 0, 32, 0, 3, 0, 55, 0, 0, 0, 0, 0, 4, 0, 3, 0, 1, 0, 1, 0, 2, 0, 3, 0, 80, 3, 131, 148, 1, 0, 30, 170, 0, 0, 3, 0, 86, 4, 22, 3, 163, 15, 1, 0, 2, 0, 2, 0, 20, 0, 20, 0, 0, 0, 0, 0, 2,
        19, 2, 0, 20, 0, 22, 0, 0, 0
    },
    svFlags = 0,

    postLoad = function(self)
        local model = getEscTypeLabel(self.values)
        local version = getUInt(self, {29, 30, 31, 32})
        local firmware = string.format("%.5f", getUInt(self, {25, 26, 27, 28}) / 100000)
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

        -- direction
        -- save flags, changed bit will be applied in pre-save
        local f = self.fields[2]
        self.svFlags = getPageValue(self, f.vals[1])
        f.value = (self.svFlags & (1 << escFlags.spinDirection)) ~= 0 and 1 or 0

        -- set BEC voltage max (8.4 or 12.3)
        f = self.fields[3]
        f.max = (self.svFlags & (1 << escFlags.bec12v)) == 0 and 84 or 123
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
    end,
    preSave = function(self)
        -- direction
        -- apply bits to saved flags
        -- local f = self.fields[2]
        -- self.svFlags = bitReplace(self.svFlags, f.value, escFlags.spinDirection)
        -- setPageValue(self, f.vals[1], self.svFlags)
        return self.values
    end
}

