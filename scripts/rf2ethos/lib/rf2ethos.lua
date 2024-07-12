-- All RF2 globals should be stored in the rf2 table, to avoid conflict with globals from other scripts.
rf2ethos = {}

rf2ethos.runningInSimulator = system:getVersion().simulation


function rf2ethos.dataBindFields()
    for i = 1, #rf2ethos.Page.fields do

        if rf2ethos.dialogs.progressDisplay == true then
            local percent = (i / #rf2ethos.Page.fields) * 100
            if rf2ethos.triggers.triggerESCLOADER ~= true then
                rf2ethos.dialogs.progress:value(percent)
            end
        end

        if rf2ethos.Page.values and #rf2ethos.Page.values >= rf2ethos.Page.minBytes then
            local f = rf2ethos.Page.fields[i]
            if f.vals then
                f.value = 0
                for idx = 1, #f.vals do
                    local raw_val = rf2ethos.Page.values[f.vals[idx]] or 0
                    raw_val = raw_val << ((idx - 1) * 8)
                    f.value = f.value | raw_val
                end
                local bits = #f.vals * 8
                if f.min and f.min < 0 and (f.value & (1 << (bits - 1)) ~= 0) then
                    f.value = f.value - (2 ^ bits)
                end
                f.value = f.value / (f.scale or 1)
            end
        end
    end
end

function rf2ethos.sportTelemetryPop()
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
end

function rf2ethos.sportTelemetryPush(sensorId, frameId, dataId, value)
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
end

function rf2ethos.getRSSI()
	if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
		-- this will return the last known value if nothing is received
		return rf2ethos.rssiSensor:value()
	end
	-- return 0 if no telemetry signal to match OpenTX
	return 0
end

function rf2ethos.startsWith(str, prefix)
	if #prefix > #str then
		return false
	end
	for i = 1, #prefix do
		if str:byte(i) ~= prefix:byte(i) then
			return false
		end
	end
	return true
end

function rf2ethos.getWindowSize()
	return lcd.getWindowSize()
	-- return 784, 406
	-- return 472, 288
	-- return 472, 240
end




function rf2ethos.log(str)
        local f = io.open("/LOGS/rf2ethos.log", 'a')
        io.write(f, tostring(str) .. "\n")
        io.close(f)
    end
	

function rf2ethos.print(str)
        rf2ethos.utils.log(tostring(str))
end

return rf2ethos	