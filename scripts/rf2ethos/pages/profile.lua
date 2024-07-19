local labels = {}
local fields = {}

-- pid controller settings =
-- labels[#labels + 1] = { subpage=1,t ="Ground Error Decay", label=1      }
fields[#fields + 1] = {
    subpage = 1,
    t = "Ground Error Decay",
    help = "profilesErrorDecayGround",
    min = 0,
    max = 250,
    unit = "s",
    default = 250,
    vals = {2},
    decimals = 1,
    scale = 10
}

labels[#labels + 1] = {
    subpage = 1,
    t = "Inflight Error Decay",
    label = 2,
    inline_size = 13.6
}
fields[#fields + 1] = {
    subpage = 1,
    t = "Time",
    help = "profilesErrorDecayGroundCyclicTime",
    inline = 2,
    label = 2,
    min = 0,
    max = 250,
    unit = "s",
    default = 180,
    vals = {3},
    decimals = 1,
    scale = 10
}
fields[#fields + 1] = {
    subpage = 1,
    t = "Limit",
    help = "profilesErrorDecayGroundCyclicLimit",
    inline = 1,
    label = 2,
    min = 0,
    max = 250,
    unit = "°",
    default = 20,
    vals = {5}
}

-- labels[#labels + 1] = {subpage = 1, t = "   Yaw Error Decay", label = 3, inline_size=13.6}
fields[#fields + 1] = {
    subpage = 'disableme as bad',
    t = "Time",
    help = "profilesErrorDecayGroundYawTime",
    inline = 2,
    label = 3,
    min = 0,
    max = 250,
    unit = "s",
    vals = {4},
    decimals = 1,
    scale = 10
}
fields[#fields + 1] = {
    subpage = 'disableme as bad',
    t = "Limit",
    help = "profilesErrorDecayGroundYawLimit",
    inline = 1,
    label = 3,
    min = 0,
    max = 250,
    unit = "°",
    vals = {6}
}

labels[#labels + 1] = {
    subpage = 1,
    t = "Error limit",
    label = 4,
    inline_size = 8.15
}
fields[#fields + 1] = {
    subpage = 1,
    t = "R",
    help = "profilesErrorLimit",
    inline = 3,
    label = 4,
    min = 0,
    max = 180,
    default = 30,
    unit = "°",
    vals = {8}
}
fields[#fields + 1] = {
    subpage = 1,
    t = "P",
    help = "profilesErrorLimit",
    inline = 2,
    label = 4,
    min = 0,
    max = 180,
    default = 30,
    unit = "°",
    vals = {9}
}
fields[#fields + 1] = {
    subpage = 1,
    t = "Y",
    help = "profilesErrorLimit",
    inline = 1,
    label = 4,
    min = 0,
    max = 180,
    default = 45,
    unit = "°",
    vals = {10}
}

labels[#labels + 1] = {
    subpage = 1,
    t = "HSI Offset limit",
    label = 5,
    inline_size = 8.15
}
fields[#fields + 1] = {
    subpage = 1,
    t = "R",
    help = "profilesErrorHSIOffsetLimit",
    inline = 3,
    label = 5,
    min = 0,
    max = 180,
    default = 45,
    unit = "°",
    vals = {37}
}
fields[#fields + 1] = {
    subpage = 1,
    t = "P",
    help = "profilesErrorHSIOffsetLimit",
    inline = 2,
    label = 5,
    min = 0,
    max = 180,
    default = 45,
    unit = "°",
    vals = {38}
}

fields[#fields + 1] = {
    subpage = 1,
    t = "Error rotation",
    help = "profilesErrorRotation",
    min = 0,
    max = 1,
    vals = {7},
    table = {[0] = "OFF", "ON"}
}

labels[#labels + 1] = {
    subpage = 1,
    t = "I-term relax",
    label = 6,
    inline_size = 40.15
}
fields[#fields + 1] = {
    subpage = 1,
    t = "",
    help = "profilesItermRelaxType",
    inline = 1,
    label = 6,
    min = 0,
    max = 2,
    vals = {17},
    table = {[0] = "OFF", "RP", "RPY"}
}

labels[#labels + 1] = {
    subpage = 1,
    t = "    Cut-off point",
    label = 15,
    inline_size = 8.15
}
fields[#fields + 1] = {
    subpage = 1,
    t = "R",
    help = "profilesItermRelax",
    inline = 3,
    label = 15,
    min = 1,
    max = 100,
    default = 10,
    vals = {18}
}
fields[#fields + 1] = {
    subpage = 1,
    t = "P",
    help = "profilesItermRelax",
    inline = 2,
    label = 15,
    min = 1,
    max = 100,
    default = 10,
    vals = {19}
}
fields[#fields + 1] = {
    subpage = 1,
    t = "Y",
    help = "profilesItermRelax",
    inline = 1,
    label = 15,
    min = 1,
    max = 100,
    default = 15,
    vals = {20}
}

-- tail rotor settings
labels[#labels + 1] = {
    subpage = 2,
    t = "Yaw stop gain",
    label = "ysgain",
    inline_size = 13.6
}
fields[#fields + 1] = {
    subpage = 2,
    t = "CW",
    help = "profilesYawStopGainCW",
    inline = 2,
    label = "ysgain",
    min = 25,
    max = 250,
    default = 100,
    vals = {21}
}
fields[#fields + 1] = {
    subpage = 2,
    t = "CCW",
    help = "profilesYawStopGainCCW",
    inline = 1,
    label = "ysgain",
    min = 25,
    max = 250,
    default = 100,
    vals = {22}
}

fields[#fields + 1] = {
    subpage = 2,
    t = "Precomp Cutoff",
    help = "profilesYawPrecompCutoff",
    min = 0,
    max = 250,
    default = 5,
    unit = "Hz",
    vals = {23}
}
fields[#fields + 1] = {
    subpage = 2,
    t = "Cyclic FF gain",
    help = "profilesYawFFCyclicGain",
    min = 0,
    max = 250,
    default = 30,
    vals = {24}
}
fields[#fields + 1] = {
    subpage = 2,
    t = "Collective FF gain",
    help = "profilesYawFFCollectiveGain",
    min = 0,
    max = 250,
    default = 0,
    vals = {25}
}

labels[#labels + 1] = {
    subpage = 2,
    t = "Collective Impulse FF",
    label = "colimpff",
    inline_size = 13.6
}
fields[#fields + 1] = {
    subpage = 2,
    t = "Gain",
    help = "profilesYawFFImpulseGain",
    inline = 2,
    label = "colimpff",
    min = 0,
    max = 250,
    default = 0,
    vals = {26}
}
fields[#fields + 1] = {
    subpage = 2,
    t = "Decay",
    help = "profilesyawFFImpulseDecay",
    inline = 1,
    label = "colimpff",
    min = 0,
    max = 250,
    default = 25,
    unit = "s",
    vals = {27}
}

labels[#labels + 1] = {
    subpage = 4,
    t = "Collective Pitch Compensation",
    t2 = "Col. Pitch Compensation",
    label = "cpcomp",
    inline_size = 40.15
}
fields[#fields + 1] = {
    subpage = 4,
    t = "",
    help = "profilesPitchFFCollective",
    inline = 1,
    label = "cpcomp",
    min = 0,
    max = 250,
    default = 0,
    vals = {28}
}

-- pid controller bandwidth
labels[#labels + 1] = {
    subpage = 3,
    t = "PID Bandwidth",
    inline_size = 8.15,
    label = "pidbandwidth",
    type = 1
}
fields[#fields + 1] = {
    subpage = 3,
    t = "R",
    help = "profilesPIDBandwidth",
    inline = 3,
    label = "pidbandwidth",
    min = 0,
    max = 250,
    default = 50,
    vals = {11}
}
fields[#fields + 1] = {
    subpage = 3,
    t = "P",
    help = "profilesPIDBandwidth",
    inline = 2,
    label = "pidbandwidth",
    min = 0,
    max = 250,
    default = 50,
    vals = {12}
}
fields[#fields + 1] = {
    subpage = 3,
    t = "Y",
    help = "profilesPIDBandwidth",
    inline = 1,
    label = "pidbandwidth",
    min = 0,
    max = 250,
    default = 100,
    vals = {13}
}

labels[#labels + 1] = {
    subpage = 3,
    t = "D-term cut-off",
    inline_size = 8.15,
    label = "dcutoff",
    type = 1
}
fields[#fields + 1] = {
    subpage = 3,
    t = "R",
    help = "profilesPIDBandwidthDtermCutoff",
    inline = 3,
    label = "dcutoff",
    min = 0,
    max = 250,
    default = 15,
    vals = {14}
}
fields[#fields + 1] = {
    subpage = 3,
    t = "P",
    help = "profilesPIDBandwidthDtermCutoff",
    inline = 2,
    label = "dcutoff",
    min = 0,
    max = 250,
    default = 15,
    vals = {15}
}
fields[#fields + 1] = {
    subpage = 3,
    t = "Y",
    help = "profilesPIDBandwidthDtermCutoff",
    inline = 1,
    label = "dcutoff",
    min = 0,
    max = 250,
    default = 20,
    vals = {16}
}

labels[#labels + 1] = {
    subpage = 3,
    t = "B-term cut-off",
    inline_size = 8.15,
    label = "bcutoff",
    type = 1
}
fields[#fields + 1] = {
    subpage = 3,
    t = "R",
    help = "profilesPIDBandwidthBtermCutoff",
    inline = 3,
    label = "bcutoff",
    min = 0,
    max = 250,
    default = 15,
    vals = {39}
}
fields[#fields + 1] = {
    subpage = 3,
    t = "P",
    help = "profilesPIDBandwidthBtermCutoff",
    inline = 2,
    label = "bcutoff",
    min = 0,
    max = 250,
    default = 15,
    vals = {40}
}
fields[#fields + 1] = {
    subpage = 3,
    t = "Y",
    help = "profilesPIDBandwidthBtermCutoff",
    inline = 1,
    label = "bcutoff",
    min = 0,
    max = 250,
    default = 20,
    vals = {41}
}

-- main rotor settings
labels[#labels + 1] = {
    subpage = 4,
    t = "Cyclic Cross coupling",
    label = "cycliccc1",
    inline_size = 40.15
}
fields[#fields + 1] = {
    subpage = 4,
    t = "Gain",
    help = "profilesCyclicCrossCouplingGain",
    inline = 1,
    label = "cycliccc1",
    line = false,
    min = 0,
    max = 250,
    default = 25,
    vals = {34}
}

labels[#labels + 1] = {
    subpage = 4,
    t = "",
    label = "cycliccc2",
    inline_size = 40.15
}
fields[#fields + 1] = {
    subpage = 4,
    t = "Ratio",
    help = "profilesCyclicCrossCouplingRatio",
    inline = 1,
    label = "cycliccc2",
    line = false,
    min = 0,
    max = 200,
    default = 0,
    unit = "%",
    vals = {35}
}

labels[#labels + 1] = {
    subpage = 4,
    t = "",
    label = "cycliccc3",
    inline_size = 40.15
}
fields[#fields + 1] = {
    subpage = 4,
    t = "Cutoff",
    help = "profilesCyclicCrossCouplingCutoff",
    inline = 1,
    label = "cycliccc3",
    line = true,
    min = 1,
    max = 250,
    default = 15,
    unit = "Hz",
    vals = {36}
}

-- auto leveling settings
labels[#labels + 1] = {
    subpage = 5,
    t = "Acro trainer",
    inline_size = 13.6,
    label = 11
}
fields[#fields + 1] = {
    subpage = 5,
    t = "Gain",
    help = "profilesAcroTrainerGain",
    inline = 2,
    label = 11,
    min = 25,
    max = 255,
    default = 75,
    vals = {32}
}
fields[#fields + 1] = {
    subpage = 5,
    t = "Max",
    help = "profilesAcroTrainerLimit",
    inline = 1,
    label = 11,
    min = 10,
    max = 80,
    default = 20,
    unit = "°",
    vals = {33}
}

labels[#labels + 1] = {
    subpage = 5,
    t = "Angle mode",
    inline_size = 13.6,
    label = 12
}
fields[#fields + 1] = {
    subpage = 5,
    t = "Gain",
    help = "profilesAngleModeGain",
    inline = 2,
    label = 12,
    min = 0,
    max = 200,
    default = 40,
    vals = {29}
}
fields[#fields + 1] = {
    subpage = 5,
    t = "Max",
    help = "profilesAngleModeLimit",
    inline = 1,
    label = 12,
    min = 10,
    max = 90,
    default = 55,
    unit = "°",
    vals = {30}
}

labels[#labels + 1] = {
    subpage = 5,
    t = "Horizon mode",
    inline_size = 13.6,
    label = 13
}
fields[#fields + 1] = {
    subpage = 5,
    t = "Gain",
    help = "profilesHorizonModeGain",
    inline = 2,
    label = 13,
    min = 0,
    max = 200,
    default = 40,
    vals = {31}
}

return {
    read = 94, -- msp_PID_PROFILE
    write = 95, -- msp_SET_PID_PROFILE
    title = "Profile - Advanced",
    refreshswitch = true,
    reboot = false,
    eepromWrite = true,
    minBytes = 41,
    labels = labels,
    simulatorResponse = {
        3, 25, 250, 0, 12, 0, 1, 30, 30, 45, 50, 50, 100, 15, 15, 20, 2, 10, 10,
        15, 100, 100, 5, 0, 30, 0, 25, 0, 40, 55, 40, 75, 20, 25, 0, 15, 45, 45,
        15, 15, 20
    },
    fields = fields,
    postRead = function(self)
        -- rf2ethos.utils.log("postRead")
    end,
    postLoad = function(self)
        -- rf2ethos.utils.log("postLoad")
    end
}
