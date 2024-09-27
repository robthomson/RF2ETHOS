--
-- background processing of msp traffic
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
msp.protocol = assert(compile.loadScript(config.toolDir .. "protocols.lua"))()


-- BACKGROUND checks
function msp.wakeupBgChecks()

   
    if msp.mspQueue ~= nil and msp.mspQueue:isProcessed()then


        if rf2ethos.config.apiVersion == nil and msp.mspQueue:isProcessed() then

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
            msp.mspQueue:add(message)

        elseif (rf2ethos.config.tailMode == nil or rf2ethos.config.swashMode == nil) and msp.mspQueue:isProcessed() then
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
                msp.mspQueue:add(message)
        elseif ( rf2ethos.config.activeProfile == nil or rf2ethos.config.activeRateProfile == nil) then   
                local message = {
                    command = 101, -- MSP_SERVO_CONFIGURATIONS
                    processReply = function(self, buf)
                    
                        if #buf >= 30 then
                    
                            buf.offset = 24
                            local activeProfile = msp.mspHelper.readU8(buf)
                            buf.offset = 26
                            local activeRate = msp.mspHelper.readU8(buf)                              
                        
                                          
                            rf2ethos.config.activeProfile = activeProfile + 1
                            rf2ethos.config.activeRateProfile = activeRate + 1

                        end 
                    end,
                    simulatorResponse = {240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1},

                }
                msp.mspQueue:add(message)          
        elseif (rf2ethos.config.servoCount == nil) and msp.mspQueue:isProcessed() then
                local message = {
                    command = 120, -- MSP_SERVO_CONFIGURATIONS
                    processReply = function(self, buf)
                         if #buf >= 20 then
                                local servoCount = msp.mspHelper.readU8(buf)
                                
                                -- update master one in case changed
                                rf2ethos.config.servoCount = servoCount
                        end
                    end,
                    simulatorResponse = {
                        4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
                        120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
                    }
                }
                msp.mspQueue:add(message)
                
        elseif (rf2ethos.config.servoOverride == nil) and msp.mspQueue:isProcessed() then
                local message = {
                    command = 192, -- MSP_SERVO_OVERIDE
                    processReply = function(self, buf)
                         if #buf >= 16 then
                         
                                for i = 0, rf2ethos.config.servoCount do
                                    buf.offset = i
                                    local servoOverride = msp.mspHelper.readU8(buf)
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
                msp.mspQueue:add(message)
                
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
        msp.sensor = sport.getSensor({primId = 0x32})
        msp.mspQueue = mspQueue
        if rf2ethos.rssiSensor then
            rf2ethos.sensor:module(rf2ethos.rssiSensor:module())
        end
        
        -- set active protocol to use
        msp.protocol = msp.protocol.getProtocol()
     
        -- preload all transport methods
        msp.protocolTransports = {}
        for i,v in pairs(protocols.getTransports()) do
            msp.protocolTransports[i] = assert(compile.loadScript(config.toolDir .. v))()
        end
     
        -- set active transport table to use
        local transport = msp.protocolTransports[msp.protocol.mspProtocol]
        msp.protocol.mspRead = transport.mspRead
        msp.protocol.mspSend = transport.mspSend
        msp.protocol.mspWrite = transport.mspWrite
        msp.protocol.mspPoll = transport.mspPoll
        
        
        msp.mspQueue = assert(compile.loadScript(config.toolDir .. "msp/mspQueue.lua"))()
        msp.mspQueue.maxRetries = msp.protocol.maxRetries
        msp.mspHelper = assert(compile.loadScript(config.toolDir .. "msp/mspHelper.lua"))()
        assert(compile.loadScript(config.toolDir .. "msp/common.lua"))()        

        msp.init = false
    end 
 

    if msp.activeProtocol ~= msp.protocol.mspProtocol then
        rf2ethos.utils.log("Switching protocol: " .. msp.activeProtocol)
        msp.protocol = protocol.getProtocol()
        -- set active transport table to use
        local transport = msp.protocolTransports[msp.protocol.mspProtocol]
        msp.protocol.mspRead = transport.mspRead
        msp.protocol.mspSend = transport.mspSend
        msp.protocol.mspWrite = transport.mspWrite
        msp.protocol.mspPoll = transport.mspPoll  

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
    
    msp.mspQueue:processQueue()   
    collectgarbage()
end

return msp