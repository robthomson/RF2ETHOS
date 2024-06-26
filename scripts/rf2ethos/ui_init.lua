local apiVersionReceived = false
local getApiVersion, f
local returnTable = {f = nil, t = ""}
local SUPPORTED_API_VERSION = "12.06" -- see main/msp/msp_protocol.h
local environment = system.getVersion()

local function init()
    -- if true then return true end
    if rf2ethos.getRSSI() == 0 then
        returnTable.t = "Waiting for connection"
    elseif not apiVersionReceived then
        getApiVersion = getApiVersion or assert(utils.loadScript("/scripts/rf2ethos/api_version.lua"))()
        returnTable.t = getApiVersion.t
        apiVersionReceived = getApiVersion.f()
        if apiVersionReceived then
            getApiVersion = nil
            collectgarbage()
        end
    elseif environment.simulation == true then
        return true
    elseif tostring(apiVersion) ~= SUPPORTED_API_VERSION then -- work-around for comparing floats
        returnTable.t = "This version of the Lua scripts (" .. SUPPORTED_API_VERSION .. ")\ncan't be used with the selected model (" .. tostring(apiVersion) .. ")."
    else
        -- received correct API version, proceed
        return true
    end
    return false
end

returnTable.f = init

return returnTable
