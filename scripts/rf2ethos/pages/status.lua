local fields = {}
local labels = {}
local fcStatus = {}
local dataflashSummary = {}
local wakeupScheduler = os.clock()
local status = {}
local summary = {}
local triggerEraseDataFlash = false


fields[1] = { t = "Arming Flags",  value="0", type=2,disable=true}
fields[2] = { t = "Dataflash Free Space",  value="0" ,type=2,disable=true }
fields[3] = { t = "Real-time load", value = "0",type=2,disable=true}
fields[4] = { t = "CPU load", value = "0" ,type=2,disable=true}



local function getStatus()
    local message = {
        command = 101, -- MSP_STATUS
        processReply = function(self, buf)
            --status.pidCycleTime = rf2ethos.mspHelper.readU16(buf)
            --status.gyroCycleTime = rf2ethos.mspHelper.readU16(buf)
            buf.offset = 12
            status.realTimeLoad = rf2ethos.mspHelper.readU16(buf)
            --print("Real-time load: "..tostring(status.realTimeLoad))
            status.cpuLoad = rf2ethos.mspHelper.readU16(buf)
            --print("CPU load: "..tostring(status.cpuLoad))
            buf.offset = 18
            status.armingDisableFlags = rf2ethos.mspHelper.readU32(buf)
            buf.offset = 24
            status.profile = rf2ethos.mspHelper.readU8(buf)
            --print("Profile: "..tostring(status.profile))
            buf.offset = 26
            status.rateProfile = rf2ethos.mspHelper.readU8(buf)
			--print("Rate Profile: "..tostring(status.rateProfile))

	

        end,
        simulatorResponse = { 240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1 }
    }

    rf2ethos.mspQueue:add(message)
end

