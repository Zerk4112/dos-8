poke(0x5F2D, 0x1)
m_x,m_y = 0,0
m_on=false
m_cr = true
k_cur_blink = false
function keys_init()

    key_lock = false
    allowed_keys = {
        "a","b","c","d","e","f","g","h","i","j","k","l","m",
        "n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","-","=","[",
        "]","\\",";","'","`",",",".","/", " ", "!","@","#",
        "$","%","^","&","*","(",")","_","+","{","}","|",":",
        "\"","<",">","?","~","⁸","","\r"
    }
    keys_history = {}
    keys_buffer = ""
    keys_pressed = false
    keys_released = false
    keys_x = 0
    keys_y = 0
    scroll_x = 0
    scroll_y = 0
    make_cr(function()
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

function add_line(str, _s)
    local s = _s or false
    add(keys_history, str)
    keys_y+=8
    if not s then
        add(keys_history, "")
        keys_y+=8 
    end
end

function upd_k()
    if (key_pressed) key_pressed = 0 
    while stat(30) and not bsod do
        local pressed = stat(31)
        local chk_scroll = function(pass)
            keys_buffer = ""
            if keys_y<120 then
                if (pass==nil) keys_y+=8
            elseif keys_y>120 then
                keys_y = 120
            end
        end
        if (pressed == "p" or pressed == "\r") poke(0x5f30,1) -- suppress pause
        if in_table(allowed_keys, pressed) then
            key_pressed = 1
            if pressed == "⁸" then -- backspace is pressed
                local sfx_num = flr(rnd(2)+57)
                sfx(sfx_num)
                
                keys_buffer = sub(keys_buffer, 1, #keys_buffer-1)
            
            elseif pressed == "\r" then -- enter is pressed
                key_pressed = 2
                local sfx_num = flr(rnd(2)+59)
                sfx(sfx_num)
                if user == nil and pass == nil then
                    local user_str = keys_buffer
                    if accounts[user_str] then
                        keys_buffer = ""
                        user = user_str
                        add_line("uSER: "..user_str)
                    
                    else
                        add_line("uSER: "..user_str, true)
                        add_line("uSER NOT FOUND")
                        keys_buffer = ""

                    end
                    chk_scroll(true)
                elseif user ~= nil and pass == nil then
                    local pass_str = keys_buffer
                    -- check if valid pass
                    if accounts[user].password == pass_str then
                        keys_buffer = ""
                        pass = pass_str
                        keys_history = {}
                        keys_y = 0
                        add_line("wELCOME "..user)
                        add_line("tODAYS DATE IS "..stat(91).."/"..stat(92).."/"..stat(90))
                        current_drive = "c:"
                        current_path = "/"
                        current_dir = files[current_drive]["/"]
                    else
                        local pbuff = ""
                        for i=1,#keys_buffer do
                            pbuff = pbuff.."*"
                        end
                        add_line("pASSWORD: "..pbuff, true)
                        add_line("pASSWORD INCORRECT")

                        user = nil
                        keys_buffer = ""
                    end
                    chk_scroll(true)
                elseif user ~= nil and pass ~= nil and not key_lock then
                    local command = split(keys_buffer, " ")[1]
                    local args = sub(keys_buffer, #command+2, #keys_buffer)
                    local func = files[current_drive]["/"]['contents']["bin"]['contents'][command]
                    if (program_running==false) add(keys_history, current_drive..current_path..">"..keys_buffer)
                    if keys_buffer == "" then
                    elseif func then
                        if args then
                            func:func(args)
                        else
                            func:func()
                        end
                    else
                        add_line("bAD COMMAND OR FILE NAME")
                        sfx(1)
                    end
                    chk_scroll()
                elseif key_lock then
                    -- keys_buffer = keys_buffer..pressed
                end
            else
                keys_buffer = keys_buffer..pressed
                local sfx_num = flr(rnd(3)+61)
                sfx(sfx_num)
            end
        end
    end
    
end

function word_wrap(_w)
    local w = _w or 31
    local lines = {}
    local line = ""
    for i=1, #keys_buffer do
        line = line..sub(keys_buffer, i, i)
        if #line >w or i==#keys_buffer then
            add(lines, line)
            line = ""
        end
    end
    return lines
end

function draw_k()
    if user ~= nil and pass ~= nil then
        if program_running==false then
            print(current_drive..current_path..">"..keys_buffer, keys_x, keys_y+scroll_y, 7)
        elseif program_running then
            if (spkeys_prompt==nil) spkeys_prompt=""
            local lines = word_wrap()
            if (#lines>0 )print(spkeys_prompt..lines[1], keys_x, keys_y+scroll_y, 7)
            if #lines>1 then
                for i=2, #lines do
                    print(spkeys_prompt..lines[i], keys_x, keys_y+8*(i-1)+scroll_y, 7)
                end
            end
            if (#lines==0) print(spkeys_prompt..keys_buffer, keys_x, keys_y+scroll_y, 7)
        end
    else
        if user == nil and pass == nil then
            print("uSER: "..keys_buffer, keys_x, keys_y, 7)
        elseif user ~= nil and pass == nil then
        local pbuff = ""
        for i=1,#keys_buffer do
            pbuff = pbuff.."*"
        end
            print("pASSWORD: "..pbuff, keys_x, keys_y, 7)
        end
    end

        for i=#keys_history,1,-1 do
            print(keys_history[i], keys_x, keys_y-8*(#keys_history-i+1)+scroll_y, 7)
        end
    -- draw cursor as red rectangle
    if k_cur_blink then
        if program_running then
            local full_buffer = "> "..keys_buffer
        elseif user ~= nil and pass ~= nil then
            local full_buffer = current_drive..current_path..">"..keys_buffer
            rectfill(keys_x+(4*#full_buffer), keys_y+scroll_y, keys_x+1+(4*#full_buffer+2), keys_y+4+scroll_y, 8)
        elseif user == nil and pass == nil then
            local full_buffer = "uSER: "..keys_buffer
            rectfill(keys_x+(4*#full_buffer), keys_y+scroll_y, keys_x+1+(4*#full_buffer+2), keys_y+4+scroll_y, 8)
        elseif user ~= nil and pass == nil then
            local full_buffer = "pASSWORD: "..keys_buffer
            rectfill(keys_x+(4*#full_buffer), keys_y+scroll_y, keys_x+1+(4*#full_buffer+2), keys_y+4+scroll_y, 8)
        
        end
    end
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
            m_clk = true
            m_hld = true
            make_cr(function()
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

function find_char_in_string(string, char)
    for i=1, #string do
        if sub(string, i, i) == char then
            return true
        end
    end
    return false
end