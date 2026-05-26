extends Node
## Magic System - Deep spell casting with 10 schools, 5 tiers, and world-altering magic
## AETHERIA: Echoes of the Supreme

signal spell_cast(caster: Node, spell_data: Dictionary, target: Variant)
signal spell_completed(caster: Node, spell_data: Dictionary)
spell_interrupted(caster: Node, spell_data: Dictionary)
signal world_altered(event_id: String, description: String)

# Magic Schools
enum School { ELEMENTAL, ARCANE, DIVINE, NECROTIC, NATURE, SPATIAL, ILLUSION, ENHANCEMENT, RUNIC, VOID }

# Spell Tiers
enum Tier { BASIC, NOVICE, ADEPT, MASTER, WORLD }

# Casting State
var active_casts: Dictionary = {} # caster -> {spell_data, start_time, cast_time}
var channeling_spells: Dictionary = {} # caster -> {spell_data, channel_duration, elapsed}
var cooldowns: Dictionary = {} # (spell_id, caster) -> remaining_time

# Spell Registry - Will be populated from resources
var spell_registry: Dictionary = {}

# Wild Magic Risk
var wild_magic_enabled: bool = false
var overcast_threshold: float = 0.3 # MP cost ratio that triggers wild magic risk

# Singleton Instance
static var instance: MagicSystem

func _ready() -> void:
	instance = self
	load_spell_database()
	print("[MagicSystem] Initialized - 10 Schools of Magic Ready")

