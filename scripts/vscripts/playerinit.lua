


function initplayerstats()

   local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','') 
   math.randomseed(tonumber(timeTxt))
   PlayerStats={}
   --[[player_id=1
       ...
       player_id=10
     ]]
   for i=1,10 do
     PlayerStats[i]={}  --每个玩家的数据包
   end
 
   --初始化刷怪
  local entity_leftUp = Entities:FindByName(nil,"spawn_area_leftUp") --找到左上的实体
  origin_leftUp = entity_leftUp:GetAbsOrigin()

  local entity_rightDown=Entities:FindByName(nil,"spawn_area_rightDown") --找到左上的实体
  origin_rightDown = entity_rightDown:GetAbsOrigin()

  --刷5个羊 3个牛 1个火人
  createunit("yang")
  createunit("yang")
  createunit("yang")
  createunit("yang")
  createunit("yang")

  createunit("niu")
  createunit("niu")
  createunit("niu")

  createunit("huoren")


end


function createunit(unitname)
  local location=Vector(math.random(origin_rightDown.x-origin_leftUp.x)+origin_leftUp.x,math.random(origin_rightDown.y-origin_leftUp.y)+origin_leftUp.y,origin_rightDown.z)
  local unit=CreateUnitByName(unitname, location, true, nil, nil, DOTA_TEAM_NEUTRALS)
  unit:SetContext("name",unitname,0)
end

-- 计算两个单位之间的距离
function CalcDistanceBetweenUnit(unit1,unit2)
	local position1 = unit1:GetOrigin()
	local position2 = unit2:GetOrigin()
	return math.sqrt(math.pow(position1.x-position2.x,2) + math.pow(position1.y-position2.y,2) + math.pow(position1.z-position2.z,2))
end

--[[玩家的数据结构
{
	[0]={
		['init'] = true, // 是否被初始化
		['body'] = { // group中是每个单位的实例，加body_index字段是因为unit死亡后无法获得它的任何属性，也就无法判定该unit在body中的位置
			[1] = {['unit'] = hero_unit,['body_index'] = 1},
			[2] = {['unit'] = followed_unit1,['body_index'] = 2},
			[3] = {['unit'] = followed_unit2,['body_index'] = 3},
			...
		}
	},
	[1]={
		//同上
	}
	...
}
]]
function CreateBody(player_id)
	local body_length = #(PlayerStats[player_id]['body'])
	local followed_index = body_length
	local followed_unit = PlayerStats[player_id]['body'][followed_index]['unit']
	local forwardVector = followed_unit:GetForwardVector()
	local position = followed_unit:GetAbsOrigin()
	local new_position = position-forwardVector*100
	--这里这个new_position 受地形或单位影响有不能创建的可能，我们需要找一个确定可以创建的点来创建
	local hero_unit = PlayerStats[player_id]['body'][1]['unit']
	local bCanFindPath = GridNav:CanFindPath( hero_unit:GetOrigin(), new_position )
	while not bCanFindPath do
		local _position = hero_unit:GetOrigin() + RandomVector( RandomFloat( 0, 100 ) )
		bCanFindPath = GridNav:CanFindPath( hero_unit:GetOrigin(), _position )
		if (bCanFindPath) then
			new_position = _position
		end
	end
	--------------------------------
	local new_unit=CreateUnitByName("littlebug", new_position, true, nil, nil, followed_unit:GetTeam())
	if new_unit == nil then
		print("littlebug创建失败，position:"..new_position)
		return
	end
	new_unit:SetForwardVector(forwardVector)
	--new_unit:SetControllableByPlayer(player_id, true)
	-- 每个小强的逻辑都是跟随前一个单位，DoUniqueString 保证每个单位有独立的Timer
	local curBodyThinkTimer = DoUniqueString("bodyThinkTimer")
	table.insert(PlayerStats[player_id]['body'],{['unit']=new_unit,['body_index']=body_length+1,['bodyThinkTimer'] = curBodyThinkTimer})
	
	GameRules:GetGameModeEntity():SetContextThink(curBodyThinkTimer,
	function ()
		-- 前面有逐帧的Think保证数据正常
		if new_unit:IsNull() or new_unit:GetHealth() == 0 then
			print("当前结点丢失，直接跳过，body_index为："..(body_length+1))
			return nil
		end
		
		-- 如果都没有丢失，这个时候重新获取跟随目标（因为处理丢失异常后，可能出现不是跟随上一个单位的问题）
		local unit_index = GetUnitIndex(player_id,new_unit)
		-- 测试unit表为空的情况
		if PlayerStats[player_id]['body'][unit_index-1] == nil then
			print("测试unit表为空的情况：unit_index:"..unit_index)
			PrintTable(PlayerStats[player_id]['body'])
		end
		local follow_unit = PlayerStats[player_id]['body'][unit_index-1]['unit']
		-- 测试 follow_unit 为空的情况
		if follow_unit == nil then
			print("测试unit表为空的情况：unit_index:"..unit_index)
			PrintTable(PlayerStats[player_id]['body'][unit_index-1])
		end
		-- 修改一下移动速度，如果距离前一个单位过远，则提高他的基础移动速度
		if  CalcDistanceBetweenUnit(follow_unit,new_unit) > 100 then
			new_unit:SetBaseMoveSpeed(450)
		else
			new_unit:SetBaseMoveSpeed(310)
		end
		-- 单位朝前一个单位移动
		new_unit:MoveToNPC(follow_unit)
		return 0.2
	 end,0) 
