extends Node
## Gambit Controller - FF12-inspired tactical AI programming system for companions
## AETHERIA: Echoes of the Supreme

signal gambit_executed(companion_id: String, gambit_name: String, target: Node)
signal combat_mode_changed(is_combat: bool)
signal companion_order_sent(companion_id: String, order_type: String, target: Variant)

# Gambit Structure: {condition, action, priority, enabled}
enum ConditionType { ALWAYS, ENEMY_IN_RANGE, ALLY_HP_LOW, SELF_HP_LOW, ENEMY_CASTING, STATUS_EFFECT, TIMER }
enum ActionType { ATTACK, SPELL, ITEM, MOVE, DEFEND, USE_SKILL, FOLLOW, HOLD_POSITION }
enum TargetType { SELF, NEAREST_ENEMY, NEAREST_ALLY, SPECIFIC_ENEMY, SPECIFIC_ALLY, MASTER, LOWEST_HP_ALLY, HIGHEST_THREAT_ENEMY }

# Active Combat State
var is_combat_active: bool = false
var combat_participants: Array = []
var threat_table: Dictionary = {} # enemy -> {character: threat_value}

# Companion Gambit Slots (each companion has 4 gambit slots)
var companion_gambits: Dictionary = {
	# "companion_id": [gambit1, gambit2, gambit3, gambit4]
}

# Default Gambit Templates
var default_gambit_templates: Array = [
	{"name": "Heal Low Ally", "condition": ConditionType.ALLY_HP_LOW, "target": TargetType.LOWEST_HP_ALLY, "action": ActionType.SPELL, "parameter": "Cure", "priority": 10},
	{"name": "Attack Nearest", "condition": ConditionType.ENEMY_IN_RANGE, "target": TargetType.NEAREST_ENEMY, "action": ActionType.ATTACK, "parameter": null, "priority": 5},
	{"name": "Self Cure", "condition": ConditionType.SELF_HP_LOW, "target": TargetType.SELF, "action": ActionType.SPELL, "parameter": "Cure", "priority": 15},
	{"name": "Follow Master", "condition": ConditionType.ALWAYS, "target": TargetType.MASTER, "action": ActionType.FOLLOW, "parameter": null, "priority": 1},
	{"name": "Remove Status", "condition": ConditionType.STATUS_EFFECT, "target": TargetType.NEAREST_ALLY, "action": ActionType.SPELL, "parameter": "Esuna", "priority": 12},
	{"name": "Attack Caster", "condition": ConditionType.ENEMY_CASTING, "target": TargetType.NEAREST_ENEMY, "action": ActionType.ATTACK, "parameter": null, "priority": 8},
	{"name": "Defend Master", "condition": ConditionType.SELF_HP_LOW, "target": TargetType.MASTER, "action": ActionType.DEFEND, "parameter": null, "priority": 7},
	{"name": "Buff Master", "condition": ConditionType.TIMER, "target": TargetType.MASTER, "action": ActionType.SPELL, "parameter": "Haste", "priority": 6, "timer_interval": 30.0}
]

# Evaluation Timer
var gambit_evaluation_interval: float = 0.5
var gambit_evaluation_timer: float = 0.0

# Singleton Instance
static var instance: GambitController

func _ready() -> void:
	instance = self
	print("[GambitController] Initialized - Tactical AI System Ready")

func _process(delta: float) -> void:
	if is_combat_active:
		gambit_evaluation_timer += delta
		if gambit_evaluation_timer >= gambit_evaluation_interval:
			gambit_evaluation_timer = 0.0
			evaluate_all_gambits()

func enable_combat_mode(enabled: bool) -> void:
	is_combat_active = enabled
	emit_signal("combat_mode_changed", enabled)
	
	if enabled:
		print("[GambitController] Combat mode activated")
	else:
		print("[GambitController] Combat mode deactivated")
		threat_table.clear()

func register_companion(companion_id: String, companion_node: Node) -> void:
	if companion_id not in companion_gambits:
		# Initialize with default gambits
		companion_gambits[companion_id] = [
			default_gambit_templates[0].duplicate(), # Heal Low Ally
			default_gambit_templates[1].duplicate(), # Attack Nearest
			default_gambit_templates[2].duplicate(), # Self Cure
			default_gambit_templates[3].duplicate()  # Follow Master
		]
	
	if companion_node not in combat_participants:
		combat_participants.append(companion_node)

