local labels = {}
local fields = {}

fields[#fields + 1] = {t = "Profile type", min = 0, max = 1, vals = {1}, table = {[0] = "PID", "Rate"}}
fields[#fields + 1] = {t = "Source profile", min = 0, max = 5, vals = {3}, tableIdxInc = -1, table = {"1", "2", "3", "4", "5", "6"}}
fields[#fields + 1] = {t = "Dest. profile", min = 0, max = 5, vals = {2}, tableIdxInc = -1, table = {"1", "2", "3", "4", "5", "6"}}

return {
    read = 101, -- msp_STATUS
    write = 183, -- msp_COPY_PROFILE
    reboot = false,
    eepromWrite = true,
    title = "Copy",
    minBytes = 30,
    labels = labels,
    refreshswitch = true,
    fields = fields,
    simulatorResponse = {252, 1, 127, 0, 35, 0, 0, 0, 0, 0, 0, 122, 1, 182, 0, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1},
    postRead = function(self)
        rf2ethos.utils.log("postRead")
        self.maxPidProfiles = self.values[25]
        self.currentPidProfile = self.values[24]
        self.values = {0, self.getDestinationPidProfile(self), self.currentPidProfile}
        self.minBytes = 3
    end,
    postLoad = function(self)
        rf2ethos.utils.log("postLoad")
    end,
    getDestinationPidProfile = function(self)
        local destPidProfile
        if (self.currentPidProfile < self.maxPidProfiles - 1) then
            destPidProfile = self.currentPidProfile + 1
        else
            destPidProfile = self.currentPidProfile - 1
        end
        return destPidProfile
    end
}
