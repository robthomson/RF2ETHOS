local template = assert(rf2ethos.loadScriptRF2ETHOS(radio.template))()

local pages = {}


pages[#pages + 1] = { title = "YGE", folder="rf2yge" }
pages[#pages + 1] = { title = "SCORPION", folder="rf2scorp" }
pages[#pages + 1] = { title = "HOBBYWING 5", folder="rf2hw5"}

return {

    title = "ESC",
    pages = pages,
}