func load_spell_database() -> void:
	# Core spell definitions - In production, these would load from .tres resources
	spell_registry = {
		# === ELEMENTAL SCHOOL ===
		"fireball": {"name": "Fireball", "school": School.ELEMENTAL, "tier": Tier.BASIC, "mp_cost": 10, "cast_time": 1.0, "cooldown": 2.0, "range": 20.0, "effect": "damage", "power": 50, "element": "fire"},
		"inferno": {"name": "Inferno", "school": School.ELEMENTAL, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 2.0, "cooldown": 5.0, "range": 25.0, "effect": "aoe_damage", "power": 80, "element": "fire", "aoe_radius": 5.0},
		"flame_wall": {"name": "Flame Wall", "school": School.ELEMENTAL, "tier": Tier.ADEPT, "mp_cost": 45, "cast_time": 2.5, "cooldown": 10.0, "range": 15.0, "effect": "create_barrier", "power": 60, "element": "fire", "duration": 15.0},
		"volcanic_eruption": {"name": "Volcanic Eruption", "school": School.ELEMENTAL, "tier": Tier.MASTER, "mp_cost": 120, "cast_time": 5.0, "cooldown": 60.0, "range": 50.0, "effect": "massive_aoe", "power": 200, "element": "fire", "aoe_radius": 20.0, "terrain_alter": true},
		"ice_shard": {"name": "Ice Shard", "school": School.ELEMENTAL, "tier": Tier.BASIC, "mp_cost": 10, "cast_time": 1.0, "cooldown": 2.0, "range": 20.0, "effect": "damage", "power": 45, "element": "ice", "status_effect": "slow"},
		"blizzard": {"name": "Blizzard", "school": School.ELEMENTAL, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 2.0, "cooldown": 5.0, "range": 25.0, "effect": "aoe_damage", "power": 70, "element": "ice", "status_effect": "freeze", "aoe_radius": 6.0},
		"ice_age": {"name": "Ice Age", "school": School.ELEMENTAL, "tier": Tier.WORLD, "mp_cost": 500, "cast_time": 10.0, "cooldown": 600.0, "range": 200.0, "effect": "world_transform", "power": 0, "element": "ice", "aoe_radius": 100.0, "permanent": true},
		"lightning_bolt": {"name": "Lightning Bolt", "school": School.ELEMENTAL, "tier": Tier.BASIC, "mp_cost": 12, "cast_time": 0.8, "cooldown": 1.5, "range": 25.0, "effect": "damage", "power": 55, "element": "lightning", "instant": true},
		"thunder_storm": {"name": "Thunder Storm", "school": School.ELEMENTAL, "tier": Tier.ADEPT, "mp_cost": 50, "cast_time": 3.0, "cooldown": 12.0, "range": 30.0, "effect": "multi_strike", "power": 40, "element": "lightning", "hits": 5},
		"judgment_bolt": {"name": "Judgment Bolt", "school": School.ELEMENTAL, "tier": Tier.MASTER, "mp_cost": 150, "cast_time": 4.0, "cooldown": 45.0, "range": 40.0, "effect": "massive_aoe", "power": 250, "element": "lightning", "aoe_radius": 15.0},
		
		# === ARCANE SCHOOL ===
		"magic_missile": {"name": "Magic Missile", "school": School.ARCANE, "tier": Tier.BASIC, "mp_cost": 8, "cast_time": 0.5, "cooldown": 1.0, "range": 30.0, "effect": "damage", "power": 40, "homing": true},
		"arcane_blast": {"name": "Arcane Blast", "school": School.ARCANE, "tier": Tier.NOVICE, "mp_cost": 20, "cast_time": 1.5, "cooldown": 3.0, "range": 25.0, "effect": "damage", "power": 90, "penetrates_shields": true},
		"mana_shield": {"name": "Mana Shield", "school": School.ARCANE, "tier": Tier.ADEPT, "mp_cost": 35, "cast_time": 1.0, "cooldown": 20.0, "range": 0.0, "effect": "buff", "duration": 30.0, "absorbs_damage": true},
		"teleport": {"name": "Teleport", "school": School.ARCANE, "tier": Tier.ADEPT, "mp_cost": 40, "cast_time": 2.0, "cooldown": 15.0, "range": 50.0, "effect": "movement", "instant": true},
		"reality_fracture": {"name": "Reality Fracture", "school": School.ARCANE, "tier": Tier.WORLD, "mp_cost": 600, "cast_time": 12.0, "cooldown": 900.0, "range": 100.0, "effect": "dimensional_tear", "power": 500, "permanent": true},
		
		# === DIVINE SCHOOL ===
		"cure": {"name": "Cure", "school": School.DIVINE, "tier": Tier.BASIC, "mp_cost": 15, "cast_time": 1.5, "cooldown": 3.0, "range": 15.0, "effect": "heal", "power": 80},
		"cura": {"name": "Cura", "school": School.DIVINE, "tier": Tier.NOVICE, "mp_cost": 30, "cast_time": 2.0, "cooldown": 5.0, "range": 20.0, "effect": "heal", "power": 150},
		"curaga": {"name": "Curaga", "school": School.DIVINE, "tier": Tier.ADEPT, "mp_cost": 55, "cast_time": 2.5, "cooldown": 8.0, "range": 25.0, "effect": "heal", "power": 300},
		"raise": {"name": "Raise", "school": School.DIVINE, "tier": Tier.MASTER, "mp_cost": 100, "cast_time": 5.0, "cooldown": 120.0, "range": 10.0, "effect": "resurrect", "power": 0},
		"holy": {"name": "Holy", "school": School.DIVINE, "tier": Tier.MASTER, "mp_cost": 130, "cast_time": 4.0, "cooldown": 50.0, "range": 35.0, "effect": "massive_damage", "power": 280, "element": "holy", "effective_vs_undead": true},
		"divine_intervention": {"name": "Divine Intervention", "school": School.DIVINE, "tier": Tier.WORLD, "mp_cost": 550, "cast_time": 8.0, "cooldown": 720.0, "range": 150.0, "effect": "mass_resurrect_heal", "power": 1000, "aoe_radius": 75.0},
		
		# === NECROTIC SCHOOL ===
		"drain": {"name": "Drain", "school": School.NECROTIC, "tier": Tier.BASIC, "mp_cost": 12, "cast_time": 1.0, "cooldown": 2.0, "range": 15.0, "effect": "damage_heal", "power": 50, "steal_hp": true},
		"dark_fire": {"name": "Dark Fire", "school": School.NECROTIC, "tier": Tier.NOVICE, "mp_cost": 22, "cast_time": 1.5, "cooldown": 3.0, "range": 20.0, "effect": "damage", "power": 85, "element": "dark", "dot_ticks": 3},
		"summon_undead": {"name": "Summon Undead", "school": School.NECROTIC, "tier": Tier.ADEPT, "mp_cost": 45, "cast_time": 3.0, "cooldown": 30.0, "range": 10.0, "effect": "summon", "summon_type": "skeleton", "duration": 120.0},
		"wither": {"name": "Wither", "school": School.NECROTIC, "tier": Tier.ADEPT, "mp_cost": 40, "cast_time": 2.0, "cooldown": 15.0, "range": 25.0, "effect": "debuff", "stat_reduction": "strength", "duration": 30.0},
		"death": {"name": "Death", "school": School.NECROTIC, "tier": Tier.MASTER, "mp_cost": 140, "cast_time": 3.0, "cooldown": 90.0, "range": 20.0, "effect": "instant_kill", "success_rate": 0.5},
		"apocalypse": {"name": "Apocalypse", "school": School.NECROTIC, "tier": Tier.WORLD, "mp_cost": 580, "cast_time": 10.0, "cooldown": 800.0, "range": 120.0, "effect": "mass_death", "aoe_radius": 60.0, "success_rate": 0.3},
		
		# === NATURE SCHOOL ===
		"healing_wind": {"name": "Healing Wind", "school": School.NATURE, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 2.0, "cooldown": 8.0, "range": 30.0, "effect": "aoe_heal", "power": 100, "aoe_radius": 10.0},
		"entangle": {"name": "Entangle", "school": School.NATURE, "tier": Tier.BASIC, "mp_cost": 10, "cast_time": 1.0, "cooldown": 5.0, "range": 20.0, "effect": "root", "duration": 5.0},
		"poison_cloud": {"name": "Poison Cloud", "school": School.NATURE, "tier": Tier.NOVICE, "mp_cost": 20, "cast_time": 1.5, "cooldown": 6.0, "range": 25.0, "effect": "aoe_dot", "power": 30, "ticks": 5, "aoe_radius": 8.0},
		"tree_form": {"name": "Tree Form", "school": School.NATURE, "tier": Tier.ADEPT, "mp_cost": 35, "cast_time": 2.0, "cooldown": 45.0, "range": 0.0, "effect": "self_buff", "defense_bonus": 50, "duration": 60.0},
		"wrath_of_nature": {"name": "Wrath of Nature", "school": School.NATURE, "tier": Tier.MASTER, "mp_cost": 110, "cast_time": 4.0, "cooldown": 55.0, "range": 40.0, "effect": "massive_aoe", "power": 220, "aoe_radius": 18.0},
		"genesis": {"name": "Genesis", "school": School.NATURE, "tier": Tier.WORLD, "mp_cost": 520, "cast_time": 15.0, "cooldown": 600.0, "range": 150.0, "effect": "terraform", "biome_transform": "forest", "aoe_radius": 80.0, "permanent": true},
		
		# === SPATIAL SCHOOL ===
		"warp": {"name": "Warp", "school": School.SPATIAL, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 1.5, "cooldown": 10.0, "range": 40.0, "effect": "teleport_self"},
		"gravity_well": {"name": "Gravity Well", "school": School.SPATIAL, "tier": Tier.ADEPT, "mp_cost": 45, "cast_time": 2.5, "cooldown": 20.0, "range": 30.0, "effect": "pull_enemies", "power": 0, "aoe_radius": 12.0, "duration": 5.0},
		"black_hole": {"name": "Black Hole", "school": School.SPATIAL, "tier": Tier.MASTER, "mp_cost": 135, "cast_time": 4.0, "cooldown": 75.0, "range": 35.0, "effect": "massive_damage", "power": 300, "aoe_radius": 10.0, "sucks_in": true},
		"dimension_door": {"name": "Dimension Door", "school": School.SPATIAL, "tier": Tier.ADEPT, "mp_cost": 50, "cast_time": 3.0, "cooldown": 25.0, "range": 100.0, "effect": "teleport_party"},
		"spatial_rift": {"name": "Spatial Rift", "school": School.SPATIAL, "tier": Tier.WORLD, "mp_cost": 540, "cast_time": 8.0, "cooldown": 500.0, "range": 80.0, "effect": "create_portal", "permanent": false, "duration": 300.0},
		
		# === ILLUSION SCHOOL ===
		"blur": {"name": "Blur", "school": School.ILLUSION, "tier": Tier.BASIC, "mp_cost": 10, "cast_time": 1.0, "cooldown": 15.0, "range": 0.0, "effect": "self_buff", "evasion_bonus": 30, "duration": 20.0},
		"mirror_image": {"name": "Mirror Image", "school": School.ILLUSION, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 1.5, "cooldown": 30.0, "range": 0.0, "effect": "summon_decoy", "images": 2, "duration": 45.0},
		"invisibility": {"name": "Invisibility", "school": School.ILLUSION, "tier": Tier.ADEPT, "mp_cost": 40, "cast_time": 2.0, "cooldown": 40.0, "range": 10.0, "effect": "stealth", "duration": 60.0},
		"mass_confusion": {"name": "Mass Confusion", "school": School.ILLUSION, "tier": Tier.MASTER, "mp_cost": 100, "cast_time": 3.5, "cooldown": 60.0, "range": 35.0, "effect": "aoe_debuff", "aoe_radius": 15.0, "duration": 25.0},
		"world_mirror": {"name": "World Mirror", "school": School.ILLUSION, "tier": Tier.WORLD, "mp_cost": 480, "cast_time": 6.0, "cooldown": 400.0, "range": 200.0, "effect": "mass_illusion", "creates_fake_world": true, "duration": 180.0},
		
		# === ENHANCEMENT SCHOOL ===
		"strength_boost": {"name": "Strength Boost", "school": School.ENHANCEMENT, "tier": Tier.BASIC, "mp_cost": 12, "cast_time": 1.0, "cooldown": 5.0, "range": 15.0, "effect": "buff", "stat": "strength", "bonus": 20, "duration": 60.0},
		"magic_boost": {"name": "Magic Boost", "school": School.ENHANCEMENT, "tier": Tier.BASIC, "mp_cost": 12, "cast_time": 1.0, "cooldown": 5.0, "range": 15.0, "effect": "buff", "stat": "magic", "bonus": 20, "duration": 60.0},
		"haste": {"name": "Haste", "school": School.ENHANCEMENT, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 1.5, "cooldown": 10.0, "range": 15.0, "effect": "buff", "speed_bonus": 50, "duration": 90.0},
		"protect": {"name": "Protect", "school": School.ENHANCEMENT, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 1.5, "cooldown": 10.0, "range": 15.0, "effect": "buff", "defense_bonus": 30, "duration": 120.0},
		"shell": {"name": "Shell", "school": School.ENHANCEMENT, "tier": Tier.NOVICE, "mp_cost": 25, "cast_time": 1.5, "cooldown": 10.0, "range": 15.0, "effect": "buff", "magic_defense_bonus": 30, "duration": 120.0},
		"omnistr": {"name": "Omnistrength", "school": School.ENHANCEMENT, "tier": Tier.MASTER, "mp_cost": 90, "cast_time": 3.0, "cooldown": 45.0, "range": 25.0, "effect": "party_buff", "all_stats_bonus": 40, "duration": 180.0},
		
		# === RUNIC SCHOOL ===
		"rune_power": {"name": "Rune Power", "school": School.RUNIC, "tier": Tier.BASIC, "mp_cost": 15, "cast_time": 2.0, "cooldown": 10.0, "range": 0.0, "effect": "empower_next_spell", "power_multiplier": 1.5},
		"rune_shield": {"name": "Rune Shield", "school": School.RUNIC, "tier": Tier.NOVICE, "mp_cost": 30, "cast_time": 2.0, "cooldown": 25.0, "range": 0.0, "effect": "barrier", "absorbs": 200, "duration": 45.0},
		"rune_weapon": {"name": "Rune Weapon", "school": School.RUNIC, "tier": Tier.ADEPT, "mp_cost": 45, "cast_time": 2.5, "cooldown": 30.0, "range": 0.0, "effect": "weapon_enchant", "extra_damage": 50, "duration": 120.0},
		"rune_armor": {"name": "Rune Armor", "school": School.RUNIC, "tier": Tier.ADEPT, "mp_cost": 50, "cast_time": 3.0, "cooldown": 40.0, "range": 0.0, "effect": "armor_enchant", "defense_bonus": 40, "duration": 180.0},
		"ancient_rune": {"name": "Ancient Rune", "school": School.RUNIC, "tier": Tier.MASTER, "mp_cost": 120, "cast_time": 5.0, "cooldown": 90.0, "range": 30.0, "effect": "place_rune", "rune_type": "explosive", "damage": 250},
		
		# === VOID SCHOOL ===
		"void_touch": {"name": "Void Touch", "school": School.VOID, "tier": Tier.BASIC, "mp_cost": 18, "cast_time": 1.0, "cooldown": 3.0, "range": 5.0, "effect": "damage", "power": 70, "ignores_armor": true},
		"void_zone": {"name": "Void Zone", "school": School.VOID, "tier": Tier.NOVICE, "mp_cost": 35, "cast_time": 2.0, "cooldown": 15.0, "range": 25.0, "effect": "aoe_damage", "power": 40, "aoe_radius": 8.0, "duration": 10.0, "silences": true},
		"void_shift": {"name": "Void Shift", "school": School.VOID, "tier": Tier.ADEPT, "mp_cost": 55, "cast_time": 2.5, "cooldown": 35.0, "range": 0.0, "effect": "phase_out", "duration": 5.0, "untargetable": true},
		"entropy": {"name": "Entropy", "school": School.VOID, "tier": Tier.MASTER, "mp_cost": 145, "cast_time": 4.0, "cooldown": 80.0, "range": 30.0, "effect": "dispel_all", "aoe_radius": 15.0},
		"void_annihilation": {"name": "Void Annihilation", "school": School.VOID, "tier": Tier.WORLD, "mp_cost": 650, "cast_time": 15.0, "cooldown": 1000.0, "range": 100.0, "effect": "erase_existence", "aoe_radius": 50.0, "permanent": true}
	}