end	

-- 获取某个小强躯干的结点索引
function GetUnitIndex(player_id,unit)
	local body_data = PlayerStats[player_id]['body']
	for i,v in ipairs(body_data) do
		-- 不能因为两个单位都死亡就将其判定为同一个位置
		--if v == unit or (v:IsNull() and unit:IsNull()) then
		if v.unit == unit then
			if i<0 then
				print("unitInex:"..i)
			end
			return i
		end
	end
	-- 找不到时，查看单位的情况
	if unit:IsNull() then
		print("查找的单位为空") -- 最后因为这个原因导致返回-1
	else
		print("查找的单位不为空，entindex:"..unit:entindex())
	end
	return -1
end

-- 清除所有非法数据，更新 body_index
function ClearAllInvalid(player_id)
	local body_data = PlayerStats[player_id]['body']
	local body_length = #body_data
	for i=body_length,1,-1 do
		local unit = body_data[i]['unit']
		-- 发现跟随逻辑有个延迟，必须等尸体消失后才跟随，所以判定应该为死亡后就跟随
		if unit:IsNull() or unit:GetHealth() == 0 then
			local curBodyThinkTimer = body_data[i]['bodyThinkTimer']
			GameRules:GetGameModeEntity():SetContextThink(curBabyThinkTimer,nil,0)
			table.remove(PlayerStats[player_id]['body'],i)
		else
			PlayerStats[player_id]['body'][i]['body_index'] = i
		end
	end
end

-- 杀死所有后续子结点
function KillAllChildren(player_id,unit_index)
	local group_length_old = #(PlayerStats[player_id]['body'])
	for i=group_length_old,unit_index,-1 do
		local unit = PlayerStats[player_id]['body'][i]['unit']
		if not unit:IsNull() then
			unit:ForceKill(true)
		end
		-- table.remove(PlayerStats[player_id]['body'],i)
	end
end

-- 杀死某个小强，并将其从玩家数据中移除
function KillBody(player_id,unit_index,remove_child)
	if unit_index < 0 then return end;
	remove_child = remove_child and true
	local body_data = PlayerStats[player_id]['body']
	local body_unit = body_data[unit_index]['unit']
	if not remove_child then
		if not body_unit:IsNull() then
			body_unit:ForceKill(true)
		end
		-- 单位自杀后，它后面的所有单位都会找不到前一个单位，所以需要把后面所有的单位的前一个跟随单位往前移动
		ClearAllInvalid(player_id,unit_index)
	else
		-- 如果是杀死所有后续子结点
		KillAllChildren(player_id,unit_index)
		ClearAllInvalid(player_id,unit_index)
	end
end

-- 杀死一半的身体
function KillHalfBody(player_id)
	local body_length = #(PlayerStats[player_id]['body'])
	-- 每隔一段时间杀死他身体的一半，头不计算在内，所以-1
	local half_body_length = math.ceil((body_length-1)/2)
	-- 计算索引时以头后开始算，所以+1
	local alive_unit_count = half_body_length + 1
	if alive_unit_count > 1 then
		-- 因为是从索引开始杀，所以是存活结点数再+1
		local begin_killed_index = alive_unit_count + 1
		print("杀死的开始索引为："..begin_killed_index)
		KillBody(player_id,begin_killed_index,true)
	end
end