local fields = {}
local labels = {}

local version = rf2ethos.config.Version
local ethosVersion = rf2ethos.config.environment.major .. "." .. rf2ethos.config.environment.minor .. "." .. rf2ethos.config.environment.revision
local apiVersion = rf2ethos.config.apiVersion
local project = rf2ethos.config.project
local developerLead = rf2ethos.config.developerLead
local contributors0 = rf2ethos.config.contributors0
local contributors1 = rf2ethos.config.contributors1
local license = rf2ethos.config.license

local supportedMspVersion = ""
for i, v in ipairs(rf2ethos.config.supportedMspApiVersion) do
    if i == 1 then
        supportedMspVersion = v
    else
        supportedMspVersion = supportedMspVersion .. "," .. v
    end
end

fields[1] = {t = "RF2ETHOS Version", value = version, type = 3, disable = true}
fields[2] = {t = "Ethos Version", value = ethosVersion, type = 3, disable = true}
fields[3] = {t = "MSP Version", value = apiVersion, type = 3, disable = true}
fields[4] = {t = "Supported MSP Versions", value = supportedMspVersion, type = 3, disable = true}
fields[5] = {t = "Licence", value = license, type = 3, disable = true}
fields[6] = {t = "Project", value = project, type = 3, disable = true}
fields[7] = {t = "Rotorflight Developer", value = "Dr Rudder", type = 3, disable = true}
fields[8] = {t = "RF2ETHOS Developer", value = developerLead, type = 3, disable = true}
fields[9] = {t = "Contributors", value = contributors0, type = 3, disable = true}
fields[10] = {t = "-", value = contributors1, type = 3, disable = true}
fields[11] = {t = "Website", value = "www.rotorflight.org", type = 3, disable = true}

function readMSP()
    rf2ethos.triggers.isReady = true
    rf2ethos.triggers.closeProgressLoader = true
end

return {
    read = readMSP,
    write = nil,
    title = "Status",
    reboot = false,
    eepromWrite = false,
    minBytes = 0,
    wakeup = wakeup,
    labels = labels,
    fields = fields,
    refreshswitch = false,
    simulatorResponse = {},
    navButtons = {menu = true, save = false, reload = false, tool = false, help = false}
}
