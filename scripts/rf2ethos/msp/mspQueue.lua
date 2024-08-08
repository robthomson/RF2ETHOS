-- MspQueueController class
local MspQueueController = {}
MspQueueController.__index = MspQueueController

function MspQueueController.new()
    local self = setmetatable({}, MspQueueController)
    self.messageQueue = {}
    self.currentMessage = nil
    self.lastTimeCommandSent = 0
    self.retryCount = 0
    self.maxRetries = 3
    return self
end

function MspQueueController:isProcessed()
    return not self.currentMessage and #self.messageQueue == 0
end

function joinTableItems(table, delimiter)
    if table == nil or #table == 0 then return "" end
    delimiter = delimiter or ""
    local result = table[1]
    for i = 2, #table do result = result .. delimiter .. table[i] end
    return result
end

local function popFirstElement(tbl)
    return table.remove(tbl, 1)
end

function MspQueueController:processQueue()
    if self:isProcessed() then return end

    if not self.currentMessage then
        self.currentMessage = popFirstElement(self.messageQueue)
        self.retryCount = 0
    end

    local cmd, buf, err
    -- rf2ethos.utils.log("retryCount: "..self.retryCount)

    -- rf2ethos.protocol.retry = self.retryCount

    if not rf2ethos.runningInSimulator then
        if self.lastTimeCommandSent == 0 or self.lastTimeCommandSent + 0.5 < os.clock() then
            if self.currentMessage.payload then
                rf2ethos.protocol.mspWrite(self.currentMessage.command, self.currentMessage.payload)
            else
                rf2ethos.protocol.mspWrite(self.currentMessage.command, {})
            end
            self.lastTimeCommandSent = os.clock()
            self.retryCount = self.retryCount + 1
            -- rf2ethos.dialogs.progressCounter = 0
        end

        mspProcessTxQ()
        cmd, buf, err = mspPollReply()
    else
        if not self.currentMessage.simulatorResponse then
            -- rf2ethos.utils.log("No simulator response for command " .. tostring(self.currentMessage.command))
            self.currentMessage = nil
            return
        end
        cmd = self.currentMessage.command
        buf = self.currentMessage.simulatorResponse
        err = nil
    end

    if cmd then rf2ethos.utils.log("Received cmd: " .. tostring(cmd)) end

    if (cmd == self.currentMessage.command and not err) or (self.currentMessage.command == 68 and self.retryCount == 2) -- 68 = MSP_REBOOT
    or (self.currentMessage.command == 217 and err and self.retryCount == 2) -- ESC
    then
        rf2ethos.utils.log("Received: {" .. joinTableItems(buf, ", ") .. "}")
        if self.currentMessage.processReply then self.currentMessage:processReply(buf) end
        self.currentMessage = nil
    elseif self.retryCount > self.maxRetries then
        self.currentMessage = nil
    end
end

local function deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in next, original, nil do copy[deepCopy(key)] = deepCopy(value) end
        setmetatable(copy, deepCopy(getmetatable(original)))
    else -- number, string, boolean, etc
        copy = original
    end
    return copy
end

function MspQueueController:add(message)
    if message ~= nil then
        message = deepCopy(message)
        -- rf2ethos.utils.log("Queueing command " .. message.command .. " at position " .. #self.messageQueue + 1)
        self.messageQueue[#self.messageQueue + 1] = message
        return self
    else
        -- rf2ethos.utils.log("Unable to queue - nil message.  Check function is callable")
        -- this can go wrong if the function is declared below save function!!!
    end
end

return MspQueueController.new()

--[[ Usage example

local myMspMessage =
{
    command = 111,
    processReply = function(self, buf)
        --rf2ethos.utils.log("Do something with the response buffer")
    end,
    simulatorResponse = { 1, 2, 3, 4 }
}

local anotherMspMessage =
{
    command = 123,
    processReply = function(self, buf)
        --rf2ethos.utils.log("Received response for command "..tostring(self.command).." with length "..tostring(#buf))
    end,
    simulatorResponse = { 254, 128 }
}

local myMspQueue = MspQueueController.new()
myMspQueue
  :add(myMspMessage)
  :add(anotherMspMessage)

while not myMspQueue:isProcessed() do
    myMspQueue:processQueue()
end
--]]
