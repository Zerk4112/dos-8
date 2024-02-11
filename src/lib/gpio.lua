

function init_gpio()
    printh("initializing gpio")
    control_pin = 0
    fetch_pin = 1
    error_pin = 4
    data_pins = {}
    for i=8, 127 do
        add(data_pins, i)
    end
    
    clk_pin = 2
    control_mode = 0
    modes = {
        "idle",
        "receive",
        "send",
        "fetch"
    }
    data_stream = ""
    gpio_callback = function() printh("processing data_stream: "..data_stream) end -- default callback
    clear_pins(true)
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
    -- clear the clock pin
    poke(0x5f80 + clk_pin, 255)
    
end


function gpio_update()
    if peek(0x5f80 + error_pin) == 1 then
        clear_pins(true)
        throw_bsod("unable to fetch data from bbs", false)
    end
    local prev_mode = control_mode
    control_mode = peek(0x5f80 + control_pin)
    if control_mode == 0 then
    elseif control_mode == 1 and prev_mode==control_mode then
        receive_data()
    elseif control_mode == 2 and prev_mode==control_mode then
        send_data()
    elseif control_mode == 3 and prev_mode==control_mode then
        printh("asking for data_stream from javascript")
        if (peek(0x5f80 + fetch_pin)==0) poke(0x5f80 + fetch_pin, 255) -- switch to receive mode
    elseif control_mode == 4 and prev_mode==control_mode then
        printh("javascript has sent data_stream, processing it")
    end
end

function read_data()
    local data = {}
    for i=8, 127 do
        if peek(0x5f80 + i) ~= 255 then
            add(data, {
                pin = i,
                value = peek(0x5f80 + i)
            })
        end
    end
    return data
end

function receive_data()
    local data = read_data()
    local clk_val = peek(0x5f80 + clk_pin)
    if #data>0 and clk_val==255 then
        for i=1, #data do
            printh("received data async: " .. data[i].value.. " on pin: " .. data[i].pin)
            data_stream = data_stream .. allowed_keys[data[i].value+1]
            poke(0x5f80 + data[i].pin, 255)
        end
    elseif clk_val ~= 255 then
        printh("receive is finished, switching back to idle mode")
        gpio_callback()
        data_stream = ""
        
        poke(0x5f80 + control_pin, 0)
    end
end

function send_data()
    if #data_stream>0 and peek(0x5f80 + clk_pin) == 0 then
        for i=8, 127 do
            if #data_stream == 0 then
                break
            end
            local data = sub(data_stream, 1, 1)
            data_stream = sub(data_stream, 2)
            printh("sending data: " .. data ..", index: " .. get_index_of_key(data) .. ", on pin: " .. i)
            poke(0x5f80 + i, get_index_of_key(data))
        end
        poke(0x5f80 + clk_pin, 255)
    elseif #data_stream == 0 and peek(0x5f80 + clk_pin) == 0 then
        printh("no more data to send")
        clear_pins()
        poke(0x5f80 + control_pin, 0)
    end
end
