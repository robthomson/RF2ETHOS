local template = assert(rf2ethos.loadScriptrf2ethos(radio.template))()

local pages = {}


pages[#pages + 1] = { title = "SCORPION", folder="rf2scorp", image="scorpion.png" }
pages[#pages + 1] = { title = "HOBBYWING 5", folder="rf2hw5", image="hobbywing.png"}
pages[#pages + 1] = { title = "YGE", folder="rf2yge", image="yge.png" }

return {

    title = "ESC",
    pages = pages,
}
