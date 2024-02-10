pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-->8 
-- constants
coroutines = {}
aroutines = {}
anim_paise = false
-- functions
function create_pause(n, callback, _cp)
    local cp = _cp or false
    if not anim_pause then
        local routine = make_cr(function()
            if (n>0) yields(n)
            if callback then
                callback()
            end
        end)
        add(pause_queue, routine)
    end
end

function manage_pauses()
    for pause in all(pause_queue) do
        if costatus(pause)=='dead' then
            del(pause_queue, pause)
        end
    end
    if #pause_queue==0 then
        anim_pause = false
    else
        anim_pause = true
    end
end

function make_cr(func, _t)
    local t = _t or coroutines
    local co = cocreate(func)
    add(t, co)
    return co
end

function poke_crs(_t)
    local t = _t or coroutines
    for i, routine in pairs(t) do
        poke_cr(routine)
    end
end

function poke_cr(cr, param)
    local a,e
    if costatus(cr) then
        if param then
            a,e = coresume(cr, param)
        else
            a,e = coresume(cr, param)
        end
        if (e) printh('COROUTINE EXCEPTION: '..e) throw_bsod(e)
    end
    if costatus(cr)=='dead' then
        del(aroutines, cr)
        del(coroutines, cr)
    end
end

function yields(n)
    for i=1,n do
        yield()
    end
end



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
    -- printh("keys_init")
    keys_history = {}
    keys_buffer = ""
    keys_pressed = false
    keys_released = false
    keys_x = 0
    keys_y = 0
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
                    printh("checking user")
                    local user_str = keys_buffer
                    printh("user: "..user_str)
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
                    printh("password: "..pass_str)
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
                        add(keys_history, "pASSWORD: "..pass_str)
                        add(keys_history, "pASSWORD INCORRECT")
                        add(keys_history, "")
                        keys_buffer = ""
                        keys_y+=24
                        user = nil
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
                        add(keys_history, "bAD COMMAND OR FILE NAME")
                        add(keys_history, "")
                        keys_y+=16
                        sfx(1)
                    end
                    chk_scroll()
                elseif key_lock then
                    printh("mak: key lock is on")
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

