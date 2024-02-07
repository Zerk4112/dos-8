-- function made by samhocevar (https://www.lexaloffle.com/bbs/?uid=14958) on the lexaloffle bbs on a post called Direct access to sound "hardware" (https://www.lexaloffle.com/bbs/?tid=29382)
-- Updated to remove depreciated band function with & operator (https://pico-8.fandom.com/wiki/Band)
function fm_sfx(form,freq,vol,ch)
    if (state==nil) state={}
    local id=state[ch]
    if id==nil then
        id=flr(rnd(4))
        for k,v in pairs(state) do
            if v==id then state[k]=nil end
        end
    end 
    state[ch]=id
    local n=63-id
    local sfxaddr=0x3200+68*n
    local sfxbyte1 = (freq&63)+(form&3)*64
    local sfxbyte2 = (vol&7)*2+(form&4)/4
    poke(sfxaddr,sfxbyte1)
    poke(sfxaddr+1,sfxbyte2)
    poke2(sfxaddr+66,256)
    sfx(n,id)
end
