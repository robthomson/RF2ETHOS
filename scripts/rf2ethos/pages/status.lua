local fields = {}
local labels = {}
local fcStatus = {}
local dataflashSummary = {}


fields[#fields + 1] = { t = "Arming Flags",  value=0}

fields[#fields + 1] = { t = "Dataflash Free Space",  value=0  }

fields[#fields + 1] = { t = "Real-time load",   value = 0, scale = 10 }
fields[#fields + 1] = { t = "CPU load",     	value = 0, scale = 10  }



local function postLoad(self)
	rf2ethos.triggers.isReady = true
end	

local function armingDisableFlagsToString(flags)
    local t = ""
    for i = 0, 25 do
        if (flags & (1 << i)) ~= 0 then
            if t ~= "" then t = t .. ", " end
            if i == 0 then t = t .. "No Gyro" end
            if i == 1 then t = t .. "Fail Safe" end
            if i == 2 then t = t .. "RX Fail Safe" end
            if i == 3 then t = t .. "Bad RX Recovery" end
            if i == 4 then t = t .. "Box Fail Safe" end
            if i == 5 then t = t .. "Governor" end
            --if i == 6 then t = t .. "Crash Detected" end
            if i == 7 then t = t .. "Throttle" end
            if i == 8 then t = t .. "Angle" end
            if i == 9 then t = t .. "Boot Grace Time" end
            if i == 10 then t = t .. "No Pre Arm" end
            if i == 11 then t = t .. "Load" end
            if i == 12 then t = t .. "Calibrating" end
            if i == 13 then t = t .. "CLI" end
            if i == 14 then t = t .. "CMS Menu" end
            if i == 15 then t = t .. "BST" end
            if i == 16 then t = t .. "MSP" end
            if i == 17 then t = t .. "Paralyze" end
            if i == 18 then t = t .. "GPS" end
            if i == 19 then t = t .. "Resc" end
            if i == 20 then t = t .. "RPM Filter" end
            if i == 21 then t = t .. "Reboot Required" end
            if i == 22 then t = t .. "DSHOT Bitbang" end
            if i == 23 then t = t .. "Acc Calibration" end
            if i == 24 then t = t .. "Motor Protocol" end
            if i == 25 then t = t .. "Arm Switch" end
        end
    end
    if t == "" then t = "-" end
    return t
end

local function getFreeDataflashSpace()
    if not dataflashSummary.supported then return "N/A" end
    local freeSpace = dataflashSummary.totalSize - dataflashSummary.usedSize
    return string.format("%.1f MB", freeSpace / (1024 * 1024))
end

local function wakeup()

end

return {
    read = 111, 
    write = 204, 
    title = "Status",
    reboot = false,
    eepromWrite = false,
    minBytes = 25,
	wakeup = wakeup,
    labels = labels,
    fields = fields,
    refreshswitch = false,
    simulatorResponse = {},
    postLoad = postLoad

}
