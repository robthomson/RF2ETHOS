--
-- Rotorflight Clock Sync
-- this syncs the flight controllers clock with the radio
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

-- declare vars
local clocksync = {}
clocksync.init = true
clocksync.sensor = nil
clocksync.protocol = {}
clocksync.rssiSensor = nil
clocksync.config = config
clocksync.timeIsSet = false


-- GRAB THE SPORT TELEMETRY FRAME
function clocksync.sportTelemetryPop()
    -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
    local frame = clocksync.sensor:popFrame()
    if frame == nil then return nil, nil, nil, nil end
    -- physId = physical / remote sensor Id (aka sensorId)
    --   0x00 for FPORT, 0x1B for SmartPort
    -- primId = frame ID  (should be 0x32 for reply frames)
    -- appId = data Id
    return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

-- PUSH THE TELEMETRY FRAME
function clocksync.sportTelemetryPush(sensorId, frameId, dataId, value)
    -- OpenTX:
    -- When called without parameters, it will only return the status of the output buffer without sending anything.
    --   Equivalent in Ethos may be:   sensor:idle() ???
    -- @param sensorId  physical sensor ID
    -- @param frameId   frame ID
    -- @param dataId    data ID
    -- @param value     value
    -- @retval boolean  data queued in output buffer or not.
    -- @retval nil      incorrect telemetry protocol.  (added in 2.3.4)
    return clocksync.sensor:pushFrame({physId = sensorId, primId = frameId, appId = dataId, value = value})
end

function clocksync.getRssiSensor()
    local rssiSensor
    local rssiNames = {"RSSI", "RSSI 2.4G", "RSSI 900M", "Rx RSSI1", "Rx RSSI2", "RSSI Int", "RSSI Ext"}
    for i, name in ipairs(rssiNames) do
        rssiSensor = system.getSource(name)
        if rssiSensor then return rssiSensor end
    end
end

function clocksync.log(msg)
    if clocksync.config.logEnable == true then print(msg) end
end

function clocksync.joinTableItems(table, delimiter)
    if table == nil or #table == 0 then return "" end
    delimiter = delimiter or ""
    local result = table[1]
    for i = 2, #table do result = result .. delimiter .. table[i] end
    return result
end

function clocksync.setRtc(callback, callbackParam)
    local message = {
        command = 246, -- MSP_SET_RTC
        payload = {},
        processReply = function(self, buf)
            clocksync.log("RTC set.")
            if callback then callback(callbackParam) end
        end,
        simulatorResponse = {}
    }

    local now = os.time()
    -- format: seconds after the epoch / milliseconds
    for i = 1, 4 do
        rf2ethos.mspHelper.writeU8(message.payload, now & 0xFF)
        now = now >> 8
    end
    -- we don't have milliseconds

    rf2ethos.mspHelper.writeU16(message.payload, 0)

    rf2ethos.mspQueue:add(message)
end

function clocksync.onRtcSet()
    timeIsSet = true
    system.playTone(1600, 500, 0)
    clocksync.timeIsSet = true
    collectgarbage()
end

function clocksync.background()

    if clocksync.init == true then
        -- get sensor we call for checking link up
        clocksync.rssiSensor = clocksync.getRssiSensor()

        -- get sensor for msp comms
        clocksync.sensor = sport.getSensor({primId = 0x32})
        clocksync.sensor:module(clocksync.rssiSensor:module())

        rf2ethos.protocol = assert(compile.loadScript(clocksync.config.toolDir .. "protocols.lua"))()
        rf2ethos.mspQueue = assert(compile.loadScript(clocksync.config.toolDir .. "msp/mspQueue.lua"))()
        rf2ethos.mspQueue.maxRetries = clocksync.protocol.maxRetries
        rf2ethos.mspHelper = assert(compile.loadScript(clocksync.config.toolDir .. "msp/mspHelper.lua"))()
        assert(compile.loadScript(clocksync.config.toolDir .. rf2ethos.protocol.mspTransport))()
        assert(compile.loadScript(clocksync.config.toolDir .. "msp/common.lua"))()

        clocksync.init = false
    end


    -- process my queue
    rf2ethos.mspQueue:processQueue()

    if clocksync.rssiSensor ~= nil and clocksync.rssiSensor:state() == true then
        -- set the time
        if clocksync.timeIsSet == false and rf2ethos.mspQueue:isProcessed() then clocksync.setRtc(clocksync.onRtcSet) end
    else
        -- link was lost.  assume need to resync clock
        clocksync.timeIsSet = false
    end

end

return {run = clocksync.background}

