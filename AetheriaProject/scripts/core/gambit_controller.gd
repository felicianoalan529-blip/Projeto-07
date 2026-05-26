extends Node

class_name GambitController

enum GambitCondition {
	ALLY_HP_BELOW,
	ALLY_STATUS_EFFECT,
	ENEMY_IN_RANGE,
	ENEMY_TYPE_IS,
	SELF_HP_BELOW,
	SELF_MP_BELOW,
	ALWAYS,
	NEVER,
	COMMAND_RECEIVED,
	TIME_OF_DAY
}

enum GambitAction {
	CAST_SPELL,
	USE_ITEM,
	MOVE_TO,
	ATTACK_TARGET,
	FOLLOW_TARGET,
	HOLD_POSITION,
	USE_SKILL,
	FLEE,
	BUFF_SELF,
	BUFF_ALLY
}

var gambit_slots: Array = []
var current_target: Node3D = null
var owner: Node3D = null
var is_active: bool = true

signal action_executed(action_name: String, target_name: String)
signal gambit_triggered(gambit_name: String)

func _ready():
	print("[GambitController] Initialized")

func setup_gambits(new_gambits: Array):
	gambit_slots = new_gambits
	print("[GambitController] Loaded ", gambit_slots.size(), " gambits")

func add_gambit(condition: GambitCondition, condition_value: Variant, action: GambitAction, action_value: Variant, priority: int = 0):
	var gambit = {
		"condition": condition,
		"condition_value": condition_value,
		"action": action,
		"action_value": action_value,
		"priority": priority,
		"cooldown": 0.0,
		"last_used": -999.0
	}
	gambit_slots.append(gambit)
	gambit_slots.sort_custom(func(a, b): return a.priority > b.priority)
	print("[GambitController] Added gambit: ", GambitCondition.keys()[condition], " -> ", GambitAction.keys()[action])

func evaluate_gambits(delta: float, allies: Array, enemies: Array):
	if not is_active:
		return
	
	for gambit in gambit_slots:
		if gambit.cooldown > 0:
			gambit.cooldown -= delta
			continue
		
		if check_condition(gambit.condition, gambit.condition_value, allies, enemies):
			execute_action(gambit.action, gambit.action_value, allies, enemies)
			gambit.last_used = Time.get_ticks_msec() / 1000.0
			gambit.cooldown = 2.0 # Default cooldown
			emit_signal("gambit_triggered", GambitCondition.keys()[gambit.condition])
			break # Only execute one gambit per evaluation cycle

func check_condition(condition: GambitCondition, value: Variant, allies: Array, enemies: Array) -> bool:
	match condition:
		GambitCondition.ALLY_HP_BELOW:
			for ally in allies:
				if ally.has_method("get_health_percent"):
					if ally.get_health_percent() < value:
						return true
		
		GambitCondition.ENEMY_IN_RANGE:
			if current_target and owner:
				var distance = owner.global_position.distance_to(current_target.global_position)
				return distance <= value
		
		GambitCondition.SELF_HP_BELOW:
			if owner and owner.has_method("get_health_percent"):
				return owner.get_health_percent() < value
		
		GambitCondition.SELF_MP_BELOW:
			if owner and owner.has_method("get_mana_percent"):
				return owner.get_mana_percent() < value
		
		GambitCondition.ALWAYS:
			return true
		
		GambitCondition.NEVER:
			return false
		
		GambitCondition.ENEMY_TYPE_IS:
			if current_target and current_target.has_method("get_enemy_type"):
				return current_target.get_enemy_type() == value
		
		GambitCondition.TIME_OF_DAY:
			if GameManager.instance:
				var time = GameManager.instance.time_of_day
				if value == "day":
					return time >= 0.25 and time <= 0.75
				elif value == "night":
					return time < 0.25 or time > 0.75
	
	return false

func execute_action(action: GambitAction, value: Variant, allies: Array, enemies: Array):
	match action:
		GambitAction.CAST_SPELL:
			if owner and owner.has_method("cast_spell"):
				var target = select_target(value, allies, enemies)
				if target:
					owner.cast_spell(value, target)
					emit_signal("action_executed", "Cast Spell", target.name)
		
		GambitAction.USE_ITEM:
			if owner and owner.has_method("use_item"):
				owner.use_item(value)
				emit_signal("action_executed", "Use Item", value)
		
		GambitAction.ATTACK_TARGET:
			if current_target:
				if owner and owner.has_method("perform_attack"):
					owner.perform_attack(current_target)
					emit_signal("action_executed", "Attack", current_target.name)
		
		GambitAction.FOLLOW_TARGET:
			if owner and value is Node3D:
				# Follow logic would be implemented here
				emit_signal("action_executed", "Follow", value.name)
		
		GambitAction.HOLD_POSITION:
			emit_signal("action_executed", "Hold Position", "")
		
		GambitAction.BUFF_SELF:
			if owner and owner.has_method("cast_spell"):
				owner.cast_spell(value, owner)
				emit_signal("action_executed", "Buff Self", value)
		
		GambitAction.BUFF_ALLY:
			var target = select_lowest_hp_ally(allies)
			if target and owner and owner.has_method("cast_spell"):
				owner.cast_spell(value, target)
				emit_signal("action_executed", "Buff Ally", target.name)

func select_target(criteria: Variant, allies: Array, enemies: Array) -> Node3D:
	if criteria == "nearest":
		return get_nearest_enemy(enemies)
	elif criteria == "lowest_hp":
		return get_lowest_hp_enemy(enemies)
	elif criteria == "current":
		return current_target
	elif criteria is Node3D:
		return criteria
	
	return current_target

func get_nearest_enemy(enemies: Array) -> Node3D:
	if enemies.is_empty() or not owner:
		return null
	
	var nearest = null
	var min_distance = INF
	
	for enemy in enemies:
		var dist = owner.global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest = enemy
	
	return nearest

func get_lowest_hp_enemy(enemies: Array) -> Node3D:
	if enemies.is_empty():
		return null
	
	var lowest = null
	var min_hp = INF
	
	for enemy in enemies:
		if enemy.has_method("get_health_percent"):
			var hp = enemy.get_health_percent()
			if hp < min_hp:
				min_hp = hp
				lowest = enemy
	
	return lowest

func select_lowest_hp_ally(allies: Array) -> Node3D:
	if allies.is_empty():
		return null
	
	var lowest = null
	var min_hp = INF
	
	for ally in allies:
		if ally.has_method("get_health_percent"):
			var hp = ally.get_health_percent()
			if hp < min_hp:
				min_hp = hp
				lowest = ally
	
	return lowest

func set_target(new_target: Node3D):
	current_target = new_target
	print("[GambitController] Target set to: ", new_target.name if new_target else "None")

func clear_target():
	current_target = null

func toggle_active():
	is_active = !is_active
	print("[GambitController] Active: ", is_active)
