--[[
set crsf_flight_mode_reuse = GOV_ADJFUNC
]] --
local rf2gov = {}

rf2gov.refresh = true
rf2gov.environment = system.getVersion()
rf2gov.oldsensors = {"govmode"}
rf2gov.wakeupSchedulerUI = os.clock()
local sensors

function rf2gov.sensorMakeNumber(x)
    if x == nil or x == "" then x = 0 end

    x = string.gsub(x, "%D+", "")
    x = tonumber(x)
    if x == nil or x == "" then x = 0 end

    return x
end

function rf2gov.create(widget)
    return
end

function rf2gov.paint(widget)

    local w, h = lcd.getWindowSize()

    lcd.font(FONT_XXL)
    str = sensors.govmode
    tsizeW, tsizeH = lcd.getTextSize(str)

    offsetY = 5

    posX = w / 2 - tsizeW / 2
    posY = h / 2 - tsizeH / 2 + offsetY

    lcd.drawText(posX, posY, str)

end

function rf2gov.getSensors()

    if rf2gov.environment.simulation == true then
        govmode = "DISABLED"
    else
        if system.getSource("Rx RSSI1") ~= nil then
            -- we are running crsf
            local crsfSOURCE = system.getSource("Vbat")
            if crsfSOURCE ~= nil then
                -- crsf passthru
                govId = system.getSource("Gov"):value()
                if govId == 0 then
                    govmode = "OFF"
                elseif govId == 1 then
                    govmode = "IDLE"
                elseif govId == 2 then
                    govmode = "SPOOLUP"
                elseif govId == 3 then
                    govmode = "RECOVERY"
                elseif govId == 4 then
                    govmode = "ACTIVE"
                elseif govId == 5 then
                    govmode = "THR-OFF"
                elseif govId == 6 then
                    govmode = "LOST-HS"
                elseif govId == 7 then
                    govmode = "AUTOROT"
                elseif govId == 8 then
                    govmode = "BAILOUT"
                elseif govId == 100 then
                    govmode = "DISABLED"
                elseif govId == 101 then
                    govmode = "DISARMED"
                else
                    govmode = "UNKNOWN"
                end
            else
                if system.getSource("Flight mode") ~= nil then govmode = system.getSource("Flight mode"):stringValue() end
            end
        else
            -- we are run sport
            if system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x5450}) ~= nil then
                govId = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x5450}):stringValue()
                govId = rf2gov.sensorMakeNumber(govId)
                -- print(govId)
                if govId == 0 then
                    govmode = "OFF"
                elseif govId == 1 then
                    govmode = "IDLE"
                elseif govId == 2 then
                    govmode = "SPOOLUP"
                elseif govId == 3 then
                    govmode = "RECOVERY"
                elseif govId == 4 then
                    govmode = "ACTIVE"
                elseif govId == 5 then
                    govmode = "THR-OFF"
                elseif govId == 6 then
                    govmode = "LOST-HS"
                elseif govId == 7 then
                    govmode = "AUTOROT"
                elseif govId == 8 then
                    govmode = "BAILOUT"
                elseif govId == 100 then
                    govmode = "DISABLED"
                elseif govId == 101 then
                    govmode = "DISARMED"
                else
                    govmode = "UNKNOWN"
                end
            else
                govmode = ""
            end
        end
    end

    if rf2gov.oldsensors.govmode ~= govmode then rf2gov.refresh = true end

    ret = {govmode = govmode}
    rf2gov.oldsensors = ret

    return ret
end

-- MAIN WAKEUP FUNCTION. THIS SIMPLY FARMS OUT AT DIFFERING SCHEDULES TO SUB FUNCTIONS
function rf2gov.wakeup(widget)

    local schedulerUI
    if lcd.isVisible() then
        schedulerUI = 0.25
    else
        schedulerUI = 1
    end

    -- keep cpu load down by running UI at reduced interval
    local now = os.clock()
    if (now - rf2gov.wakeupSchedulerUI) >= schedulerUI then
        rf2gov.wakeupSchedulerUI = now
        rf2gov.wakeupUI()
    end

end

function rf2gov.wakeupUI(widget)
    rf2gov.refresh = false
    sensors = rf2gov.getSensors()

    if rf2gov.refresh == true then lcd.invalidate() end

    return
end

return rf2gov