local function getDataflashSummary()
    local message = {
        command = 70, -- MSP_DATAFLASH_SUMMARY
        processReply = function(self, buf)
            --rf2ethos.print("buf length: "..#buf)
            local flags = rf2ethos.mspHelper.readU8(buf)
            summary.ready = (flags & 1) ~= 0
            summary.supported = (flags & 2) ~= 0
            summary.sectors = rf2ethos.mspHelper.readU32(buf)
            summary.totalSize = rf2ethos.mspHelper.readU32(buf)
            summary.usedSize = rf2ethos.mspHelper.readU32(buf)
            --rf2ethos.print("summary.ready: "..tostring(summary.ready))
            --rf2ethos.print("summary.supported: "..tostring(summary.supported))
            --rf2ethos.print("summary.sectors: "..tostring(summary.sectors))
            --rf2ethos.print("summary.totalSize: "..tostring(summary.totalSize))
            --rf2ethos.print("summary.usedSize: "..tostring(summary.usedSize))

        end,
        simulatorResponse = { 3, 1,0,0,0, 0,4,0,0, 0,3,0,0 }
    }
    rf2ethos.mspQueue:add(message)
end

local function eraseDataflash()
    local message = {
        command = 72, -- MSP_DATAFLASH_ERASE
        processReply = function(self, buf)
            local summary = {}
        end,
        simulatorResponse = { }
    }
    rf2ethos.mspQueue:add(message)
end


local function postLoad(self)
	getStatus()
	getDataflashSummary()	
end	



local function armingDisableFlagsToString(flags)
    local t = ""
    for i = 0, 25 do
        if (flags & (1 << i)) ~= 0 then
            if t ~= "" then t = t .. ", " end
            if i == 0 then t = t .. "No Gyro" end
            if i == 1 then t = t .. "Fail Safe" end
            if i == 2 then t = t .. "RX Fail Safe" end
            if i == 3 then t = t .. "Bad RX Recovery" end
            if i == 4 then t = t .. "Box Fail Safe" end
            if i == 5 then t = t .. "Governor" end
            --if i == 6 then t = t .. "Crash Detected" end
            if i == 7 then t = t .. "Throttle" end
            if i == 8 then t = t .. "Angle" end
            if i == 9 then t = t .. "Boot Grace Time" end
            if i == 10 then t = t .. "No Pre Arm" end
            if i == 11 then t = t .. "Load" end
            if i == 12 then t = t .. "Calibrating" end
            if i == 13 then t = t .. "CLI" end
            if i == 14 then t = t .. "CMS Menu" end
            if i == 15 then t = t .. "BST" end
            if i == 16 then t = t .. "MSP" end
            if i == 17 then t = t .. "Paralyze" end
            if i == 18 then t = t .. "GPS" end
            if i == 19 then t = t .. "Resc" end
            if i == 20 then t = t .. "RPM Filter" end
            if i == 21 then t = t .. "Reboot Required" end
            if i == 22 then t = t .. "DSHOT Bitbang" end
            if i == 23 then t = t .. "Acc Calibration" end
            if i == 24 then t = t .. "Motor Protocol" end
            if i == 25 then t = t .. "Arm Switch" end
        end
    end
    if t == "" then t = "N/A" end
    return t
end

local function getFreeDataflashSpace()
    if not summary.supported then return "N/A" end
    local freeSpace = summary.totalSize - summary.usedSize
    return string.format("%.1f MB", freeSpace / (1024 * 1024))
end


local function wakeup()
		
		if status.armingDisableFlags ~= nil or summary.supported ~= nil then
			rf2ethos.triggers.isReady = true
		end	
		
		if triggerEraseDataFlash == true then
				rf2ethos.audio.playEraseFlash = true
				triggerEraseDataFlash = false
				
				rf2ethos.ui.progessDisplay("Erasing...","Erasing dataflash.")	
				rf2ethos.Page.eraseDataflash()
				rf2ethos.triggers.isReady = true
		end
		
		if triggerEraseDataFlash == false then
			local now = os.clock()
			if (now - wakeupScheduler) >= 2 then	
				wakeupScheduler = now
				firstRun = false
				if rf2ethos.mspQueue:isProcessed() then
	
					getStatus()
					getDataflashSummary()

					if status.armingDisableFlags ~= nil then
							local value = armingDisableFlagsToString(status.armingDisableFlags)
							rf2ethos.formFields[1] = form.addTextField(rf2ethos.formLines[1], nil, function() return value end, function(newValue) text = value end)
							rf2ethos.formFields[1]:enable(false)				
					end


					if summary.supported == true then
							local value = getFreeDataflashSpace()
							rf2ethos.formFields[2] = form.addTextField(rf2ethos.formLines[2], nil, function() return value end, function(newValue) text = value end)
							rf2ethos.formFields[2]:enable(false)						
					end
					
					if status.realTimeLoad ~= nil then
						local value = status.realTimeLoad
						rf2ethos.formFields[3] = form.addNumberField(rf2ethos.formLines[3], nil, value, value, function() return value end, function(value) end)
						rf2ethos.formFields[3]:suffix("%")	
						rf2ethos.formFields[3]:decimals(1)	
						rf2ethos.formFields[3]:enable(false)
					end
					if status.cpuLoad ~= nil then
						local value = status.cpuLoad
						rf2ethos.formFields[4] = form.addNumberField(rf2ethos.formLines[4], nil, value, value, function() return value end, function(value) end)
						rf2ethos.formFields[4]:suffix("%")	
						rf2ethos.formFields[4]:decimals(1)	
						rf2ethos.formFields[4]:enable(false)						
					end
					

				end
			end	
		end


end

local function onToolMenu(self)

	local buttons = {
				{
					label = "        OK        ",
					action = function()
						
						--we cant launch the loader here to se rely on the modules
						--wakup function to do this
						triggerEraseDataFlash = true
						return true
					end
				}, {
					label = "CANCEL",
					action = function()
						return true
					end
				}
			}
			local message
			local title

			title = "Erase"
			message = "Would you like to erase the dataflash?"

			form.openDialog({
				width = nil,
				title = title,
				message = message,
				buttons = buttons,
				wakeup = function()
				end,
				paint = function()
				end,
				options = TEXT_LEFT
			})

end


return {
    read = nil, 
    write = nil, 
    title = "Status",
    reboot = false,
    eepromWrite = false,
    minBytes = 0,
	wakeup = wakeup,
    labels = labels,
    fields = fields,
    refreshswitch = false,
    simulatorResponse = {},
    postLoad = postLoad,
	eraseDataflash = eraseDataflash,
    onToolMenu = onToolMenu,	
	navButtons={menu=true,save=false,reload=false,tool=true,help=true}
}
