extends Node
class_name CombatSystem

## Sistema de Combate - Gerencia dano, aggro, status effects e resolução de ações
## AETHERIA: Echoes of the Supreme

signal combat_started(participants: Array)
signal combat_ended()
signal entity_damaged(target: Node, amount: float, damage_type: DamageType)
signal entity_healed(target: Node, amount: int)
signal entity_died(entity: Node, killer: Node)
signal threat_updated(entity: Node, threat_table: Dictionary)

# Tipos de Dano
enum DamageType {
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	HOLY,
	DARK,
	NATURE,
	ARCANE,
	POISON,
	BLEED
}

# Status Effects
enum StatusEffect {
	NONE,
	POISON,
	BURN,
	FROZEN,
	STUNNED,
	SILENCED,
	BLINDED,
	WEAKENED,
	HASTED,
	PROTECTED,
	CURSED,
	REGENERATING
}

# Dados de Entidade em Combate
class CombatEntity:
	var entity: Node
	var max_hp: int = 100
	var current_hp: int = 100
	var level: int = 1
	var is_dead: bool = false
	var threat_table: Dictionary = {}  # { attacker: threat_value }
	var active_effects: Array[ActiveEffect] = []
	var elemental_resistances: Dictionary = {}
	var elemental_weaknesses: Dictionary = {}
	
	func _init(node: Node, hp: int, lvl: int) -> void:
		entity = node
		max_hp = hp
		current_hp = hp
		level = lvl

# Efeito Ativo
class ActiveEffect:
	var effect_type: StatusEffect
	var source: Node
	var duration: float = 0.0
	var remaining_time: float = 0.0
	var tick_damage: int = 0
	var tick_interval: float = 0.0
	var tick_timer: float = 0.0
	var stat_modifiers: Dictionary = {}

# Configurações
@export var base_threat_decay: float = 2.0  # Threat perdido por segundo
@export var assist_threat_multiplier: float = 0.5
@export var crit_chance_base: float = 0.05
@export var crit_damage_multiplier: float = 2.0

# Estado do Combate
var in_combat: bool = false
var combat_entities: Array[CombatEntity] = []
var combat_participants: Array[Node] = []
var _combat_timer: float = 0.0
var _out_of_combat_threshold: float = 5.0  # Segundos sem ação para sair de combate

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not in_combat:
		return
	
	_combat_timer += delta
	
	# Atualizar efeitos ativos
	_update_effects(delta)
	
	# Decair threat
	_decay_threat(delta)
	
	# Verificar se combate acabou
	if _check_combat_end():
		end_combat()

func register_entity(entity: Node, max_hp: int, level: int) -> CombatEntity:
	var combat_entity = CombatEntity.new(entity, max_hp, level)
	combat_entities.append(combat_entity)
	return combat_entity

func unregister_entity(entity: Node) -> void:
	for i in range(combat_entities.size() - 1, -1, -1):
		if combat_entities[i].entity == entity:
			combat_entities.remove_at(i)
			break

func start_combat(initial_participants: Array[Node]) -> void:
	if in_combat:
		return
	
	in_combat = true
	combat_participants = initial_participants.duplicate()
	_combat_timer = 0.0
	
	# Registrar todas as entidades
	for participant in initial_participants:
		if not is_entity_registered(participant):
			var hp = participant.get("max_hp") if participant.has_method("get") else 100
			var level = participant.get("level") if participant.has_method("get") else 1
			register_entity(participant, hp, level)
	
	combat_started.emit(initial_participants)
	print("[CombatSystem] Combat started with %d participants" % initial_participants.size())

func end_combat() -> void:
	in_combat = false
	
	# Limpar threat tables
	for combat_entity in combat_entities:
		combat_entity.threat_table.clear()
		combat_entity.active_effects.clear()
	
	combat_ended.emit()
	print("[CombatSystem] Combat ended")

