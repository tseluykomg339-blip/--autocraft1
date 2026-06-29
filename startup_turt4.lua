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
    
    -- Пытаемся найти "CRAFT:21"
    local command, count = msg:match("^([^:]+):([%d]+)$")
    if command and count then
        return command, tonumber(count)
    end
    
    -- Если команда без количества (просто "CRAFT") — делаем 1 крафт
    return msg, 1
end

-- Функция для выкидывания предметов (исправленная)
local function dropAll()
    for i = 1, 16 do
        turtle.select(i)
        -- Пытаемся выкинуть вниз
        if not turtle.dropDown() then
            -- Если не получилось, пытаемся выкинуть вперёд
            if not turtle.drop() then
                -- Если и вперёд не получилось, пробуем вверх
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
        
        -- ГЛАВНЫЙ ЦИКЛ: делаем ровно count крафтов
        for i = 1, count do
            print("Crafting step " .. i .. "/" .. count)
            
            -- Очищаем черепаху перед каждым крафтом
            dropAll()
            
            if not turtle.craft() then
                print("CRAFT FAILED at step " .. i .. "!")
                rednet.send(id, "FAIL:" .. i)
                success = false
                break
            end
        end
        
        if success then
            print("SUCCESS! All " .. count .. " crafts done.")
            dropAll()
            rednet.send(id, "OK:" .. count)
        end
    end
end
