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
                                            yield()
                                        end

                                        -- read data from data stream
                                        gpio_callback = function()
                                            local data = json_parse(data_stream)
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
                                                    yield()
                                                end
                                                add_line("dATA SENT.")
                                                key_lock = false
                                                program_running = false
                                                break
                                            elseif #keys_buffer>0 and find_char_in_string(keys_buffer, "n") then
                                                add_line("yOU HAVE CHOSEN TO CANCEL.")
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

    current_path = "/"
    current_drive = "c:"
    current_dir = files[current_drive][current_path]
end

function check_permissions(target)
    local dir = get_dir_from_path(current_path)
    if target.permissions == "all" then
        return true
    else
        if target.permissions == user then
            return true
        end
    end
    return false
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