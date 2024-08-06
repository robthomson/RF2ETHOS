
local SUPPORTED_API_VERSIONS = rf2ethos.config.supportedMspApiVersion

local mspApiVersion = assert(compile.loadScript("msp/mspApiVersion.lua"))()
local returnTable = { f = nil, t = "" }
local apiVersion
local lastRunTS

local function stringInArray(array, s)
    for i, value in ipairs(array) do
        if value == s then
            return true
        end
    end
    return false
end


local function init()
    if rf2ethos.getRSSI() == 0 and not rf2ethos.runningInSimulator then
        returnTable.t = "Connecting [ checking for telemetry ]"
        return false
    end

    if not apiVersion and (not lastRunTS or lastRunTS + 2 < os.clock()) then
        returnTable.t = "Connecting [ checking msp versions ]"
        mspApiVersion.getApiVersion(function(_, version) apiVersion = version end)
        lastRunTS = os.clock()
    end

    rf2ethos.mspQueue:processQueue()

    if rf2ethos.mspQueue:isProcessed() and apiVersion then
        --if tostring(apiVersion) ~= SUPPORTED_API_VERSION then -- work-around for comparing floats
        --    returnTable.t = "This version of the Lua scripts ("..SUPPORTED_API_VERSION..")\ncan't be used with the selected model ("..tostring(apiVersion)..")."
		local apiVersionAsString = tostring(apiVersion) -- work-around for comparing floats
		if not stringInArray(SUPPORTED_API_VERSIONS, apiVersionAsString) then
            returnTable.t = "This version of the Lua scripts \ncan't be used with the selected model ("..apiVersionAsString..")."       
		else
            -- received correct API version, proceed
			rf2ethos.config.apiVersion = apiVersion
            return true
        end
    end

    return false
end

returnTable.f = init

return returnTable
