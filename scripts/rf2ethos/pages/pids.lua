local fields = {}
local rows = {}
local cols = {}

local activateWakeup = false
local currentProfileChecked = false

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
        rf2ethos.app.triggers.isReady = true
        rf2ethos.utils.mspGetCurrentProfile()
        activateWakeup = true
end

local function openPage(idx, title, script)

        rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages
        rf2ethos.app.triggers.isReady = false

        rf2ethos.app.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
        collectgarbage()

        rf2ethos.app.lastIdx = idx
        rf2ethos.app.lastTitle = title
        rf2ethos.app.lastScript = script
        rf2ethos.lastPage = script

        rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages

        longPage = false

        form.clear()

        rf2ethos.app.ui.fieldHeader(title)
        local numCols
        if rf2ethos.app.Page.cols ~= nil then
                numCols = #rf2ethos.app.Page.cols
        else
                numCols = 6
        end
        local screenWidth = rf2ethos.config.lcdWidth - 10
        local padding = 10
        local paddingTop = rf2ethos.app.radio.linePaddingTop
        local h = rf2ethos.app.radio.navbuttonHeight
        local w = ((screenWidth * 70 / 100) / numCols)
        local paddingRight = 20
        local positions = {}
        local positions_r = {}
        local pos

        line = form.addLine("")

        local loc = numCols
        local posX = screenWidth - paddingRight
        local posY = paddingTop

        local c = 1
        while loc > 0 do
                local colLabel = rf2ethos.app.Page.cols[loc]
                pos = {x = posX, y = posY, w = w, h = h}
                form.addStaticText(line, pos, colLabel)
                positions[loc] = posX - w + paddingRight
                positions_r[c] = posX - w + paddingRight
                posX = math.floor(posX - w)
                loc = loc - 1
                c = c + 1
        end

        -- display each row
        local pidRows = {}
        for ri, rv in ipairs(rf2ethos.app.Page.rows) do pidRows[ri] = form.addLine(rv) end

        for i = 1, #rf2ethos.app.Page.fields do
                local f = rf2ethos.app.Page.fields[i]
                local l = rf2ethos.app.Page.labels
                local pageIdx = i
                local currentField = i

                posX = positions[f.col]

                pos = {x = posX + padding, y = posY, w = w - padding, h = h}

                minValue = f.min * rf2ethos.utils.decimalInc(f.decimals)
                maxValue = f.max * rf2ethos.utils.decimalInc(f.decimals)
                if f.mult ~= nil then
                        minValue = minValue * f.mult
                        maxValue = maxValue * f.mult
                end

                rf2ethos.app.formFields[i] = form.addNumberField(pidRows[f.row], pos, minValue, maxValue, function()
                        local value = rf2ethos.utils.getFieldValue(rf2ethos.app.Page.fields[i])
                        return value
                end, function(value)
                        f.value = rf2ethos.utils.saveFieldValue(rf2ethos.app.Page.fields[i], value)
                        rf2ethos.app.saveValue(i)
                end)
                if f.default ~= nil then
                        local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
                        if f.mult ~= nil then default = default * f.mult end
                        rf2ethos.app.formFields[i]:default(default)
                else
                        rf2ethos.app.formFields[i]:default(0)
                end
                if f.decimals ~= nil then rf2ethos.app.formFields[i]:decimals(f.decimals) end
                if f.unit ~= nil then rf2ethos.app.formFields[i]:suffix(f.unit) end
                if f.help ~= nil then
                        if rf2ethos.app.fieldHelpTxt[f.help]['t'] ~= nil then
                                local helpTxt = rf2ethos.app.fieldHelpTxt[f.help]['t']
                                rf2ethos.app.formFields[i]:help(helpTxt)
                        end
                end
        end

end




local function wakeup()

        if activateWakeup == true and currentProfileChecked == false and rf2ethos.bg.mspQueue:isProcessed()then           
                if rf2ethos.config.ethosRunningVersion >= 1516 then
                        -- update active profile
                        -- the check happens in postLoad          
                        if rf2ethos.config.activeProfile ~= nil then
                                rf2ethos.app.formFields['title']:value(rf2ethos.app.Page.title .. " #" .. rf2ethos.config.activeProfile)
                                currentProfileChecked = true
                        end        
                end        
        end        

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
        postLoad = postLoad,
        openPage = openPage,
        wakeup = wakeup
}
