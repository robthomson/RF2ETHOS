-- RotorFlight + ETHOS LUA configuration
local config = {}

-- LuaFormatter off
config.toolName = "RF2ETHOS"                                        -- name of the tool
config.toolDir = "/scripts/rf2ethos/"                               -- base path the script is installed into
config.Version = "2.1.6"                                            -- version number of this software release
config.logEnable = false                                            -- will log to: /scripts/rf2ethos/rf2ethos.log
config.logEnableScreen = false                                      -- if config.logEnable is true then also print to screen
config.mspTxRxDebug = false                                         -- simple print of full msp payload that is sent and received
config.reloadOnSave = false                                         -- trigger a reload on save
config.ethosVersion = 1515                                          -- min version of ethos supported by this script
config.ethosVersionString = "ETHOS < V1.5.15"                       -- string to print if ethos version error occurs
config.defaultRateTable = 4 -- ACTUAL                               -- default rate table - typically this will be ACTUAL, but can be changed if user always uses a different one
config.supportedMspApiVersion = {"12.06", "12.07"}                  -- supported msp versions
config.simulateOnTransmitter = false                                -- make the transmitter run as if its running in the SIM (no fbl required)
config.skipRssiSensorCheck = false                                  -- skip checking for a valid signal when loading connecting to the fbl
config.icon = lcd.loadMask(config.toolDir .. "gfx/icon.png")        -- icon

-- tasks
config.mspTaskName = config.toolName .. " [Background Tasks]"                     -- background task name for msp services etc
config.mspTaskKey = "rf2bg"                                        -- key id used for msp services
config.clockSyncTaskName = config.toolName .. " [Clock Sync]"       -- background task name for clock syncs etc
config.clockSyncTaskKey = "rf2bgk"                                  -- key id used for background tasks
config.elrsTelemTaskName = config.toolName .. " [ELRS Telemetry]"   -- background task name for clock syncs etc
config.elrsTelemTaskKey = "rf2elrs"                                 -- key id used for background tasks
config.adjFunctionTaskName = config.toolName .. " [ADJ Functions]"  -- background task name adjust functions
config.adjFunctionTaskKey = "rf2adjf"                               -- key id used for adjust functions

-- widgets
config.rf2govName = "RotorFlight Governor"                          -- RF2Gov Name
config.rf2govKey = "rf2gov"                                         -- RF2Gov Key
config.rf2statusName = "RotorFlight Status"                         -- RF2Status name
config.rf2statusKey = "bkshss"                                      -- RF2Status key

-- LuaFormatter on

local compile = assert(loadfile(config.toolDir .. "compile.lua"))(config)

-- main
rf2ethos = {}
rf2ethos.config = config
rf2ethos.app = assert(compile.loadScript(config.toolDir .. "rf2ethos.lua"))(config, compile)
rf2ethos.utils = assert(compile.loadScript(config.toolDir .. "lib/utils.lua"))(config, compile)
rf2ethos.bg = assert(compile.loadScript(config.toolDir .. "bg.lua"))(config,compile)

-- tasks
rf2ethos.tasks = {}
rf2ethos.tasks.clocksync = assert(compile.loadScript(config.toolDir .. "tasks/clocksync.lua"))(config,compile)
rf2ethos.elrstelemetry = assert(compile.loadScript(config.toolDir .. "tasks/elrstelemetry.lua"))(config,compile)
rf2ethos.adjfunctions = assert(compile.loadScript(config.toolDir .. "tasks/adjfunctions.lua"))(config,compile)

-- widgets
rf2ethos.rf2gov = assert(compile.loadScript(config.toolDir .. "widgets/rf2gov.lua"))(config,compile)
rf2ethos.rf2status = assert(compile.loadScript(config.toolDir .. "widgets/rf2status.lua"))(config,compile)

-- LuaFormatter off

local function init()
        system.registerSystemTool({event = rf2ethos.app.event, name = config.toolName, icon = config.icon, create = rf2ethos.app.create, wakeup = rf2ethos.app.wakeup, paint = rf2ethos.app.paint, close = rf2ethos.app.close})
        system.registerTask({name = config.mspTaskName, key = config.mspTaskKey, wakeup = rf2ethos.bg.wakeup})
        system.registerTask({name = config.clockSyncTaskName , key = config.clockSyncTaskKey, wakeup = rf2ethos.tasks.clocksync.wakeup})
        system.registerTask({name = config.elrsTelemTaskName, key = config.elrsTelemTaskKey, wakeup = rf2ethos.elrstelemetry.wakeup})        
        system.registerTask({name = config.adjFunctionTaskName, key = config.adjFunctionTaskKey, wakeup = rf2ethos.adjfunctions.wakeup})
        system.registerWidget({name = config.rf2govName,key = config.rf2govKey, create = rf2ethos.rf2gov.create, paint = rf2ethos.rf2gov.paint, wakeup = rf2ethos.rf2gov.wakeup, persistent = false})        
        system.registerWidget({name = config.rf2statusName,key = config.rf2statusKey, menu = rf2ethos.rf2status.menu, event = rf2ethos.rf2status.event, write = rf2ethos.rf2status.write, read = rf2ethos.rf2status.read, configure = rf2ethos.rf2status.configure, create = rf2ethos.rf2status.create, paint = rf2ethos.rf2status.paint, wakeup = rf2ethos.rf2status.wakeup, persistent = false})        
end

-- LuaFormatter on

return {init = init}



