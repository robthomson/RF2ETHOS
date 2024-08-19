compile = {}

local arg = {...}
local config = arg[1]
local toolDir = config.toolDir

local readConfig
local switchParam
local pref
local spref
local s

function compile.initialise()
       readConfig = false
end

local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function baseName()
	local baseName
	baseName = config.toolDir:gsub("/scripts/","")
	baseName = baseName:gsub("/","")
	return baseName
end

local function loadPreference(preference)

    file = preference .. ".cfg"
    local f
    f = io.open(file, "rb")
    if f ~= nil then
        -- file exists
        local rData
        c = 0
        tc = 1
        rData = io.read(f, "l")
        io.close(f)

        return rData
    end

end

-- explode a string
local function explode(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do table.insert(t, str) end
    return t
end

function compile.loadScript(script)

    -- we need to add code to stop this reading every time function runs
	local cachefile
	cachefile = toolDir .. "compiled/" .. script:gsub("/", "_") .. "c"

   
    if readConfig == false or readConfig == nil then 

        readConfig = true

        -- read preference
        pref = tonumber(loadPreference(toolDir  .. "/preferences/compilation"))
        spref = loadPreference(toolDir  .. "/preferences/compilationswitch")
        s = explode(spref, ",")
	    switchParam = system.getSource({category = s[1], member = s[2]})	
            
        if pref == 0 or pref == nil then
            config.useCompiler = true
            -- check physical overrides
        elseif pref == 1 then
            config.useCompiler = false 
        elseif pref == 2 then
                if tonumber(switchParam:value()) == 100  then
                    config.useCompiler = false
					
					local audioParam = tonumber(rf2ethos.utils.loadPreference(toolDir .. "/preferences/audio"))
					
					if audioParam == 0 then
						system.playFile(toolDir .. "sounds/compdis.wav")
					end
					
                else
                    config.useCompiler = true
                end
        end

    end


    -- overrides
    if config.useCompiler == true then
        if file_exists("/scripts/" .. baseName() .. ".nocompile" ) == true then
		    config.useCompiler = false
	    end

        if file_exists("/scripts/nocompile" ) == true  then
		    config.useCompiler = false
	    end
    end

    if config.useCompiler == true then
        if file_exists(cachefile) ~= true then
            system.compile(script)
            os.rename(script .. 'c', cachefile)
        end
        print("Loading: " .. cachefile)
        return loadfile(cachefile)
    else
        if file_exists(cachefile) == true then
            os.remove(cachefile)
        end		
		print("Loading: " .. script)
        return loadfile(script)
    end

end

return compile
