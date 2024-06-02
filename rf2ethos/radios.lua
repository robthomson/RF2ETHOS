local LCD_W, LCD_H = rf2ethos.getWindowSize()
local resolution = LCD_W .. "x" .. LCD_H

local supportedRadios = {
    -- TANDEM X20, TANDEM XE (800x480)
    ["784x406"] = {msp = {template = "/scripts/rf2ethos/templates/784x406.lua", inlinesize_mult = 1, text=1, helpQrCodeSize=100, text = 1, buttonHeight = 40, buttonPadding = 15, buttonPaddingTop = 8}},
    -- TANDEM X18, TWIN X Lite (480x320)
    ["472x288"] = {msp = {template = "/scripts/rf2ethos/templates/472x288.lua", inlinesize_mult = 1.28, text=2, helpQrCodeSize=70, navButtonOffset = 47, text = 2, buttonWidth = 75, buttonHeight = 30, buttonPadding = 10, buttonPaddingTop = 6}},
    -- Horus X10, Horus X12 (480x272)
    ["472x240"] = {msp = {template = "/scripts/rf2ethos/templates/472x240.lua", inlinesize_mult = 1.0715, text=1,  helpQrCodeSize=70, text = 2, buttonHeight = 30, buttonPadding = 15, buttonPaddingTop = 4}},
    -- Twin X14 (632x314)
    ["632x314"] = {msp = {template = "/scripts/rf2ethos/templates/632x314.lua", inlinesize_mult = 1.11, text=2,helpQrCodeSize=100, navButtonOffset = 47, buttonWidth = 95, text = 2, buttonHeight = 35, buttonPadding = 10, buttonPaddingTop = 8}}
}

local radio = assert(supportedRadios[resolution], resolution .. " not supported")

return radio
