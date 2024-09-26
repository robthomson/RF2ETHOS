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

msp.wakeupBgChecksInit = true

local protocol = assert(compile.loadScript(config.toolDir .. "protocols.lua"))()


-- BACKGROUND checks
function msp.wakeupBgChecks()


    if rf2ethos.mspQueue ~= nil and rf2ethos.mspQueue:isProcessed()then



        if rf2ethos.config.apiVersion == nil and rf2ethos.mspQueue:isProcessed() then

            local message = {
                command = 1, -- MIXER
                processReply = function(self, buf)
                    if #buf >= 3 then
                        local version = buf[2] + buf[3] / 100
                        rf2ethos.config.apiVersion = version
                        rf2ethos.utils.log("MSP Version: " .. rf2ethos.config.apiVersion)
                    end
                end,
                simulatorResponse = {0, 12, 7}
            }
            rf2ethos.mspQueue:add(message)

        elseif (rf2ethos.config.tailMode == nil or rf2ethos.config.swashMode == nil) and rf2ethos.mspQueue:isProcessed() then
                local message = {
                    command = 42, -- MIXER
                    processReply = function(self, buf)
                        if #buf >= 19 then

                            local tailMode = buf[2]
                            local swashMode = buf[6]
                            rf2ethos.config.swashMode = swashMode
                            rf2ethos.config.tailMode = tailMode
                            rf2ethos.utils.log("Tail mode: " .. rf2ethos.config.tailMode)
                            rf2ethos.utils.log("Swash mode: " .. rf2ethos.config.swashMode)
                        end
                    end,
                    simulatorResponse = {0, 1, 0, 0, 0, 2, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
                }
                rf2ethos.mspQueue:add(message)
        elseif ( rf2ethos.config.activeProfile == nil or rf2ethos.config.activeRateProfile == nil) then   
                rf2ethos.utils.mspGetCurrentProfile()            
        elseif (rf2ethos.config.servoCount == nil) and rf2ethos.mspQueue:isProcessed() then
                local message = {
                    command = 120, -- MSP_SERVO_CONFIGURATIONS
                    processReply = function(self, buf)
                         if #buf >= 20 then
                                local servoCount = rf2ethos.mspHelper.readU8(buf)
                                
                                -- update master one in case changed
                                rf2ethos.config.servoCount = servoCount
                        end
                    end,
                    simulatorResponse = {
                        4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
                        120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
                    }
                }
                rf2ethos.mspQueue:add(message)
                
        elseif (rf2ethos.config.servoOverride == nil) and rf2ethos.mspQueue:isProcessed() then
                local message = {
                    command = 192, -- MSP_SERVO_OVERIDE
                    processReply = function(self, buf)
                         if #buf >= 16 then
                         
                                for i = 0, rf2ethos.config.servoCount do
                                    buf.offset = i
                                    local servoOverride = rf2ethos.mspHelper.readU8(buf)
                                    if servoOverride == 0 then
                                        rf2ethos.utils.log("Servo overide: true")
                                        rf2ethos.config.servoOverride = true
                                    end
                                end      
                                if rf2ethos.config.servoOverride == nil then
                                    rf2ethos.config.servoOverride = false 
                                end      
                        end
                    end,
                    simulatorResponse = {209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7}
                }
                rf2ethos.mspQueue:add(message)
                
                -- do this at end of last one
                msp.wakeupBgChecksInit = false
        end    
    end
  
end

function msp.resetState()
    rf2ethos.config.servoOverride = nil
    rf2ethos.config.servoCount = nil
    rf2ethos.config.tailMode = nil
    rf2ethos.config.apiVersion = nil
end

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

        msp.resetState()        
        msp.wakeupBgChecksInit = true     
    end  
    
    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() == false then
        msp.resetState()
        msp.wakeupBgChecksInit = true 
    end
 
    -- bgchecks
    -- keep cpu load down by running Form at reduced interval

    if msp.wakeupBgChecksInit == true then
        msp.wakeupBgChecks()
    end
 
    rf2ethos.backgroundMsp = true
    rf2ethos.rssiSensor = rf2ethos.utils.getRssiSensor()
    
    rf2ethos.mspQueue:processQueue()   
    collectgarbage()
end

return msp

