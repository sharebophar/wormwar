-- Generated from template
require('playerinit')
require('utility_functions')

if WormWar == nil then
	WormWar = class({})
end

temp_flag=0

function PrecacheEveryThingFromKV( context )
	local kv_files = {"scripts/npc/npc_units_custom.txt","scripts/npc/npc_abilities_custom.txt","scripts/npc/npc_heroes_custom.txt","scripts/npc/npc_abilities_override.txt","npc_items_custom.txt"}
	for _, kv in pairs(kv_files) do
		local kvs = LoadKeyValues(kv)
		if kvs then
			print("BEGIN TO PRECACHE RESOURCE FROM: ", kv)
			PrecacheEverythingFromTable( context, kvs)
		end
	end
    print("done loading shiping")
end
function PrecacheEverythingFromTable( context, kvtable)
	for key, value in pairs(kvtable) do
		if type(value) == "table" then
			PrecacheEverythingFromTable( context, value )
		else
			if string.find(value, "vpcf") then
				PrecacheResource( "particle",  value, context)
				print("PRECACHE PARTICLE RESOURCE", value)
			end
			if string.find(value, "vmdl") then 	
				PrecacheResource( "model",  value, context)
				print("PRECACHE MODEL RESOURCE", value)
			end
			if string.find(value, "vsndevts") then
				PrecacheResource( "soundfile",  value, context)
				print("PRECACHE SOUND RESOURCE", value)
			end
		end
	end

   
end

function Precache( context )
	print("BEGIN TO PRECACHE RESOURCE")
	local time = GameRules:GetGameTime()
	PrecacheEveryThingFromKV( context )
	PrecacheResource("particle_folder", "particles/buildinghelper", context)
	PrecacheUnitByNameSync("npc_dota_hero_tinker", context)
	time = time - GameRules:GetGameTime()
	print("DONE PRECACHEING IN:"..tostring(time).."Seconds")
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = WormWar()
	GameRules.AddonTemplate:InitGameMode()
end

function WormWar:InitGameMode()
	print( "Template addon is loaded." )
	self._GameMode = GameRules:GetGameModeEntity()
  -- 禁用游戏内通告，类似谁获得了装备或者学习了哪个技能？
	self._GameMode:SetAnnouncerDisabled( true )
  -- 设置未探索的战争迷雾不可见，为false则开图，开图后小地图上和场景中的战争迷雾都会消失
	self._GameMode:SetUnseenFogOfWarEnabled( true )
  -- Set a fixed delay for all players to respawn after.
  -- 不明白
	self._GameMode:SetFixedRespawnTime( 4 )
	
  -- 设置每跳金币获得，这个跳的时间可以通过 SetGoldTickTime 设置
	GameRules:SetGoldPerTick( 0 )
  -- 设置游戏正式开始的时间，Dota里进入游戏后，前期有一个准备时间，会提示30秒后全面开战之类的
	GameRules:SetPreGameTime( 0 )
  -- 选择队伍界面的时间，为0时不显示界面直接跳过，填-1时为无限期时间
  -- 现在有bug，有界面选择的客户端逻辑时，填0会导致不能选角，得看一下和rpg_example的区别
	-- GameRules:SetCustomGameSetupTimeout( 0 ) -- skip the custom team UI with 0, or do indefinite duration with -1
  -- 自动开始游戏的等待时间
	GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
    if temp_flag==0 then
         initplayerstats()
         temp_flag=1
    end
	self._GameMode:SetThink( "OnThink", self, "GlobalThink", 20 )
    ListenToGameEvent('entity_killed', Dynamic_Wrap(WormWar, 'OnEntityKilled'), self)
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(WormWar, "OnNPCSpawned"), self)
end

-- Evaluate the state of the game
function WormWar:OnThink()
    --玩家初始化

	
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- 填一个测试用例，每隔一段时间杀死小强的随机一个身体部分
		if(PlayerStats and PlayerStats[1] and PlayerStats[1]['body'] ) then
		--[[ 每隔一段时间杀死一个随机身体结点，并自动连接上
			local random_unit = GetRandomElement(PlayerStats[1]['body'],2)
			if random_unit and random_unit['unit'] and not random_unit['unit']:IsNull() then
				print("每隔20秒强制删除一个身体")
				random_unit['unit']:ForceKill(true)
			end
		]]
		--杀死一半的尾巴
			-- KillHalfBody(1)
		end
		--print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 20
