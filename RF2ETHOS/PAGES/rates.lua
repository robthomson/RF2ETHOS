local template = assert(rf2ethos.loadScriptRF2ETHOS(radio.template))()

local labels = {}
local fields = {}

if RateTable == nil then
    RateTable = defaultRateTable
end

-- NONE
if RateTable == 0 then

    rTableName = "NONE"
    rows = {"Roll", "Pitch", "Yaw", "Col"}
    cols = {"RC Rate", "Rate", "Expo"}
    -- rc rate
    fields[#fields + 1] = {row = 1, col = 1, subpage = 1, min = 0, max = 0, vals = {2}, default = 0}
    fields[#fields + 1] = {row = 2, col = 1, subpage = 1, min = 0, max = 0, vals = {8}, default = 0}
    fields[#fields + 1] = {row = 3, col = 1, subpage = 1, min = 0, max = 0, vals = {14}, default = 0}
    fields[#fields + 1] = {row = 4, col = 1, subpage = 1, min = 0, max = 0, vals = {20}, default = 0}
    -- fc rate
    fields[#fields + 1] = {row = 1, col = 2, subpage = 1, min = 0, max = 0, vals = {4}, default = 0}
    fields[#fields + 1] = {row = 2, col = 2, subpage = 1, min = 0, max = 0, vals = {10}, default = 0}
    fields[#fields + 1] = {row = 3, col = 2, subpage = 1, min = 0, max = 0, vals = {16}, default = 0}
    fields[#fields + 1] = {row = 4, col = 2, subpage = 1, min = 0, max = 0, vals = {22}, default = 0}
    --  expo
    fields[#fields + 1] = {row = 1, col = 3, subpage = 1, min = 0, max = 0, vals = {3}, default = 0}
    fields[#fields + 1] = {row = 2, col = 3, subpage = 1, min = 0, max = 0, vals = {9}, default = 0}
    fields[#fields + 1] = {row = 3, col = 3, subpage = 1, min = 0, max = 0, vals = {15}, default = 0}
    fields[#fields + 1] = {row = 4, col = 3, subpage = 1, min = 0, max = 0, vals = {21}, default = 0}
    -- BETAFL
elseif RateTable == 1 then

    rTableName = "BETAFLIGHT"
    rows = {"Roll", "Pitch", "Yaw", "Col"}
    cols = {"RC Rate", "SuperRate", "Expo"}

    -- rc rate
    fields[#fields + 1] = {row = 1, col = 1, subpage = 1, min = 0, max = 255, vals = {2}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 2, col = 1, subpage = 1, min = 0, max = 255, vals = {8}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 3, col = 1, subpage = 1, min = 0, max = 255, vals = {14}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 4, col = 1, subpage = 1, min = 0, max = 255, vals = {20}, default = 203, decimals = 2, scale = 100}
    -- fc rate
    fields[#fields + 1] = {row = 1, col = 2, subpage = 1, min = 0, max = 100, vals = {4}, default = 0, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 2, col = 2, subpage = 1, min = 0, max = 100, vals = {10}, default = 0, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 3, col = 2, subpage = 1, min = 0, max = 100, vals = {16}, default = 0, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 4, col = 2, subpage = 1, min = 0, max = 100, vals = {22}, default = 1, decimals = 2, scale = 100}
    --  expo
    fields[#fields + 1] = {row = 1, col = 3, subpage = 1, min = 0, max = 100, vals = {3}, decimals = 2, scale = 100, default = 0, decimals = 2}
    fields[#fields + 1] = {row = 2, col = 3, subpage = 1, min = 0, max = 100, vals = {9}, decimals = 2, scale = 100, default = 0, decimals = 2}
    fields[#fields + 1] = {row = 3, col = 3, subpage = 1, min = 0, max = 100, vals = {15}, decimals = 2, scale = 100, default = 0, decimals = 2}
    fields[#fields + 1] = {row = 4, col = 3, subpage = 1, min = 0, max = 100, vals = {21}, decimals = 2, scale = 100, default = 0, decimals = 2}
    -- RACEFL
elseif RateTable == 2 then

    rTableName = "RACEFLIGHT"
    rows = {"Roll", "Pitch", "Yaw", "Col"}
    cols = {"Rate", "Acro+", "Expo"}

    -- rc rate
    fields[#fields + 1] = {row = 1, col = 1, subpage = 1, min = 0, max = 100, vals = {2}, default = 36, mult = 10}
    fields[#fields + 1] = {row = 2, col = 1, subpage = 1, min = 0, max = 100, vals = {8}, default = 36, mult = 10}
    fields[#fields + 1] = {row = 3, col = 1, subpage = 1, min = 0, max = 100, vals = {14}, default = 36, mult = 10}
    fields[#fields + 1] = {row = 4, col = 1, subpage = 1, min = 0, max = 100, vals = {20}, default = 50, decimals = 1, scale = 4}
    -- fc rate
    fields[#fields + 1] = {row = 1, col = 2, subpage = 1, min = 0, max = 255, vals = {4}, default = 0}
    fields[#fields + 1] = {row = 2, col = 2, subpage = 1, min = 0, max = 255, vals = {10}, default = 0}
    fields[#fields + 1] = {row = 3, col = 2, subpage = 1, min = 0, max = 255, vals = {16}, default = 0}
    fields[#fields + 1] = {row = 4, col = 2, subpage = 1, min = 0, max = 255, vals = {22}, default = 0}
    --  expo
    fields[#fields + 1] = {row = 1, col = 3, subpage = 1, min = 0, max = 100, vals = {3}, default = 0}
    fields[#fields + 1] = {row = 2, col = 3, subpage = 1, min = 0, max = 100, vals = {9}, default = 0}
    fields[#fields + 1] = {row = 3, col = 3, subpage = 1, min = 0, max = 100, vals = {15}, default = 0}
    fields[#fields + 1] = {row = 4, col = 3, subpage = 1, min = 0, max = 100, vals = {21}, default = 0}

    -- KISS
elseif RateTable == 3 then

    rTableName = "KISS"
    rows = {"Roll", "Pitch", "Yaw", "Col"}
    cols = {"RC Rate", "Rate", "RC Curve"}

    -- rc rate
    fields[#fields + 1] = {row = 1, col = 1, subpage = 1, min = 0, max = 255, vals = {2}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 2, col = 1, subpage = 1, min = 0, max = 255, vals = {8}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 3, col = 1, subpage = 1, min = 0, max = 255, vals = {14}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 4, col = 1, subpage = 1, min = 0, max = 255, vals = {20}, default = 205, decimals = 2, scale = 100}
    -- fc rate
    fields[#fields + 1] = {row = 1, col = 2, subpage = 1, min = 0, max = 99, vals = {4}, default = 0, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 2, col = 2, subpage = 1, min = 0, max = 99, vals = {10}, default = 0, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 3, col = 2, subpage = 1, min = 0, max = 99, vals = {16}, default = 0, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 4, col = 2, subpage = 1, min = 0, max = 99, vals = {22}, default = 1, decimals = 2, scale = 100}
    --  expo
    fields[#fields + 1] = {row = 1, col = 3, subpage = 1, min = 0, max = 100, vals = {3}, decimals = 2, scale = 100, default = 0, decimals = 2}
    fields[#fields + 1] = {row = 2, col = 3, subpage = 1, min = 0, max = 100, vals = {9}, decimals = 2, scale = 100, default = 0, decimals = 2}
    fields[#fields + 1] = {row = 3, col = 3, subpage = 1, min = 0, max = 100, vals = {15}, decimals = 2, scale = 100, default = 0, decimals = 2}
    fields[#fields + 1] = {row = 4, col = 3, subpage = 1, min = 0, max = 100, vals = {21}, decimals = 2, scale = 100, default = 0, decimals = 2}
    -- ACTUAL
elseif RateTable == 4 then

    rTableName = "ACTUAL"
    rows = {"Roll", "Pitch", "Yaw", "Col"}

    if radio.text == 2 then
        cols = {"Cntr. Sens.", "Max Rate", "Expo"}
    else
        cols = {"Center Sensitivity", "Max Rate", "Expo"}
    end

    -- rc rate
    fields[#fields + 1] = {row = 1, col = 1, subpage = 1, min = 0, max = 100, vals = {2}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 2, col = 1, subpage = 1, min = 0, max = 100, vals = {8}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 3, col = 1, subpage = 1, min = 0, max = 100, vals = {14}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 4, col = 1, subpage = 1, min = 0, max = 100, vals = {20}, default = 48, decimals = 1, step = 5, scale = 4}
    -- fc rate
    fields[#fields + 1] = {row = 1, col = 2, subpage = 1, min = 0, max = 100, vals = {4}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 2, col = 2, subpage = 1, min = 0, max = 100, vals = {10}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 3, col = 2, subpage = 1, min = 0, max = 100, vals = {16}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 4, col = 2, subpage = 1, min = 0, max = 100, vals = {22}, default = 48, step = 5, decimals = 1, scale = 4}
    --  expo
    fields[#fields + 1] = {row = 1, col = 3, subpage = 1, min = 0, max = 100, vals = {3}, decimals = 2, scale = 100, default = 0}
    fields[#fields + 1] = {row = 2, col = 3, subpage = 1, min = 0, max = 100, vals = {9}, decimals = 2, scale = 100, default = 0}
    fields[#fields + 1] = {row = 3, col = 3, subpage = 1, min = 0, max = 100, vals = {15}, decimals = 2, scale = 100, default = 0}
    fields[#fields + 1] = {row = 4, col = 3, subpage = 1, min = 0, max = 100, vals = {21}, decimals = 2, scale = 100, default = 0}

    -- QUICK
elseif RateTable == 5 then

    rTableName = "QUICK"
    rows = {"Roll", "Pitch", "Yaw", "Col"}
    cols = {"RC Rate", "Max Rate", "Expo"}

    -- rc rate
    fields[#fields + 1] = {row = 1, col = 1, subpage = 1, min = 0, max = 255, vals = {2}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 2, col = 1, subpage = 1, min = 0, max = 255, vals = {8}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 3, col = 1, subpage = 1, min = 0, max = 255, vals = {14}, default = 180, decimals = 2, scale = 100}
    fields[#fields + 1] = {row = 4, col = 1, subpage = 1, min = 0, max = 255, vals = {20}, default = 205, decimals = 2, scale = 100}
    -- fc rate
    fields[#fields + 1] = {row = 1, col = 2, subpage = 1, min = 0, max = 100, vals = {4}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 2, col = 2, subpage = 1, min = 0, max = 100, vals = {10}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 3, col = 2, subpage = 1, min = 0, max = 100, vals = {16}, default = 36, mult = 10, step = 10}
    fields[#fields + 1] = {row = 4, col = 2, subpage = 1, min = 0, max = 208.2, vals = {22}, default = 104.16, mult = 4.807, step = 10}
    --  expo
    fields[#fields + 1] = {row = 1, col = 3, subpage = 1, min = 0, max = 100, vals = {3}, decimals = 2, scale = 100, default = 0}
    fields[#fields + 1] = {row = 2, col = 3, subpage = 1, min = 0, max = 100, vals = {9}, decimals = 2, scale = 100, default = 0}
    fields[#fields + 1] = {row = 3, col = 3, subpage = 1, min = 0, max = 100, vals = {15}, decimals = 2, scale = 100, default = 0}
    fields[#fields + 1] = {row = 4, col = 3, subpage = 1, min = 0, max = 100, vals = {21}, decimals = 2, scale = 100, default = 0}
end

fields[#fields + 1] = {
    t = "Rates Type",
    ratetype = 1,
    subpage = 2,
    min = 0,
    max = 5,
    vals = {1},
    table = {[0] = "NONE", "BETAFLIGHT", "RACEFLIGHT", "KISS", "ACTUAL", "QUICK"},
    postEdit = function(self)
        self.flagRateChange(self, true)
    end
}

labels[#labels + 1] = {t = "Roll dynamics", subpage = 2, label = "rolldynamics", inline_size = 13.6}
fields[#fields + 1] = {t = "Time", inline = 2, subpage = 2, label = "rolldynamics", min = 0, max = 250, vals = {5}, unit = "ms"}
fields[#fields + 1] = {t = "Accel", inline = 1, subpage = 2, label = "rolldynamics", min = 0, max = 50000, vals = {6, 7}, unit = "°/s"}

labels[#labels + 1] = {t = "Pitch dynamics", label = "pitchdynamics", inline_size = 13.6}
fields[#fields + 1] = {t = "Time", inline = 2, subpage = 2, label = "pitchdynamics", min = 0, max = 250, vals = {11}, unit = "ms"}
fields[#fields + 1] = {t = "Accel", inline = 1, subpage = 2, label = "pitchdynamics", min = 0, max = 50000, vals = {12, 13}, unit = "°/s"}

labels[#labels + 1] = {t = "Yaw dynamics", label = "yawdynamics", inline_size = 13.6}
fields[#fields + 1] = {t = "Time", inline = 2, subpage = 2, label = "yawdynamics", min = 0, max = 250, vals = {17}, unit = "ms"}
fields[#fields + 1] = {t = "Accel", inline = 1, subpage = 2, label = "yawdynamics", min = 0, max = 50000, vals = {18, 19}, unit = "°/s"}

labels[#labels + 1] = {t = "Collective dynamics", label = "coldynamics", inline_size = 13.6}
fields[#fields + 1] = {t = "Time", inline = 2, subpage = 2, label = "coldynamics", min = 0, max = 250, vals = {23}, unit = "ms"}
fields[#fields + 1] = {t = "Accel", inline = 1, subpage = 2, label = "coldynamics", min = 0, max = 50000, vals = {24, 25}, unit = "°/^s", mult = 10}

return {
    read = 111, -- MSP_RC_TUNING
    write = 204, -- MSP_SET_RC_TUNING
    title = "Rates",
    reboot = false,
    eepromWrite = true,
    minBytes = 25,
    labels = labels,
    fields = fields,
    rows = rows,
    cols = cols,
    rTableName = rTableName,
    flagRateChange = function(self)
        -- print("We need to reset the rates tables on save")
        ResetRates = true
    end
}
