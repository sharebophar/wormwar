--[[ Utility Functions ]]


---------------------------------------------------------------------------
-- Broadcast messages to screen
-- 广播消息到屏幕中央
---------------------------------------------------------------------------
function BroadcastMessage( sMessage, fDuration )
	local centerMessage = {
		message = sMessage,
		duration = fDuration
	}
	FireGameEvent( "show_center_message", centerMessage )
end

---------------------------------------------------------------------------
-- GetRandomElement
-- 获取表中的随机元素，start_index 默认为1
---------------------------------------------------------------------------
function GetRandomElement( table,start_index )
	start_index = start_index or 1
	if start_index > #table then
		return nil
	end
	local nRandomIndex = RandomInt( start_index, #table )
    local randomElement = table[ nRandomIndex ]
    return randomElement
end

---------------------------------------------------------------------------
-- ShuffledList
-- 对列表洗牌，打乱里面的元素;
-- PS：如果每次GetRandomElement前打乱一次表格，则即便伪随机得出来的数值可能随机性会更强一些
---------------------------------------------------------------------------
function ShuffledList( orig_list )
	local list = shallowcopy( orig_list )
	local result = {}
	local count = #list
	for i = 1, count do
		local pick = RandomInt( 1, #list )
		result[ #result + 1 ] = list[ pick ]
		table.remove( list, pick )
	end
	return result
end

---------------------------------------------------------------------------
-- string.starts
-- 判定字符串 string 是否以 start 开头
---------------------------------------------------------------------------
function string.starts( string, start )
   return string.sub( string, 1, string.len( start ) ) == start
end

---------------------------------------------------------------------------
-- string.split
-- 切分字符串 str 到数组中，sep 为分隔符
---------------------------------------------------------------------------
function string.split( str, sep )
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

---------------------------------------------------------------------------
-- shallowcopy
-- 复制一个表中的键值对 到一个新表，并返回这个新表，浅拷贝
---------------------------------------------------------------------------
function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---------------------------------------------------------------------------
-- Table functions
---------------------------------------------------------------------------
-- 打印表格，可以在调试的时候查看一个表格中的数据是否正确
function PrintTable( t, indent )
	-- print( "PrintTable( t, indent ): " )
	if type(t) ~= "table" then return end
	indent = indent or "  "
	for k,v in pairs( t ) do
		if type( v ) == "table" then
			if ( v ~= t ) then
				print( indent .. tostring( k ) .. ":\n" .. indent .. "{" )
				PrintTable( v, indent .. "  " )
				print( indent .. "}" )
			end
		else
		print( indent .. tostring( k ) .. ":" .. tostring(v) )
		end
	end
end

-- 查找一个表格中是否包含某个key,不包含时返回nil
function TableFindKey( table, val )
	if table == nil then
		print( "nil" )
		return nil
	end

	for k, v in pairs( table ) do
		if v == val then
			return k
		end
	end
	return nil
end

-- 返回表的长度
function TableLength( t )
	local nCount = 0
	for _ in pairs( t ) do
		nCount = nCount + 1
	end
	return nCount
end