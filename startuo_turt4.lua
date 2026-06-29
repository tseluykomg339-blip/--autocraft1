-- Проверяем модем
if peripheral.getType("right") == "modem" then
    rednet.open("right")
    print("Wireless Modem OPENED")
else
    print("ERROR: No modem in RIGHT hand!")
end

-- Проверяем, что это крафтящая черепаха
if not turtle.craft then
    print("ERROR: This is NOT a Crafting Turtle!")
end

-- Функция для парсинга команды
local function parseCommand(msg)
    if not msg then return nil, 1 end
    local command, count = msg:match("^([^:]+):([%d]+)$")
    if command and count then
        return command, tonumber(count)
    end
    return msg, 1
end

-- Функция для выкидывания предметов (очистка)
local function dropAll()
    for i = 1, 16 do
        turtle.select(i)
        if not turtle.dropDown() then
            if not turtle.drop() then
                turtle.dropUp()
            end
        end
    end
end

while true do
    print("Waiting for signal...")
    local id, msg = rednet.receive()
    
    print("RECEIVED: " .. tostring(msg) .. " from " .. id)
    
    local command, count = parseCommand(msg)
    
    if command == "CRAFT" then
        turtle.refuel()
        
        print("Starting " .. count .. " crafts...")
        local success = true
        
        for i = 1, count do
            print("Crafting step " .. i .. "/" .. count)
            
            -- ==============================================
            -- ПРАВИЛЬНЫЙ ПОРЯДОК ДЕЙСТВИЙ:
            -- 1. НЕ ОЧИЩАЕМ черепаху, потому что в ней уже лежат ингредиенты!
            -- 2. Пытаемся скрафтить
            -- 3. Если крафт удался, очищаем черепаху (выкидываем результат)
            -- ==============================================
            
            if not turtle.craft() then
                print("CRAFT FAILED at step " .. i .. "!")
                rednet.send(id, "FAIL:" .. i)
                success = false
                break
            end
            
            -- После успешного крафта выкидываем результат
            dropAll()
        end
        
        if success then
            print("SUCCESS! All " .. count .. " crafts done.")
            dropAll()  -- Финальная очистка
            rednet.send(id, "OK:" .. count)
        end
    end
end
