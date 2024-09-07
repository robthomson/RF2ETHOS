local line = {}
local fields = {}

local formLoaded = false
local triggerStart = false
local startTest = false
local startTestTime = os.clock()
local startTestLength = 20

local testLoader
local testLoaderDisplay = false
local testLoaderUpdateRate = 2
local testLoaderUpdateTime = os.clock()
local testLoaderStepSize = 100 / (startTestLength/2)
local testLoaderStepSizeValue = 0

rf2ethos.mspSpeedTestStats = {}

local function openPage(pidx, title, script)

    rf2ethos.lastIdx = pidx
    rf2ethos.lastTitle = title
    rf2ethos.lastScript = script

 
    local windowWidth = rf2ethos.config.lcdWidth
    local windowHeight = rf2ethos.config.lcdHeight

    local y = rf2ethos.radio.linePaddingTop

    form.clear()

    local titleline = form.addLine("Msp speed")

    local buttonW = 100
	local buttonWs = buttonW  - (buttonW  * 20) / 100
    local x = windowWidth - buttonWs

    rf2ethos.formNavigationFields['menu'] = form.addButton(line, {x = x -5 - buttonW, y = rf2ethos.radio.linePaddingTop, w = buttonW, h = rf2ethos.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            rf2ethos.ui.openMainMenu()

        end
    })
    rf2ethos.formNavigationFields['menu']:focus()

    -- HELP BUTTON
	local help = assert(compile.loadScript(rf2ethos.config.toolDir .. "help/pages.lua"))()
	local section = string.gsub(rf2ethos.lastScript, ".lua", "") -- remove .lua
	rf2ethos.formNavigationFields['help'] = form.addButton(line, {x = x, y = rf2ethos.radio.linePaddingTop, w = buttonWs, h = rf2ethos.radio.navbuttonHeight}, {
		text = "?",
		icon = nil,
		options = FONT_S,
		paint = function()
		end,
		press = function()
			if rf2ethos.Page and rf2ethos.Page.onHelpMenu then
				rf2ethos.Page.onHelpMenu(rf2ethos.Page)
			else
				rf2ethos.ui.openPagehelp(help.data, section)
			end
		end
	})





	--line['intro'] = form.addLine("")
	--form.addStaticText(line['intro'], {x=0,y=rf2ethos.radio.linePaddingTop,w=windowWidth,h=rf2ethos.radio.formRowHeight}, "Please press that start button to commence testing your data link.")


	line['total'] = form.addLine("Total queries")
    fields['total'] = form.addTextField(line['total'], nil, function() return "0" end, function(value) end)
	fields['total']:enable(false)
	
	line['success'] = form.addLine("Successfull queries")
    fields['success'] = form.addTextField(line['success'], nil, function() return "0" end, function(value) end)
	fields['success']:enable(false)

	line['timeouts'] = form.addLine("Timed out queries")
    fields['timeouts'] = form.addTextField(line['timeouts'], nil, function() return "0" end, function(value) end)
	fields['timeouts']:enable(false)
 
	line['retries'] = form.addLine("Protocol Retries")
    fields['retries'] = form.addTextField(line['retries'], nil, function() return "0" end, function(value) end)
	fields['retries']:enable(false)
 
	line['start'] = form.addLine("")
    fields['start'] = form.addTextButton(line['start'], nil, "TEST", function() triggerStart = true end)


	formLoaded = true
end

local function updateStats()

    fields['total'] = form.addTextField(line['total'], nil, function() return rf2ethos.mspSpeedTestStats['count'] end, function(value) end)
	fields['total']:enable(false)

end


local function getMSP()
    local message = {
        command = 94, -- MSP_STATUS
        processReply = function(self, buf)
				
        end,
        simulatorResponse = {3, 25, 250, 0, 12, 0, 1, 30, 30, 45, 50, 50, 100, 15, 15, 20, 2, 10, 10, 15, 100, 100, 5, 0, 30, 0, 25, 0, 40, 55, 40, 75, 20, 25, 0, 15, 45, 45, 15, 15, 20}
    }
    rf2ethos.mspQueue:add(message)
end

local function wakeup()

	if formLoaded == true then
		rf2ethos.triggers.closeProgressLoader = true
		formLoaded = false
	end
	
   if triggerStart == true then
        local buttons = {
            {
                label = "        OK        ",
                action = function()
                    -- trigger test
					startTestTime = os.clock()
                    startTest = true
                    return true
                end
            }, {
                label = "CANCEL",
                action = function()
                    return true
                end
            }
        }
        form.openDialog({
            width = nil,
            title = "Start",
            message = "Click OK to start testing your rf systems msp performance?",
            buttons = buttons,
            wakeup = function()
            end,
            paint = function()
            end,
            options = TEXT_LEFT
        })

        triggerStart = false
    end	
	
	if startTest == true then
		local now = os.clock()

		-- launch progress box
		if testLoaderDisplay == false then
			testLoader = form.openProgressDialog("Testing..", "Testing msp performance...")
			testLoader:value(0)
			testLoader:closeAllowed(false)
			testLoaderDisplay = true
			rf2ethos.mspSpeedTestStats['count'] = 0
		end

		-- update progress box
		if (now - testLoaderUpdateRate) >= testLoaderUpdateTime then
			testLoaderUpdateTime = now
			testLoader:value(testLoaderStepSizeValue)
			testLoaderStepSizeValue = testLoaderStepSizeValue + testLoaderStepSize
		end
		
		-- close progress box
		if (now - startTestLength) > startTestTime then
			
			updateStats()
		
			startTest = false
			testLoader:close()
			testLoaderDisplay = false	
		end

		-- do msp query
		if rf2ethos.mspQueue:isProcessed() then
			rf2ethos.mspSpeedTestStats['count'] = rf2ethos.mspSpeedTestStats['count'] + 1
			getMSP()
		end
	
	end
	

end

rf2ethos.uiState = rf2ethos.uiStatus.pages

return {title = "Msp speed", openPage = openPage, wakeup = wakeup, event = event}
