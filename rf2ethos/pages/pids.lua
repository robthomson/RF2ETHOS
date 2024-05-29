local template = assert(rf2ethos.loadScriptrf2ethos(radio.template))()

local fields = {}
local rows = {}
local cols = {}

rows = {"Roll", "Pitch", "Yaw"}
--cols = {"P", "I", "O", "D", "F", "B"}
--cols = {"D", "P", "I", "F", "O", "B"}
cols = {"P", "I", "D", "F", "O", "B"}

-- P
fields[#fields + 1] = {help="profilesProportional", row = 1, col = 1, min = 0, max = 1000, default = 50, vals = {1, 2}}
fields[#fields + 1] = {help="profilesProportional", row = 2, col = 1, min = 0, max = 1000, default = 50, vals = {9, 10}}
fields[#fields + 1] = {help="profilesProportional", row = 3, col = 1, t = "PY", min = 0, max = 1000, default = 50, vals = {17, 18}}

-- I
fields[#fields + 1] = {help="profilesIntegral", row = 1, col = 2, min = 0, max = 1000, default = 100, vals = {3, 4}}
fields[#fields + 1] = {help="profilesIntegral", row = 2, col = 2, min = 0, max = 1000, default = 100, vals = {11, 12}}
fields[#fields + 1] = {help="profilesIntegral", row = 3, col = 2, min = 0, max = 1000, default = 50, vals = {19, 20}}

-- O
fields[#fields + 1] = {help="profilesHSI", row = 1, col = 5, min = 0, max = 1000, default = 0, vals = {31, 32}}
fields[#fields + 1] = {help="profilesHSI", row = 2, col = 5, min = 0, max = 1000, default = 0, vals = {33, 34}}

-- D
fields[#fields + 1] = {help="profilesDerivative", row = 1, col = 3, min = 0, max = 1000, default = 10, vals = {5, 6}}
fields[#fields + 1] = {help="profilesDerivative", row = 2, col = 3, min = 0, max = 1000, default = 20, vals = {13, 14}}
fields[#fields + 1] = {help="profilesDerivative", row = 3, col = 3, min = 0, max = 1000, default = 10, vals = {21, 22}}

-- F
fields[#fields + 1] = {help="profilesFeedforward", row = 1, col = 4, min = 0, max = 1000, default = 100, vals = {7, 8}}
fields[#fields + 1] = {help="profilesFeedforward", row = 2, col = 4, min = 0, max = 1000, default = 100, vals = {15, 16}}
fields[#fields + 1] = {help="profilesFeedforward", row = 3, col = 4, min = 0, max = 1000, default = 0, vals = {23, 24}}

-- B
fields[#fields + 1] = {help="profilesBoost", row = 1, col = 6, min = 0, max = 1000, default = 0, vals = {25, 26}}
fields[#fields + 1] = {help="profilesBoost", row = 2, col = 6, min = 0, max = 1000, default = 0, vals = {27, 28}}
fields[#fields + 1] = {help="profilesBoost", row = 3, col = 6, min = 0, max = 1000, default = 0, vals = {29, 30}}

return {
    read = 112, -- msp_PID_TUNING
    write = 202, -- msp_SET_PID_TUNING
    title = "PIDs",
    reboot = false,
    eepromWrite = true,
    minBytes = 34,
    fields = fields,
    rows = rows,
    cols = cols
}
