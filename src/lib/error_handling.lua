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
    -- poke(0x5f2d, 1)
    -- printh("checking for key press")
    if stat(30) and reset then

        yields(60)
        run()
    else
        if stat(30) then

            bsod = false

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

        -- for each line in bsod_message, print it to the screen using the x and y coordinates
        for i = 1, #bsod_message do
            -- wrap line if it's too long
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