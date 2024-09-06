
local pages = {}

local mspSignature
local mspHeaderBytes
local mspBytes
local simulatorResponse
local escDetails = {}
local foundESC = false
local foundESCupdateTag = false

local ESC

local modelField
local versionField
local firmwareField

local findTimeoutClock = os.clock()
local findTimeout = 5

local modelLine
local modelText
local modelTextPos = {x = 0, y = rf2ethos.radio.linePaddingTop, w = rf2ethos.config.lcdWidth, h = rf2ethos.radio.navbuttonHeight}



local function getESCDetails()
    local message = {
        command = 217, -- MSP_STATUS
        processReply = function(self, buf)

			if buf[1] == mspSignature then
			
				escDetails.model = ESC.getEscModel(buf)
				escDetails.version =  ESC.getEscVersion(buf)
				escDetails.firmware =  ESC.getEscFirmware(buf)

				foundESC = true
			
			end
				
        end,
        simulatorResponse = simulatorResponse
    }

    rf2ethos.mspQueue:add(message)
end

local function openPage(pidx, title, script)

	rf2ethos.lastIdx = pidx
	rf2ethos.lastTitle = title
	rf2ethos.lastScript = script
		
	local folder = title

    ESC = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/init.lua"))()
	

	mspSignature = ESC.mspSignature
	mspHeaderBytes = ESC.mspHeaderBytes
	mspBytes  = ESC.mspBytes 
	simulatorResponse = ESC.simulatorResponse

    rf2ethos.formFields = {}
    rf2ethos.formLines = {}
    -- rf2ethos.utils.log("ui.openPageEscTool")


    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight

    local y = rf2ethos.radio.linePaddingTop

    form.clear()

    line = form.addLine("Esc" .. ' / ' .. ESC.toolName)
	
	

    buttonW = 100
    local x = windowWidth - buttonW

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x - buttonW - 5, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
			rf2ethos.ui.openPage(pidx, "Esc", "esc.lua")
			
        end
    })
    rf2ethos.formNavigationFields['menu']:focus()

    rf2ethos.formNavigationFields['refresh'] = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "RELOAD",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
			--rf2ethos.ui.openPage(pidx, folder, "esc_tool.lua")
			rf2ethos.Page = nil
			rf2ethos.triggers.triggerReload = true
        end
    })
    rf2ethos.formNavigationFields['menu']:focus()


    ESC.pages = assert(compile.loadScript(rf2ethos.config.toolDir .. "pages/esc/" .. folder .. "/pages.lua"))()


    modelLine = form.addLine("")
	modelText = form.addStaticText(modelLine, modelTextPos, "")


    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- size of buttons
    rf2ethos.config.iconsizeParam = rf2ethos.utils.loadPreference(rf2ethos.config.toolDir .. "/preferences/iconsize")

    if rf2ethos.config.iconsizeParam == nil or rf2ethos.config.iconsizeParam == "" then
        rf2ethos.config.iconsizeParam = 1
    else
        rf2ethos.config.iconsizeParam = tonumber(rf2ethos.config.iconsizeParam)
    end

    -- TEXT ICONS
    if rf2ethos.config.iconsizeParam == 0 then
        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = (rf2ethos.config.lcdWidth - padding) / rf2ethos.radio.buttonsPerRow - padding
        buttonH = rf2ethos.radio.navbuttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if rf2ethos.config.iconsizeParam == 1 then

        padding = rf2ethos.radio.buttonPaddingSmall
        buttonW = rf2ethos.radio.buttonWidthSmall
        buttonH = rf2ethos.radio.buttonHeightSmall
        numPerRow = rf2ethos.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if rf2ethos.config.iconsizeParam == 2 then

        padding = rf2ethos.radio.buttonPadding
        buttonW = rf2ethos.radio.buttonWidth
        buttonH = rf2ethos.radio.buttonHeight
        numPerRow = rf2ethos.radio.buttonsPerRow
    end

    local lc = 0
    local bx = 0

	if rf2ethos.gfx_buttons["esctool"] == nil then
		rf2ethos.gfx_buttons["esctool"] = {}
	end
	if rf2ethos.menuLastSelected["esctool"] == nil then	
		rf2ethos.menuLastSelected["esctool"] = 1
	end	

    for pidx, pvalue in ipairs(ESC.pages) do

        if lc == 0 then
            if rf2ethos.config.iconsizeParam == 0 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 1 then y = form.height() + rf2ethos.radio.buttonPaddingSmall end
            if rf2ethos.config.iconsizeParam == 2 then y = form.height() + rf2ethos.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if rf2ethos.config.iconsizeParam ~= 0 then
            if rf2ethos.gfx_buttons["esctool"][pvalue.image] == nil then rf2ethos.gfx_buttons["esctool"][pvalue.image] = lcd.loadMask(rf2ethos.config.toolDir .. "gfx/esc/" .. pvalue.image) end
        else
            rf2ethos.gfx_buttons["esctool"][pvalue.image] = nil
        end

        -- rf2ethos.utils.log("x = " .. bx .. ", y = " .. y .. ", w = " .. buttonW .. ", h = " .. buttonH)
        rf2ethos.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.title,
            icon = rf2ethos.gfx_buttons["esctool"][pvalue.image],
            options = FONT_S,
            paint = function()
            end,
            press = function()
				rf2ethos.menuLastSelected["esctool"] = pidx
                rf2ethos.ui.progessDisplay()


				--rf2ethos.ui.openPage(pidx, folder, "esc_form.lua",pvalue.script)
				rf2ethos.ui.openPage(pidx, title, "esc/"..folder.."/pages/".. pvalue.script)
				
            end
        })

		if rf2ethos.menuLastSelected["esctool"] == pidx then rf2ethos.formFields[pidx]:focus() end

        rf2ethos.formFields[pidx]:enable(false)

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

	getESCDetails()

   
 
end



local function wakeup()

	-- enable the form
	if foundESC == true and foundESCupdateTag == false then
		foundESCupdateTag = true
		if escDetails.model ~= nil and escDetails.model ~= nil and  escDetails.firmware ~= nil then
			local text = escDetails.model .. " " .. escDetails.version .. " " .. escDetails.firmware
			rf2ethos.escHeaderLineText = text
			modelText = form.addStaticText(modelLine, modelTextPos, text)
		end
		
		for i,v in ipairs(rf2ethos.formFields) do
			  rf2ethos.formFields[i]:enable(true)
		end
		
		rf2ethos.triggers.closeProgressLoader = true
		
	end
	
	if foundESCupdateTag == false and (findTimeoutClock <= os.clock() - findTimeout) then
		rf2ethos.ui.progessDisplayClose()
		rf2ethos.triggers.isReady = true
		modelText = form.addStaticText(modelLine, modelTextPos, "UNKNOWN")
	end

end

local function event(widget, category, value, x, y)
	
	--print("Event received:" .. ", " .. category .. "," .. value .. "," .. x .. "," .. y)

	 if category == 5 or value == 35 then
		rf2ethos.ui.openPage(pidx, "Esc", "esc.lua")
		return true
	 end
	 
	 return false
end

return {title = "ESC", 
		openPage = openPage,
		wakeup = wakeup,
		event = event
		}
