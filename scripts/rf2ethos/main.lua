-- RotorFlight + ETHOS LUA configuration
local config = {}

-- LuaFormatter off
config.toolName = "RF2ETHOS"                                        -- name of the tool
config.toolDir = "/scripts/rf2ethos/"                               -- base path the script is installed into
config.Version = "2.1.5"                                            -- version number of this software release
config.logEnable = true                                            -- will log to: /scripts/rf2ethos/rf2ethos.log
config.logEnableScreen = true                                      -- if config.logEnable is true then also print to screen
config.mspTxRxDebug = true                                         -- simple print of full msp payload that is sent and received
config.reloadOnSave = false                                         -- trigger a reload on save
config.ethosVersion = 1514                                          -- min version of ethos supported by this script
config.ethosVersionString = "ETHOS < V1.5.14"                       -- string to print if ethos version error occurs
config.defaultRateTable = 4 -- ACTUAL                               -- default rate table - typically this will be ACTUAL, but can be changed if user always uses a different one
config.supportedMspApiVersion = {"12.06", "12.07"}                  -- supported msp versions
config.simulateOnTransmitter = false                                -- make the transmitter run as if its running in the SIM (no fbl required)
config.skipRssiSensorCheck = false                                  -- skip checking for a valid signal when loading connecting to the fbl
config.icon = lcd.loadMask(config.toolDir .. "gfx/icon.png")        -- icon

-- tasks
config.mspTaskName = config.toolName .. " [Msp]"              -- background task name for msp services etc
config.mspTaskKey = "rf2msp"                                  -- key id used for msp services
config.clockSyncTaskName = config.toolName .. " [Clock Sync]"       -- background task name for clock syncs etc
config.clockSyncTaskKey = "rf2bgk"                                  -- key id used for background tasks
config.elrsTelemTaskName = config.toolName .. " [ELRS Telemetry]"   -- background task name for clock syncs etc
config.elrsTelemTaskKey = "rf2elrs"                                 -- key id used for background tasks
config.adjFunctionTaskName = config.toolName .. " [ADJ Functions]"  -- background task name adjust functions
config.adjFunctionTaskKey = "rf2adjf"                               -- key id used for adjust functions

-- LuaFormatter on

local compile = assert(loadfile(config.toolDir .. "compile.lua"))(config)

rf2ethos = {}
rf2ethos.config = config
rf2ethos.app = assert(compile.loadScript(config.toolDir .. "rf2ethos.lua"))(config, compile)
rf2ethos.utils = assert(compile.loadScript(config.toolDir .. "lib/utils.lua"))(config, compile)
rf2ethos.msp = assert(compile.loadScript(config.toolDir .. "msp/msp.lua"))(config,compile)

rf2ethos.tasks = {}
rf2ethos.tasks.clocksync = assert(compile.loadScript(config.toolDir .. "tasks/clocksync.lua"))(config,compile)
rf2ethos.elrstelemetry = assert(compile.loadScript(config.toolDir .. "tasks/elrstelemetry.lua"))(config,compile)
rf2ethos.adjfunctions = assert(compile.loadScript(config.toolDir .. "tasks/adjfunctions.lua"))(config,compile)

local function init()
    system.registerSystemTool({event = rf2ethos.app.event, name = config.toolName, icon = config.icon, create = rf2ethos.app.create, wakeup = rf2ethos.app.wakeup, paint = rf2ethos.app.paint, close = rf2ethos.app.close})
    system.registerTask({name = config.mspTaskName, key = config.mspTaskKey, wakeup = rf2ethos.msp.wakeup})
    system.registerTask({name = config.clockSyncTaskName , key = config.clockSyncTaskKey, wakeup = rf2ethos.tasks.clocksync.wakeup})
    system.registerTask({name = config.elrsTelemTaskName, key = config.elrsTelemTaskKey, wakeup = rf2ethos.elrstelemetry.wakeup})    
    system.registerTask({name = config.adjFunctionTaskName, key = config.adjFunctionTaskKey, wakeup = rf2ethos.adjfunctions.wakeup})    
end

return {init = init}
