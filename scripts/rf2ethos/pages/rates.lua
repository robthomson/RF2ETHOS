local labels = {}
local tables = {}

local activateWakeup = false
local currentProfileChecked = false


tables[0] = rf2ethos.config.toolDir .. "pages/ratetables/none.lua"
tables[1] = rf2ethos.config.toolDir .. "pages/ratetables/betaflight.lua"
tables[2] = rf2ethos.config.toolDir .. "pages/ratetables/raceflight.lua"
tables[3] = rf2ethos.config.toolDir .. "pages/ratetables/kiss.lua"
tables[4] = rf2ethos.config.toolDir .. "pages/ratetables/actual.lua"
tables[5] = rf2ethos.config.toolDir .. "pages/ratetables/quick.lua"

if rf2ethos.RateTable == nil then rf2ethos.RateTable = rf2ethos.config.defaultRateTable end

local mytable = assert(compile.loadScript(tables[rf2ethos.RateTable]))()

local fields = mytable.fields

fields[13] = {t = "Rates Type", hidden = true, ratetype = 1, min = 0, max = 5, vals = {1}}

local function postLoad(self)
    -- if the activeRateTable is not what we are displaying
    -- then we need to trigger a reload of the page
    local v = rf2ethos.Page.values[1]
    if v ~= nil then rf2ethos.activeRateTable = math.floor(v) end

    if rf2ethos.activeRateTable ~= nil then
        if rf2ethos.activeRateTable ~= rf2ethos.RateTable then
            rf2ethos.RateTable = rf2ethos.activeRateTable
            rf2ethos.app.triggers.reload = true
            return
        end
    end

    rf2ethos.app.triggers.isReady = true

    rf2ethos.utils.mspGetCurrentProfile()
    activateWakeup = true    
    
end

local function flagRateChange(self)
    rf2ethos.app.triggers.resetRates = true
end

local function openPage(idx, title, script)

    rf2ethos.Page = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/" .. script))()
    collectgarbage()

    rf2ethos.lastIdx = idx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script
    rf2ethos.lastPage = script

    rf2ethos.app.uiState = rf2ethos.app.uiStatus.pages

    longPage = false

    form.clear()

    rf2ethos.app.ui.fieldHeader(title)

    local numCols = #rf2ethos.Page.cols

    -- we dont use the global due to scrollers
    local screenWidth, screenHeight = rf2ethos.getWindowSize()

    local padding = 10
    local paddingTop = rf2ethos.app.radio.linePaddingTop
    local h = rf2ethos.app.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 10
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine(rf2ethos.Page.rTableName)

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = rf2ethos.Page.cols[loc]

        positions[loc] = posX - w
        positions_r[c] = posX - w

        lcd.font(FONT_STD)
        local tsizeW, tsizeH = lcd.getTextSize(colLabel)

        local posTxt = (positions_r[c] + w) - tsizeW

        pos = {x = posTxt, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)

        posX = math.floor(posX - w)

        loc = loc - 1
        c = c + 1
    end

    -- display each row
    local rateRows = {}
    for ri, rv in ipairs(rf2ethos.Page.rows) do rateRows[ri] = form.addLine(rv) end

    for i = 1, #rf2ethos.Page.fields do
        local f = rf2ethos.Page.fields[i]
        local l = rf2ethos.Page.labels
        local pageIdx = i
        local currentField = i

        if f.hidden == nil or f.hidden == false then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * rf2ethos.utils.decimalInc(f.decimals)
            maxValue = f.max * rf2ethos.utils.decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end

            rf2ethos.app.formFields[i] = form.addNumberField(rateRows[f.row], pos, minValue, maxValue, function()
                local value
                if rf2ethos.activeRateTable == 0 then
                    value = 0
                else
                    value = rf2ethos.utils.getFieldValue(f)
                end
                return value
            end, function(value)
                f.value = rf2ethos.utils.saveFieldValue(f, value)
                rf2ethos.saveValue(i)
            end)
            if f.default ~= nil then
                local default = f.default * rf2ethos.utils.decimalInc(f.decimals)
                if f.mult ~= nil then default = math.floor(default * f.mult) end
                if f.scale ~= nil then default = math.floor(default / f.scale) end
                rf2ethos.app.formFields[i]:default(default)
            else
                rf2ethos.app.formFields[i]:default(0)
            end
            if f.decimals ~= nil then rf2ethos.app.formFields[i]:decimals(f.decimals) end
            if f.unit ~= nil then rf2ethos.app.formFields[i]:suffix(f.unit) end
            if f.step ~= nil then rf2ethos.app.formFields[i]:step(f.step) end
            if f.help ~= nil then
                if rf2ethos.fieldHelpTxt[f.help]['t'] ~= nil then
                    local helpTxt = rf2ethos.fieldHelpTxt[f.help]['t']
                    rf2ethos.app.formFields[i]:help(helpTxt)
                end
            end
            if f.disable == true then rf2ethos.app.formFields[i]:enable(false) end
        end
    end

end

local function wakeup()

    if activateWakeup == true and currentProfileChecked == false and rf2ethos.mspQueue:isProcessed()then       
        if rf2ethos.config.ethosRunningVersion >= 1516 then
            -- update active profile
            -- the check happens in postLoad      
            if rf2ethos.config.activeProfile ~= nil then
                rf2ethos.app.formFields['title']:value(rf2ethos.Page.title .. " #" .. rf2ethos.config.activeRateProfile)
                currentProfileChecked = true
            end    
        end    
    end    

end

return {
    read = 111, -- msp_RC_TUNING
    write = 204, -- msp_SET_RC_TUNING
    title = "Rates",
    reboot = false,
    eepromWrite = true,
    minBytes = 25,
    labels = labels,
    fields = fields,
    refreshswitch = true,
    rows = mytable.rows,
    cols = mytable.cols,
    simulatorResponse = {4, 18, 25, 32, 20, 0, 0, 18, 25, 32, 20, 0, 0, 32, 50, 45, 10, 0, 0, 56, 0, 56, 20, 0, 0},
    rTableName = mytable.rTableName,
    flagRateChange = flagRateChange,
    postLoad = postLoad,
    openPage = openPage,
    wakeup = wakeup

}