func deal_damage(
	target: Node,
	amount: float,
	damage_type: DamageType,
	source: Node = null,
	is_critical: bool = false,
	skip_resistance: bool = false
) -> float:
	var combat_target = get_combat_entity(target)
	if combat_target == null or combat_target.is_dead:
		return 0.0
	
	# Calcular resistências/fracassos
	var final_damage = amount
	if not skip_resistance:
		final_damage = _apply_resistances(amount, damage_type, combat_target)
	
	# Aplicar crítico
	if is_critical or randf() < crit_chance_base:
		final_damage *= crit_damage_multiplier
		print("[CombatSystem] Critical hit!")
	
	# Garantir dano mínimo
	final_damage = max(1, floor(final_damage))
	
	# Aplicar dano
	combat_target.current_hp = max(0, combat_target.current_hp - int(final_damage))
	
	# Notificar via sinais
	if target.has_signal("health_changed"):
		target.emit_signal("health_changed", combat_target.current_hp, combat_target.max_hp)
	
	entity_damaged.emit(target, final_damage, damage_type)
	
	# Adicionar threat
	if source:
		add_threat(source, target, final_damage)
	
	# Verificar morte
	if combat_target.current_hp <= 0:
		combat_target.is_dead = true
		entity_died.emit(target, source)
		
		if target.has_method("die"):
			target.die(source)
		
		# Remover da lista se morto
		check_and_remove_dead_entity(combat_target)
	
	print("[CombatSystem] Dealt %d %s damage to %s" % [int(final_damage), DamageType.keys()[damage_type], target.name])
	return final_damage

func heal_amount(target: Node, amount: int, source: Node = null) -> int:
	var combat_target = get_combat_entity(target)
	if combat_target == null or combat_target.is_dead:
		return 0
	
	var actual_heal = min(amount, combat_target.max_hp - combat_target.current_hp)
	combat_target.current_hp += actual_heal
	
	if target.has_signal("health_changed"):
		target.emit_signal("health_changed", combat_target.current_hp, combat_target.max_hp)
	
	entity_healed.emit(target, actual_heal)
	
	# Healer gera threat no alvo curado
	if source and combat_target != source:
		add_threat(source, target, actual_heal * 0.5)
	
	print("[CombatSystem] Healed %s for %d HP" % [target.name, actual_heal])
	return actual_heal

func apply_status_effect(
	target: Node,
	effect: StatusEffect,
	duration: float,
	source: Node = null,
	tick_damage: int = 0,
	tick_interval: float = 0.0,
	stat_mods: Dictionary = {}
) -> void:
	var combat_target = get_combat_entity(target)
	if combat_target == null or combat_target.is_dead:
		return
	
	# Verificar se já existe efeito do mesmo tipo
	for existing_effect in combat_target.active_effects:
		if existing_effect.effect_type == effect:
			# Refresh duration
			existing_effect.remaining_time = max(existing_effect.remaining_time, duration)
			return
	
	# Criar novo efeito
	var new_effect = ActiveEffect.new()
	new_effect.effect_type = effect
	new_effect.source = source
	new_effect.duration = duration
	new_effect.remaining_time = duration
	new_effect.tick_damage = tick_damage
	new_effect.tick_interval = tick_interval
	new_effect.stat_modifiers = stat_mods.duplicate()
	
	combat_target.active_effects.append(new_effect)
	print("[CombatSystem] Applied %s to %s for %.1fs" % [StatusEffect.keys()[effect], target.name, duration])

func remove_status_effect(target: Node, effect: StatusEffect) -> void:
	var combat_target = get_combat_entity(target)
	if combat_target == null:
		return
	
	for i in range(combat_target.active_effects.size() - 1, -1, -1):
		if combat_target.active_effects[i].effect_type == effect:
			combat_target.active_effects.remove_at(i)
			break

func add_threat(source: Node, target: Node, amount: float) -> void:
	var combat_target = get_combat_entity(target)
	if combat_target == null:
		return
	
	if source not in combat_target.threat_table:
		combat_target.threat_table[source] = 0.0
	
	combat_target.threat_table[source] += amount
	
	# Iniciar combate se necessário
	if not in_combat and amount > 0:
		start_combat([source, target])
	
	threat_updated.emit(target, combat_target.threat_table)

func get_highest_threat_target(attacker: Node) -> Node:
	var highest_threat: float = -1
	var highest_target: Node = null
	
	for combat_entity in combat_entities:
		if attacker in combat_entity.threat_table:
			var threat = combat_entity.threat_table[attacker]
			if threat > highest_threat:
				highest_threat = threat
				highest_target = combat_entity.entity
	
	return highest_target

func get_threat_value(attacker: Node, target: Node) -> float:
	var combat_target = get_combat_entity(target)
	if combat_target == null:
		return 0.0
	
	return combat_target.threat_table.get(attacker, 0.0)

func clear_threat(source: Node, target: Node) -> void:
	var combat_target = get_combat_entity(target)
	if combat_target == null:
		return
	
	if source in combat_target.threat_table:
		combat_target.threat_table.erase(source)

