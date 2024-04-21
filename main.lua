-- RotorFlight + ETHOS LUA configuration
local environment = system.getVersion()

local LUA_VERSION = "2.0 - 240229"

apiVersion = 0

local uiStatus =
{
    init     = 1,
    mainMenu = 2,
    pages    = 3,
    confirm  = 4,
}

local pageStatus =
{
    display = 1,
    editing = 2,
    saving  = 3,
    eepromWrite = 4,
    rebooting = 5,
}

local telemetryStatus =
{
    ok = 1,
    noSensor = 2,
    noTelemetry = 3
}

local uiMsp =
{
    reboot = 68,
    eepromWrite = 250,
}

local uiState = uiStatus.init
local prevUiState
local pageState = pageStatus.display
-- local requestTimeout = 1.5   -- in seconds (originally 0.8)
local currentPage = 1
local currentField = 1
local saveTS = 0
local saveRetries = 0
local popupMenuActive = 1
local pageScrollY = 0
local mainMenuScrollY = 0
local telemetryState
local saveTimeout, saveMaxRetries, PageFiles, Page, init, popupMenu, requestTimeout, rssiSensor
local createForm = false
local isSaving = false
local wasSaving = false
local lastLabel = nil

-- New variables for Ethos version
local screenTitle = nil
local lastEvent = nil
local enterEvent = nil
local enterEventTime
local callCreate = true
local lastPage

local lastIdx = nil
local lastTitle = nil
local lastScript = nil

lcdNeedsInvalidate = false

--- Virtual key translations from Ethos to OpenTX
local EVT_VIRTUAL_ENTER = 32
local EVT_VIRTUAL_ENTER_LONG = 129
local EVT_VIRTUAL_EXIT = 97
local EVT_VIRTUAL_PREV = 99
local EVT_VIRTUAL_NEXT = 98

local MENU_TITLE_BGCOLOR, ITEM_TEXT_SELECTED, ITEM_TEXT_NORMAL, ITEM_TEXT_EDITING


protocol = nil
radio = nil
sensor = nil

rfglobals = {}

local function saveSettings()
    if Page.values then
        local payload = Page.values
        if Page.preSave then
            payload = Page.preSave(Page)
        end
        saveTS = os.clock()
        if pageState == pageStatus.saving then
            saveRetries = saveRetries + 1
        else
            pageState = pageStatus.saving
            saveRetries = 0
            print("Attempting to write page values...")
        end
        protocol.mspWrite(Page.write, payload)
    end
end

local function eepromWrite()
    saveTS = os.clock()
    if pageState == pageStatus.eepromWrite then
        saveRetries = saveRetries + 1
    else
        pageState = pageStatus.eepromWrite
        saveRetries = 0
        --print("Attempting to write to eeprom...")
    end
    protocol.mspRead(uiMsp.eepromWrite)
end

local function rebootFc()
    -- Only sent once.  I think a response may come back from FC if successful?
    -- May want to either check for that and repeat if not, or check for loss of telemetry to confirm, etc.
    -- TODO: Implement an auto-retry?  Right now if the command gets lost then there's just no reboot and no notice.
    --print("Attempting to reboot the FC (one shot)...")
    saveTS = os.clock()
    pageState = pageStatus.rebooting
    protocol.mspRead(uiMsp.reboot)
    -- https://github.com/rotorflight/rotorflight-firmware/blob/9a5b86d915df557ff320f30f1376cb8ce9377157/src/main/msp/msp.c#L1853
end

local function invalidatePages()
    Page = nil
    pageState = pageStatus.display
    saveTS = 0
    collectgarbage()
    lcdNeedsInvalidate = true
end


local function dataBindFields()
    for i=1,#Page.fields do
        if #Page.values >= Page.minBytes then
            local f = Page.fields[i]
            if f.vals then
                f.value = 0
                for idx=1, #f.vals do
                    local raw_val = Page.values[f.vals[idx]] or 0
                    raw_val = raw_val<<((idx-1)*8)
                    f.value = f.value|raw_val
                end
                local bits = #f.vals * 8
                if f.min and f.min < 0 and (f.value & (1 << (bits - 1)) ~= 0) then
                    f.value = f.value - (2 ^ bits)
                end
                f.value = f.value/(f.scale or 1)
            end
        end
    end
