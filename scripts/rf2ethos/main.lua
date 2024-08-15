-- RotorFlight + ETHOS LUA configuration
local config = {}
config.toolName = "RF2ETHOS"							-- name of the tool
config.toolDir = "/scripts/rf2ethos/"					-- base path the script is installed into
config.logEnable = false								-- will log to: /scripts/rf2ethos/rf2ethos.log
config.logEnableScreen = false							-- if config.logEnable is true then also print to screen
config.mspTxRxDebug = false								-- simple print of full msp payload that is sent and received
config.reloadOnSave = false								-- trigger a reload on save
config.useCompiler = true								-- compile the scripts (can be bypassed by /scripts/nocompile or /scripts/rf2ethos.nocompile)
config.ethosVersion = 1510								-- min version of ethos supported by this script
config.ethosVersionString = "ETHOS < V1.5.10"			-- string to print if ethos version error occurs
config.defaultRateTable = 4 -- ACTUAL					-- default rate table - typically this will be ACTUAL, but can be changed if user always uses a different one
config.supportedMspApiVersion = { "12.06", "12.07" }	-- supported msp versions


local icon = lcd.loadMask(config.toolDir .. "RF.png")

compile = assert(loadfile(config.toolDir .. "compile.lua"))(config)

rf2ethos = assert(compile.loadScript(config.toolDir .. "rf2ethos.lua"))(config, compile)

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
    system.registerSystemTool({event = event, name = config.toolName, icon = icon, create = create, wakeup = wakeup, close = close})
end

return {init = init}
