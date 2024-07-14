-- All RF2 globals should be stored in the rf2 table, to avoid conflict with globals from other scripts.
rf2ethos = {}

rf2ethos.runningInSimulator = system:getVersion().simulation

-- Ethos: when the RF1 and RF2 system tools are both installed, RF1 tries to call getRSSI in RF2 and gets stuck.
-- To avoid this, getRSSI is renamed in rf2ethos.
rf2ethos.getRSSI = function()
    -- --rf2ethos.utils.log("getRSSI RF2")
    if rf2ethos.config.environment.simulation == true then
        return 100
    end

    if rf2ethos.rssiSensor ~= nil and rf2ethos.rssiSensor:state() then
        -- this will return the last known value if nothing is received
        return rf2ethos.rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

function rf2ethos.resetState()

    rf2ethos.escMode = false
    rf2ethos.triggers.escPowerCycle = false
    rf2ethos.escManufacturer = nil
    rf2ethos.triggers.resetRates = false
    rf2ethos.escScript = nil
    pageLoaded = 100
    pageTitle = nil
    pageFile = nil
    rf2ethos.triggers.exitAPP = false
    rf2ethos.triggers.noRFMsg = false
    rf2ethos.triggers.linkUPTime = nil
    rf2ethos.dialogs.nolinkDisplay = false
    rf2ethos.dialogs.nolinkValue = 0
    rf2ethos.triggers.telemetryState = nil

end

function rf2ethos.profileSwitchCheck()
    profileswitchParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/profileswitch")
    if profileswitchParam ~= nil then
        local s = rf2ethos.utils.explode(profileswitchParam, ",")
        profileswitchParam = system.getSource({category = s[1], member = s[2]})
        rf2ethos.triggers.profileswitchLast = profileswitchParam:value()
    end
end

function rf2ethos.rateSwitchCheck()
    rateswitchParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/rateswitch")
    if rateswitchParam ~= nil then
        local s = rf2ethos.utils.explode(rateswitchParam, ",")
        rateswitchParam = system.getSource({category = s[1], member = s[2]})
        rf2ethos.triggers.rateswitchLast = rateswitchParam:value()
    end
end


rf2ethos.settingsSaved = function()
    -- check if this page requires writing to eeprom to save (most do)
    if rf2ethos.Page and rf2ethos.Page.eepromWrite then
        -- don't write again if we're already responding to earlier page.write()s
        if rf2ethos.pageState ~= rf2ethos.pageStatus.eepromWrite then
            rf2ethos.pageState = rf2ethos.pageStatus.eepromWrite
            rf2ethos.mspQueue:add(mspEepromWrite)
        end
    elseif rf2ethos.pageState ~= rf2ethos.pageStatus.eepromWrite then
        -- If we're not already trying to write to eeprom from a previous save, then we're done.
        if rf2ethos.mspQueue:isProcessed() then
            invalidatePages()
        end
    end
end

function rf2ethos.getFieldValue(f)


	if f.value == nil then
		f.value = 0
	end
	if f.t == nil then
		f.t = "N/A"
	end

	--rf2ethos.utils.log(f.t .. ":" .. f.value)


    local v

    if f.value ~= nil then
        if f.decimals ~= nil then
            v = rf2ethos.utils.round(f.value * rf2ethos.utils.decimalInc(f.decimals))
        else
            v = f.value
        end
    else
        v = 0
    end

    if f.mult ~= nil then
        v = math.floor(v * f.mult + 0.5)
    end

    return v
end

function rf2ethos.saveValue(currentField)
    if rf2ethos.config.environment.simulation == true then
        return
    end

    local f = rf2ethos.Page.fields[currentField]
    local scale = f.scale or 1
    local step = f.step or 1

    for idx = 1, #f.vals do
            rf2ethos.Page.values[f.vals[idx]] = math.floor(f.value * scale + 0.5) >> ((idx - 1) * 8)
    end
    if f.upd and rf2ethos.Page.values then
        f.upd(rf2ethos.Page)
    end
end


function rf2ethos.dataBindFields()
    for i = 1, #rf2ethos.Page.fields do

		-- display progress loader when retrieving data
        if rf2ethos.dialogs.progressDisplay == true then
            local percent = (i / #rf2ethos.Page.fields) * 100
			-- we have to stop this happening on esc as we handle this
			-- differently
            if rf2ethos.triggers.triggerESCLOADER ~= true then
                rf2ethos.dialogs.progress:value(percent)
            end
        end

        if rf2ethos.Page.values and #rf2ethos.Page.values >= rf2ethos.Page.minBytes then
            local f = rf2ethos.Page.fields[i]
            if f.vals then
                f.value = 0
                for idx = 1, #f.vals do
                    --local raw_val = rf2ethos.Page.values[f.vals[idx]] or 0
					-- inject header bytes if we have
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
		rf2ethos.utils.log(str)
 end


function rf2ethos.print(str)
        --rf2ethos.utils.log(tostring(str))
end

-- when saving - we have to force a reload of data of copy-profiles due to way you

function rf2ethos.resetCopyProfiles()
    if rf2ethos.lastScript == "copy_profiles.lua" then
        -- invalidatePages
        -- rf2ethos.ui.openPageDefaultLoader(rf2ethos.lastIdx, rf2ethos.lastSubPage, rf2ethos.lastTitle, rf2ethos.lastScript)
        rf2ethos.triggers.wasReloading = true
        rf2ethos.triggers.createForm = true
        rf2ethos.triggers.wasSaving = false
        rf2ethos.triggers.wasLoading = false
        rf2ethos.triggers.reloadRates = false

    end
end

function rf2ethos.saveFieldValue(f, value)
    if value ~= nil then
        if f.decimals ~= nil then
            f.value = value / rf2ethos.utils.decimalInc(f.decimals)
        else
            f.value = value
        end
        if f.postEdit then
            f.postEdit(rf2ethos.Page)
        end
    end

    if f.mult ~= nil then
        f.value = f.value / f.mult
    end

    return f.value
end


function rf2ethos.resetRates()
    if rf2ethos.lastScript == "rates.lua" and rf2ethos.lastSubPage == 2 then
        if rf2ethos.triggers.resetRates == true then
            rf2ethos.NewRateTable = rf2ethos.Page.fields[13].value

            local newTable = rf2ethos.utils.defaultRates(rf2ethos.NewRateTable)

            for k, v in pairs(newTable) do
                local f = rf2ethos.Page.fields[k]
                for idx = 1, #f.vals do
                    rf2ethos.Page.values[f.vals[idx]] = v >> ((idx - 1) * 8)
                end
            end
            rf2ethos.triggers.resetRates = false
        end
    end
end



return rf2ethos