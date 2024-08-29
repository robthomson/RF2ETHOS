local fields = {}
local rows = {}
local cols = {}

rows = {"Roll", "Pitch", "Yaw"}
-- cols = {"P", "I", "O", "D", "F", "B"}
-- cols = {"D", "P", "I", "F", "O", "B"}
cols = {"P", "I", "D", "F", "O", "B"}

-- P
fields[1] = {help = "profilesProportional", row = 1, col = 1, min = 0, max = 1000, default = 50, vals = {1, 2}}
fields[2] = {help = "profilesProportional", row = 2, col = 1, min = 0, max = 1000, default = 50, vals = {9, 10}}
fields[3] = {help = "profilesProportional", row = 3, col = 1, t = "PY", min = 0, max = 1000, default = 80, vals = {17, 18}}

-- I
fields[4] = {help = "profilesIntegral", row = 1, col = 2, min = 0, max = 1000, default = 120, vals = {3, 4}}
fields[5] = {help = "profilesIntegral", row = 2, col = 2, min = 0, max = 1000, default = 120, vals = {11, 12}}
fields[6] = {help = "profilesIntegral", row = 3, col = 2, min = 0, max = 1000, default = 150, vals = {19, 20}}

-- D
fields[7] = {help = "profilesDerivative", row = 1, col = 3, min = 0, max = 1000, default = 30, vals = {5, 6}}
fields[8] = {help = "profilesDerivative", row = 2, col = 3, min = 0, max = 1000, default = 50, vals = {13, 14}}
fields[9] = {help = "profilesDerivative", row = 3, col = 3, min = 0, max = 1000, default = 20, vals = {21, 22}}

-- F
fields[10] = {help = "profilesFeedforward", row = 1, col = 4, min = 0, max = 1000, default = 100, vals = {7, 8}}
fields[11] = {help = "profilesFeedforward", row = 2, col = 4, min = 0, max = 1000, default = 100, vals = {15, 16}}
fields[12] = {help = "profilesFeedforward", row = 3, col = 4, min = 0, max = 1000, default = 0, vals = {23, 24}}

-- O
fields[13] = {help = "profilesHSI", row = 1, col = 5, min = 0, max = 1000, default = 40, vals = {31, 32}}
fields[14] = {help = "profilesHSI", row = 2, col = 5, min = 0, max = 1000, default = 40, vals = {33, 34}}

-- B
fields[15] = {help = "profilesBoost", row = 1, col = 6, min = 0, max = 1000, default = 0, vals = {25, 26}}
fields[16] = {help = "profilesBoost", row = 2, col = 6, min = 0, max = 1000, default = 0, vals = {27, 28}}
fields[17] = {help = "profilesBoost", row = 3, col = 6, min = 0, max = 1000, default = 0, vals = {29, 30}}

local function postLoad(self)
    rf2ethos.triggers.isReady = true
end

return {
    read = 112, -- msp_PID_TUNING
    write = 202, -- msp_SET_PID_TUNING
    title = "PIDs",
    reboot = false,
    eepromWrite = true,
    refreshswitch = true,
    minBytes = 34,
    simulatorResponse = {70, 0, 225, 0, 90, 0, 120, 0, 100, 0, 200, 0, 70, 0, 120, 0, 100, 0, 125, 0, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 25, 0, 25, 0},
    fields = fields,
    rows = rows,
    cols = cols,
    postLoad = postLoad
}
