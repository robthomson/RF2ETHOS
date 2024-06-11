local environment = system.getVersion()

local supportedProtocols = {
    smartPort = {
        mspTransport = "/scripts/rf2ethos/msp/sp.lua",
        push = rf2ethos.sportTelemetryPush,
        maxTxBufferSize = 6,
        maxRxBufferSize = 6,
        saveMaxRetries = 4, -- originally 2
        saveTimeout = 5.0,
        pageReqTimeout = 0.8
    },
    crsf = {mspTransport = "/scripts/rf2ethos/msp/crsf.lua", 
			maxTxBufferSize = 8, 
			maxRxBufferSize = 58, 
			saveMaxRetries = 4, 
			saveTimeout = 1.5, pageReqTimeout = 0.8},
    simulation = {mspTransport = "/scripts/rf2ethos/msp/simulation.lua", maxTxBufferSize = 8, maxRxBufferSize = 58, saveMaxRetries = 2, saveTimeout = 1.5, pageReqTimeout = 0.8}
}

local function getProtocol()
    if environment.simulation then
        print("Using SIM")
        return supportedProtocols.simulation
    end
    if system.getSource("Rx RSSI1") ~= nil then
        print("Using crsf")
        return supportedProtocols.crsf
    end
    print("Using sport")
    return supportedProtocols.smartPort
end

return getProtocol()