func cast_spell(spell_id: String, caster: Node, target: Variant, position: Vector3 = Vector3.ZERO) -> bool:
	if not spell_registry.has(spell_id):
		print("[MagicSystem] Unknown spell: ", spell_id)
		return false
	
	var spell_data = spell_registry[spell_id].duplicate()
	
	# Check if caster has enough MP
	var caster_mp = caster.get("mp", 0) if caster.has_method("get") or caster is Node else 0
	if caster_mp < spell_data.mp_cost:
		print("[MagicSystem] Not enough MP for ", spell_data.name)
		return false
	
	# Check cooldown
	var cooldown_key = "%s_%s" % [spell_id, caster.get_path() if caster is Node else str(caster)]
	if cooldowns.has(cooldown_key) and cooldowns[cooldown_key] > 0:
		print("[MagicSystem] Spell on cooldown: ", spell_data.name)
		return false
	
	# Check if already casting
	if active_casts.has(caster):
		print("[MagicSystem] Already casting")
		return false
	
	# Begin casting
	active_casts[caster] = {
		"spell_data": spell_data,
		"target": target,
		"position": position,
		"start_time": Time.get_ticks_msec(),
		"cast_time": spell_data.cast_time
	}
	
	emit_signal("spell_cast", caster, spell_data, target)
	
	# Instant cast spells
	if spell_data.get("instant", false) or spell_data.cast_time <= 0:
		complete_spell(caster)
		return true
	
	return true

