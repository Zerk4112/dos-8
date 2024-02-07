-- mak.lua
--
-- A collection of mouse utility functions for PICO-8.
--
-- Functions:
--   mouse_init() - initializes mouse coroutine (disabled by default)
--   upd_m() - updates mouse position and click state
--   draw_m() - draws mouse sprite
--   get_m_xy() - gets mouse x and y position
--   chk_m_clk() - checks mouse click and hold state
--
-- Usage:
--  #include coroutines.lua
-- function _init()
--    mouse_init()
-- end
--
-- function _update()
--     upd_m() (This is used if mouse_init() is disabled with m_cr=false)
-- end
--
-- function _draw()
--     cls()
--     draw_m()
-- end
--
-- Dependencies:
--   coroutines.lua

poke(0x5F2D, 0x1)
m_x,m_y = 0,0
m_on=false
k_on=false
m_cr = true
k_cur_blink = false
function keys_init()
    allowed_keys = {
        "a","b","c","d","e","f","g","h","i","j","k","l","m",
        "n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","-","=","[",
        "]","\\",";","'","`",",",".","/", " ", "!","@","#",
        "$","%","^","&","*","(",")","_","+","{","}","|",":",
        "\"","<",">","?","~","⁸","","\r"
    }
    -- printh("keys_init")
    keys_history = {}
    keys_buffer = ""
    keys_pressed = false
    keys_released = false
    keys_x = 0
    keys_y = 0
    k_on = true
    make_cr(function()
        k_on = true
        while true do
            upd_k()
            yield()
        end
    end)
    make_cr(function()
        while true do
            draw_k()
            yield()
        end
    end,aroutines)

    make_cr(function()
        while true do
            k_cur_blink = not k_cur_blink
            yields(15)
        end
    end,aroutines)
end

function in_table(t,v)
    for i=1,#t do
        if t[i] == v then
            return true
        end
    end
    return false
end

