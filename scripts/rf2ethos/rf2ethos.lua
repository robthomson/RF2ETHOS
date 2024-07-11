-- All RF2 globals should be stored in the rf2 table, to avoid conflict with globals from other scripts.
rf2ethos = {
    runningInSimulator = system:getVersion().simulation,

    sportTelemetryPop = function()
        -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
        local frame = rf2ethos.sensor:popFrame()
        if frame == nil then
            return nil, nil, nil, nil
        end
        -- physId = physical / remote sensor Id (aka sensorId)
        --   0x00 for FPORT, 0x1B for SmartPort
        -- primId = frame ID  (should be 0x32 for reply frames)
        -- appId = data Id
        return frame:physId(), frame:primId(), frame:appId(), frame:value()
    end,

    sportTelemetryPush = function(sensorId, frameId, dataId, value)
        -- OpenTX:
        -- When called without parameters, it will only return the status of the output buffer without sending anything.
        --   Equivalent in Ethos may be:   sensor:idle() ???
        -- @param sensorId  physical sensor ID
        -- @param frameId   frame ID
        -- @param dataId    data ID
        -- @param value     value
        -- @retval boolean  data queued in output buffer or not.
        -- @retval nil      incorrect telemetry protocol.  (added in 2.3.4)
        return rf2ethos.sensor:pushFrame({physId = sensorId, primId = frameId, appId = dataId, value = value})
    end,

    getRSSI = function()
        if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
            -- this will return the last known value if nothing is received
            return rf2ethos.rssiSensor:value()
        end
        -- return 0 if no telemetry signal to match OpenTX
        return 0
    end,

    startsWith = function(str, prefix)
        if #prefix > #str then
            return false
        end
        for i = 1, #prefix do
            if str:byte(i) ~= prefix:byte(i) then
                return false
            end
        end
        return true
    end,

    getWindowSize = function()
        return lcd.getWindowSize()
        -- return 784, 406
        -- return 472, 288
        -- return 472, 240
    end,

    log = function(str)
        local f = io.open("/LOGS/rf2ethos.log", 'a')
        io.write(f, tostring(str) .. "\n")
        io.close(f)
    end,

    print = function(str)
        print(tostring(str))
        -- rf2ethos.log(str)
    end,

    clock = os.clock
}
