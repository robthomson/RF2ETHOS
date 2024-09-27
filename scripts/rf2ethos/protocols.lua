local arg = {...}
local config = arg[1]
local compile = arg[2]

protocols = {}

local supportedProtocols =
{
    smartPort =
    {
        mspTransport    = "msp/sp.lua",
        mspProtocol     = "smartPort",
        push            = sportTelemetryPush,
        maxTxBufferSize = 6,
        maxRxBufferSize = 6,
        maxRetries      = 10,
        saveTimeout     = 10.0,
        cms             = {},
        pageReqTimeout = 10,
    },
    crsf =
    {
        mspTransport    = "msp/crsf.lua",
        mspProtocol     = "crsf",
        maxTxBufferSize = 8,
        maxRxBufferSize = 58,
        maxRetries      = 5,
        saveTimeout     = 10.0,
        cms             = {},
        pageReqTimeout = 10
    }
}


function protocols.getProtocol()
    if system.getSource("Rx RSSI1") ~= nil then 
            return supportedProtocols.crsf 
    end
    return supportedProtocols.smartPort
end


function protocols.getTransports()
    local transport = {}
    for i,v in pairs(supportedProtocols) do
        transport[i] = v.mspTransport
    end 
    return transport
end


return protocols
