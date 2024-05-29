local template = assert(rf2ethos.loadScriptrf2ethos(radio.template))()

local pages = {}


pages[#pages + 1] = { title = "SCORPION", folder="rf2scorp" }
pages[#pages + 1] = { title = "HOBBYWING 5", folder="rf2hw5"}
pages[#pages + 1] = { title = "YGE", folder="rf2yge" }

return {

    title = "ESC",
    pages = pages,
}
