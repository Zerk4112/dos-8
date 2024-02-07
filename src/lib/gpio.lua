

function init_gpio()
    printh("initializing gpio")
    control_pin = 0
    data_pin = 1
    data_pins = {}
    for i=8, 127 do
        add(data_pins, i)
    end
    -- reset all pins
    clear_pins(true)
    clk_pin = 2
    control_mode = 0
    modes = {
        "idle",
        "receive",
        "send",
    }
    data_stream = "this is a test sentence"
    gpio_callback = function() printh("processing data_stream: "..data_stream) end

    -- set data pin high
    -- poke(0x5f80 + data_pin, 255)
    -- create routine for updating gpio
    gpio_routine = make_cr(function()
        while true do
            gpio_update()
            yield()
        end
    end, coroutines)
end

function get_index_of_key(key)
    for i=1, #allowed_keys do
        if allowed_keys[i] == key then
            return i
        end
    end
    return -1
end

function clear_pins(_ctrl)
    if _ctrl ~= nil then
        for i=0, 7 do
            poke(0x5f80 + i, 0)
        end
    end
    
    for i=8, 127 do
        poke(0x5f80 + i, 255)
    end
    
end


function gpio_update()
    local prev_mode = control_mode
    control_mode = peek(0x5f80 + control_pin)
    if control_mode == 0 then
        -- printh("nothing is happening, waiting for input")
    elseif control_mode == 1 and prev_mode==control_mode then
        -- printh("receiving data")
        receive_data()
    elseif control_mode == 2 and prev_mode==control_mode then
        -- printh("sending data")
        send_data()
    end
end

function read_data()
    local data = {}
    for i=1, #data_pins do
        if peek(0x5f80 + data_pins[i]) ~= 255 then
            add(data, {
                pin = data_pins[i],
                value = peek(0x5f80 + data_pins[i])
            })
        end
    end
    return data
end

function receive_data()
    -- local data = peek(0x5f80 + data_pin)
    local data = read_data()
    printh("received data: " .. #data)
    local clk_val = peek(0x5f80 + clk_pin)
    if #data>0 and clk_val==255 then
        for i=1, #data do
            printh("received data async: " .. data[i].value.. " on pin: " .. data[i].pin)
            data_stream = data_stream .. allowed_keys[data[i].value+1]
            poke(0x5f80 + data[i].pin, 255)
        end
        -- local letter = allowed_keys[data+1]
        -- printh("received data: " .. letter)
        -- data_stream = data_stream .. letter
        -- poke(0x5f80 + data_pin, 255)
    elseif clk_val ~= 255 then
        printh("receive is finished, switching back to idle mode")
        gpio_callback()
        data_stream = ""
        
        poke(0x5f80 + control_pin, 0)
    end
    -- data_stream = data_stream .. data
end

function send_data()
    if #data_stream>0 and peek(0x5f80 + clk_pin) == 0 then
        for i=1, #data_pins do
            if #data_stream == 0 then
                break
            end
            local data = sub(data_stream, 1, 1)
            data_stream = sub(data_stream, 2)
            printh("sending data: " .. data)
            poke(0x5f80 + data_pins[i], get_index_of_key(data))
        end
        -- local next_letter = sub(data_stream, 1, 1)
        -- data_stream = sub(data_stream, 2)
        -- printh("sending data: " .. next_letter)
        -- poke(0x5f80 + data_pin, get_index_of_key(next_letter))
        poke(0x5f80 + clk_pin, 255)
    elseif #data_stream == 0 then
        printh("no more data to send")
        clear_pins()
        -- poke(0x5f80 + clk_pin, 255)
        poke(0x5f80 + data_pin, 0)
        poke(0x5f80 + control_pin, 0)
    end
    -- local data = string.sub(data_stream, 1, 1)
    -- data_stream = string.sub(data_stream, 2)
    -- poke(0x5f80 + data_pin, data)
    -- printh("sent data: " .. data)
end
