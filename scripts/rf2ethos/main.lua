-- RotorFlight + ETHOS LUA configuration
local config = {}

-- LuaFormatter off
cfg.toolName = "RF2ETHOS" 								-- name of the tool
cfg.toolDir = "/scripts/rf2ethos/" 						-- base path the script is installed into
cfg.Version = "2.1.0"									-- version number of this software release
cfg.logEnable = false 									-- will log to: /scripts/rf2ethos/rf2ethos.log
cfg.logEnableScreen = false 							-- if cfg.logEnable is true then also print to screen
cfg.mspTxRxDebug = false 								-- simple print of full msp payload that is sent and received
cfg.reloadOnSave = false 								-- trigger a reload on save
cfg.ethosVersion = 1514 								-- min version of ethos supported by this script
cfg.ethosVersionString = "ETHOS < V1.5.14" 				-- string to print if ethos version error occurs
cfg.defaultRateTable = 4 -- ACTUAL						-- default rate table - typically this will be ACTUAL, but can be changed if user always uses a different one
cfg.supportedMspApiVersion = {"12.06", "12.07"} 		-- supported msp versions
cfg.simulateOnTransmitter = false 						-- make the transmitter run as if its running in the SIM (no fbl required)
-- LuaFormatter on

local icon = lcd.loadMask(cfg.toolDir .. "RF.png")

compile = assert(loadfile(cfg.toolDir .. "compile.lua"))(config)

rf2ethos = assert(compile.loadScript(cfg.toolDir .. "rf2ethos.lua"))(config, compile)

local function wakeup()
    rf2ethos.wakeup()
end

local function paint()
    rf2ethos.paint()
end

local function event(widget, category, value, x, y)
    return rf2ethos.event(widget, category, value, x, y)
end

local function create()
    rf2ethos.compile.initialise()
    return rf2ethos.create()
end

local function close()
    return rf2ethos.close()
end

local function init()
    system.registerSystemTool({event = event, name = cfg.toolName, icon = icon, create = create, wakeup = wakeup, paint = paint, close = close})
end

return {init = init}
