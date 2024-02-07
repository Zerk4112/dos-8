-- coroutines.lua
--
-- A collection of coroutine utility functions for PICO-8.
--
-- Functions:
--   
--
-- Usage:
--  #include coroutines.lua
-- function _init()
--     update_routine = make_cr(function()
--         while true do
--             printh('hello world')
--             yields(30)
--         end
--     end, coroutines)
--
--     draw_routine = make_cr(function()
--         while true do
--             circfill(rnd(128), rnd(128), 1, 7)
--             yield()
--         end
--     end, aroutines)
-- end
--
-- function _update()
--     poke_crs(coroutines)
--     manage_pauses()
-- end
--
-- function _draw()
--     cls()
--     poke_crs(aroutines)
-- end
--

-->8 
-- constants
coroutines = {}
aroutines = {}
anim_paise = false

-->8
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
