-- Configuration
rednet.open("bottom")
rednet.open("back")

local monControl = peripheral.wrap("right")
local monList    = peripheral.wrap("monitor_9")
local barrel     = peripheral.wrap("minecraft:barrel_3")
local storage    = peripheral.wrap("create:item_vault_1")
local turtleName = "turtle_1"
local turtleID   = 4
local recipeFile = "recipes.dat"

local bSlots = {1, 2, 3, 10, 11, 12, 19, 20, 21}
local tSlots = {1, 2, 3, 5, 6, 7, 9, 10, 11}
local recipes = {}
local deleteMode = false -- Режим удаления

function save()
    local f = fs.open(recipeFile, "w")
    f.write(textutils.serialize(recipes))
    f.close()
end

function load()
    if fs.exists(recipeFile) then
        local f = fs.open(recipeFile, "r")
        recipes = textutils.unserialize(f.readAll()) or {}
        f.close()
    end
end

function draw()
    if monControl then
        monControl.setBackgroundColor(colors.black)
        monControl.clear()
        monControl.setTextScale(1)
        monControl.setCursorPos(1, 2)
        monControl.setBackgroundColor(colors.red)
        monControl.write(" [ QUICK CRAFT ] ")
        monControl.setCursorPos(1, 4)
        monControl.setBackgroundColor(colors.blue)
        monControl.write(" [ SAVE RECIPE ] ")
        
        -- Кнопка удаления
        monControl.setCursorPos(1, 6)
        monControl.setBackgroundColor(deleteMode and colors.orange or colors.gray)
        monControl.write(deleteMode and " [ DELETE: ON  ] " or " [ DELETE: OFF ] ")
    end

    if monList then
        monList.setBackgroundColor(colors.black)
        monList.clear()
        monList.setTextScale(1)
        monList.setTextColor(deleteMode and colors.red or colors.lime)
        monList.setCursorPos(1, 1)
        monList.write(deleteMode and "=== DELETE MODE ===" or "=== AUTO CRAFT ===")
        local line = 3
        for name, _ in pairs(recipes) do
            monList.setCursorPos(1, line)
            monList.write("> " .. name)
            line = line + 1
        end
    end
end

load()
draw()

while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    
    if side == "right" then
        if y == 2 then 
            for i = 1, 9 do barrel.pushItems(turtleName, bSlots[i], 1, tSlots[i]) end
            rednet.send(turtleID, "CRAFT")
        elseif y == 4 then
            print("Enter recipe name:")
            local name = read()
            local current = {}
            local items = barrel.list()
            for i=1, 9 do
                if items[bSlots[i]] then current[i] = items[bSlots[i]].name end
            end
            recipes[name] = current
            save()
            draw()
        elseif y == 6 then -- Переключаем режим удаления
            deleteMode = not deleteMode
            draw()
        end

    elseif side == "monitor_9" then
        local line = 3
        local toDelete = nil
        for name, recipeData in pairs(recipes) do
            if y == line then
                if deleteMode then
                    toDelete = name
                else
                    -- Обычный крафт
                    print("Auto-crafting: " .. name)
                    local vaultItems = storage.list()
                    for slot, itemName in pairs(recipeData) do
                        for vSlot, item in pairs(vaultItems) do
                            if item.name == itemName then
                                storage.pushItems(turtleName, vSlot, 1, tSlots[slot])
                                break
                            end
                        end
                    end
                    sleep(0.5)
                    rednet.send(turtleID, "CRAFT")
                end
            end
            line = line + 1
        end
        
        if toDelete then
            recipes[toDelete] = nil
            save()
            deleteMode = false -- Выключаем режим после удаления
            draw()
        end
    end
end
