local labels = {}
local fields = {}
local escinfo = {}

-- update pole count label text
local function updatePoles(self)
    local f = self.fields[3]
    -- local l = self.labels[4]
    l.t = f.value * 2
end

-- update gear ratio label text
local function updateRatio(self)
    local fm = self.fields[4]
    local fp = self.fields[5]
    -- local l = self.labels[5]
    local v = fp.value ~= 0 and fm.value / fp.value or 0
    l.t = string.format("%.2f", v) .. ":1"
end

escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}
escinfo[#escinfo + 1] = {t = ""}

labels[#labels + 1] = {t = "ESC"}

fields[#fields + 1] = {t = "P-Gain", min = 1, max = 10, vals = {mspHeaderBytes + 11, mspHeaderBytes + 12}}
fields[#fields + 1] = {t = "I-Gain", min = 1, max = 10, vals = {mspHeaderBytes + 13, mspHeaderBytes + 14}}

fields[#fields + 1] = {t = "Motor Pole Pairs", min = 1, max = 100, vals = {mspHeaderBytes + 41, mspHeaderBytes + 42}, upd = updatePoles}
labels[#labels + 1] = {t = "0"}
fields[#fields + 1] = {t = "Main Teeth", min = 1, max = 1800, vals = {mspHeaderBytes + 45, mspHeaderBytes + 46}, upd = updateRatio}
labels[#labels + 1] = {t = ":"}
fields[#fields + 1] = {t = "Pinion Teeth", min = 1, max = 255, vals = {mspHeaderBytes + 43, mspHeaderBytes + 44}}

fields[#fields + 1] = {t = "Stick Zero (us)", min = 900, max = 1900, vals = {mspHeaderBytes + 35, mspHeaderBytes + 36}}
fields[#fields + 1] = {t = "Stick Range (us)", min = 600, max = 1500, vals = {mspHeaderBytes + 37, mspHeaderBytes + 38}}

return {
    read = 217, -- msp_ESC_PARAMETERS
    write = 218, -- msp_SET_ESC_PARAMETERS
    eepromWrite = true,
    reboot = false,
    title = "Other Settings",
    minBytes = mspBytes,
    labels = labels,
    fields = fields,
    escinfo = escinfo,

    updatePoles = updatePoles,
    updateRatio = updateRatio,
    preSave = function(self)
        -- direction
        -- apply bits to saved flags
    end,
    postLoad = function(self)
        local model = getEscTypeLabel(self.values)
        local version = getUInt(self, {29, 30, 31, 32})
        local firmware = string.format("%.5f", getUInt(self, {25, 26, 27, 28}) / 100000)
        self.escinfo[1].t = model
        self.escinfo[2].t = version
        self.escinfo[3].t = firmware

        -- update pole count
        -- self.updatePoles(self)

        -- update gear ratio
        -- self.updateRatio(self)
    end
}