end

function WormWar:OnEntityKilled( keys )
    local unit = EntIndexToHScript(keys.entindex_killed)
    local label=unit:GetContext("name")


    --判断是不是羊或牛或小火人
    --如果是 重新刷新 新的单位
    --       或者增加一个指数 随时间增加增加 提高刷新新单位的几率 刷新单位的时候清零
    if label then
       if label=="yang" then
       	 createunit("yang")
       end
       if label=="niu" then
       	 createunit("niu")
       end
       if label=="huoren" then
       	 createunit("huoren")
       end	 
    end	

    
end

function WormWar:OnNPCSpawned( keys )
	local unit =  EntIndexToHScript(keys.entindex)
	
	if unit:IsHero() then
		local nPlayerID = unit:GetPlayerOwnerID()
		local player_id = nPlayerID + 1 -- 使索引遵循lua的惯例，所以+1了
		PlayerStats[player_id]['body']={}
		--PlayerStats[player_id]['group_length']=1
		PlayerStats[player_id]['body'][1]={['unit']=unit,['body_index']=1}
		-- 单次初始化内容
		if not PlayerStats[player_id]['init'] then
			PlayerStats[player_id]['init'] = true
			-- 锁定视角到自身英雄
			PlayerResource:SetCameraTarget( nPlayerID, unit )
			-- 强制选择自身英雄
			PlayerResource:SetOverrideSelectionEntity( nPlayerID, unit )
			-- 设置两次表示可靠金钱和不可靠金钱，Dota里不可靠金钱在死亡后会有损失
			PlayerResource:SetGold( nPlayerID, 0, false )
			PlayerResource:SetGold( nPlayerID, 0, true )
			-- 英雄升级，但不播放特效
			for i=1,6 do
				unit:HeroLevelUp( false )
			end
			-- 升级0和1号技能，0号技能是普攻，1是第一个技能，这里0和1是根据 npc_heroes_custom.txt 中配置的Ability1和Ability2决定的
			unit:UpgradeAbility( unit:GetAbilityByIndex( 0 ) )
			unit:UpgradeAbility( unit:GetAbilityByIndex( 1 ) )
			unit:UpgradeAbility( unit:GetAbilityByIndex( 2 ) )
			unit:UpgradeAbility( unit:GetAbilityByIndex( 3 ) )
			
			-- 清除脏数据，效率应该比身体部分的移动行为频率高
			self._GameMode:SetContextThink("ClearAllInvalid", 
			function()
				ClearAllInvalid(player_id)
				return 0
			end,0)
			
			-- 头部移动逻辑
			if unit:IsOwnedByAnyPlayer() then
				self._GameMode:SetContextThink("AutoMoveThink", 
				function()
					return self:OnAutoMoveThink(unit)
				end,0)
			end
		end
   end
end	

-- 自动移动逻辑，抽离出来给技能按钮调用
function WormWar:OnAutoMoveThink(unit)
	local nPlayerID = unit:GetPlayerOwnerID()
	local player_id = nPlayerID + 1
	local forward_vector=unit:GetForwardVector()
	--local truechaoxiang=forward_vector:Normalized()
	local position=unit:GetAbsOrigin()
	unit:MoveToPosition(position+forward_vector*500)

	local aroundit=FindUnitsInRadius(DOTA_TEAM_NEUTRALS, position, nil, 
									100,
									DOTA_UNIT_TARGET_TEAM_FRIENDLY,
									DOTA_UNIT_TARGET_ALL,
									DOTA_UNIT_TARGET_FLAG_NONE,
									FIND_ANY_ORDER,
									false)
	for k,v in pairs(aroundit) do
		local name_label=v:GetContext("name")
		if name_label then
			if name_label=="yang" then
				v:ForceKill(true)
				CreateBody(player_id)
			end
			if name_label=="niu" then
				v:ForceKill(true)
				CreateBody(player_id)
				CreateBody(player_id)
			end
			if name_label == "huoren" then
				v:ForceKill(true)
				KillHalfBody(player_id)
				BroadcastMessage("碰到了火人，掉了一半长度",5)
			end
		end	
	end
	return 0
end