func unregister_companion(companion_id: String) -> void:
	companion_gambits.erase(companion_id)
	for i in range(combat_participants.size()):
		if combat_participants[i].get_meta("companion_id") == companion_id:
			combat_participants.remove_at(i)
			break

func set_gambit(companion_id: String, slot: int, gambit_data: Dictionary) -> void:
	if companion_id not in companion_gambits:
		register_companion(companion_id, null)
	
	if slot < 0 or slot >= 4:
		return
	
	companion_gambits[companion_id][slot] = gambit_data
	print("[GambitController] Gambit set for ", companion_id, " slot ", slot, ": ", gambit_data.get("name", "Custom"))

func get_gambit(companion_id: String, slot: int) -> Dictionary:
	if companion_id not in companion_gambits:
		return {}
	
	if slot < 0 or slot >= 4:
		return {}
	
	return companion_gambits[companion_id][slot]

func evaluate_all_gambits() -> void:
	for companion_id in companion_gambits.keys():
		var companion_node = get_companion_node(companion_id)
		if not companion_node or not companion_node.is_inside_tree():
			continue
		
		var gambits = companion_gambits[companion_id]
		
		# Sort gambits by priority (highest first)
		var sorted_gambits = gambits.duplicate()
		sorted_gambits.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))
		
		# Evaluate each gambit in priority order
		for gambit in sorted_gambits:
			if not gambit.get("enabled", true):
				continue
			
			if evaluate_condition(gambit, companion_node):
				var target = find_target(gambit.get("target", TargetType.NEAREST_ENEMY), companion_node, gambit.get("parameter", ""))
				
				if target:
					execute_action(gambit, companion_node, target)
					emit_signal("gambit_executed", companion_id, gambit.get("name", ""), target)
					break # Only execute one gambit per evaluation cycle

func evaluate_condition(gambit: Dictionary, companion_node: Node) -> bool:
	var condition = gambit.get("condition", ConditionType.ALWAYS)
	
	match condition:
		ConditionType.ALWAYS:
			return true
		
		ConditionType.ENEMY_IN_RANGE:
			var nearest_enemy = find_target(TargetType.NEAREST_ENEMY, companion_node, "")
			if nearest_enemy:
				var distance = companion_node.global_position.distance_to(nearest_enemy.global_position)
				var range_threshold = gambit.get("range", 15.0)
				return distance <= range_threshold
			return false
		
		ConditionType.ALLY_HP_LOW:
			var lowest_ally = find_target(TargetType.LOWEST_HP_ALLY, companion_node, "")
			if lowest_ally:
				var hp_percent = lowest_ally.get("hp", 100) / lowest_ally.get("hp_max", 100)
				return hp_percent < 0.5 # Below 50% HP
			return false
		
		ConditionType.SELF_HP_LOW:
			var self_hp_percent = companion_node.get("hp", 100) / companion_node.get("hp_max", 100)
			return self_hp_percent < 0.5
		
		ConditionType.ENEMY_CASTING:
			# Check if any enemy is currently casting a spell
			for enemy in get_nearby_enemies(companion_node, 20.0):
				if enemy.get("is_casting", false):
					return true
			return false
		
		ConditionType.STATUS_EFFECT:
			# Check if any ally has a negative status effect
			for ally in get_nearby_allies(companion_node, 15.0):
				var status_effects = ally.get("status_effects", [])
				for effect in status_effects:
					if effect.get("type") == "debuff":
						return true
			return false
		
		ConditionType.TIMER:
			var last_execution = companion_node.get_meta("gambit_last_" + str(gambit.get("name", ""))) or 0.0
			var current_time = GameManager.game_time if GameManager else 0.0
			var interval = gambit.get("timer_interval", 30.0)
			return (current_time - last_execution) >= interval
		
	return false

