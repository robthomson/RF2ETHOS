local function calibrate(callback, callbackParam)
    local message = {
        command = 205, -- MSP_ACC_CALIBRATION
        processReply = function(self, buf)
            -- rf2ethos.utils.log("Accelerometer calibrated.")
            if callback then callback(callbackParam) end
        end,
        simulatorResponse = {}
    }
    rf2ethos.mspQueue:add(message)
end

return {calibrate = calibrate}
