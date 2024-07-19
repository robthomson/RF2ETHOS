local 
    labels =
    {}
local 
    fields =
    {}
local 
    escinfo =
    {}

labels[#labels +
    1] =
    {
        t = "ESC Parameters"
    }
labels[#labels +
    1] =
    {
        t = "fw-ver"
    }

labels[#labels +
    1] =
    {
        t = "hw-ver"
    }

labels[#labels +
    1] =
    {
        t = "type"
    }

labels[#labels +
    1] =
    {
        t = "name"
    }

fields[#fields +
    1] =
    {
        t = "dummy field",
        min = 0,
        max = 0,
        vals = {
            100000
        }
    }

escinfo[#escinfo +
    1] =
    {
        t = ""
    }
escinfo[#escinfo +
    1] =
    {
        t = ""
    }
escinfo[#escinfo +
    1] =
    {
        t = ""
    }

return
    {
        read = 217, -- msp_ESC_PARAMETERS
        eepromWrite = true,
        reboot = false,
        title = "Debug",
        minBytes = mspBytes,
        labels = labels,
        fields = fields,
        escinfo = escinfo,
        simulatorResponse = {
            83,
            128,
            84,
            114,
            105,
            98,
            117,
            110,
            117,
            115,
            32,
            69,
            83,
            67,
            45,
            54,
            83,
            45,
            56,
            48,
            65,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            4,
            0,
            3,
            0,
            3,
            0,
            1,
            0,
            3,
            0,
            136,
            19,
            22,
            3,
            16,
            39,
            64,
            31,
            136,
            19,
            0,
            0,
            1,
            0,
            7,
            2,
            0,
            6,
            63,
            0,
            160,
            15,
            64,
            31,
            208,
            7,
            100,
            0,
            0,
            0,
            200,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            200,
            250,
            0,
            0
        },
        postRead = function(
            self)

            if self.values[1] ~=
                mspSignature then
                -- self.values = nil
                self.escinfo[1]
                    .t =
                    ""
                self.escinfo[2]
                    .t =
                    ""
                self.escinfo[2]
                    .t =
                    ""
                rf2ethos.triggers
                    .mspDataLoaded =
                    true
                return
            end
        end,
        postLoad = function(
            self)
            if self.values[1] ~=
                mspSignature then
                -- self.values = nil
                self.escinfo[1]
                    .t =
                    ""
                self.escinfo[2]
                    .t =
                    ""
                self.escinfo[2]
                    .t =
                    ""
                return
            else
                local 
                    model =
                    getEscType(
                        self)
                local 
                    version =
                    "v" ..
                        getUInt(
                            self,
                            {
                                59,
                                60
                            })
                local 
                    firmware =
                    string.format(
                        "%08X",
                        getUInt(
                            self,
                            {
                                55,
                                56,
                                57,
                                58
                            }))
                self.escinfo[1]
                    .t =
                    model
                self.escinfo[2]
                    .t =
                    version
                self.escinfo[3]
                    .t =
                    firmware
            end
        end
    }