func _process(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	var delta_sec = delta
	
	# Update active casts
	for caster in active_casts.keys():
		var cast_info = active_casts[caster]
		var elapsed = (current_time - cast_info.start_time) / 1000.0
		
		if elapsed >= cast_info.cast_time:
			complete_spell(caster)
	
	# Update cooldowns
	for key in cooldowns.keys():
		cooldowns[key] -= delta_sec
		if cooldowns[key] <= 0:
			cooldowns.erase(key)
	
	# Update channeling spells
	for caster in channeling_spells.keys():
		var channel_info = channeling_spells[caster]
		channel_info.elapsed += delta_sec
		
		if channel_info.elapsed >= channel_info.channel_duration:
			stop_channeling(caster)

func complete_spell(caster: Node) -> void:
	if not active_casts.has(caster):
		return
	
	var cast_info = active_casts[caster]
	var spell_data = cast_info.spell_data
	var target = cast_info.target
	var position = cast_info.position
	
	# Deduct MP cost
	if caster.has_method("consume_mp"):
		caster.consume_mp(spell_data.mp_cost)
	elif caster is Node and caster.has_meta("mp"):
		var current_mp = caster.get_meta("mp")
		caster.set_meta("mp", current_mp - spell_data.mp_cost)
	
	# Apply spell effect
	apply_spell_effect(spell_data, caster, target, position)
	
	# Set cooldown
	var cooldown_key = "%s_%s" % [spell_data.get("id", ""), caster.get_path() if caster is Node else str(caster)]
	cooldowns[cooldown_key] = spell_data.cooldown
	
	# Check for World Tier spells
	if spell_data.tier == Tier.WORLD:
		trigger_world_alteration(spell_data, caster, target, position)
	
	active_casts.erase(caster)
	emit_signal("spell_completed", caster, spell_data)

func apply_spell_effect(spell_data: Dictionary, caster: Node, target: Variant, position: Vector3) -> void:
	var effect = spell_data.effect
	
	match effect:
		"damage":
			deal_damage(caster, target, spell_data.power, spell_data.get("element", ""))
		
		"aoe_damage":
			deal_aoe_damage(caster, position if target == null else get_target_position(target), 
				spell_data.power, spell_data.get("aoe_radius", 5.0), spell_data.get("element", ""))
		
		"heal":
			heal_target(caster, target, spell_data.power)
		
		"aoe_heal":
			heal_aoe(caster, position if target == null else get_target_position(target), 
				spell_data.power, spell_data.get("aoe_radius", 10.0))
		
		"buff":
			apply_buff(caster, target, spell_data)
		
		"summon":
			summon_entity(caster, position if target == null else get_target_position(target), spell_data)
		
		"teleport", "teleport_self", "teleport_party":
			perform_teleport(caster, target, position, spell_data)
		
		"create_barrier":
			create_barrier(caster, position, spell_data)
		
		"terrain_alter", "terraform", "world_transform":
			alter_terrain(caster, position, spell_data)
		
		"massive_aoe", "mass_death", "massive_damage":
			deal_massive_aoe(caster, position if target == null else get_target_position(target), 
				spell_data.power, spell_data.get("aoe_radius", 15.0))
		
		_:
			print("[MagicSystem] Unhandled effect type: ", effect)

func deal_damage(caster: Node, target: Variant, power: int, element: String = "") -> void:
	if target is Node:
		var damage = calculate_damage(power, caster, target, element)
		if target.has_method("take_damage"):
			target.take_damage(damage, element, caster)

func deal_aoe_damage(caster: Node, center: Vector3, power: int, radius: float, element: String = "") -> void:
	# Find all enemies in radius and damage them
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = 2 # Enemy layer
	query.transform = Transform3D(Basis(), center)
	
	var sphere = SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	
	var results = space_state.intersect_shape(query, 100)
	for result in results:
		var collider = result.collider
		if collider != caster:
			deal_damage(caster, collider, power, element)

func heal_target(caster: Node, target: Variant, power: int) -> void:
	if target is Node and target.has_method("heal"):
		target.heal(power, caster)

func heal_aoe(caster: Node, center: Vector3, power: int, radius: float) -> void:
	# Find all allies in radius and heal them
	# Implementation similar to deal_aoe_damage but for allies
	pass

func apply_buff(caster: Node, target: Variant, spell_data: Dictionary) -> void:
	if target is Node and target.has_method("apply_buff"):
		target.apply_buff(spell_data)

func summon_entity(caster: Node, position: Vector3, spell_data: Dictionary) -> void:
	# Spawn summoned entity at position
	pass

func perform_teleport(caster: Node, target: Variant, position: Vector3, spell_data: Dictionary) -> void:
	var dest_position = position
	if target is Vector3:
		dest_position = target
	elif target is Node:
		dest_position = target.global_position
	
	if caster is Node:
		caster.global_position = dest_position

func create_barrier(caster: Node, position: Vector3, spell_data: Dictionary) -> void:
	# Create barrier object at position
	pass

func alter_terrain(caster: Node, position: Vector3, spell_data: Dictionary) -> void:
	if WorldManager:
		# Modify terrain based on spell
		var radius = spell_data.get("aoe_radius", 10.0)
		var block_type = get_terrain_block_for_spell(spell_data)
		
		for x in range(-int(radius), int(radius) + 1):
			for z in range(-int(radius), int(radius) + 1):
				if x * x + z * z <= radius * radius:
					var world_pos = Vector3i(position.x + x, position.y, position.z + z)
					WorldManager.set_block(world_pos, block_type)

func get_terrain_block_for_spell(spell_data: Dictionary) -> int:
	if spell_data.get("element") == "ice":
		return 9 # Crystal/Ice
	elif spell_data.get("element") == "fire":
		return 15 # Fire Block
	else:
		return 3 # Stone

func trigger_world_alteration(spell_data: Dictionary, caster: Node, target: Variant, position: Vector3) -> void:
	var event_id = "%s_%d" % [spell_data.name, int(Time.get_unix_time_from_system())]
	var description = "%s cast %s, altering the world!" % [caster.name if caster is Node else "Unknown", spell_data.name]
	
	emit_signal("world_altered", event_id, description)
	print("[MagicSystem] WORLD ALTERATION: ", description)
	
	if GameManager:
		GameManager.trigger_world_event(event_id)

func stop_channeling(caster: Node) -> void:
	if channeling_spells.has(caster):
		channeling_spells.erase(caster)

func cast_spell_by_name(spell_name: String, caster: Node, target: Variant) -> bool:
	# Find spell by name (case-insensitive)
	for spell_id in spell_registry.keys():
		if spell_registry[spell_id].name.nocasecmp_to(spell_name) == 0:
			return cast_spell(spell_id, caster, target)
	return false

func get_spell_info(spell_id: String) -> Dictionary:
	return spell_registry.get(spell_id, {})

func list_spells_by_school(school: School) -> Array:
	var result = []
	for spell_id in spell_registry.keys():
		if spell_registry[spell_id].school == school:
			result.append(spell_id)
	return result

func list_spells_by_tier(tier: Tier) -> Array:
	var result = []
	for spell_id in spell_registry.keys():
		if spell_registry[spell_id].tier == tier:
			result.append(spell_id)
	return result

func calculate_damage(base_power: int, caster: Node, target: Node, element: String = "") -> int:
	var caster_magic = caster.get("magic", 10) if caster.has_method("get") or caster is Node else 10
	var target_defense = target.get("defense", 10) if target.has_method("get") or target is Node else 10
	
	var damage = base_power + (caster_magic * 2) - target_defense
	damage = max(1, damage) # Minimum 1 damage
	
	# Element modifiers could go here
	
	return damage

func get_target_position(target: Variant) -> Vector3:
	if target is Vector3:
		return target
	elif target is Node:
		return target.global_position
	return Vector3.ZERO
