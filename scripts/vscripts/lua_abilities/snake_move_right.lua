require( "utility_functions" )

snake_move_right = class({})

function snake_move_right:OnSpellStart()
	local caster = self:GetCaster()
	-- 按键按下时修改角色朝向
	local vector = caster:GetForwardVector()
	vector.x = 1
	vector.y = 0
	vector.z = 0
	caster:SetForwardVector(vector)
end