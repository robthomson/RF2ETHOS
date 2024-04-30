local LCD_W, LCD_H = rf2touch.getWindowSize()
local resolution = LCD_W .. "x" .. LCD_H

local supportedRadios = {
    -- TANDEM X20, TANDEM XE (800x480)
    ["784x406"] = {msp = {template = "/scripts/RF2TOUCH/TEMPLATES/784x406.lua", text=1, buttonHeight = 40,buttonPadding = 15, buttonPaddingTop = 8}},
    -- TANDEM X18, TWIN X Lite (480x320)
    ["472x288"] = {msp = {template = "/scripts/RF2TOUCH/TEMPLATES/472x288.lua", navButtonOffset=47, text=2, buttonWidth=75, buttonHeight = 30, buttonPadding = 10, buttonPaddingTop = 6}},
    -- Horus X10, Horus X12 (480x272)
    ["472x240"] = {msp = {template = "/scripts/RF2TOUCH/TEMPLATES/472x240.lua",text=2, buttonHeight = 40, buttonPadding = 15, buttonPaddingTop = 8}},
    -- Twin X14 (632x314)
    ["632x314"] = {msp = {template = "/scripts/RF2TOUCH/TEMPLATES/632x314.lua", text=2, buttonHeight = 35, buttonPadding = 10, buttonPaddingTop = 8}}
}

local radio = assert(supportedRadios[resolution], resolution .. " not supported")

return radio