function upd_k()
    while stat(30) and not bsod do
        -- printh("key pressed")
        local pressed = stat(31)
        local chk_scroll = function(pass)
            keys_buffer = ""
            if keys_y<120 then
                if (pass==nil) keys_y+=8
            elseif keys_y>120 then
                keys_y = 120
            end
        end
        -- printh("pressed:"..pressed)
        if (pressed == "p" or pressed == "\r") poke(0x5f30,1) -- suppress pause
        if in_table(allowed_keys, pressed) then
            if pressed == "⁸" then -- backspace is pressed
                local sfx_num = flr(rnd(2)+57)
                sfx(sfx_num)
                
                keys_buffer = sub(keys_buffer, 1, #keys_buffer-1)
            
            elseif pressed == "\r" then -- enter is pressed
                local sfx_num = flr(rnd(2)+59)
                sfx(sfx_num)
                -- split the buffer into command and arguments by spaces, without using "find"
                if user == nil and pass == nil then
                    printh("checking user")
                    local user_str = keys_buffer
                    printh("user: "..user_str)
                    -- check if valid user
                    if accounts[user_str] then
                        printh("user found")
                        keys_buffer = ""
                        user = user_str
                        add(keys_history, "uSER: "..user_str)
                        keys_y+=8
                    
                    else
                        add(keys_history, "uSER: "..user_str)
                        add(keys_history, "uSER NOT FOUND")
                        add(keys_history, "")
                        keys_buffer = ""
                        keys_y+=24

                    end
                    chk_scroll(true)
                elseif user ~= nil and pass == nil then
                    printh("checking pass")
                    local pass_str = keys_buffer
                    printh("pass: "..pass_str)
                    -- check if valid pass
                    if accounts[user].password == pass_str then
                        printh("pass correct")
                        keys_buffer = ""
                        pass = pass_str
                        keys_history = {}
                        keys_y = 0
                        add(keys_history, "wELCOME "..user)
                        add(keys_history, "")
                        add(keys_history, "tODAYS DATE IS "..stat(91).."/"..stat(92).."/"..stat(90))
                        add(keys_history, "")
                        keys_y+=32
                        current_drive = "c:"
                        current_path = "/"
                        current_dir = files[current_drive]["/"]
                    else
                        printh("pass incorrect")
                        add(keys_history, "pASS: "..pass_str)
                        add(keys_history, "pASSWORD INCORRECT")
                        add(keys_history, "")
                        keys_buffer = ""
                        keys_y+=24
                        user = nil
                    end
                    chk_scroll(true)
                elseif user ~= nil and pass ~= nil then
                    local command = split(keys_buffer, " ")[1]
                    -- args is the rest of the string after the first space, which may contain multiple arguments separated by spaces
                    local args = sub(keys_buffer, #command+2, #keys_buffer)
                    -- local args = split(keys_buffer, " ")[2]
                    local func = files[current_drive]["/"]['contents']["bin"]['contents'][command]
                    add(keys_history, current_drive..current_path..">"..keys_buffer)
                    if keys_buffer == "" then
                        -- add(keys_history, current_drive..current_path..">")
                        -- printh("do nothing")
                    elseif func then
                        if args then
                            -- printh("running "..command.." with args "..args)
                            func:func(args)
                        else
                            -- printh("running "..command.." with no args")
                            func:func()
                        end
                    else
                        -- printh("Command not found")
                        add(keys_history, "bAD COMMAND OR FILE NAME")
                        add(keys_history, "")
                        keys_y+=16
                        sfx(1)
                        -- add(keys_history, "")

                    end
                    -- add(keys_history, "")
                    -- keys_buffer = ""
                    -- if keys_y<120 then
                    --     keys_y+=8
                    -- elseif keys_y>120 then
                    --     keys_y = 120
                    -- end
                    chk_scroll()
                end
            else
                keys_buffer = keys_buffer..pressed
                local sfx_num = flr(rnd(3)+61)
                sfx(sfx_num)
            end
        end
    end
    
end

function draw_k()
    if user ~= nil and pass ~= nil then
        print(current_drive..current_path..">"..keys_buffer, keys_x, keys_y, 7)
        -- draw keys history above the input like in linux terminal in reverse order
        
    else
        if user == nil and pass == nil then
            print("uSER: "..keys_buffer, keys_x, keys_y, 7)
        elseif user ~= nil and pass == nil then
            print("pASS: "..keys_buffer, keys_x, keys_y, 7)
        end
    end
    for i=#keys_history,1,-1 do
        print(keys_history[i], keys_x, keys_y-8*(#keys_history-i+1), 7)
    end

    -- draw cursor as red rectangle
    if k_cur_blink then
        if user ~= nil and pass ~= nil then
            local full_buffer = current_drive..current_path..">"..keys_buffer
            rectfill(keys_x+(4*#full_buffer), keys_y, keys_x+1+(4*#full_buffer+2), keys_y+4, 8)
        elseif user == nil and pass == nil then
            local full_buffer = "uSER: "..keys_buffer
            rectfill(keys_x+(4*#full_buffer), keys_y, keys_x+1+(4*#full_buffer+2), keys_y+4, 8)
        elseif user ~= nil and pass == nil then
            local full_buffer = "pASS: "..keys_buffer
            rectfill(keys_x+(4*#full_buffer), keys_y, keys_x+1+(4*#full_buffer+2), keys_y+4, 8)
        end
    end
    -- for i=1,#keys_history do
    --     print(keys_history[i], keys_x, keys_y-8*i, 7)
    -- end
end

function upd_m()
    get_m_xy()
    chk_m_clk()
end

function mouse_init()
    if m_cr then
        make_cr(function()
            m_on = true
            while true do
                upd_m()
                yield()
            end
        end)
    end
    
end

function get_m_xy()
    m_x, m_y = flr(stat(32)),flr(stat(33))
end

function chk_m_clk()
    if (m_clk==nil) then
        m_clk = false
        m_hld = false
    end

    if stat(34)==1 then
        if not m_clk and not m_hld then
            -- printh("mouse clicked")
            m_clk = true
            m_hld = true
            make_cr(function()
                -- printh("mouse held")
                local t = 0
                while m_hld do
                    t+=1
                    if t>6 or stat(34)==0 then
                        break
                    end
                    yield()
                end
                m_clk = false
            end)
        
        end
    else 
        m_hld = false
        m_clk = false
    end
end

function draw_m()
    spr(0, m_x, m_y, 1, 1, false, false)
end
