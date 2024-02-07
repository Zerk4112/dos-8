entities = {}

function create_entity(...)
    local e = {
        x,y,w,h,sx,sy,sw,sh = ...,
    }
    add(entities, e)
    return e
end

