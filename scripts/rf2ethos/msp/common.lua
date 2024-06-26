local environment = system.getVersion()
-- Protocol version
local msp_VERSION = 1 << 5
local msp_STARTFLAG = 1 << 4

-- Sequence number for next msp packet
local mspSeq = 0
local mspRemoteSeq = 0
local mspRxBuf = {}
local mspRxError = false
local mspRxSize = 0
local mspRxCRC = 0
local mspRxReq = 0
local mspStarted = false
local mspLastReq = 0
local mspTxBuf = {}
local mspTxIdx = 1
local mspTxCRC = 0

function mspProcessTxQ()
    if (#(mspTxBuf) == 0) then
        return false
    end
    -- if not sensor:idle() then  -- was protocol.push() -- maybe sensor:idle()  here??
    -- print("Sensor not idle... waiting to send cmd: "..tostring(mspLastReq))
    -- return true
    -- end
    if environment.simulation ~= true then
        -- print("Sending mspTxBuf size "..tostring(#mspTxBuf).." at Idx "..tostring(mspTxIdx).." for cmd: "..tostring(mspLastReq))
    end
    local payload = {}
    payload[1] = mspSeq + msp_VERSION
    mspSeq = (mspSeq + 1) & 0x0F
    if mspTxIdx == 1 then
        -- start flag
        payload[1] = payload[1] + msp_STARTFLAG
    end
    local i = 2
    while (i <= protocol.maxTxBufferSize) and mspTxIdx <= #mspTxBuf do
        payload[i] = mspTxBuf[mspTxIdx]
        mspTxIdx = mspTxIdx + 1
        mspTxCRC = mspTxCRC ~ payload[i]
        i = i + 1
    end
    if i <= protocol.maxTxBufferSize then
        payload[i] = mspTxCRC
        i = i + 1
        -- zero fill
        while i <= protocol.maxTxBufferSize do
            payload[i] = 0
            i = i + 1
        end
        protocol.mspSend(payload)
        mspTxBuf = {}
        mspTxIdx = 1
        mspTxCRC = 0
        return false
    end
    protocol.mspSend(payload)
    return true
end

function mspSendRequest(cmd, payload)
    if environment.simulation ~= true then
        -- print("Sending cmd "..cmd)
    end
    -- busy
    if #(mspTxBuf) ~= 0 or not cmd then
        if environment.simulation ~= true then
            print("Existing mspTxBuf is still being sent, failed send of cmd: " .. tostring(cmd))
        end
        return nil
    end
    mspTxBuf[1] = #(payload)
    mspTxBuf[2] = cmd & 0xFF -- msp command
    for i = 1, #(payload) do
        mspTxBuf[i + 2] = payload[i] & 0xFF
    end
    mspLastReq = cmd
end

local function mspReceivedReply(payload)
    -- print("Starting mspReceivedReply")
    local idx = 1
    local status = payload[idx]
    local version = (status & 0x60) >> 5
    local start = (status & 0x10) ~= 0
    local seq = status & 0x0F
    idx = idx + 1
    -- print(" msp sequence #:  "..string.format("%u",seq))
    if start then
        -- start flag set
        mspRxBuf = {}
        mspRxError = (status & 0x80) ~= 0
        mspRxSize = payload[idx]
        mspRxReq = mspLastReq
        idx = idx + 1
        if version == 1 then
            -- print("version == 1")
            mspRxReq = payload[idx]
            idx = idx + 1
        end
        mspRxCRC = mspRxSize ~ mspRxReq
        if mspRxReq == mspLastReq then
            mspStarted = true
        end
    elseif not mspStarted then
        -- print("  mspReceivedReply: missing Start flag")
        return nil
    elseif (mspRemoteSeq + 1) & 0x0F ~= seq then
        -- print("  mspReceivedReply: msp packet sequence # incorrect")
        mspStarted = false
        return nil
    end
    while (idx <= protocol.maxRxBufferSize) and (#mspRxBuf < mspRxSize) do
        mspRxBuf[#mspRxBuf + 1] = payload[idx]
        mspRxCRC = mspRxCRC ~ payload[idx]
        idx = idx + 1
    end
    if idx > protocol.maxRxBufferSize then
        -- print("  mspReceivedReply:  payload continues into next frame.")
        -- Store the last sequence number so we can start there on the next continuation payload
        mspRemoteSeq = seq
        return false
    end
    mspStarted = false
    -- check CRC
    if mspRxCRC ~= payload[idx] and version == 0 then
        -- print("  mspReceivedReply:  payload checksum incorrect, message failed!")
        -- print("    Calculated mspRxCRC:  0x"..string.format("%X", mspRxCRC))
        -- print("    CRC from payload:     0x"..string.format("%X", payload[idx]))
        return nil
    end
    -- print("  Got reply for cmd "..mspRxReq)
    return true
end

function mspPollReply()

    if environment.simulation == true then
        return 1, "ababababababababababababababababsa", 1
    end

    local startTime = utils.getTime()
    while (utils.getTime() - startTime < 5) do
        local mspData = protocol.mspPoll()
        if mspData ~= nil and mspReceivedReply(mspData) then
            mspLastReq = 0
            return mspRxReq, mspRxBuf, mspRxError
        end
    end
end
