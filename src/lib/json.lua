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
	local i = 0
	for k,v in pairs(_t) do
		i+=1
		printh("i: "..i.."/ #_t: "..len(_t).." k: "..k.." v: "..v)
		if type(v)=='table' then
			stringified = stringified..'"'..k..'":{ '
			stringified = stringified..table_print(v, '')
			stringified = stringified..'}, '
		else
			local s = ","
			if (i==len(_t)) s = ""
			stringified = stringified..'"'..k..'": "'..v..'"'..s
		end
	end
	if (r==nil) stringified = stringified..'}'
	return stringified
end

function len(_t)
	local i = 0
	for k,v in pairs(_t) do
		i+=1
	end
	return i
end