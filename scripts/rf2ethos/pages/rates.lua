local labels = {}
local tables = {}

tables[0] = rf2ethos.config.toolDir .. "pages/ratetables/none.lua"
tables[1] = rf2ethos.config.toolDir .. "pages/ratetables/betaflight.lua"
tables[2] = rf2ethos.config.toolDir .. "pages/ratetables/raceflight.lua"
tables[3] = rf2ethos.config.toolDir .. "pages/ratetables/kiss.lua"
tables[4] = rf2ethos.config.toolDir .. "pages/ratetables/actual.lua"
tables[5] = rf2ethos.config.toolDir .. "pages/ratetables/quick.lua"

if rf2ethos.RateTable == nil then rf2ethos.RateTable = rf2ethos.config.defaultRateTable end

local mytable = assert(compile.loadScript(tables[rf2ethos.RateTable]))()

local fields = mytable.fields


fields[13] = {t = "Rates Type",hidden=true,ratetype = 1, min = 0,max = 5,vals = {1}}




return {
    read = 111, -- msp_RC_TUNING
    write = 204, -- msp_SET_RC_TUNING
    title = "Rates",
    reboot = false,
    eepromWrite = true,
    minBytes = 25,
    labels = labels,
    fields = fields,
    refreshswitch = true,
    rows = mytable.rows,
    cols = mytable.cols,
    simulatorResponse = {4, 18, 25, 32, 20, 0, 0, 18, 25, 32, 20, 0, 0, 32, 50, 45, 10, 0, 0, 56, 0, 56, 20, 0, 0},
    rTableName = mytable.rTableName,
    flagRateChange = function(self)
        -- --rf2ethos.utils.log("We need to reset the rates tables on save")
        rf2ethos.triggers.resetRates = true
    end,
    postRead = function(self)

    end,
    postLoad = function(self)
 
		-- if the activeRateTable is not what we are displaying
		-- then we need to trigger a reload of the page
		local v = rf2ethos.Page.values[1]
		if v ~= nil then rf2ethos.activeRateTable  = math.floor(v) end

		if rf2ethos.activeRateTable ~= nil then
			if rf2ethos.activeRateTable ~= rf2ethos.RateTable then
				rf2ethos.RateTable = rf2ethos.activeRateTable 
				rf2ethos.triggers.reload = true
				return
			end
		end

		rf2ethos.triggers.isReady = true
    end	

}