end

-- Run lcd.invalidate() if anything actionable comes back from it.
local function processMspReply(cmd,rx_buf,err)


    if Page and rx_buf ~= nil then
        if environment.simulation ~= true then
		print("heredoc")
            print("Page is processing reply for cmd "..tostring(cmd).." len rx_buf: "..#rx_buf.." expected: "..Page.minBytes)
        end
    end
    if not Page or not rx_buf then
    elseif cmd == Page.write then
        -- check if this page requires writing to eeprom to save (most do)
        if Page.eepromWrite then
            -- don't write again if we're already responding to earlier page.write()s
            if pageState ~= pageStatus.eepromWrite then
                eepromWrite()
            end
        elseif pageState ~= pageStatus.eepromWrite then
            -- If we're not already trying to write to eeprom from a previous save, then we're done.
            invalidatePages()
        end
        lcdNeedsInvalidate = true
    elseif cmd == uiMsp.eepromWrite then
        if Page.reboot then
            rebootFc()
        end
        invalidatePages()
    elseif (cmd == Page.read) and (#rx_buf > 0) then
        --print("processMspReply:  Page.read and non-zero rx_buf")
        Page.values = rx_buf
        if Page.postRead then
            Page.postRead(Page)
        end
        dataBindFields()
        if Page.postLoad then
            Page.postLoad(Page)
            print("Postload executed")
        end
        lcdNeedsInvalidate = true
    end
end

local function requestPage()
    if Page.read and ((not Page.reqTS) or (Page.reqTS + requestTimeout <= os.clock())) then
        --print("Trying requestPage()")
        Page.reqTS = os.clock()
        protocol.mspRead(Page.read)
    end
end


function sportTelemetryPop()
		-- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
		local frame = sensor:popFrame()
		if frame == nil then
			return nil, nil, nil, nil
		end
		-- physId = physical / remote sensor Id (aka sensorId)
		--   0x00 for FPORT, 0x1B for SmartPort
		-- primId = frame ID  (should be 0x32 for reply frames)
		-- appId = data Id
		return frame:physId(), frame:primId(), frame:appId(), frame:value()	
end

function sportTelemetryPush(sensorId, frameId, dataId, value)
    -- OpenTX:
    -- When called without parameters, it will only return the status of the output buffer without sending anything.
    --   Equivalent in Ethos may be:   sensor:idle() ???
    -- @param sensorId  physical sensor ID
    -- @param frameId   frame ID
    -- @param dataId    data ID
    -- @param value     value
    -- @retval boolean  data queued in output buffer or not.
    -- @retval nil      incorrect telemetry protocol.  (added in 2.3.4)
		return sensor:pushFrame({physId=sensorId, primId=frameId, appId=dataId, value=value})
end

-- Ethos: when the RF1 and RF2 system tools are both installed, RF1 tries to call getRSSI in RF2 and gets stuck.
-- To avoid this, getRSSI is renamed in RF2.
function rf2touch_getRSSI()
      --print("getRSSI RF2")
    if environment.simulation == true then
        return 100
    end
      
    if rssiSensor ~= nil and rssiSensor:state() then
      -- this will return the last known value if nothing is received
      return rssiSensor:value()
    end
    -- return 0 if no telemetry signal to match OpenTX
    return 0
end

function getTime()
    return os.clock() * 100;
end

function loadScript(script)
    return loadfile(script)
end

function getWindowSize()
    return lcd.getWindowSize()
    --return 784, 406
    --return 472, 288
    --return 472, 240
end

local function updateTelemetryState()
    local oldTelemetryState = telemetryState

    if not rssiSensor then
        telemetryState = telemetryStatus.noSensor
    elseif rf2touch_getRSSI() == 0 then
        telemetryState = telemetryStatus.noTelemetry
    else
        telemetryState = telemetryStatus.ok
    end

    if oldTelemetryState ~= telemetryState then
        lcdNeedsInvalidate = true
    end
end


local function saveValue(newValue,currentField)
    local f = Page.fields[currentField]
    local scale = f.scale or 1
    local mult = f.mult or 1
    
	f.value = newValue*mult/scale, (f.min or 0)/scale, (f.max or 255)/scale
	f.value = math.floor(f.value*scale/mult + 0.5)*mult/scale
    for idx=1, #f.vals do
        Page.values[f.vals[idx]] = math.floor(f.value*scale + 0.5)>>((idx-1)*8)
    end
    if f.upd and Page.values then
        f.upd(Page)
    end
end

---
--- ETHOS system tool functions
---

local translations = {en="RF2 TOUCH"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end


function msgBox(str)

	lcd.font(FONT_STD)

    local w, h = lcd.getWindowSize()	
	boxW = math.floor(w / 2)
	boxH = 45
	tsizeW, tsizeH = lcd.getTextSize(str)

	--draw the background
	if isDARKMODE then
		lcd.color(lcd.RGB(40, 40, 40))
	else
		lcd.color(lcd.RGB(240, 240, 240))
	end
	lcd.drawFilledRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH)

	--draw the border
	if isDARKMODE then
		-- dark theme
		lcd.color(lcd.RGB(255, 255, 255, 1))
	else
		-- light theme
		lcd.color(lcd.RGB(90, 90, 90))
	end
	lcd.drawRectangle(w / 2 - boxW / 2, h / 2 - boxH / 2, boxW, boxH)

	if isDARKMODE then
		-- dark theme
		lcd.color(lcd.RGB(255, 255, 255, 1))
	else
		-- light theme
		lcd.color(lcd.RGB(90, 90, 90))
	end
	lcd.drawText((w / 2) - tsizeW / 2, (h / 2) - tsizeH / 2, str)
	
	lcd.invalidate()
	
return
end


-- EVENT:  Called for button presses, scroll events, touch events, etc.
local function event(widget, category, value, x, y)
        --print("Event received:", category, value, x, y)
        return false
end


function paint()
	if telemetryState ~= 1 then
		msgBox("NO RF LINK")
	end
	if pageState >= pageStatus.saving then		
		local saveMsg = ""
		if pageState == pageStatus.saving then
			saveMsg = "Saving..."
			if saveRetries > 0 then
				saveMsg = "Retry #"..string.format("%u",saveRetries)
			end
		elseif pageState == pageStatus.eepromWrite then
			saveMsg = "Updating..."
			if saveRetries > 0 then
				saveMsg = "Retry #"..string.format("%u",saveRetries)
			end
		elseif pageState == pageStatus.rebooting then
			saveMsg = "Rebooting..."
		end
		msgBox(saveMsg)
		--print(saveMsg)
	else
		isSaving = false
	end	
	
end

function wakeUpForm() 
	if telemetryState ~= 1 or (pageState >= pageStatus.saving) then
		-- we dont refresh as busy doing other stuff
		--print("Form invalidation disabled....")
	else
		if isSaving == false and wasSaving == false then
			form.invalidate()
		end
	end	
end



-- WAKEUP:  Called every ~30-50ms by the main Ethos software loop
function wakeup(widget)
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
    -- Process outgoing TX packets and check for incoming frames
    -- Should run every wakeup() cycle with a few exceptions where returns happen earlier
	
	    updateTelemetryState()
		

		if uiState == uiStatus.init then
			--print("Init")
			local prevInit
			if init ~= nil then
				prevInit = init.t
			end
			init = init or assert(loadScript("/scripts/RF2TOUCH/ui_init.lua"))()

			local initSuccess = init.f()
			
			print(initSuccess)
			
			if prevInit ~= init.t then
				-- Update initialization message
				lcd.invalidate()
			end
			if not initSuccess then
				-- waiting on api version to finish successfully.
					
				return 0
			end
			init = nil
			invalidatePages()
			uiState = prevUiState or uiStatus.mainMenu
			prevUiState = nil

		elseif uiState == uiStatus.mainMenu then
				--print("Menu")
		elseif uiState == uiStatus.pages then
			if prevUiState ~= uiState then
				lcdNeedsInvalidate = true
				prevUiState = uiState
			end

			if pageState == pageStatus.saving then
				if (saveTS + saveTimeout) < os.clock() then
					if saveRetries < saveMaxRetries then
						saveSettings()
						lcdNeedsInvalidate = true
					else
						print("Failed to write page values!")
						invalidatePages()
					end
					-- drop through to processMspReply to send MSP_SET and see if we've received a response to this yet.
				end
			elseif pageState == pageStatus.eepromWrite then
				if (saveTS + saveTimeout) < os.clock() then
					if saveRetries < saveMaxRetries then
						eepromWrite()
						lcdNeedsInvalidate = true
					else
						print("Failed to write to eeprom!")
						invalidatePages()
					end
					-- drop through to processMspReply to send MSP_SET and see if we've received a response to this yet.
				end
			end
			if not Page then
				print("Reloading data : " .. lastPage)
				Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. lastPage))()
				collectgarbage()
			end			
			if not Page.values and pageState == pageStatus.display then
			  requestPage()
			end			
		
		end

        mspProcessTxQ()
        processMspReply(mspPollReply())
        lastEvent = nil
		
		-- handle some display stuff to bring form in and out of focus for no rf link
		if telemetryState ~= 1 or (pageState >= pageStatus.saving) then
			-- we have no telemetry - hide the form
			form.clear()
			createForm = true
		else
			if createForm == true then	
				if wasSaving == true then
					openPage(lastIdx, lastTitle, lastScript)
					wasSaving = false
				else	
					openMainMenu()
				end	
				createForm = false
			else
				createForm = false
			end
		end	
		
		
		
