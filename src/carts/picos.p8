pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

#include ../lib/json.lua
#include ../lib/error_handling.lua
#include ../lib/mak.lua
#include ../lib/coroutines.lua
#include ../lib/gpio.lua


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
    user = nil
    pass = nil
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
                                    "    aRGUMENTS DEPEND ON LOADED PROGRAM."
                                },
                                func = function(self, args) 
                                    printh("running loaded program: "..tostr(loaded_program))
                                    if loaded_program == nil then
                                        add_line("nO PROGRAM LOADED.")
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
                                        add_line("nO FILE SPECIFIED.")
                                        sfx(1)
                                    elseif file == nil then
                                        add_line("fILE NOT FOUND.")
                                        sfx(1)
                                    elseif file.type ~= "exe" then
                                        add_line("nOT AN EXECUTABLE.")
                                        sfx(1)
                                    else
                                        loaded_program = file.func
                                        add_line("pROGRAM LOADED.")
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
                                    add_line(str)
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
                                        add_line(v.."  \t"..dir.contents[v].type, "")
                                    end
                                    for k, v in pairs(files) do
                                        if #v<=4 then
                                            add_line(v.."  \t"..dir.contents[v].type, "")
                                        else
                                            add_line(v.."  \t"..dir.contents[v].type, "")
                                        end
                                        print(v, 0, keys_y, 8)
                                    end
                                    add_line("", "")
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
                                        add_line("nO FILE SPECIFIED.")
                                        sfx(1)
                                        return
                                    elseif file == nil then
                                        add_line("fILE NOT FOUND.")
                                        sfx(1)
                                        return
                                    elseif file.type ~= "txt" then
                                        add_line("nOT A TEXT FILE.")
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
                                            add_line(v, "")
                                        end
                                        add_line("", "")

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
                                        add_line(current_drive..current_path)
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
                                            add_line("pATH SPECIFIED IS INVALID.")
                                            sfx(1)
                                            return
                                        elseif new_dir.type ~= "dir" then
                                            add_line("nOT A DIRECTORY.")
                                            sfx(1)
                                            return
                                        elseif check_permissions(new_dir) == false and new_dir.permissions then
                                            add_line("aCCESS dENIED.")
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
                                        add_line("nO FILE SPECIFIED.")
                                        sfx(1)
                                        return
                                    elseif file == nil then
                                        add_line("fILE NOT FOUND.")
                                        sfx(1)
                                        return
                                    elseif file.type ~= "txt" then
                                        add_line("nOT A TEXT FILE.")
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
                                        add_line("aVAILABLE COMMANDS:")
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
                                        add_line("","")
                                    else
                                        keys_history = {}
                                        keys_y = 16
                                        local com = files[current_drive]["/"].contents["bin"].contents[topic]
                                        if com == nil then
                                            add_line("cOMMAND NOT FOUND.")
                                            sfx(1)
                                            return
                                        end
                                        add_line("hELP FOR "..topic..":")
                                        for k, v in pairs(com.help_long) do
                                            local line = v
                                            if #line > 29 then
                                                local str1 = sub(line, 1, 29)
                                                local str2 = sub(line, 30, #line)
                                                add(keys_history, str1)
                                                add(keys_history, str2)
                                                keys_y+=8
                                            else
                                                add_line(line, "")
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
                                        
                                        add_line("fetching bbs data...")

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
                                            for comment in all(data) do
                                                local name = comment.name
                                                local message = comment.comment
                                                local timestamp = comment.timestamp
                                                -- wrap message at 29 characters, max 3 lines
                                                local lines = {}
                                                for i=1, #message, 29 do
                                                    add(lines, sub(message, i, i+28))
                                                end


                                                add_line("--------------------------------", "")
                                                add_line("nAME: \t"..name, "")
                                                add_line("tIME: \t"..timestamp, "")
                                                add_line("mESSAGE: ")
                                                for i=1, #lines do
                                                    add_line(lines[i], "")
                                                end


                                            keys_y += 8
                                            end
                                            add_line("--------------------------------", "")
                                            add_line("^^----messages----^^", "")

                                            add_line("uSE ARROW KEYS TO NAVIGATE", "")
                                            add_line("pRESS ANY OTHER KEY TO EXIT", "")
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
                                        add_line("yOU ARE ABOUT TO POST TO THE BBS", "")
                                        add_line("CONTINUE? (y/n)", "")
                                        while true do
                                            if #keys_buffer>0 and find_char_in_string(keys_buffer, "y") then
                                                local data = {}
                                                sfx(1)
                                                spkeys_prompt="nAME: "
                                                keys_buffer=""
                                                while true do
                                                    if #keys_buffer>10 then
                                                        keys_buffer = sub(keys_buffer, 1, 10)
                                                    end
                                                    if #keys_buffer>0 and key_pressed==2 then
                                                        add_line("nAME: "..keys_buffer, "")
                                                        data.name = keys_buffer
                                                        keys_buffer = ""
                                                        break
                                                    end
                                                    yield()
                                                end
                                                
                                                -- spkeys_prompt="mESSAGE: "
                                                spkeys_prompt=""
                                                add_line("mESSAGE: ", "")
                                                while true do
                                                    if #keys_buffer>0 and key_pressed==2 then
                                                        local lines = word_wrap()
                                                        for i=1, #lines do
                                                            add_line(lines[i], "")
                                                        end
                                                        data.message = keys_buffer
                                                        keys_buffer = ""
                                                        
                                                        break
                                                    end
                                                    yield()
                                                end
                                                spkeys_prompt=""
                                                add_line("iS THIS CORRECT? y/n", "")
                                                while true do
                                                    if #keys_buffer>0 and find_char_in_string(keys_buffer, "y") then
                                                        add_line("pOST CONFIRMED.")
                                                        keys_buffer = ""

                                                        break
                                                    elseif #keys_buffer>0 and find_char_in_string(keys_buffer, "n") then
                                                        add_line("pOST CANCELLED.")
                                                        keys_buffer = ""

                                                        key_lock = false
                                                        program_running = false
                                                        return
                                                    end
                                                    yield()
                                                end
                                                -- send data to bbs
                                                add_line("sENDING DATA...")
                                                data_stream = table_print(data)
                                                poke(0x5f80 + control_pin,2)
                                                poke(0x5f80 + clk_pin,0)
                                                while peek(0x5f80 + control_pin) == 2 do
                                                    printh("waiting for target to receive")
                                                    yield()
                                                end
                                                add_line("dATA SENT.")
                                                key_lock = false
                                                program_running = false
                                                break
                                            elseif #keys_buffer>0 and find_char_in_string(keys_buffer, "n") then
                                                add_line("yOU HAVE CHOSEN TO CANCEL.")
                                                keys_y += 16
                                                key_lock = false
                                                program_running = false
                                                return
                                            elseif #keys_buffer>0 and (not find_char_in_string(keys_buffer, "n") or #keys_buffer>0 and find_char_in_string(keys_buffer, "y")) then
                                                keys_buffer=""
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
