--[[
local msp_API_VERSION = 1
local config.apiVersionReceived = false
local lastRunTS = 0
local INTERVAL = 50
local environment = system.getVersion()

local function processMspReply(cmd, rx_buf, err)
    if rf2ethos.config.environment.simulation == true then
        config.apiVersionReceived = true
        return
    else
        if cmd == msp_API_VERSION and #rx_buf >= 3 and not err then
            config.apiVersion = rx_buf[2] + rx_buf[3] / 100
            config.apiVersionReceived = true
        end
    end
end

local function getApiVersion()

    if rf2ethos.config.environment.simulation == true then
        config.apiVersionReceived = true
        lastRunTS = rf2ethos.utils.getTime()
        return "12.06"
    else
        if not config.apiVersionReceived and (lastRunTS == 0 or lastRunTS + INTERVAL < rf2ethos.utils.getTime()) then
            protocol.mspRead(msp_API_VERSION)
            lastRunTS = rf2ethos.utils.getTime()
        end

        mspProcessTxQ()
        processMspReply(mspPollReply())

        return config.apiVersionReceived
    end
end

return {f = getApiVersion, t = "Waiting for API version"}
]] --
