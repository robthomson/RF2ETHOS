-- RotorFlight + ETHOS LUA configuration

local config = {}
config.toolName = "RF2ETHOS"
config.toolDir = "/scripts/rf2ethos/"
config.logEnable = false
config.useCompiler = true
config.ethosVersion = 1510
config.luaVersion = "2.0.0 - 240625"
config.ethosVersionString = "ETHOS < V1.5.10"
config.environment = system.getVersion()
config.saveTimeout = nil
config.maxRetries = nil
config.apiVersion = 0
config.defaultRateTable = 4 -- ACTUAL
config.requestTimeout = nil
config.lcdWidth = nil
config.lcdHeight = nil
config.iconsizeParam = nil

local icon = lcd.loadMask(config.toolDir .. "RF.png")

compile = assert(loadfile(config.toolDir .. "compile.lua"))(config)


rf2ethos = assert(compile.loadScript(config.toolDir .. "rf2ethos.lua"))(config,compile)


local function wakeup()
	rf2ethos.wakeup()
end


local function event(widget, category, value, x, y)
	return rf2ethos.event(widget, category, value, x, y)
end

local function create()
	return rf2ethos.create()
end

local function close()
	return rf2ethos.close()
end



local function init()
    system.registerSystemTool({
		event = event, 
		name = config.toolName, 
		icon = icon, 
		create = create, 
		wakeup = wakeup, 
		close = close})
end

return {init = init}