end

--local openMainMenu


local function convertPageValueTable(tbl)
	local thetable = {}
	if 	tbl[0] ~= nil then
		thetable[0] = {}
		thetable[0][1] = tbl[0]
		thetable[0][2] = 0			
	end
	for idx,value in ipairs(tbl) do
		thetable[idx] = {}
		thetable[idx][1] = value
		thetable[idx][2] = idx	
	end
	return thetable
end

function print_r(arr, indentLevel)
    local str = ""
    local indentStr = "#"

    if(indentLevel == nil) then
        print(print_r(arr, 0))
        return
    end

    for i = 0, indentLevel do
        indentStr = indentStr.."\t"
    end

    for index,value in ipairs(arr) do
        if type(value) == "table" then
            str = str..indentStr..index..": \n"..print_r(value, (indentLevel + 1))
        else 
            str = str..indentStr..index..": "..value.."\n"
        end
    end
    return str
end



function openPage(idx, title, script)

	uiState = uiStatus.pages
	

	lastIdx = idx
	lastTitle = title
	lastScript = script

    form.clear()
	
	lastPage = script
	Page = assert(loadScript("/scripts/RF2TOUCH/pages/" .. script))()
	collectgarbage()		

	print("IDX: " .. idx)
	print("SCRIPT: " .. script)


	local w, h = lcd.getWindowSize()
	
	
	line = form.addLine(title)
	
	-- column starts at 59.4% of w
	padding = 5	
	colStart = math.floor((w * 59.4) /100)
	buttonW = (w-colStart)/2 - padding
	buttonH = 30
	form.addTextButton(line, 
						{x=colStart, y=padding, w=buttonW, h=buttonH}, 
						"MENU",
						function() 
								openMainMenu()
						end)		
	form.addTextButton(line, 
						{x=colStart + buttonW + padding , y=padding, w=buttonW, h=buttonH}, 
						"SAVE",
						function() 
						
							local buttons = {
							  {label="        OK        ", 
							   action=function() 
										 isSaving = true
										 wasSaving = true
										 saveSettings()
									     return true 
									  end
							  },
							  {label="CANCEL", 
							   action=function() 
										return true 
									end},
							  }
							form.openDialog("SAVE SETTINGS TO FBL", "Save current page to flight controller", buttons)
							--saveSettings()
						end)	


	for i=1,#Page.fields do

		local f = Page.fields[i]
		local pageValue = f
		local pageIdx= i

		if pageValue.t ~= nil then
		    if pageValue.label ~= nil then
				fieldName = "    " .. pageValue.t
			else
				fieldName = pageValue.t
			end
		else
			fieldName = 'unknown'
		end
		
	
			
		-- insert label
		if pageValue.label ~= nil then
					local l = Page.labels[pageValue.label]
					local labelValue = l
					
					if pageValue.t ~= nil then
						labelName = labelValue.t
					else
						labelName = 'unknown'
					end	
					if pageValue.label ~= lastLabel then
						line = form.addLine(labelName)
						form.addStaticText(line, nil, "")
						lastLabel = pageValue.label
					end
		end

		
		-- CHOICE
		if pageValue.field == 0 then
			if pageValue.table then		
				line = form.addLine(fieldName)
				field = form.addChoiceField(
					line,
					nil,
					convertPageValueTable(pageValue.table),
					function()
						-- get the value
						return f.value
					end,
					function(newValue)
						-- store the value
						f.value = newValue
						saveValue(newValue,i)
					end
				)
				if pageValue.default ~= nil then
					-- choice fields do not support this method
				end	
			end		
		end	
		-- SLIDER
		if pageValue.field == 1 then
			if not pageValue.table then	 
				line = form.addLine(fieldName)
				field = form.addSliderField(
					line,
					nil,
					pageValue.min,
					pageValue.max,
					function() 
						-- get the value
							return f.value	
					end,
					function(newValue) 
						-- write the value
						f.value = newValue 
						saveValue(newValue,i)
					end
					)	
				if pageValue.default ~= nil then
					 -- slider fields do not support this method
				end					
			end 
		end	
		-- NUMBER
		if pageValue.field == 2 then
			if not pageValue.table then		
				line = form.addLine(fieldName)
				field = form.addNumberField(
					line,
					nil,
					pageValue.min,
					pageValue.max,
					function()
						-- get the value
							return f.value
					end,
					function(value)
						-- save the value
						f.value = value
						saveValue(value,i)
					end
				)
				if pageValue.default ~= nil then
					 field:default(pageValue.default)
				end		
				if pageValue.decimals ~= nil then
					 field:decimals(pageValue.decimals)
				end						
				if pageValue.suffix ~= nil then
					 field:suffix(pageValue.suffix)
				end	
			end	
		end
							
	end


	lcdNeedsInvalidate = true