# Funções Auxiliares
func _update_effects(delta: float) -> void:
	for combat_entity in combat_entities:
		if combat_entity.is_dead:
			continue
		
		var effects_to_remove: Array[int] = []
		
		for i in range(combat_entity.active_effects.size()):
			var effect = combat_entity.active_effects[i]
			effect.remaining_time -= delta
			
			# Aplicar dano por tick
			if effect.tick_damage > 0 and effect.tick_interval > 0:
				effect.tick_timer += delta
				if effect.tick_timer >= effect.tick_interval:
					effect.tick_timer = 0.0
					deal_damage(
						combat_entity.entity,
						effect.tick_damage,
						_get_effect_damage_type(effect.effect_type),
						effect.source
					)
			
			# Marcar para remoção se expirou
			if effect.remaining_time <= 0:
				effects_to_remove.append(i)
		
		# Remover efeitos expirados (de trás para frente)
		for i in range(effects_to_remove.size() - 1, -1, -1):
			combat_entity.active_effects.remove_at(effects_to_remove[i])

func _decay_threat(delta: float) -> void:
	for combat_entity in combat_entities:
		for attacker in combat_entity.threat_table.keys():
			combat_entity.threat_table[attacker] = max(
				0,
				combat_entity.threat_table[attacker] - base_threat_decay * delta
			)

func _check_combat_end() -> bool:
	if combat_participants.is_empty():
		return true
	
	# Verificar se todos estão mortos ou fora de combate
	var alive_count = 0
	for combat_entity in combat_entities:
		if not combat_entity.is_dead:
			alive_count += 1
	
	return alive_count <= 1

func _apply_resistances(base_damage: float, damage_type: DamageType, target: CombatEntity) -> float:
	var multiplier = 1.0
	
	# Aplicar fraquezas
	if damage_type in target.elemental_weaknesses:
		multiplier += target.elemental_weaknesses[damage_type]
	
	# Aplicar resistências
	if damage_type in target.elemental_resistances:
		multiplier -= target.elemental_resistances[damage_type]
	
	return base_damage * multiplier

func _get_effect_damage_type(effect: StatusEffect) -> DamageType:
	match effect:
		StatusEffect.POISON:
			return DamageType.POISON
		StatusEffect.BURN:
			return DamageType.FIRE
		StatusEffect.FROZEN:
			return DamageType.ICE
		_:
			return DamageType.PHYSICAL

func get_combat_entity(entity: Node) -> CombatEntity:
	for combat_entity in combat_entities:
		if combat_entity.entity == entity:
			return combat_entity
	return null

func is_entity_registered(entity: Node) -> bool:
	return get_combat_entity(entity) != null

func check_and_remove_dead_entity(combat_entity: CombatEntity) -> void:
	if combat_entity.is_dead:
		var index = combat_entities.find(combat_entity)
		if index >= 0:
			combat_entities.remove_at(index)

func get_alive_allies(reference: Node) -> Array[Node]:
	var allies: Array[Node] = []
	
	for combat_entity in combat_entities:
		if not combat_entity.is_dead and combat_entity.entity != reference:
			allies.append(combat_entity.entity)
	
	return allies

func get_nearest_enemy(position: Vector3, max_distance: float = 100.0) -> Node:
	var nearest: Node = null
	var nearest_dist: float = max_distance
	
	for combat_entity in combat_entities:
		if combat_entity.is_dead:
			continue
		
		var dist = position.distance_to(combat_entity.entity.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = combat_entity.entity
	
	return nearest

func get_enemies_in_range(position: Vector3, radius: float) -> Array[Node]:
	var enemies: Array[Node] = []
	
	for combat_entity in combat_entities:
		if combat_entity.is_dead:
			continue
		
		var dist = position.distance_to(combat_entity.entity.global_position)
		if dist <= radius:
			enemies.append(combat_entity.entity)
	
	return enemies

# Utilitário para calcular dano baseado em stats
func calculate_damage(
	base_damage: float,
	attack_stat: int,
	defense_stat: int,
	elemental_bonus: float = 0.0
) -> float:
	var attack_multiplier = 1.0 + (attack_stat / 100.0)
	var defense_reduction = 100.0 / (100.0 + defense_stat)
	
	var final_damage = base_damage * attack_multiplier * defense_reduction
	final_damage += elemental_bonus
	
	return max(1, final_damage)
