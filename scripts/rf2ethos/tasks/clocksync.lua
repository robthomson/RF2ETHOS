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



function clocksync.setRtc(callback, callbackParam)
    local message = {
        command = 246, -- MSP_SET_RTC
        payload = {},
        processReply = function(self, buf)
            rf2ethos.utils.log("RTC set.")
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
    system.playTone(1600, 500, 0)
    clocksync.timeIsSet = true
    ELRS_PAUSE_TELEMETRY = false
    CRSF_PAUSE_TELEMETRY = false
    collectgarbage()
end

function clocksync.run()

    if system:getVersion().simulation == true then
        return
    end

    rf2ethos.rssiSensor = rf2ethos.utils.getRssiSensor()
  
    if clocksync.init == true then

        -- get sensor for msp comms
        rf2ethos.sensor = sport.getSensor({primId = 0x32})
        rf2ethos.sensor:module(rf2ethos.rssiSensor:module())

        local protocol = assert(loadfile(rf2ethos.config.toolDir .. "protocols.lua"))()
        rf2ethos.protocol = protocol.getProtocol()
        rf2ethos.mspQueue = assert(compile.loadScript(clocksync.config.toolDir .. "msp/mspQueue.lua"))()
        rf2ethos.mspQueue.maxRetries = rf2ethos.protocol.maxRetries
        rf2ethos.mspHelper = assert(compile.loadScript(clocksync.config.toolDir .. "msp/mspHelper.lua"))()
        assert(compile.loadScript(clocksync.config.toolDir .. rf2ethos.protocol.mspTransport))()
        assert(compile.loadScript(clocksync.config.toolDir .. "msp/common.lua"))()

        clocksync.init = false
    end 

    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() == true then
        -- set the time
        if clocksync.timeIsSet == false and rf2ethos.mspQueue:isProcessed() then 
            clocksync.setRtc(clocksync.onRtcSet) 
        end
    else
        -- link was lost.  assume need to resync clock
        clocksync.timeIsSet = false
        ELRS_PAUSE_TELEMETRY = false
        CRSF_PAUSE_TELEMETRY = false        
    end

    -- process my queue
    if rf2ethos.guiIsRunning == false and clocksync.timeIsSet == false then
        rf2ethos.mspQueue:processQueue()
    end   

end


return clocksync

