if peripheral.getType("right") == "modem" then
    rednet.open("right")
    print("Wireless Modem OPENED")
else
    print("ERROR: No modem in RIGHT hand!")
end

-- Проверка: а есть ли верстак?
if not turtle.craft then
    print("ERROR: This is NOT a Crafting Turtle!")
end

while true do
    print("Waiting for signal...")
    local id, msg = rednet.receive()
    
    print("RECEIVED: " .. tostring(msg) .. " from " .. id)
    
    if msg == "CRAFT" then
        -- Принудительная заправка
        turtle.refuel()
        
        print("Attempting to craft...")
        if turtle.craft() then
            print("SUCCESS! Dropping items...")
            for i = 1, 16 do
                turtle.select(i)
                turtle.dropDown()
            end
            rednet.send(id, "OK")
        else
            print("CRAFT FAILED! Check recipe.")
            rednet.send(id, "FAIL")
        end
    end
end
