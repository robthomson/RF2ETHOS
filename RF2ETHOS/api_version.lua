local MSP_API_VERSION = 1
local apiVersionReceived = false
local lastRunTS = 0
local INTERVAL = 50
local environment = system.getVersion()

local function processMspReply(cmd, rx_buf, err)
    if environment.simulation == true then
        apiVersionReceived = true
        return
    else
        if cmd == MSP_API_VERSION and #rx_buf >= 3 and not err then
            apiVersion = rx_buf[2] + rx_buf[3] / 100
            apiVersionReceived = true
        end
    end
end

local function getApiVersion()

    if environment.simulation == true then
        apiVersionReceived = true
        lastRunTS = rf2ethos.getTime()
        return "12.06"
    else
        if not apiVersionReceived and (lastRunTS == 0 or lastRunTS + INTERVAL < rf2ethos.getTime()) then
            protocol.mspRead(MSP_API_VERSION)
            lastRunTS = rf2ethos.getTime()
        end

        mspProcessTxQ()
        processMspReply(mspPollReply())

        return apiVersionReceived
    end
end

return {f = getApiVersion, t = "Waiting for API version"}
