-- RotorFlight + ETHOS LUA configuration
local config = {}

-- LuaFormatter off
config.toolName = "RF2ETHOS"                                        -- name of the tool
config.toolDir = "/scripts/rf2ethos/"                               -- base path the script is installed into
config.Version = "2.1.5"                                            -- version number of this software release
config.logEnable = false                                            -- will log to: /scripts/rf2ethos/rf2ethos.log
config.logEnableScreen = false                                      -- if config.logEnable is true then also print to screen
config.mspTxRxDebug = false                                         -- simple print of full msp payload that is sent and received
config.reloadOnSave = false                                         -- trigger a reload on save
config.ethosVersion = 1514                                          -- min version of ethos supported by this script
config.ethosVersionString = "ETHOS < V1.5.14"                       -- string to print if ethos version error occurs
config.defaultRateTable = 4 -- ACTUAL                               -- default rate table - typically this will be ACTUAL, but can be changed if user always uses a different one
config.supportedMspApiVersion = {"12.06", "12.07"}                  -- supported msp versions
config.simulateOnTransmitter = false                                -- make the transmitter run as if its running in the SIM (no fbl required)
config.skipRssiSensorCheck = false                                  -- skip checking for a valid signal when loading connecting to the fbl

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


rf2ethos = {}

local icon = lcd.loadMask(config.toolDir .. "gfx/icon.png")

local compile = assert(loadfile(config.toolDir .. "compile.lua"))(config)
rf2ethos.app = assert(compile.loadScript(config.toolDir .. "rf2ethos.lua"))(config, compile)
rf2ethos.utils = assert(compile.loadScript(config.toolDir .. "lib/utils.lua"))()

local msp
local function mspTask()
    if msp == nil then
        msp = assert(compile.loadScript(config.toolDir .. "tasks/msp.lua"))(config,compile)
    else
        msp.run()
    end    
end


local elrsTelemetry
local function elrsTelemetryTask()
    if elrsTelemetry == nil then
        elrsTelemetry = assert(compile.loadScript(config.toolDir .. "tasks/elrstelemetry.lua"))(config,compile)
    else
        elrsTelemetry.run()
    end    
end

local clockSync
local function clockSyncTask()
    if clockSync == nil then
        clockSync = assert(compile.loadScript(config.toolDir .. "tasks/clocksync.lua"))(config,compile)
    else
        clockSync.run()
    end    
end

local adjFunction
local function adjFunctionTask()
    if adjFunction == nil then
        adjFunction = assert(compile.loadScript(config.toolDir .. "tasks/adjfunctions.lua"))(config,compile)
    else
        adjFunction.run()
    end    
end

local function init()
    system.registerSystemTool({event = rf2ethos.app.event, name = config.toolName, icon = icon, create = rf2ethos.app.create, wakeup = rf2ethos.app.wakeup, paint = rf2ethos.app.paint, close = rf2ethos.app.close})
--    system.registerTask({name = config.mspTaskName, key = config.mspTaskKey, wakeup = mspTask})
--    system.registerTask({name = config.clockSyncTaskName , key = config.clockSyncTaskKey, wakeup = clockSyncTask})
--    system.registerTask({name = config.elrsTelemTaskName, key = config.elrsTelemTaskKey, wakeup = elrsTelemetryTask})    
--    system.registerTask({name = config.adjFunctionTaskName, key = config.adjFunctionTaskKey, wakeup = adjFunctionTask})    
end

return {init = init}
