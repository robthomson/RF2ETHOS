local toolName = "YGE"
moduleName = "RF2YGE"
moduleTitle = "YGE ESC v0.42"

mspSignature = 0xA5
mspHeaderBytes = 2
mspBytes = 60 -- 66

escType = {
    [848] = "YGE 35 LVT BEC",
    [1616] = "YGE 65 LVT BEC",
    [2128] = "YGE 85 LVT BEC",
    [2384] = "YGE 95 LVT BEC",
    [4944] = "YGE 135 LVT BEC",
    [2304] = "YGE 90 HVT Opto",
    [4608] = "YGE 120 HVT Opto",
    [5712] = "YGE 165 HVT",
    [8272] = "YGE 205 HVT",
    [8273] = "YGE 205 HVT BEC",
    [4177] = "YGE Aureus 105",
    [4179] = "YGE Aureus 105v2",
    [5025] = "YGE Aureus 135",
    [5027] = "YGE Aureus 135v2",
    [5457] = "YGE Saphir 155",
    [5459] = "YGE Saphir 155v2",
    [4689] = "YGE Saphir 125",
    [4928] = "YGE Opto 135",
    [9552] = "YGE Opto 255",
    [16464] = "YGE Opto 405"
}

escFlags = {spinDirection = 0, f3cAuto = 1, keepMah = 2, bec12v = 3}

function getEscTypeLabel(values)
    local idx = (values[mspHeaderBytes + 24] * 256) + values[mspHeaderBytes + 23]
    return escType[idx] or "YGE ESC (" .. idx .. ")"
end

function getUInt(page, vals)
    if page == nil then return "" end
    local v = 0
    for idx = 1, #vals do
        local raw_val = page.values[vals[idx] + mspHeaderBytes] or 0
        raw_val = raw_val * (256 ^ (idx - 1))
        v = v + raw_val
    end
    return v
end

function getPageValue(page, index)
    return page.values[mspHeaderBytes + index]
end

function setPageValue(page, index, value)
    page.values[mspHeaderBytes + index] = value
end

rf2ethos.config.apiVersion = 0
mcuId = nil
-- runningInSimulator = string.sub(select(2,getVersion()), -4) == "simu"

return {toolName = toolName, mspSignature = mspSignature, mspHeaderBytes = mspHeaderBytes, mspBytes = mspBytes}