function draw_k()
    if user ~= nil and pass ~= nil then
        if program_running==false then
            print(current_drive..current_path..">"..keys_buffer, keys_x, keys_y+scroll_y, 7)
        elseif program_running then
            if (spkeys_prompt==nil) spkeys_prompt=""
            print(spkeys_prompt..keys_buffer, keys_x, keys_y+scroll_y, 7)
        end
        -- draw keys history above the input like in linux terminal in reverse order
        
    else
        if user == nil and pass == nil then
            print("uSER: "..keys_buffer, keys_x, keys_y, 7)
        elseif user ~= nil and pass == nil then
            print("pASSWORD: "..keys_buffer, keys_x, keys_y, 7)
        end
    end

    -- if program_running == false then
        for i=#keys_history,1,-1 do
            print(keys_history[i], keys_x, keys_y-8*(#keys_history-i+1)+scroll_y, 7)
        end
    -- end

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



-- math.lua
--
-- A collection of math utility functions for PICO-8.
--
-- Functions:
--   randib(a,b) --> integer
--   aget(x1,y1,x2,y2) --> float
--   dst(x0,y0,x1,y1) --> float
--   sqr(x) --> float
--
-- Usage:
--   #include "lib/math.lua"
--   local x = randib(1, 10)
--   local y = randb(1, 10)
--   local d = dst(0, 0, 10, 10)
--   local s = sqr(10)
--   local a = aget(0, 0, 10, 10)

function aget(x1,y1,x2,y2) return atan2(-(x1-x2), -(y1-y2)) end

function dst(x0,y0,x1,y1)
    local dx=(x0-x1)/64
    local dy=(y0-y1)/64
    local dsq=dx*dx+dy*dy
    if(dsq<0) return 32767.99999
    return sqrt(dsq)*64
end

function sqr(x) return x*x end

function randib(a,b)
    return flr(rnd(b-a+1))+a
end

function to_degrees(angle)
    return angle*360
end

function map_range(value, original_min, original_max, target_min, target_max)
    local scale = (value - original_min) / (original_max - original_min)
    return target_min + (target_max - target_min) * scale
end

-- function round_float(num, dp)
--     local mult = 10 ^ dp
--     return flr(num * mult) / mult
-- end

function round_float(num, decimal_places)
    local integer_part = flr(num)
    local multiplier = 10 ^ decimal_places
    local decimal_part = flr(num * multiplier) % multiplier
    local decimal_str = tostring(decimal_part)
    while #decimal_str < decimal_places do
        decimal_str = "0" .. decimal_str
    end
    return integer_part .. "." .. decimal_str
end

function randfb(min, max)
    return rnd(max - min) + min
end


function throw_bsod(message, _reset)
    bsod = true
    if _reset ~=nil then
        reset = false
    else
        reset = true
    end
    add(bsod_message, "eRROR "..message.." HAS OCCURRED.")
    if (reset) add(bsod_message, "dos-8 HAS BEEN SHUT DOWN TO PREVENT DAMAGE TO YOUR COMPUTER.")
    sfx(0)
end

function init_bsod()
    bsod = false
    bsod_message = {}
    bsod_x, bsod_y = 0, 16
end

function update_bsod()
    if stat(30) and reset then
        yields(60)
        run()
    else
        if stat(30) then

            bsod = false
            bsod_message = {}
        end
    end
end
function draw_bsod()
    if bsod then
        bsod_x=0
        bsod_y=26
        cls(12)
        rectfill(bsod_x+49, bsod_y, bsod_x+75, bsod_y+8, 6)
        print("sYSTEM", bsod_x+51, bsod_y+2, 12)
        bsod_y+=14

        for i = 1, #bsod_message do
            local line = bsod_message[i]
            local line_max = 32
            
            if #line > 32 then
                local line1 = sub(line, 1, 32)
                
                local line2 = sub(line, 33, #line)
                print(line1, 0, bsod_y, 6)
                print(line2, 0, bsod_y + 8, 6)
                bsod_y+=16
            else
                print(line, 0, bsod_y, 6)
                bsod_y+=8
            end
            bsod_y+=8
        end

        bsod_y+=16
        if reset then
            print("pRESS ANY KEY TO REBOOT", 20, bsod_y, 6)
        else
            print("pRESS ANY KEY TO CONTINUE", 16, bsod_y, 6)
        end
        
    end
end




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
    gpio_callback = function() printh("processing data_stream: "..data_stream) end
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
        printh("error detected, clearing pins")
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
        printh("received data: " .. #data)

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
            
            printh("pin value: " .. peek(0x5f80 + i))
        end
        poke(0x5f80 + clk_pin, 255)
    elseif #data_stream == 0 and peek(0x5f80 + clk_pin) == 0 then
        printh("no more data to send")
        clear_pins()
        poke(0x5f80 + control_pin, 0)
    end
end



local function error(str)
	printh("error"..str)
	assert()
end

local function match(s,tokens)
	for i=1,#tokens do
		if(s==sub(tokens,i,i)) return true
	end
	return false
end
local function skip_delim(str, pos, delim, err_if_missing)
 if sub(str,pos,pos)!=delim then
  if(err_if_missing) error('expected '..delim..' near position '.. pos)
  return pos,false
 end
 return pos+1,true
end
local function parse_str_val(str, pos, val)
	val=val or ''
	if pos>#str then
		error('end of input found while parsing string.')
	end
	local c=sub(str,pos,pos)
	if(c=='"') return val,pos+1
	return parse_str_val(str,pos+1,val..c)
end
local function parse_num_val(str,pos,val)
	val=val or ''
	if pos>#str then
		error('end of input found while parsing string.')
	end
	local c=sub(str,pos,pos)
	if(not match(c,"-0123456789.x")) return val+0,pos
	return parse_num_val(str,pos+1,val..c)
end
-- public values and functions.
local table_delims={
	['{']="}",
	['[']="]"}
-- register json context here
local _g={
	['true']=true,
	['false']=false}

function json_parse(str, pos, end_delim)
	pos=pos or 1
	if(pos>#str) error('reached unexpected end of input.')
	local first=sub(str,pos,pos)
	if match(first,"{[") then
		local obj,key,delim_found={},true,true
		pos+=1
		while true do
			key,pos=json_parse(str, pos, table_delims[first])
			if(key==nil) return obj,pos
			if not delim_found then error('comma missing between table items.') end
			if first=="{" then
				pos=skip_delim(str,pos,':',true)  -- true -> error if missing.
				obj[key],pos=json_parse(str,pos)
			else
				add(obj,key)
			end
			pos,delim_found=skip_delim(str, pos, ',')
  end
 elseif first=='"' then
 	-- parse a string.
  return parse_str_val(str,pos+1)
 elseif match(first,"-0123456789") then
 	-- parse a number.
  return parse_num_val(str, pos)
 elseif first==end_delim then  -- end of an object or array.
  return nil,pos+1
 else  -- parse true, false
  for lit_str,lit_val in pairs(_g) do
   local lit_end=pos+#lit_str-1
   if sub(str,pos,lit_end)==lit_str then return lit_val,lit_end+1 end
  end
  local pos_info_str = 'position ' .. pos .. ': ' .. sub(str, pos, pos + 10)
  error('invalid json syntax starting at ' .. pos_info_str)
	end
end

function table_print(_t, r)
	local stringified = ''
	if (r==nil) stringified = '{'
	printh('table_print')
	local i = 0
	for k,v in pairs(_t) do
		i+=1
		printh("i: "..i.."/ #_t: "..len(_t).." k: "..k.." v: "..v)
		if type(v)=='table' then
			printh('"'..k..'":{ ')
			stringified = stringified..'"'..k..'":{ '
			stringified = stringified..table_print(v, '')
			printh('}, ')
			stringified = stringified..'}, '
		else
			local s = ","
			if (i==len(_t)) s = ""
			printh('"'..k..'": "'..v..'"'..s)
			stringified = stringified..'"'..k..'": "'..v..'"'..s
		end
	end
	if (r==nil) stringified = stringified..'}'
	printh('stringified: '..stringified)
	return stringified
end

function len(_t)
	local i = 0
	for k,v in pairs(_t) do
		i+=1
	end
	return i
end



function find_char_in_string(string, char)
    for i=1, #string do
        if sub(string, i, i) == char then
            return true
        end
    end
    return false
end

function get_dir_from_path(path)
    local breadcrumbs = split(path, "/")
    for k, v in pairs(breadcrumbs) do
        if v == "" then
            breadcrumbs[k] = "/"
        end
    end
    -- remove trailing /
    if breadcrumbs[#breadcrumbs] == "/" then
        breadcrumbs[#breadcrumbs] = nil
    end
    local dir = files[current_drive]['/']
    if #breadcrumbs > 1 then
        for i = 2, #breadcrumbs do
            dir = dir.contents[breadcrumbs[i]]
        end
    end
    return dir
end

function _init()
    init_gpio()
    init_bsod()
    init_filesystem()
    program_running = false
    program_callback = nil
    loaded_program = nil
    loaded_disk = nil
    user = "zerk"
    pass = "dev"
    more = false
    os_name = "dos-8"
    bkgr_clr = 0
    debug = false
    menuitem(2, "debug", function() debug = not debug end)
    keys_init()
    scroll_x = 0
    scroll_y = 0
    accounts = {
        guest = {
            password = ""
        },
        zerk = {
            password = "dev"
        }
    }


    current_path = "/"
    current_drive = "c:"
    current_dir = files[current_drive][current_path]
end

function init_disks()
    disks = {
        ["picos"] = {
            type = "dir",
            contents = {
                ["picos"] = {
                    type = "com",
                    func = init_picos
                },
                ["mouse"] = {
                    type = "com",
                    func = mouse_init
                }
            }
        }
    }
end

function check_permissions(target)
    local dir = get_dir_from_path(current_path)
    if target.permissions == "all" then
        return true
    else
        printh("target.permissions: "..target.permissions)
        printh("current dir permissions: "..dir.permissions)
        if target.permissions == user then
            return true
        end
    end
    return false
end

function init_filesystem()
    files = {
        ["a:"] = {
            type = nil, -- nil type signifies that there is no disk in the drive
            contents = nil
        },
        ["c:"] = {
            ["/"] = {
                type = "dir",
                permissions = "all",
                contents = {
                    ["bin"] = {
                        type = "dir",
                        permissions = "all",
                        contents = {
                            ["run"] = {
                                type="com",
                                help = "rUN LOADED PROGRAM",
                                help_long = {
                                    "rUN LOADED PROGRAM : rUN",
                                    "    rUNS THE PROGRAM LOADED INTO MEMORY.",
                                    "    nO ARGUMENTS."
                                },
                                func = function(self, args) 
                                    printh("running loaded program: "..tostr(loaded_program))
                                    if loaded_program == nil then
                                        add(keys_history, "nO PROGRAM LOADED.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    else
                                        loaded_program(args)
                                    end
                                end
                            },
                            ["logout"] = {
                                type = "com",
                                help = "lOGOUT",
                                help_long = {
                                    "lOGOUT : lOGOUT",
                                    "    lOGS OUT THE CURRENT USER.",
                                    "    nO ARGUMENTS."
                                },
                                func = function() 
                                    keys_history = {}
                                    keys_y = -8

                                    user = nil
                                    pass = nil
                                    current_path = ""
                                    current_drive = "user:"
                                end
                            },
                            ["load"] = {
                                type = "com",
                                help = "lOAD A PROGRAM",
                                help_long = {
                                    "lOAD A PROGRAM : lOAD <FILENAME>",
                                    "    lOADS A PROGRAM INTO MEMORY.",
                                    "    aRGUMENTS:",
                                    "        <FILENAME> - THE NAME OF THE FILE TO LOAD."
                                },
                                func = function(self, filename) 
                                    local dir = get_dir_from_path(current_path)
                                    local file = dir.contents[filename]
                                    if filename == "" then
                                        add(keys_history, "nO FILE SPECIFIED.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    elseif file == nil then
                                        add(keys_history, "fILE NOT FOUND.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    elseif file.type ~= "exe" then
                                        add(keys_history, "nOT AN EXECUTABLE.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    else
                                        loaded_program = file.func
                                    end
                                end
                            },
                            ["echo"] = {
                                type = "com",
                                help = "eCHO A STRING",
                                help_long = {
                                    "eCHO A STRING : eCHO <STRING>",
                                    "    eCHOES A STRING TO THE SCREEN.",
                                    "    eXAMPLE: eCHO HELLO, WORLD!"
                                },
                                func = function(self, ...)
                                    local args = {...}
                                    local str = ""
                                    for k, v in pairs(args) do
                                        str = str..v.." "
                                    end
                                    add(keys_history, str)
                                    add(keys_history, "")
                                    keys_y += 16
                                end
                            },
                            ["dir"] = {
                                type = "com",
                                help = "lIST CURRENT DIRECTORY",
                                help_long = {
                                    "lIST FILES AND DIRECTORIES : dIR",
                                    "    lISTS FILES AND DIRECTORIES IN THE CURRENT DIRECTORY.",
                                    "    nO ARGUMENTS."
                                },
                                func = function() 
    
                                    local dir = get_dir_from_path(current_path)
                                    local dirs = {}
                                    local files = {}
                                    for k, v in pairs(dir.contents) do
                                        if v.type == "dir" then
                                            add(dirs, k)
                                        else
                                            add(files, k)
                                        end
                                    end
                                    for k, v in pairs(dirs) do
                                        add(keys_history, v.."  \t"..dir.contents[v].type)
                                        keys_y += 8
                                    end
                                    for k, v in pairs(files) do
                                        if #v<=4 then
                                            add(keys_history, v.."  \t"..dir.contents[v].type)
                                        else
                                            add(keys_history, v.."\t"..dir.contents[v].type)
                                        end
                                        print(v, 0, keys_y, 8)
                                        keys_y += 8
                                    end
                                    add(keys_history, "")
                                    keys_y += 8
                                end
                            },
                            ["type"] = {
                                type = "com",
                                help = "dISPLAY FILE CONTENTS",
                                help_long = {
                                    "dISPLAY FILE CONTENTS : tYPE <FILENAME>",
                                    "    dISPLAYS THE CONTENTS OF A FILE.",
                                    "    aRGUMENTS:",
                                    "        <FILENAME> - THE NAME OF THE FILE TO DISPLAY."
                                },
                                func = function(s, filename) 
                                    local dir = get_dir_from_path(current_path)
                                    local file = dir.contents[filename]
                                    if filename == "" then
                                        add(keys_history, "nO FILE SPECIFIED.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    elseif file == nil then
                                        add(keys_history, "fILE NOT FOUND.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    elseif file.type ~= "txt" then
                                        add(keys_history, "nOT A TEXT FILE.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    else
                                        local lines = {}

                                        local line = file.contents
                                        if #line > 29 then
                                            while #line > 0 do
                                                local str = sub(line, 1, 29)
                                                add(lines, str)
                                                line = sub(line, 30, #line)
                                            end
                                        else
                                            add(lines, line)
                                        end

                                        for k, v in pairs(lines) do
                                            add(keys_history, v)
                                            keys_y += 8
                                        end
                                        add(keys_history, "")
                                        keys_y += 8

                                    end
                                end
                            },
                            ["cd"] = {
                                type = "com",
                                help = "cHANGE DIRECTORY",
                                help_long = {
                                    "cHANGE DIRECTORY : cD <DIR>",
                                    "    cHANGES THE CURRENT DIRECTORY TO THE SPECIFIED DIRECTORY.",
                                    "    nO ARGUMENTS WILL RETURN TO THE ROOT DIRECTORY.",
                                    "    .. WILL MOVE UP ONE DIRECTORY.",
                                    "    / WILL MOVE TO THE ROOT DIRECTORY."
                                },
                                func = function(self, dir) 
                                    if dir == nil or dir == "" or dir == "." then
                                        add(keys_history, current_drive..current_path)
                                        add(keys_history, "")
                                        keys_y += 16
                                    elseif dir == ".." then
                                        if current_path == "/" then
                                            return
                                        end
                                        local breadcrumbs = split(current_path, "/")
                                        
                                        for k, v in pairs(breadcrumbs) do
                                            if v == "" then
                                                breadcrumbs[k] = "/"
                                            end
                                        end
                                        for i = #breadcrumbs, #breadcrumbs-1, -1 do
                                            breadcrumbs[i] = nil
                                        end
                                        local new_path = ""
                                        for i=1, #breadcrumbs do
                                            if breadcrumbs[i] == "/" then
                                                new_path = new_path..breadcrumbs[i]
                                            else
                                                new_path = new_path..breadcrumbs[i].."/"
                                            end
                                        end
                                        current_path = new_path
                                    elseif dir == "/" then
                                        current_path = "/"
                                    else
                                        local new_path = current_path..dir
                                        local new_dir = get_dir_from_path(new_path)
                                        printh("new_dir: "..tostr(new_dir))
                                        printh("new_path: "..tostr(new_path))
                                        if new_dir == nil then
                                            add(keys_history, "pATH SPECIFIED IS INVALID.")
                                            add(keys_history, "")
                                            keys_y += 16
                                            sfx(1)
                                            return
                                        elseif new_dir.type ~= "dir" then
                                            add(keys_history, "nOT A DIRECTORY.")
                                            add(keys_history, "")
                                            keys_y += 16
                                            sfx(1)
                                            return
                                        elseif check_permissions(new_dir) == false and new_dir.permissions then
                                            add(keys_history, "aCCESS dENIED.")
                                            add(keys_history, "")
                                            keys_y += 16
                                            sfx(1)
                                            return
                                        end
                                        current_path = current_path..dir.."/"
                                    end
                                end
                            },
                            ["edit"] = {
                                type = "exe",
                                help = "eDIT A FILE",
                                help_long = {
                                    "eDIT A FILE : eDIT <FILENAME>",
                                    "eDITS A FILE IN THE CURRENT DIRECTORY.",
                                    "aRGUMENTS:",
                                    "    <FILENAME> - THE NAME OF THE FILE TO EDIT."
                                },
                                func = function(t,filename) 
                                    local dir = get_dir_from_path(current_path)
                                    local file = dir.contents[filename]
                                    if filename == "" then
                                        add(keys_history, "nO FILE SPECIFIED.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    elseif file == nil then
                                        add(keys_history, "fILE NOT FOUND.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    elseif file.type ~= "txt" then
                                        add(keys_history, "nOT A TEXT FILE.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    else
                                        local hex = ""
                                        for i=1, 8 do
                                            hex = hex..sub("0123456789abcdef", flr(rnd(16))+1, flr(rnd(16))+1)
                                        end
                                        printh("hex: "..hex)

                                        throw_bsod("read error in sector 0x")
                                    end
                                end
                            },
                            ["cls"] = {
                                type = "com",
                                help = "cLEAR THE SCREEN",
                                help_long = {
                                    "cLEAR THE SCREEN",
                                    "nO ARGUMENTS.",
                                },
                                func = function() 
                                    keys_history = {}
                                    keys_y = -8
                                end
                            },
                            ["help"] = {
                                type = "com",
                                help = "dISPLAY HELP",
                                help_long = {
                                    "dISPLAY HELP : hELP <COMMAND>",
                                    "    dISPLAYS HELP FOR A SPECIFIC COMMAND.",
                                    "    aRGUMENTS:",
                                    "        <COMMAND> - THE COMMAND TO DISPLAY HELP FOR.",
                                    "","","","",
                                    "    dID YOU REALLY NEED HELP WITH THIS?"
                                },
                                func = function(self, topic)
                                    if topic == "" then
                                        keys_history = {}
                                        keys_y = -8
                                        add(keys_history, "aVAILABLE COMMANDS:")
                                        add(keys_history, "")
                                        keys_y += 16
                                        local coms = files[current_drive]["/"].contents["bin"].contents
                                        for k, v in pairs(coms) do
                                            if v.type == "com" then
                                                
                                                if v.help == nil then
                                                    add(keys_history, k)
                                                else
                                                    local str = k.."  \t"..v.help
                                                    if #str > 29 then
                                                        local str1 = sub(str, 1, 29)
                                                        local str2 = sub(str, 30, #str)
                                                        add(keys_history, str1)
                                                        add(keys_history, str2)
                                                        keys_y+=8
                                                    else
                                                        add(keys_history, str)
                                                    end
                                                end
                                                keys_y += 8
                                            end
                                        end
                                        add(keys_history, "")
                                        keys_y += 8
                                    else
                                        keys_history = {}
                                        keys_y = 16
                                        local com = files[current_drive]["/"].contents["bin"].contents[topic]
                                        if com == nil then
                                            add(keys_history, "cOMMAND NOT FOUND.")
                                            add(keys_history, "")
                                            keys_y += 16
                                            sfx(1)
                                            return
                                        end
                                        add(keys_history, "hELP FOR "..topic..":")
                                        add(keys_history, "")
                                        keys_y += 16
                                        for k, v in pairs(com.help_long) do
                                            local line = v
                                            if #line > 29 then
                                                local str1 = sub(line, 1, 29)
                                                local str2 = sub(line, 30, #line)
                                                add(keys_history, str1)
                                                add(keys_history, str2)
                                                keys_y+=8
                                            else
                                                add(keys_history, line)
                                                keys_y += 8
                                            end
                                        end
                                        add(keys_history, "")
                                    end
                                end
                            }
                        }
                    },
                    ["picos"] = {
                        type = "dir",
                        permissions = "zerk",
                        contents = {
                            ["picos"] = {
                                type = "exe",
                                func = function()
                                    throw_bsod("corruption detected, please re-install",false)
                                end
                            },
                            ["mouse"] = {
                                type = "exe",
                                func = mouse_init
                            },
                            ["receive"] = {
                                type = "exe",
                                func = function()
                                    if data_stream == "" then
                                        add(keys_history, "nO MESSAGE RECEIVED.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    end
                                    printh("receiving message")
                                    add(keys_history, data_stream)
                                    keys_y += 8

                                    add(keys_history, "mESSAGE RECEIVED.")
                                    add(keys_history, "")
                                    keys_y += 16
                                    data_stream = ""
                                end
                            },
                            ["send"] = {
                                type = "exe",
                                func = function(m)
                                    printh("sending message: "..tostr(m))
                                    if m=="" then
                                        add(keys_history, "nO MESSAGE SPECIFIED.")
                                        add(keys_history, "")
                                        keys_y += 16
                                        sfx(1)
                                        return
                                    end
                                    data_stream = m
                                    add(keys_history, "mESSAGE SENT.")
                                    add(keys_history, "")
                                    keys_y += 16

                                    poke(0x5f80 + control_pin,2)
                                    poke(0x5f80 + clk_pin,0)
                                end
                            }
                        }
                    },
                    ["home"] = {
                        type = "dir",
                        home = true,
                        permissions = "all",
                        contents = {
                            ["guest"] = {
                                type = "dir",
                                permissions = "all",
                                contents = {
                                    ["notes"] = {
                                        type = "txt",
                                        contents = "dos-8 is a simple fantasy os for the fantasy console pico-8. it is a work in progress and is not intended to be a fully functional operating system. it is a fun project to work on and is a way to learn about programming and operating systems. don't touch my account. keep out!"
                                    }
                                }
                            },
                            ["zerk"] = {
                                type = "dir",
                                permissions = "zerk",
                                contents = {
                                    ["notes"] = {
                                        type = "txt",
                                        contents = "if you're reading this, then you're either me, or you've acquired the password to my account. either way, test picos! if there is corruption, reinstall from the floppy disk..."
                                    }
                                }
                            }
                        }
                    },
                    ["bbs"] = {
                        type = "exe",
                        func = function(mode)
                            program_running = true
                            local printing = true
                            sfx(1)
                            
                            local cr = make_cr(function()
                                    if mode == "list" then
                                        keys_history = {}
                                        keys_y = 8
                                        
                                        add(keys_history, "fetching bbs data...")
                                        add(keys_history, "")
                                        keys_y += 16

                                        key_lock = true
                                        poke(0x5f80 + control_pin,3) 
                                        yields(120) 
                                        while peek(0x5f80 + fetch_pin) == 255 do
                                            printh("waiting for data")
                                            yield()
                                        end

                                        -- read data from data stream
                                        printh("data ready, setting callback")
                                        gpio_callback = function()
                                            printh("processing with new callback function")
                                            local data = json_parse(data_stream)
                                            printh("data_stream: "..data_stream)
                                            add(keys_history, "lOADING bbs bROWSER...")


                                            yields(30)

                                            keys_history = {}
                                            keys_y = -8
                                            -- add(keys_history, "bbs eNTRIES:")
                                            for comment in all(data) do
                                                local name = comment.name
                                                local message = comment.comment
                                                local timestamp = comment.timestamp
                                                -- wrap message at 29 characters, max 3 lines
                                                local lines = {}
                                                for i=1, #message, 29 do
                                                    add(lines, sub(message, i, i+28))
                                                end


                                                add(keys_history, "--------------------------------")
                                                keys_y+=8
                                                add(keys_history, name.."  \t"..timestamp)
                                                add(keys_history, "")
                                                keys_y += 16
                                                for i=1, #lines do
                                                    add(keys_history, lines[i])
                                                    keys_y += 8
                                                end


                                            keys_y += 8
                                            end
                                            add(keys_history, "--------------------------------")
                                            keys_y += 8
                                            add(keys_history, "^^----messages----^^")
                                            add(keys_history, "uSE ARROW KEYS TO NAVIGATE")
                                            add(keys_history, "pRESS ANY OTHER KEY TO EXIT")
                                            keys_y += 24
                                            local cy = keys_y
                                            scroll_y-=keys_y-120
                                            key_lock=true
                                            while true do
                                                if btnp(3) then
                                                    scroll_y -= 8
                                                elseif btnp(2) then
                                                    scroll_y += 8
                                                elseif btnp(0) then
                                                    scroll_x -= 8
                                                elseif btnp(1) then
                                                    scroll_x += 8
                                                elseif key_pressed >0 then
                                                    printh("key was pressed, break loop!")
                                                    keys_history = {}
                                                    keys_y = 0
                                                    scroll_y = 0
                                                    scroll_x = 0
                                                    key_lock = false
                                                    keys_buffer=""
                                                    break
                                                end
                                                yield()
                                            end
                                            program_running = false
                                        end
                                        poke(0x5f80 + clk_pin,0)
                                    elseif mode == "post" then
                                        keys_history = {}
                                        keys_y=0
                                        scroll_y=0
                                        key_lock = true
                                        -- prompt user to confirm that they want to post
                                        add(keys_history, "yOU ARE ABOUT TO POST TO THE BBS")
                                        add(keys_history, "CONTINUE? (y/n)")
                                        keys_y += 32
                                        while true do
                                            if #keys_buffer>0 and find_char_in_string(keys_buffer, "y") then
                                                local data = {}
                                                sfx(1)
                                                spkeys_prompt="nAME: "
                                                keys_buffer=""
                                                while true do
                                                    if #keys_buffer>0 and key_pressed==2 then
                                                        add(keys_history, "nAME: "..keys_buffer)
                                                        keys_y += 8
                                                        data.name = keys_buffer
                                                        keys_buffer = ""
                                                        break
                                                    end
                                                    yield()
                                                end
                                                spkeys_prompt="mESSAGE: "
                                                while true do
                                                    if #keys_buffer>0 and key_pressed==2 then
                                                        add(keys_history, "mESSAGE: "..keys_buffer)
                                                        keys_y+=8
                                                        data.message = keys_buffer
                                                        keys_buffer = ""
                                                        
                                                        break
                                                    end
                                                    yield()
                                                end
                                                spkeys_prompt=""
                                                add(keys_history, "iS THIS CORRECT? y/n")
                                                keys_y += 8
                                                while true do
                                                    if #keys_buffer>0 and find_char_in_string(keys_buffer, "y") then
                                                        add(keys_history, "pOST CONFIRMED.")
                                                        add(keys_history, "")
                                                        keys_buffer = ""
                                                        keys_y += 16

                                                        break
                                                    elseif #keys_buffer>0 and find_char_in_string(keys_buffer, "n") then
                                                        add(keys_history, "pOST CANCELLED.")
                                                        add(keys_history, "")
                                                        keys_buffer = ""
                                                        keys_y += 16
                                                        key_lock = false
                                                        program_running = false
                                                        return
                                                    end
                                                    yield()
                                                end
                                                -- send data to bbs
                                                add(keys_history, "sENDING DATA...")
                                                add(keys_history, "")
                                                keys_y += 16
                                                data_stream = table_print(data)
                                                poke(0x5f80 + control_pin,2)
                                                poke(0x5f80 + clk_pin,0)
                                                while peek(0x5f80 + control_pin) == 2 do
                                                    printh("waiting for target to receive")
                                                    yield()
                                                end
                                                add(keys_history, "dATA SENT.")
                                                add(keys_history, "")
                                                keys_y += 16
                                                key_lock = false
                                                program_running = false
                                                break
                                            elseif #keys_buffer>0 and find_char_in_string(keys_buffer, "n") then
                                                add(keys_history, "yOU HAVE CHOSEN TO CANCEL.")
                                                add(keys_history, "")
                                                keys_buffer = ""
                                                keys_y += 16
                                                key_lock = false
                                                program_running = false
                                                return
                                            end
                                            yield()
                                        end
                                        key_lock = false
                                    else
                                        add(keys_history, "iNVALID ARG SPECIFIED.")
                                        if (keys_y<120) keys_y += 8
                                        sfx(1)
                                        program_running=false
                                    end
                                    yield()
                                    
                            end, coroutines)
                            
                        end
                    },
                }
            }
        },
    }
end

function _update60()
    poke(0x5f30,1) -- suppress pause


    poke_crs(coroutines)
    update_bsod()
    if #keys_history>128 and not bsod then
        throw_bsod("buffer overflow")
    end
end


function _draw()
    cls(bkgr_clr)
    poke_crs(aroutines)
    if (m_on) draw_m()
    draw_bsod()

    
end

__gfx__
11100000001100000011100000000000011111100011110000111100000000000011110011110111111100011110000001100000011000001111000000000000
1711000000171000001771000011110011d77d11011dd1100017710000000000001771001ddd11711ddd1001ddd1000017100000017100001771000000000000
177110000017110000177710001777101d7117d111dddd111117711111111111111111111111d1711111d101111d100177111111117710111771110000000000
17771100111777101117777111177771171171711dddddd11777777117777771177777711dd111711dd11d117711d1177777d11d7777711d7777d10000000000
177771001717d7d11717d7d11717d7d117171171117777111dd77dd11dddddd11dddddd1111d1111111d1d111171d11d7777d11d7777d101d77d100000000000
1777d1001d777dd11d777dd11d777dd11d7117d11177d7111117711111111111111111111d1d1171171d1d117171d111d7111111117d11111dd1110000000000
177d110011dddd1111dddd1111dddd1111d77d110177d710111dd11111111111111771111111111111111111111111011d11111111d110177777710000000000
11111000011111100111111001111110011111100111111000111100000000000011110001111110011111101111110011100000011100111111110000000000
00110000001100000000111011111111011111100111111111111111011100000000111001111110011101100001100000011000000000000000000000000000
01d1111001710001011117111777777111d7771101ddddd11777777111711110011117111d7777d1117d17d1001771000017d100000000000000000000000000
1dd171711771010111d77771117777111dd11771111111d1177777711777771111777771177777711777d7711117711101777d10000000000000000000000000
1dd11711177101011d11171117d77d7111111171177771d117777771177777d11d777771177777711d7777711777777101777d10000000000000000000000000
1dd171711d710101117111d1177dd77117111111177771d11777777111711dd11dd117111d7777d111d777111d7777d101777d10000000000000000000000000
11d1111111d1000117777d111777777117711dd11dddd1111dddddd1111111d11d11111111771111011d7111177dd771177777d1000000000000000000000000
1111111011110000117111111111111111777d111111111111111111011111111111111001711000001111101dd11dd1111dd111000000000000000000000000
01110000011100000111111011111111011111101111110011111111000011100111000001110000000111001111111100111100000000000000000000000000
11000000111111100001101111011000111101101101111011100111111111110111111001111110000000000000000000000000000000000000000000000000
17100000177177100017117117117100177117101711771017711771177777711771177111711711111111101111111011111110000000000000000000000000
17710000177177100177d771177d7710177177101771771011777711117d7d111711117117711771171717111717111117111111000000000000000000000000
1777100017717710177d77711777d77117d777101777d710011771101117d1111111111111111111171717111717111117111111000000000000000000000000
177d1000177177101d71d771177d17d1177d7710177d771011777711011d71101111111111111111171717111717111117111111000000000000000000000000
17d110001771771011d11d7117d11d111771d71017d177101771177111d7dd111711117117711771111111111111111111111111000000000000000000000000
1d1100001dd1dd10011d11d11d11d11017711d101d1177101dd11dd11dddddd11771177111711711111111101111111011111110000000000000000000000000
11100000111111100011111111111100111101101101111011100111111111110111111001111110000000000000000000000000000000000000000000000000
__label__
07700000007077707770077007700770007070007770707077000000777077700770777000007770707077700770000007707070777077700000777070007770
70000700070070700700700070707000070007007070707070700000070070007000070000000700707007007000000070007070070007000000707070007000
70000000070077700700700070707770070000707700707070700000070077007770070000000700777007007770000077707770070007000000777070007700
70000700070070000700700070700070070007007070707070700000070070000070070000000700707007000070000000707070070007000000700070007000
07700000700070007770077077007700700070007070077070700000070077707700070000000700707077707700000077007070777007000000700077707770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000077707700770077707070000077700770000000000000000000000000000000000000000000000000000000000000
07000000700070707070707070700700000007007070707070007070000007007000000000000000000000000000000000000000000000000000000000000000
00700000770007007770707077000700000007007070707077000700000007007770000000000000000000000000000000000000000000000000000000000000
07000000700070707000707070700700000007007070707070007070000007000070000000000000000000000000000000000000000000000000000000000000
70000000777070707000770070700700000077707070777077707070070077007700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606000666066600660666000000660666066606660606066606660000066600000600066606660666060000000666066606660066066600000000000000000
60606000600060606000600000006000606060600600606060606000000060600000600060606060600060000000600006006060600006000000000000000000
66606000660066606660660000006000666066600600606066006600000066600000600066606600660060000000660006006600666006000000000000000000
60006000600060600060600000006000606060000600606060606000000060600000600060606060600060000000600006006060006006000000000000000000
60006660666060606600666000000660606060000600066060606660000060600000666060606660666066600000600066606060660006000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000007077707770077007700770007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000700070070700700700070707000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000070077700700700070707770070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000700070070000700700070700070070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000700070007770077077007700700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
190200002d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d040
000100002d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0402d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b6200662007620000000d61014610000001d6201f6200000024620266200a62000000000000362000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c6100662007620000000d61014610000000d6201f620000002b6202d6202362000000000001162000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000018610326203262000000226101d610000001d6201d62000000126200f6200e6200c6200a6100861008610000000000000000000000000000000000000000000000000000000000000000000000000000
00010000126102b6202a620000001561014610000001462012620000000c6200a6200a62000000000000362000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b620086200d620000002f610266100000027600106000000019600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000024620256201662000000156102661000000146000b6000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000463016620166200000015610146100000014600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