func find_target(target_type: TargetType, companion_node: Node, parameter: String) -> Variant:
	match target_type:
		TargetType.SELF:
			return companion_node
		
		TargetType.NEAREST_ENEMY:
			var enemies = get_nearby_enemies(companion_node, 25.0)
			if enemies.size() > 0:
				return get_nearest_target(companion_node, enemies)
		
		TargetType.NEAREST_ALLY:
			var allies = get_nearby_allies(companion_node, 20.0)
			if allies.size() > 0:
				return get_nearest_target(companion_node, allies)
		
		TargetType.LOWEST_HP_ALLY:
			var allies = get_nearby_allies(companion_node, 20.0)
			if allies.size() > 0:
				return get_lowest_hp_target(allies)
		
		TargetType.HIGHEST_THREAT_ENEMY:
			var enemies = get_nearby_enemies(companion_node, 25.0)
			if enemies.size() > 0:
				return get_highest_threat_target(enemies)
		
		TargetType.MASTER:
			# Return the player character
			if GameManager and GameManager.player_data.has("character_node"):
				return GameManager.player_data.character_node
		
		TargetType.SPECIFIC_ENEMY, TargetType.SPECIFIC_ALLY:
			# Would need specific ID lookup
			pass
	
	return null

func get_nearest_target(source: Node, targets: Array) -> Node:
	if targets.size() == 0:
		return null
	
	var nearest = targets[0]
	var nearest_distance = source.global_position.distance_to(targets[0].global_position)
	
	for i in range(1, targets.size()):
		var distance = source.global_position.distance_to(targets[i].global_position)
		if distance < nearest_distance:
			nearest = targets[i]
			nearest_distance = distance
	
	return nearest

func get_lowest_hp_target(targets: Array) -> Node:
	if targets.size() == 0:
		return null
	
	var lowest = targets[0]
	var lowest_hp_percent = float(lowest.get("hp", 100)) / float(lowest.get("hp_max", 100))
	
	for i in range(1, targets.size()):
		var hp_percent = float(targets[i].get("hp", 100)) / float(targets[i].get("hp_max", 100))
		if hp_percent < lowest_hp_percent:
			lowest = targets[i]
			lowest_hp_percent = hp_percent
	
	return lowest

func get_highest_threat_target(enemies: Array) -> Node:
	if enemies.size() == 0:
		return null
	
	# Simplified: highest threat = highest level or boss
	var highest = enemies[0]
	var highest_threat = enemies[0].get("level", 1)
	
	for i in range(1, enemies.size()):
		var threat = enemies[i].get("level", 1)
		if enemies[i].get("is_boss", false):
			threat += 10
		if threat > highest_threat:
			highest = enemies[i]
			highest_threat = threat
	
	return highest

func get_nearby_enemies(source: Node, max_distance: float) -> Array:
	var enemies = []
	# In a real implementation, this would query the combat system or scene tree
	# For now, return empty array (would be populated during combat)
	return enemies

func get_nearby_allies(source: Node, max_distance: float) -> Array:
	var allies = []
	# Add all registered companions except self
	for companion_id in companion_gambits.keys():
		var ally_node = get_companion_node(companion_id)
		if ally_node and ally_node != source:
			var distance = source.global_position.distance_to(ally_node.global_position)
			if distance <= max_distance:
				allies.append(ally_node)
	
	# Add player character
	if GameManager and GameManager.player_data.has("character_node"):
		var player_node = GameManager.player_data.character_node
		if player_node:
			var distance = source.global_position.distance_to(player_node.global_position)
			if distance <= max_distance:
				allies.append(player_node)
	
	return allies

func execute_action(gambit: Dictionary, companion_node: Node, target: Variant) -> void:
	var action = gambit.get("action", ActionType.ATTACK)
	var parameter = gambit.get("parameter", "")
	
	# Update timer for timed gambits
	if gambit.get("condition") == ConditionType.TIMER:
		companion_node.set_meta("gambit_last_" + str(gambit.get("name", "")), 
			GameManager.game_time if GameManager else 0.0)
	
	match action:
		ActionType.ATTACK:
			if target is Node:
				companion_node.emit_signal("perform_attack", target)
				emit_signal("companion_order_sent", companion_node.get_meta("companion_id", ""), "attack", target)
		
		ActionType.SPELL:
			if target is Node and parameter != "":
				if MagicSystem:
					MagicSystem.cast_spell_by_name(parameter, companion_node, target)
				emit_signal("companion_order_sent", companion_node.get_meta("companion_id", ""), "spell", {"name": parameter, "target": target})
		
		ActionType.ITEM:
			# Use item on target
			pass
		
		ActionType.MOVE:
			if target is Vector3:
				companion_node.emit_signal("move_to", target)
		
		ActionType.DEFEND:
			companion_node.emit_signal("enter_defend_mode")
		
		ActionType.USE_SKILL:
			if target is Node and parameter != "":
				companion_node.emit_signal("use_skill", parameter, target)
		
		ActionType.FOLLOW:
			if target is Node:
				companion_node.emit_signal("follow_target", target)
		
		ActionType.HOLD_POSITION:
			companion_node.emit_signal("hold_position")

