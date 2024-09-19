local supportedProtocols =
{
    smartPort =
    {
        mspTransport    = "msp/sp.lua",
        push            = rf2ethos.sportTelemetryPush,
        maxTxBufferSize = 6,
        maxRxBufferSize = 6,
        maxRetries      = 10,
        saveTimeout     = 10.0,
        cms             = {},
        pageReqTimeout = 10
    },
    crsf =
    {
        mspTransport    = "msp/crsf.lua",
        --push            = rf2ethos.crossfireTelemetryPush,
        maxTxBufferSize = 8,
        maxRxBufferSize = 58,
        maxRetries      = 5,
        saveTimeout     = 10.0,
        cms             = {},
        pageReqTimeout = 10
    },
    ghst =
    {
        mspTransport    = "msp/ghst.lua",
        push            = rf2ethos.ghostTelemetryPush,
        maxTxBufferSize = 10, 
        maxRxBufferSize = 6, 
        maxRetries      = 3,
        saveTimeout     = 4.0,
        cms             = {},
        pageReqTimeout = 10
    }
}

local function getProtocol()
    if system.getSource("Rx RSSI1") ~= nil then return supportedProtocols.crsf end
    return supportedProtocols.smartPort
end

return getProtocol()
