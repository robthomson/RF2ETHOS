local supportedProtocols = {
    smartPort = {mspTransport = "msp/sp.lua", push = rf2ethos.sportTelemetryPush, maxTxBufferSize = 6, maxRxBufferSize = 6, maxRetries = 5, saveTimeout = 10.0, pageReqTimeout = 10},
    crsf = {mspTransport = "msp/crsf.lua", maxTxBufferSize = 8, maxRxBufferSize = 58, maxRetries = 5, saveTimeout = 10.0, pageReqTimeout = 10}
}

local function getProtocol()
    if system.getSource("Rx RSSI1") ~= nil then return supportedProtocols.crsf end
    return supportedProtocols.smartPort
end

return getProtocol()
