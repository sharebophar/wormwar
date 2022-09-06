require( "utility_functions" )

snake_move_down = class({})

function snake_move_down:OnSpellStart()
	local caster = self:GetCaster()
	-- 按键按下时修改角色朝向
	local vector = caster:GetForwardVector()
	vector.x = 0
	vector.y = -1
	vector.z = 0
	caster:SetForwardVector(vector)
end