local toolName = "Fly Rotor"
moduleName = "FLRTR"

local mspHeaderBytes = 2

-- required by framework
local function getEscModel(buffer)
    return "FlyRotor"
end

-- required by framework
local function getEscVersion(buffer)

    -- buffer is the whole msp payload
    -- looks like prob have to extract
    -- DATA[3-10]: Serial number. Example: 7771BED8DE25A9EA 

    return "version"
end

-- required by framework
local function getEscFirmware(buffer)

    -- buffer is the whole msp payload
    -- prob have to extract DATA[11-13]: IAP version, major + minor + revision. Example: 01 00 00, means 1.0.0 
   

    return "firmware"
end

return {
    toolName = toolName,
    powerCycle = false,
    mspSignature = 0x73,
    mspHeaderBytes = mspHeaderBytes,
    mspBytes = 46,
    simulatorResponse = {115, 0, 0, 0, 150, 231, 79, 190, 216, 78, 29, 169, 244, 1, 0, 0, 1, 0, 2, 0, 4, 76, 7, 148, 0, 6, 30, 125, 0, 15, 0, 3, 15, 1, 20, 0, 10, 0, 0, 0, 0, 0, 0, 2, 73, 240},
    getEscModel = getEscModel,
    getEscVersion = getEscVersion,
    getEscFirmware = getEscFirmware,
}
