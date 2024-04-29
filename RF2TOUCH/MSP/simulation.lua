local LOCAL_SENSOR_ID = 0x0D
local SMARTPORT_REMOTE_SENSOR_ID = 0x1B
local FPORT_REMOTE_SENSOR_ID = 0x00
local REQUEST_FRAME_ID = 0x30
local REPLY_FRAME_ID = 0x32

local lastSensorId, lastFrameId, lastDataId, lastValue

protocol.mspSend = function(payload)
    local dataId = payload[1] + (payload[2] << 8)
    local value = 0
    for i = 3, #payload do value = value + (payload[i] << ((i - 3) * 8)) end
    -- return protocol.push(LOCAL_SENSOR_ID, REQUEST_FRAME_ID, dataId, value)
    return 1
end

protocol.mspRead = function(cmd) return mspSendRequest(cmd, {}) end

protocol.mspWrite = function(cmd, payload) return mspSendRequest(cmd, payload) end

-- Discards duplicate data from lua input buffer
local function smartPortTelemetryPop() return end

protocol.mspPoll = function() return nil end
