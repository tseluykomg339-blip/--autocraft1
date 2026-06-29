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

-- Функция для выкидывания предметов
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
    
    if msg == "CRAFT" then
        turtle.refuel()
        
        print("Attempting one craft...")
        if turtle.craft() then
            print("SUCCESS! Dropping items...")
            dropAll()
            rednet.send(id, "OK")
        else
            print("CRAFT FAILED!")
            rednet.send(id, "FAIL")
        end
    end
end
