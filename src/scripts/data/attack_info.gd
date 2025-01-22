class_name AttackInfo

enum AttackType{
	BULLET = 0,
	MELEE = 1
}

var damage : float = 0.0
var attack_type : AttackType = AttackType.BULLET
var knock_back_vector : Vector3 = Vector3.ZERO
var attacker : Node3D = null
var receiver : Node3D = null
var origin : Vector3 = Vector3.ZERO
var hit_point : Vector3 = Vector3.ZERO

# Init template
	#var atk_info = AttackInfo.new()
	#atk_info.damage = #damage
	#atk_info.attack_type = #attack_type
	#atk_info.knock_back_vector = #knock_back_vector
	#atk_info.attacker = #ttacker
	#atk_info.receiver = #receiver
	#atk_info.origin = #origin
	#atk_info.hit_point = #hit_point

func duplicate() -> AttackInfo:
	var new_atk_info = AttackInfo.new()
	new_atk_info.damage = damage
	new_atk_info.attack_type = attack_type
	new_atk_info.knock_back_vector = knock_back_vector
	new_atk_info.attacker = attacker
	new_atk_info.receiver = receiver
	new_atk_info.origin = origin
	new_atk_info.hit_point = hit_point
	return new_atk_info 
