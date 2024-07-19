compile =
    {}

local 
    arg =
    {
        ...
    }
local 
    config =
    arg[1]
local 
    toolDir =
    config.toolDir

function compile.file_exists(
    name)
    local 
        f =
        io.open(
            name,
            "r")
    if f ~=
        nil then
        io.close(
            f)
        return
            true
    else
        return
            false
    end
end

function compile.loadScript(
    script)

    if config.useCompiler ==
        true then
        local 
            cachefile
        cachefile =
            toolDir ..
                "compiled/" ..
                script:gsub(
                    "/",
                    "_") ..
                "c"
        if compile.file_exists(
            cachefile) ~=
            true then
            system.compile(
                script)
            os.rename(
                script ..
                    'c',
                cachefile)
        end
        -- print(cachefile)
        return
            loadfile(
                cachefile)
    else
        -- print(script)
        return
            loadfile(
                script)
    end

end

return
    compile
