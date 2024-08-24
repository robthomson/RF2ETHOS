local labels = {}
local fields = {}

local inFocus = false
local triggerOverRideAll = false
local inOverRideAll = false
local triggerCenterChange = false
local currentServoCenter
local lastSetServoCenter


fields[#fields + 1] = {t = "ServoID (shown only for debug)", min = 0, max = 100, vals = {1}}
fields[#fields + 1] = {t = "Center", help = "servoMid", min = 50, max = 2250, default = 1500, vals = {2, 3},onChange=function(self) self.servoCenterTriggerChange(self) end,onFocus=function(self) self.servoCenterFocus(self)  end}
fields[#fields + 1] = {t = "Minimum", help = "servoMin", min = -1000, max = 1000, default = -700, vals = {4, 5}}
fields[#fields + 1] = {t = "Maximum", help = "servoMax", min = -1000, max = 1000, default = 700, vals = {6, 7}}

fields[#fields + 1] = {t = "Scale Negative", help = "servoScaleNeg", min = 100, max = 1000, default = 500, vals = {8, 9}}
fields[#fields + 1] = {t = "Scale Positive", help = "servoScalePos", min = 100, max = 1000, default = 500, vals = {10, 11}}

fields[#fields + 1] = {t = "Rate", help = "servoRate", min = 50, max = 5000, default = 333, unit = "Hz", vals = {12, 13}}
fields[#fields + 1] = {t = "Speed", help = "servoSpeed", min = 0, max = 60000, default = 0, unit = "ms", vals = {14, 15}}
fields[#fields + 1] = {t = "Flags", help = "servoSpeed", hideme=true, min = 0, max = 60000, default = 0, unit = "ms", vals = {16, 18}}

return {
    read = 120, -- msp_SERVO_CONFIGURATIONS
    write = 212, -- msp_SET_SERVO_CONFIGURATION
    title = "Servos",
    reboot = false,
    eepromWrite = true,
    minBytes = 33,
    labels = labels,
    fields = fields,
    simulatorResponse = {
        4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0, 120, 5,
        212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
    },
    postRead = function(self)
        -- rf2ethos.utils.log("postRead")
        self.servoCount = self.values[1]
        if rf2ethos.lastServoCount ~= self.servoCount then rf2ethos.lastServoCount = self.servoCount end
        -- self.fields[1].max = servoCount - 1
        self.servoConfiguration = {}
        for i = 1, self.servoCount do
            self.servoConfiguration[i] = {}
            for j = 1, 16 do self.servoConfiguration[i][j] = self.values[1 + (i - 1) * 16 + j] end
        end
        if rf2ethos.lastChangedServo == nil then rf2ethos.lastChangedServo = 1 end
        self.setValues(self, rf2ethos.lastChangedServo)
        self.minBytes = 1 + 16
    end,
    postLoad = function(self)
        -- rf2ethos.utils.log("postLoad")
		
		if rf2ethos.config.ethosRunningVersion >= 1415 then
			rf2ethos.Page.servoCenterFocusAllOff(self)	
		end	
		
		rf2ethos.triggers.isReady = true
    end,
    setValues = function(self, servoIndex)
        -- rf2ethos.utils.log("setValues")
        self.values = {}
        self.values[1] = servoIndex - 1
        for i = 1, 16 do self.values[1 + i] = self.servoConfiguration[servoIndex][i] end
    end,
    servoChanged = function(self, servoIndex)
        -- rf2ethos.utils.log("servoChanged")
        rf2ethos.lastChangedServo = servoIndex
        self.setValues(self, rf2ethos.lastChangedServo)
        rf2ethos.dataBindFields()
    end,	
	servoCenterFocusAllOn = function(self)
		for i = 0, #self.servoConfiguration do
				local servoIndex = i
				local message = {
					command = 193, -- MSP_SET_SERVO_OVERRIDE
					payload = { servoIndex }
				}
				rf2ethos.mspHelper.writeU16(message.payload, 0)
				rf2ethos.mspQueue:add(message)	
		end		
		rf2ethos.triggers.isReady = true
	end,
	servoCenterFocusAllOff = function(self)
	
	
		for i = 0, #self.servoConfiguration do
				local servoIndex = i
				local message = {
					command = 193, -- MSP_SET_SERVO_OVERRIDE
					payload = { servoIndex }
				}
				rf2ethos.mspHelper.writeU16(message.payload, 2001)
				rf2ethos.mspQueue:add(message)	
		end		
		rf2ethos.triggers.isReady = true
	end,
	servoCenterFocus = function(self)
			if inFocus == false then
				rf2ethos.Page.servoCenterFocusOn(self)
				inFocus = true
			else
				rf2ethos.Page.servoCenterFocusOff(off)
				inFocus = false
			end	
    end,
	servoCenterFocusOn = function(self)
		local servoIndex = rf2ethos.Page.fields[1].value -1
		
		local message = {
			command = 193, -- MSP_SET_SERVO_OVERRIDE
			payload = { servoIndex }
		}
		rf2ethos.mspHelper.writeU16(message.payload, 0)
		rf2ethos.mspQueue:add(message)		
	end,	
	servoCenterFocusOff = function(self)
		local servoIndex = rf2ethos.Page.fields[1].value -1
		
		local message = {
			command = 193, -- MSP_SET_SERVO_OVERRIDE
			payload = { servoIndex }
		}
		rf2ethos.mspHelper.writeU16(message.payload, 2001)
		rf2ethos.mspQueue:add(message)		
	end,		
	servoCenterTriggerChange = function(self)
		if inOverRideAll == true or inFocus == true then
			triggerCenterChange = true
			currentServoCenter = math.floor(rf2ethos.Page.fields[2].value)
		else
			triggerCenterChange = false
		end
	end,
	servoCenterChanged = function(self)

			local servoIndex = rf2ethos.Page.fields[1].value -1
			local servoCenter = math.floor(rf2ethos.Page.fields[2].value)
			local servoMin = math.floor(rf2ethos.Page.fields[3].value)		
			local servoMax = math.floor(rf2ethos.Page.fields[4].value)
			local servoScaleNeg = math.floor(rf2ethos.Page.fields[5].value)
			local servoScalePos = math.floor(rf2ethos.Page.fields[6].value)
			local servoRate = math.floor(rf2ethos.Page.fields[7].value)
			local servoSpeed = math.floor(rf2ethos.Page.fields[8].value)
			local servoFlags = math.floor(rf2ethos.Page.fields[9].value)
			
			local message = {
				command = 212, -- MSP_SET_SERVO_CONFIGURATION
				payload = {}
			}
			rf2ethos.mspHelper.writeU8(message.payload, servoIndex)
			rf2ethos.mspHelper.writeU16(message.payload, servoCenter)
			rf2ethos.mspHelper.writeU16(message.payload, servoMin)
			rf2ethos.mspHelper.writeU16(message.payload, servoMax)
			rf2ethos.mspHelper.writeU16(message.payload, servoScaleNeg)
			rf2ethos.mspHelper.writeU16(message.payload, servoScalePos)
			rf2ethos.mspHelper.writeU16(message.payload, servoRate)
			rf2ethos.mspHelper.writeU16(message.payload, servoSpeed)
			rf2ethos.mspHelper.writeU16(message.payload, servoFlags) 

			if rf2ethos.config.mspTxRxDebug == true or rf2ethos.config.logEnable == true then
			   local logData = "{" .. rf2ethos.utils.joinTableItems(message.payload, ", ") .. "}"
			   
			   rf2ethos.utils.log(logData)
			   
				if rf2ethos.config.mspTxRxDebug == true then
						print(logData)
				end			   
			   
			end   
			lastSetServoCenter = servoCenter
			print("Setting center to: " .. servoCenter)
			rf2ethos.mspQueue:add(message)			
	
    end,
    toolButton = function(self)

		local buttons = {
					{
						label = "        OK        ",
						action = function()
							
							--we cant launch the loader here to se rely on the modules
							--wakup function to do this
							triggerOverRideAll = true
							return true
						end
					}, {
						label = "CANCEL",
						action = function()
							return true
						end
					}
				}
				local msg
				local title
				if inOverRideAll == false then
					title = "Activate"
					message = "Set all servos to their configured center position"
				else
					title = "Disable"
					message = "Return control of the servos to the flight controller"
				end
				
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



    end,
	wakeup =  function(self)
	

		if rf2ethos.mspQueue:isProcessed() then
			if currentServoCenter ~= nil then
				if lastSetServoCenter ~= currentServoCenter then
					if triggerCenterChange == true then
							self.servoCenterChanged(self)
							triggerCenterChange = false
					end
				end	
			end
		end	
	
	
		if triggerOverRideAll == true then
			triggerOverRideAll = false

			if inOverRideAll == false then

				rf2ethos.dialogs.progressDisplay = true
				rf2ethos.dialogs.progressWatchDog = os.clock()
				rf2ethos.dialogs.progress = form.openProgressDialog("Servo overide...", "Enabling servo overide.")
				rf2ethos.dialogs.progress:value(0)
				rf2ethos.dialogs.progress:closeAllowed(false)			
			
				rf2ethos.Page.servoCenterFocusAllOn(self)
				inOverRideAll = true
			else
			
				rf2ethos.dialogs.progressDisplay = true
				rf2ethos.dialogs.progressWatchDog = os.clock()
				rf2ethos.dialogs.progress = form.openProgressDialog("Servo overide...", "Disabling servo overide.")
				rf2ethos.dialogs.progress:value(0)
				rf2ethos.dialogs.progress:closeAllowed(false)
			
				rf2ethos.Page.servoCenterFocusAllOff(self)
				inOverRideAll = false
			end
		end
	end,
	onMenuExit = function(self)

			if inOverRideAll == true then
				inOverRideAll = false
				rf2ethos.dialogs.progressDisplay = true
				rf2ethos.dialogs.progressWatchDog = os.clock()
				rf2ethos.dialogs.progress = form.openProgressDialog("Servo overide...", "Disabling servo overide.")
				rf2ethos.dialogs.progress:value(0)
				rf2ethos.dialogs.progress:closeAllowed(false)
			
				rf2ethos.Page.servoCenterFocusAllOff(self)			
				rf2ethos.triggers.closeProgressLoader = true
			end	
	
	end,

	
}
