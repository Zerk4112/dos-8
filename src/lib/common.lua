function table_stringify(t)
    local s = "{"
    for k, v in pairs(t) do
        if type(k) == "string" then
            s = s .. k .. "="
        end
        if type(v) == "table" then
            s = s .. stringify(v)
        else
            if type(v) == "string" then
                s = s .. "\"" .. v .. "\""
            else
                s = s .. tostring(v)
            end
            -- s = s .. tostring(v)
        end
        s = s .. ","
    end
    s = s .. "}"
    return s
end