func add_threat(character: Node, enemy: Node, amount: int) -> void:
	if enemy not in threat_table:
		threat_table[enemy] = {}
	
	if character not in threat_table[enemy]:
		threat_table[enemy][character] = 0
	
	threat_table[enemy][character] += amount

func get_companion_node(companion_id: String) -> Node:
	for participant in combat_participants:
		if participant.get_meta("companion_id") == companion_id:
			return participant
	return null

func clear_all_gambits(companion_id: String) -> void:
	if companion_id in companion_gambits:
		companion_gambits[companion_id] = []

func load_gambit_preset(companion_id: String, preset_name: String) -> void:
	var presets = get_gambit_presets()
	if presets.has(preset_name):
		companion_gambits[companion_id] = presets[preset_name]
		print("[GambitController] Loaded preset '", preset_name, "' for ", companion_id)

func get_gambit_presets() -> Dictionary:
	return {
		"Healer": [
			{"name": "Self Cure", "condition": ConditionType.SELF_HP_LOW, "target": TargetType.SELF, "action": ActionType.SPELL, "parameter": "Cure", "priority": 15, "enabled": true},
			{"name": "Heal Low Ally", "condition": ConditionType.ALLY_HP_LOW, "target": TargetType.LOWEST_HP_ALLY, "action": ActionType.SPELL, "parameter": "Cura", "priority": 12, "enabled": true},
			{"name": "Remove Status", "condition": ConditionType.STATUS_EFFECT, "target": TargetType.NEAREST_ALLY, "action": ActionType.SPELL, "parameter": "Esuna", "priority": 10, "enabled": true},
			{"name": "Buff Master", "condition": ConditionType.TIMER, "target": TargetType.MASTER, "action": ActionType.SPELL, "parameter": "Protect", "priority": 5, "enabled": true, "timer_interval": 60.0}
		],
		"Tank": [
			{"name": "Attack Nearest", "condition": ConditionType.ENEMY_IN_RANGE, "target": TargetType.NEAREST_ENEMY, "action": ActionType.ATTACK, "parameter": null, "priority": 5, "enabled": true},
			{"name": "Defend Self", "condition": ConditionType.SELF_HP_LOW, "target": TargetType.SELF, "action": ActionType.DEFEND, "parameter": null, "priority": 10, "enabled": true},
			{"name": "Protect Master", "condition": ConditionType.ALLY_HP_LOW, "target": TargetType.MASTER, "action": ActionType.USE_SKILL, "parameter": "Cover", "priority": 12, "enabled": true},
			{"name": "Taunt Boss", "condition": ConditionType.TIMER, "target": TargetType.HIGHEST_THREAT_ENEMY, "action": ActionType.USE_SKILL, "parameter": "Provoke", "priority": 8, "enabled": true, "timer_interval": 20.0}
		],
		"DPS": [
			{"name": "Attack Nearest", "condition": ConditionType.ENEMY_IN_RANGE, "target": TargetType.NEAREST_ENEMY, "action": ActionType.ATTACK, "parameter": null, "priority": 5, "enabled": true},
			{"name": "Focus Caster", "condition": ConditionType.ENEMY_CASTING, "target": TargetType.NEAREST_ENEMY, "action": ActionType.ATTACK, "parameter": null, "priority": 8, "enabled": true},
			{"name": "Self Buff", "condition": ConditionType.TIMER, "target": TargetType.SELF, "action": ActionType.SPELL, "parameter": "Haste", "priority": 6, "enabled": true, "timer_interval": 45.0},
			{"name": "Self Cure", "condition": ConditionType.SELF_HP_LOW, "target": TargetType.SELF, "action": ActionType.SPELL, "parameter": "Cure", "priority": 10, "enabled": true}
		]
	}
