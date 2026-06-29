-- Configuration
rednet.open("bottom")
rednet.open("back")

-- ПЕРВЫЙ МОНИТОР (управление) — подключен справа
local monControl = peripheral.wrap("right")
-- ВТОРОЙ МОНИТОР (список рецептов) — подключен как monitor_9
local monList    = peripheral.wrap("monitor_9")

local barrel     = peripheral.wrap("minecraft:barrel_3")
local storage    = peripheral.wrap("create:item_vault_1")
local turtleName = "turtle_1"
local turtleID   = 4
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
    -- ОТРИСОВКА ПЕРВОГО МОНИТОРА (управление)
    if monControl then
        monControl.setBackgroundColor(colors.black)
        monControl.clear()
        monControl.setTextScale(1)

        -- Кнопка "QUICK CRAFT"
        monControl.setCursorPos(1, 2)
        monControl.setBackgroundColor(colors.red)
        monControl.write(" [ QUICK CRAFT ] ")

        -- Кнопка "SAVE RECIPE"
        monControl.setCursorPos(1, 4)
        monControl.setBackgroundColor(colors.blue)
        monControl.write(" [ SAVE RECIPE ] ")

        -- Кнопка "-10"
        monControl.setCursorPos(1, 6)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ -10 ] ")

        -- Текущее количество
        monControl.setCursorPos(8, 6)
        monControl.setBackgroundColor(colors.black)
        monControl.setTextColor(colors.white)
        local countStr = tostring(craftCount)
        monControl.write(string.rep(" ", 3 - #countStr) .. countStr .. " ")

        -- Кнопка "+10"
        monControl.setCursorPos(14, 6)
        monControl.setBackgroundColor(colors.gray)
        monControl.write(" [ +10 ] ")

        -- Кнопка "DELETE"
        monControl.setCursorPos(1, 8)
        monControl.setBackgroundColor(deleteMode and colors.orange or colors.gray)
        monControl.write(deleteMode and " [ DELETE: ON  ] " or " [ DELETE: OFF ] ")
    end

    -- ОТРИСОВКА ВТОРОГО МОНИТОРА (список рецептов)
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

-- ОСНОВНОЙ ЦИКЛ ОБРАБОТКИ СОБЫТИЙ
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")

    -- =============================================
    -- ОБРАБОТКА НАЖАТИЙ НА ПЕРВОМ МОНИТОРЕ (right)
    -- =============================================
    if side == "right" then
        -- Кнопка "QUICK CRAFT" (y == 2)
        if y == 2 then
            for i = 1, 9 do
                barrel.pushItems(turtleName, bSlots[i], craftCount, tSlots[i])
            end
            rednet.send(turtleID, "CRAFT:" .. craftCount)

        -- Кнопка "SAVE RECIPE" (y == 4)
        elseif y == 4 then
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

        -- Кнопки управления количеством (y == 6)
        elseif y == 6 then
            if x >= 1 and x <= 7 then  -- Кнопка "-10"
                craftCount = math.max(1, craftCount - 10)
                draw()
            elseif x >= 14 and x <= 20 then  -- Кнопка "+10"
                craftCount = math.min(64, craftCount + 10)
                draw()
            end

        -- Кнопка "DELETE" (y == 8)
        elseif y == 8 then
            deleteMode = not deleteMode
            draw()
        end

    -- =============================================
    -- ОБРАБОТКА НАЖАТИЙ НА ВТОРОМ МОНИТОРЕ (monitor_9)
    -- =============================================
    elseif side == "monitor_9" then
        local line = 3
        local toDelete = nil

        for name, recipeData in pairs(recipes) do
            if y == line then
                if deleteMode then
                    toDelete = name
                else
                    print("Auto-crafting: " .. name .. " (x" .. craftCount .. ")")
                    local vaultItems = storage.list()

                    for slot, itemName in pairs(recipeData) do
                        for vSlot, item in pairs(vaultItems) do
                            if item.name == itemName then
                                storage.pushItems(turtleName, vSlot, craftCount, tSlots[slot])
                                break
                            end
                        end
                    end

                    sleep(0.5)
                    rednet.send(turtleID, "CRAFT:" .. craftCount)
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