end

function openMainMenu()

	uiState = uiStatus.mainMenu

    local windowWidth, windowHeight = lcd.getWindowSize()

    local padding = 15
    local h = 50
    local w = (windowWidth - 3 * padding) / 2
    local x = padding
    local y = -h

    form.clear()

    for idx, value in ipairs(PageFiles) do
        --print(value.title)
        
        if idx % 2 == 1 then
            x = padding
            y = y + h + padding
        else
            x = x + w + padding
        end

        form.addTextButton(
            nil, 
            {x=x, y=y, w=w, h=h}, 
            value.title,
            function() 
                openPage(idx, value.title, value.script)
            end)
    end
end

local function create()

    protocol = assert(loadScript("/scripts/RF2TOUCH/protocols.lua"))()
    radio = assert(loadScript("/scripts/RF2TOUCH/radios.lua"))().msp
    assert(loadScript(protocol.mspTransport))()
    assert(loadScript("/scripts/RF2TOUCH/MSP/common.lua"))()

    sensor = sport.getSensor({primId=0x32})
    rssiSensor = system.getSource("RSSI")
    if not rssiSensor then
        rssiSensor = system.getSource("RSSI 2.4G")
        if not rssiSensor then
            rssiSensor = system.getSource("RSSI 900M")
            if not rssiSensor then
                rssiSensor = system.getSource("Rx RSSI1")
                if not rssiSensor then
                    rssiSensor = system.getSource("Rx RSSI2")
                end
            end
        end
    end

    -- Initial var setting
    saveTimeout = protocol.saveTimeout
    saveMaxRetries = protocol.saveMaxRetries
    requestTimeout = protocol.pageReqTimeout
    uiState = uiStatus.init
    init = nil
    lastEvent = nil
    apiVersion = 0



    PageFiles = assert(loadScript("/scripts/RF2TOUCH/pages.lua"))()

	-- force page to get pickup data as it loads in
	form.onWakeup(
		function()
		wakeUpForm() 
		end)

    openMainMenu()
end

local function close()
        --print("Close")	
        pageLoaded = 100
        pageTitle = nil
        pageFile = nil
        system.exit()		
end

local icon = lcd.loadMask("/scripts/RF2TOUCH/RF.png")

local function init()
    system.registerSystemTool({event=event,paint=paint,name=name, icon=icon, create=create, wakeup=wakeup, close=close})
end

return {init=init}