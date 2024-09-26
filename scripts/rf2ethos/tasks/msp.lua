--
-- Rotorflight Clock Sync
-- this syncs the flight controllers clock with the radio
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

-- declare vars
local msp = {}
msp.init = true
msp.activeProtocol = nil
rf2ethos.backgroundMsp = false

local protocol = assert(compile.loadScript(config.toolDir .. "protocols.lua"))()

function msp.run()

    -- check what protocol is in use
    local telemetrySOURCE = system.getSource("Rx RSSI1")
    if telemetrySOURCE ~= nil then
       msp.activeProtocol = "crsf"
    else
       msp.activeProtocol = "smartPort"
    end
    
    -- tasks dont have a create function
    -- so we handle this here with a loop that
    -- runs only once
    if msp.init == true then

       
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
            rf2ethos.protocolTransports[i] = assert(compile.loadScript(rf2ethos.config.toolDir .. v))()
        end
     
        -- set active transport table to use
        local transport = rf2ethos.protocolTransports[rf2ethos.protocol.mspProtocol]
        rf2ethos.protocol.mspRead = transport.mspRead
        rf2ethos.protocol.mspSend = transport.mspSend
        rf2ethos.protocol.mspWrite = transport.mspWrite
        rf2ethos.protocol.mspPoll = transport.mspPoll
        
        
        rf2ethos.mspQueue = assert(compile.loadScript(rf2ethos.config.toolDir .. "msp/mspQueue.lua"))()
        rf2ethos.mspQueue.maxRetries = rf2ethos.protocol.maxRetries
        rf2ethos.mspHelper = assert(compile.loadScript(rf2ethos.config.toolDir .. "msp/mspHelper.lua"))()
        assert(compile.loadScript(rf2ethos.config.toolDir .. "msp/common.lua"))()        

        msp.init = false
    end 
 

    if msp.activeProtocol ~= rf2ethos.protocol.mspProtocol then
        rf2ethos.utils.log("Switching protocol: " .. msp.activeProtocol)
        rf2ethos.protocol = protocol.getProtocol()
        -- set active transport table to use
        local transport = rf2ethos.protocolTransports[rf2ethos.protocol.mspProtocol]
        rf2ethos.protocol.mspRead = transport.mspRead
        rf2ethos.protocol.mspSend = transport.mspSend
        rf2ethos.protocol.mspWrite = transport.mspWrite
        rf2ethos.protocol.mspPoll = transport.mspPoll     
    end  
    
    rf2ethos.backgroundMsp = true
    rf2ethos.rssiSensor = rf2ethos.utils.getRssiSensor()
    
    rf2ethos.mspQueue:processQueue()   
end

return msp

