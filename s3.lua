-- Configuration
rednet.open("bottom")
rednet.open("back")

local monControl = peripheral.wrap("monitor_1")
local monList    = peripheral.wrap("monitor_2")
local barrel     = peripheral.wrap("minecraft:barrel_0")
local storage    = peripheral.wrap("create:item_vault_0")
local turtleName = "turtle_4"
local turtleID   = 1
local recipeFile = "recipes.dat"

local bSlots = {1, 2, 3, 10, 11, 12, 19, 20, 21}
local tSlots = {1, 2, 3, 5, 6, 7, 9, 10, 11}
local recipes = {}
local deleteMode = false
local craftCount = 1

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
        
        -- Заголовок
        monControl.setTextColor(colors.white)
        monControl.setCursorPos(1, 1)
        monControl.write("=== CRAFT CONTROL ===")
        
        -- Кнопка "QUICK CRAFT"
        monControl.setCursorPos(1, 3)
        monControl.setBackgroundColor(colors.red)
        monControl.write(" [ QUICK CRAFT ] ")
        
        -- Кнопка "SAVE RECIPE"
        monControl.setCursorPos(1, 5)
        monControl.setBackgroundColor(colors.blue)
        monControl.write(" [ SAVE RECIPE ] ")
        
        -- =============================================
        -- НОВЫЕ КНОПКИ УПРАВЛЕНИЯ КОЛИЧЕСТВОМ
        -- =============================================
        -- Строка 7: кнопки уменьшения
        monControl.setCursorPos(1, 7)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ -10 ] ")
        
        monControl.setCursorPos(9, 7)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ -5 ] ")
        
        monControl.setCursorPos(17, 7)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ -1 ] ")
        
        -- Строка 8: отображение текущего количества
        monControl.setCursorPos(1, 8)
        monControl.setBackgroundColor(colors.black)
        monControl.setTextColor(colors.yellow)
        local countStr = tostring(craftCount)
        monControl.write("  " .. string.rep(" ", 4 - #countStr) .. countStr .. "  ")
        
        -- Строка 9: кнопки увеличения
        monControl.setCursorPos(1, 9)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ +1 ] ")
        
        monControl.setCursorPos(9, 9)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ +5 ] ")
        
        monControl.setCursorPos(17, 9)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ +10 ] ")
        
        -- Кнопка "DELETE" (строка 11)
        monControl.setCursorPos(1, 11)
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
    
    if side == "monitor_1" then
        -- Кнопка "QUICK CRAFT"
        if y == 3 then 
            print("Starting " .. craftCount .. " crafts one by one...")
            for step = 1, craftCount do
                -- Загружаем один набор ингредиентов
                for i = 1, 9 do
                    barrel.pushItems(turtleName, bSlots[i], 1, tSlots[i])
                end
                sleep(0.3)
                
                -- Отправляем команду на крафт
                rednet.send(turtleID, "CRAFT")
                
                -- Ждём ответ от черепахи
                local sender, response = rednet.receive(5)
                if response == "OK" then
                    print("Craft " .. step .. "/" .. craftCount .. " successful!")
                elseif response == "FAIL" then
                    print("Craft " .. step .. " FAILED! Stopping.")
                    break
                else
                    print("No response from turtle! Stopping.")
                    break
                end
                sleep(0.3)
            end
            print("All " .. craftCount .. " crafts completed!")
            
        -- Кнопка "SAVE RECIPE"
        elseif y == 5 then
            print("Enter recipe name:")
            local name = read()
            local current = {}
            local items = barrel.list()
            for i = 1, 9 do
                if items[bSlots[i]] then
                    current[i] = items[bSlots[i]].name
                end
            end
            recipes[name] = current
            save()
            draw()
            
        -- =============================================
        -- ОБРАБОТКА КНОПОК УПРАВЛЕНИЯ КОЛИЧЕСТВОМ (y == 7 и y == 9)
        -- =============================================
        elseif y == 7 then
            -- Кнопки уменьшения (строка 7)
            if x >= 1 and x <= 7 then
                craftCount = math.max(1, craftCount - 10)
                draw()
            elseif x >= 9 and x <= 15 then
                craftCount = math.max(1, craftCount - 5)
                draw()
            elseif x >= 17 and x <= 23 then
                craftCount = math.max(1, craftCount - 1)
                draw()
            end
            
        elseif y == 9 then
            -- Кнопки увеличения (строка 9)
            if x >= 1 and x <= 7 then
                craftCount = math.min(64, craftCount + 1)
                draw()
            elseif x >= 9 and x <= 15 then
                craftCount = math.min(64, craftCount + 5)
                draw()
            elseif x >= 17 and x <= 23 then
                craftCount = math.min(64, craftCount + 10)
                draw()
            end
            
        -- Кнопка "DELETE"
        elseif y == 11 then
            deleteMode = not deleteMode
            draw()
        end

    elseif side == "monitor_2" then
        local line = 3
        local toDelete = nil
        for name, recipeData in pairs(recipes) do
            if y == line then
                if deleteMode then
                    toDelete = name
                else
                    print("Auto-crafting: " .. name .. " (x" .. craftCount .. ")")
                    for step = 1, craftCount do
                        -- Загружаем ингредиенты из хранилища
                        local vaultItems = storage.list()
                        for slot, itemName in pairs(recipeData) do
                            for vSlot, item in pairs(vaultItems) do
                                if item.name == itemName then
                                    storage.pushItems(turtleName, vSlot, 1, tSlots[slot])
                                    break
                                end
                            end
                        end
                        sleep(0.3)
                        rednet.send(turtleID, "CRAFT")
                        
                        -- Ждём ответ
                        local sender, response = rednet.receive(5)
                        if response == "FAIL" then
                            print("Craft failed at step " .. step)
                            break
                        elseif response ~= "OK" then
                            print("No response at step " .. step)
                            break
                        end
                        sleep(0.3)
                    end
                    print("All " .. craftCount .. " crafts completed!")
                end
            end
            line = line + 1
        end
        
        if toDelete then
            recipes[toDelete] = nil
            save()
            deleteMode = false
            draw()
        end
    end
end
