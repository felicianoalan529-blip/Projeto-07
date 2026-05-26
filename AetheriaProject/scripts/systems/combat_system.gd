extends Node

class_name CombatSystem

enum DamageType {
	PHYSICAL,
	FIRE,
	WATER,
	EARTH,
	AIR,
	ARCANE,
	DIVINE,
	NECROTIC,
	NATURE,
	SPATIAL
}

enum AggroState {
	PASSIVE,
	ALERT,
	AGGROED
}

var registered_enemies: Array = []
var combat_log: Array = []

signal enemy_damaged(enemy: Node, amount: float, damage_type: DamageType)
signal enemy_died(enemy: Node)
signal aggro_changed(enemy: Node, new_target: Node)
signal combat_started(participants: Array)
signal combat_ended(survivors: Array)

func _ready():
	print("[CombatSystem] Initialized")

func register_enemy(enemy: Node):
	if not registered_enemies.has(enemy):
		registered_enemies.append(enemy)
		print("[CombatSystem] Enemy registered: ", enemy.name)

func unregister_enemy(enemy: Node):
	registered_enemies.erase(enemy)

func calculate_damage(attacker: Node, target: Node, base_damage: float, damage_type: DamageType, is_critical: bool = false) -> float:
	var final_damage = base_damage
	
	# Critical hit multiplier
	if is_critical:
		final_damage *= 2.0
		print("[CombatSystem] Critical hit!")
	
	# Apply resistances/vulnerabilities
	if target and target.has_method("get_resistance"):
		var resistance = target.get_resistance(damage_type)
		final_damage *= (1.0 - resistance)
	
	# Apply attacker buffs
	if attacker and attacker.has_method("get_damage_multiplier"):
		final_damage *= attacker.get_damage_multiplier(damage_type)
	
	# Random variance (±10%)
	var variance = randf_range(0.9, 1.1)
	final_damage *= variance
	
	return max(1, floor(final_damage))

func apply_damage(attacker: Node, target: Node, base_damage: float, damage_type: DamageType, is_critical: bool = false) -> float:
	var final_damage = calculate_damage(attacker, target, base_damage, damage_type, is_critical)
	
	if target and target.has_method("take_damage"):
		target.take_damage(final_damage, DamageType.keys()[damage_type])
	
	emit_signal("enemy_damaged", target, final_damage, damage_type)
	
	combat_log.append({
		"time": Time.get_ticks_msec(),
		"attacker": attacker.name if attacker else "environment",
		"target": target.name if target else "unknown",
		"damage": final_damage,
		"type": DamageType.keys()[damage_type],
		"critical": is_critical
	})
	
	print("[CombatSystem] ", attacker.name if attacker else "Environment", " dealt ", final_damage, " ", DamageType.keys()[damage_type], " damage to ", target.name if target else "target")
	
	return final_damage

func perform_attack(attacker: Node, target: Node, attack_power: float, damage_type: DamageType = DamageType.PHYSICAL):
	if not target:
		return
	
	var is_critical = randf() < get_crit_chance(attacker)
	var damage = apply_damage(attacker, target, attack_power, damage_type, is_critical)
	
	# Trigger on-hit effects
	if attacker and attacker.has_method("on_hit"):
		attacker.on_hit(target, damage)
	
	# Generate aggro
	generate_aggro(target, attacker, damage)

func get_crit_chance(attacker: Node) -> float:
	if attacker and attacker.has_method("get_critical_chance"):
		return attacker.get_critical_chance()
	return 0.05 # Base 5% crit chance

func generate_aggro(target: Node, attacker: Node, damage_amount: float):
	if target and target.has_method("add_aggro"):
		target.add_aggro(attacker, damage_amount)
		
		var current_target = target.get_current_target()
		if current_target != attacker:
			emit_signal("aggro_changed", target, attacker)
			print("[CombatSystem] Aggro changed: ", target.name, " now targets ", attacker.name)

func start_combat(participants: Array):
	print("[CombatSystem] Combat started with ", participants.size(), " participants")
	emit_signal("combat_started", participants)
	
	for participant in participants:
		if participant.has_method("set_in_combat"):
			participant.set_in_combat(true)

func end_combat(survivors: Array):
	print("[CombatSystem] Combat ended. Survivors: ", survivors.size())
	emit_signal("combat_ended", survivors)
	
	for survivor in survivors:
		if survivor.has_method("set_in_combat"):
			survivor.set_in_combat(false)
	
	# Clear old combat log entries (keep last 100)
	while combat_log.size() > 100:
		combat_log.pop_front()

func check_combat_status(enemies: Array, allies: Array) -> bool:
	var all_enemies_dead = true
	for enemy in enemies:
		if enemy and enemy.has_method("is_alive"):
			if enemy.is_alive():
				all_enemies_dead = false
				break
	
	return not all_enemies_dead

func get_combat_log(count: int = 10) -> Array:
	var start_index = max(0, combat_log.size() - count)
	return combat_log.slice(start_index)

func deal_area_damage(center: Vector3, radius: float, base_damage: float, damage_type: DamageType, source: Node, exclude_allies: bool = true):
	var affected_entities = find_entities_in_radius(center, radius)
	
	for entity in affected_entities:
		if exclude_allies and source and are_allies(source, entity):
			continue
		
		# Calculate falloff based on distance
		var distance = center.distance_to(entity.global_position)
		var falloff = 1.0 - (distance / radius)
		var actual_damage = base_damage * falloff
		
		apply_damage(source, entity, actual_damage, damage_type)

func find_entities_in_radius(center: Vector3, radius: float) -> Array:
	var result = []
	
	# Check registered enemies
	for enemy in registered_enemies:
		if enemy and enemy.global_position.distance_to(center) <= radius:
			result.append(enemy)
	
	# In real implementation, also check players, NPCs, etc.
	
	return result

func are_allies(entity_a: Node, entity_b: Node) -> bool:
	if not entity_a or not entity_b:
		return false
	
	if entity_a.has_method("get_faction") and entity_b.has_method("get_faction"):
		return entity_a.get_faction() == entity_b.get_faction()
	
	# Default: check if both have same owner
	if entity_a.has_node("Owner") and entity_b.has_node("Owner"):
		return entity_a.get_parent() == entity_b.get_parent()
	
	return false

func apply_status_effect(target: Node, effect_type: String, duration: float, stacks: int = 1):
	if target and target.has_method("add_status_effect"):
		target.add_status_effect(effect_type, duration, stacks)
		print("[CombatSystem] Applied ", effect_type, " to ", target.name, " for ", duration, "s")

func get_damage_type_from_school(school_name: String) -> DamageType:
	match school_name:
		"ELEMENTAL_FIRE":
			return DamageType.FIRE
		"ELEMENTAL_WATER":
			return DamageType.WATER
		"ELEMENTAL_EARTH":
			return DamageType.EARTH
		"ELEMENTAL_AIR":
			return DamageType.AIR
		"DIVINE":
			return DamageType.DIVINE
		"NECROTIC":
			return DamageType.NECROTIC
		"NATURE":
			return DamageType.NATURE
		"SPATIAL":
			return DamageType.SPATIAL
		"Arcane":
			return DamageType.ARCANE
		_:
			return DamageType.PHYSICAL
