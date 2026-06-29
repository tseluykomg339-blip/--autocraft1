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

    -- Если команда без количества (старый формат)
    return msg, 1
end

while true do
    print("Waiting for signal...")
    local id, msg = rednet.receive()

    print("RECEIVED: " .. tostring(msg) .. " from " .. id)

    local command, count = parseCommand(msg)

    if command == "CRAFT" then
        turtle.refuel()

        local success = true
        print("Starting " .. count .. " crafts...")

        for i = 1, count do
            print("Crafting step " .. i .. "/" .. count)

            if not turtle.craft() then
                print("CRAFT FAILED at step " .. i .. "!")
                rednet.send(id, "FAIL:" .. i)
                success = false
                break
            end
        end

        if success then
            print("SUCCESS! All " .. count .. " crafts done.")

            for i = 1, 16 do
                turtle.select(i)
                turtle.dropDown()
            end

            rednet.send(id, "OK:" .. count)
        end
    end
end
