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



local protocol = assert(loadfile(rf2ethos.config.toolDir .. "protocols.lua"))()

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
        if rf2ethos.rssiSensor then
            rf2ethos.sensor:module(rf2ethos.rssiSensor:module())
        end
        
        -- set active protocol to use
        rf2ethos.protocol = protocol.getProtocol()
     
        -- preload all transport methods
        rf2ethos.protocolTransports = {}
        for i,v in pairs(protocols.getTransports()) do
            rf2ethos.protocolTransports[i] = assert(loadfile(rf2ethos.config.toolDir .. v))()
        end
     
        -- set active transport table to use
        local transport = rf2ethos.protocolTransports[rf2ethos.protocol.mspProtocol]
        rf2ethos.protocol.mspRead = transport.mspRead
        rf2ethos.protocol.mspSend = transport.mspSend
        rf2ethos.protocol.mspWrite = transport.mspWrite
        rf2ethos.protocol.mspPoll = transport.mspPoll
        
        
        rf2ethos.mspQueue = assert(loadfile(rf2ethos.config.toolDir .. "msp/mspQueue.lua"))()
        rf2ethos.mspQueue.maxRetries = rf2ethos.protocol.maxRetries
        rf2ethos.mspHelper = assert(loadfile(rf2ethos.config.toolDir .. "msp/mspHelper.lua"))()
        assert(loadfile(rf2ethos.config.toolDir .. "msp/common.lua"))()        

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
    
    -- run this loop to switch the transport if this expection occurs
    if clocksync.timeIsSet == false then
        rf2ethos.protocol = protocol.getProtocol()
        -- set active transport table to use
        local transport = rf2ethos.protocolTransports[rf2ethos.protocol.mspProtocol]
        rf2ethos.protocol.mspRead = transport.mspRead
        rf2ethos.protocol.mspSend = transport.mspSend
        rf2ethos.protocol.mspWrite = transport.mspWrite
        rf2ethos.protocol.mspPoll = transport.mspPoll     
    end    
    

    -- process my queue
    if rf2ethos.guiIsRunning == false and clocksync.timeIsSet == false then
        rf2ethos.mspQueue:processQueue()
    end   

end


return clocksync

