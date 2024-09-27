local mspHelper = {
        readU8 = function(buf)
                local offset = buf.offset or 1
                local value = buf[offset]
                buf.offset = offset + 1
                return value
        end,
        readU16 = function(buf)
                local offset = buf.offset or 1
                local value = buf[offset] + buf[offset + 1] * 256
                buf.offset = offset + 2
                return value
        end,
        readS16 = function(buf)
                local offset = buf.offset or 1
                local value = buf[offset] + buf[offset + 1] * 256
                if value >= 32768 then value = value - 65536 end
                buf.offset = offset + 2
                return value
        end,
        readU32 = function(buf)
                local offset = buf.offset or 1
                local value = buf[offset] + buf[offset + 1] * 256 + buf[offset + 2] * 65536 + buf[offset + 3] * 16777216
                buf.offset = offset + 4
                return value
        end,
        writeU8 = function(buf, value)
                buf[#buf + 1] = value % 256
        end,
        writeU16 = function(buf, value)
                buf[#buf + 1] = value % 256
                buf[#buf + 1] = math.floor(value / 256) % 256
        end,
        writeU32 = function(buf, value)
                buf[#buf + 1] = value % 256
                buf[#buf + 1] = math.floor(value / 256) % 256
                buf[#buf + 1] = math.floor(value / 65536) % 256
                buf[#buf + 1] = math.floor(value / 16777216) % 256
        end,
        writeRAW = function(buf, value)
                buf[#buf + 1] = value
        end
}

return mspHelper
