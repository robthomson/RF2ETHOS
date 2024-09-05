rf2ethos.escui = assert(compile.loadScript(rf2ethos.config.toolDir .. "lib/escui.lua"))()

local pages = {}

pages[#pages + 1] = {title = "SCORPION", folder = "rf2scorp", image = "scorpion.png"}
pages[#pages + 1] = {title = "HOBBYWING 5", folder = "rf2hw5", image = "hobbywing.png"}
pages[#pages + 1] = {title = "YGE", folder = "rf2yge", image = "yge.png"}
pages[#pages + 1] = {title = "FLYROTOR", folder = "flrtr", image = "flrtr.png", disabled = true}

local function openPage(pidx, title, script)
	rf2ethos.escui.openPageEsc(pidx, title, script)
end

return {title = "ESC", 
		pages = pages,
		openPage = openPage
		}
