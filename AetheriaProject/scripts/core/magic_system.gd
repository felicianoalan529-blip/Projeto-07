extends Node

class_name MagicSystem

enum SpellTier {
	BASIC,      # Tier 1 - Low cost, simple effects
	ADVANCED,   # Tier 2 - Moderate cost, utility + damage
	EXPERT,     # Tier 3 - High cost, powerful effects
	MASTER,     # Tier 4 - Very high cost, area effects
	WORLD       # Tier 5 - Extreme cost, world-altering
}

enum SpellSchool {
	ELEMENTAL_FIRE,
	ELEMENTAL_WATER,
	ELEMENTAL_EARTH,
	ELEMENTAL_AIR,
	Arcane,
	DIVINE,
	NECROTIC,
	NATURE,
	SPATIAL,
	ILLUSION
}

var spell_database: Dictionary = {}
var active_effects: Array = []

signal spell_cast(spell_name: String, caster: Node, target: Node)
signal world_altered(effect_type: String, location: Vector3)

func _ready():
	initialize_spell_database()
	print("[MagicSystem] Initialized with ", spell_database.size(), " spells")

func initialize_spell_database():
	# === FIRE SPELLS ===
	register_spell("Flame Dart", SpellSchool.ELEMENTAL_FIRE, SpellTier.BASIC, 8, 15, 0.5, 
		"Deals small fire damage to a single target", {"damage": 25, "status": "burn"})
	
	register_spell("Fireball", SpellSchool.ELEMENTAL_FIRE, SpellTier.ADVANCED, 20, 30, 1.0,
		"Hurls a ball of fire that explodes on impact", {"damage": 60, "radius": 4, "status": "burn"})
	
	register_spell("Inferno Wall", SpellSchool.ELEMENTAL_FIRE, SpellTier.EXPERT, 35, 45, 2.0,
		"Creates a wall of flames that damages enemies passing through", {"damage": 40, "duration": 8, "width": 10})
	
	register_spell("Meteor Strike", SpellSchool.ELEMENTAL_FIRE, SpellTier.MASTER, 80, 90, 3.0,
		"Summons a meteor from the sky to devastate an area", {"damage": 150, "radius": 8, "knockback": true})
	
	register_spell("Volcanic Eruption", SpellSchool.ELEMENTAL_FIRE, SpellTier.WORLD, 200, 120, 5.0,
		"Permanently alters terrain by creating a volcano", {"damage": 300, "radius": 20, "alters_terrain": true})
	
	# === WATER SPELLS ===
	register_spell("Water Splash", SpellSchool.ELEMENTAL_WATER, SpellTier.BASIC, 7, 12, 0.5,
		"Splashes water at an enemy", {"damage": 20, "status": "wet"})
	
	register_spell("Healing Wave", SpellSchool.ELEMENTAL_WATER, SpellTier.ADVANCED, 25, 35, 1.5,
		"Heals all allies in a cone", {"heal": 80, "arc": 60, "range": 15})
	
	register_spell("Ice Lance", SpellSchool.ELEMENTAL_WATER, SpellTier.ADVANCED, 18, 25, 0.8,
		"Fires a sharp ice projectile", {"damage": 55, "status": "freeze", "slow": 0.5})
	
	register_spell("Tidal Wave", SpellSchool.ELEMENTAL_WATER, SpellTier.EXPERT, 45, 50, 2.5,
		"Summons a massive wave that pushes enemies", {"damage": 90, "knockback": true, "radius": 12})
	
	register_spell("Frozen Domain", SpellSchool.ELEMENTAL_WATER, SpellTier.MASTER, 90, 100, 4.0,
		"Freezes a large area solid", {"damage": 120, "status": "frozen", "radius": 15, "duration": 6})
	
	register_spell("Ocean Creation", SpellSchool.ELEMENTAL_WATER, SpellTier.WORLD, 220, 150, 6.0,
		"Permanently floods an area creating a lake or sea", {"radius": 50, "alters_terrain": true, "depth": 10})
	
	# === EARTH SPELLS ===
	register_spell("Stone Throw", SpellSchool.ELEMENTAL_EARTH, SpellTier.BASIC, 6, 10, 0.4,
		"Throws a small stone at an enemy", {"damage": 30, "stagger": true})
	
	register_spell("Rock Armor", SpellSchool.ELEMENTAL_EARTH, SpellTier.ADVANCED, 22, 30, 1.0,
		"Grants temporary armor made of stone", {"armor": 50, "duration": 30})
	
	register_spell("Earth Spike", SpellSchool.ELEMENTAL_EARTH, SpellTier.EXPERT, 38, 40, 1.5,
		"Causes spikes to erupt from the ground", {"damage": 100, "radius": 5, "knockup": true})
	
	register_spell("Mountain Shield", SpellSchool.ELEMENTAL_EARTH, SpellTier.MASTER, 75, 80, 2.0,
		"Creates an impenetrable barrier", {"health": 500, "duration": 20, "width": 15})
	
	register_spell("Land Rise", SpellSchool.ELEMENTAL_EARTH, SpellTier.WORLD, 180, 100, 5.0,
		"Permanently raises terrain creating a mountain or plateau", {"height": 30, "radius": 25, "alters_terrain": true})
	
	# === AIR SPELLS ===
	register_spell("Gust", SpellSchool.ELEMENTAL_AIR, SpellTier.BASIC, 5, 8, 0.3,
		"Pushes enemies back with wind", {"damage": 15, "knockback": 5})
	
	register_spell("Lightning Bolt", SpellSchool.ELEMENTAL_AIR, SpellTier.ADVANCED, 24, 28, 0.7,
		"Strikes an enemy with lightning", {"damage": 70, "chain": 3, "status": "shock"})
	
	register_spell("Wind Walk", SpellSchool.ELEMENTAL_AIR, SpellTier.EXPERT, 30, 35, 1.0,
		"Grants increased movement speed and jump height", {"speed_boost": 0.8, "jump_boost": 2.0, "duration": 20})
	
	register_spell("Storm Call", SpellSchool.ELEMENTAL_AIR, SpellTier.MASTER, 85, 95, 3.5,
		"Summons a thunderstorm over a large area", {"damage": 40, "hits": 8, "radius": 20})
	
	register_spell("Sky Tear", SpellSchool.ELEMENTAL_AIR, SpellTier.WORLD, 210, 130, 5.5,
		"Creates a permanent floating island or rift in the sky", {"radius": 30, "alters_terrain": true, "floating": true})
	
	# === ARCANE SPELLS ===
	register_spell("Arcane Missile", SpellSchool.Arcane, SpellTier.BASIC, 9, 14, 0.5,
		"Fires a pure magic projectile", {"damage": 35, "pierces": true})
	
	register_spell("Mana Shield", SpellSchool.Arcane, SpellTier.ADVANCED, 28, 40, 1.0,
		"Absorbs damage using mana instead of health", {"absorption": 100, "duration": 15})
	
	register_spell("Teleport", SpellSchool.Arcane, SpellTier.EXPERT, 35, 30, 0.8,
		"Instantly teleports to target location", {"range": 25, "cooldown_reduction": 0})
	
	register_spell("Arcane Explosion", SpellSchool.Arcane, SpellTier.MASTER, 70, 75, 2.0,
		"Releases energy in all directions", {"damage": 130, "radius": 12, "mana_cost_percent": 0.2})
	
	register_spell("Reality Fracture", SpellSchool.Arcane, SpellTier.WORLD, 250, 180, 7.0,
		"Tears reality creating a zone of wild magic", {"radius": 40, "duration": 60, "wild_magic": true, "alters_terrain": true})
	
	# === DIVINE SPELLS ===
	register_spell("Holy Light", SpellSchool.DIVINE, SpellTier.BASIC, 10, 16, 0.6,
		"Damages undead and heals living", {"damage_vs_undead": 40, "heal_vs_living": 30})
	
	register_spell("Divine Protection", SpellSchool.DIVINE, SpellTier.ADVANCED, 30, 45, 1.2,
		"Grants immunity to status effects", {"immunity_duration": 20, "magic_resist": 40})
	
	register_spell("Resurrection", SpellSchool.DIVINE, SpellTier.EXPERT, 60, 90, 3.0,
		"Brings an ally back from death", {"revive_health": 0.5, "revive_mana": 0.3})
	
	register_spell("Judgment", SpellSchool.DIVINE, SpellTier.MASTER, 95, 110, 4.0,
		"Deals massive damage based on target's sins", {"base_damage": 100, "multiplier_per_flag": 1.5})
	
	register_spell("Sacred Realm", SpellSchool.DIVINE, SpellTier.WORLD, 230, 160, 6.5,
		"Consecrates land permanently against darkness", {"radius": 60, "permanent_buff": "holy_ground", "alters_terrain": true})
	
	# === NECROTIC SPELLS ===
	register_spell("Dark Touch", SpellSchool.NECROTIC, SpellTier.BASIC, 8, 12, 0.5,
		"Drains life from a single target", {"damage": 25, "lifesteal": 0.5})
	
	register_spell("Raise Skeleton", SpellSchool.NECROTIC, SpellTier.ADVANCED, 25, 35, 1.5,
		"Summons a skeleton minion", {"minion_count": 1, "minion_hp": 50, "duration": 120})
	
	register_spell("Death Coil", SpellSchool.NECROTIC, SpellTier.EXPERT, 40, 50, 2.0,
		"Chains life drain between multiple enemies", {"damage": 60, "chains": 5, "lifesteal": 0.4})
	
	register_spell("Army of Dead", SpellSchool.NECROTIC, SpellTier.MASTER, 100, 120, 4.5,
		"Raises multiple undead warriors", {"minion_count": 8, "minion_hp": 100, "duration": 180})
	
	register_spell("Blight Lands", SpellSchool.NECROTIC, SpellTier.WORLD, 240, 150, 7.0,
		"Corrupts land permanently spreading decay", {"radius": 50, "permanent_debuff": "blighted", "alters_terrain": true})
	
	# === NATURE SPELLS ===
	register_spell("Vine Whip", SpellSchool.NATURE, SpellTier.BASIC, 7, 11, 0.4,
		"Whips enemy with thorny vines", {"damage": 22, "root_duration": 1.5})
	
	register_spell("Regrowth", SpellSchool.NATURE, SpellTier.ADVANCED, 26, 38, 1.5,
		"Heals target over time", {"heal_tick": 15, "ticks": 6, "interval": 2})
	
	register_spell("Entangle", SpellSchool.NATURE, SpellTier.EXPERT, 35, 42, 1.8,
		"Roots all enemies in an area", {"root_duration": 5, "radius": 8, "damage": 30})
	
	register_spell("Ancient Guardian", SpellSchool.NATURE, SpellTier.MASTER, 88, 100, 3.5,
		"Summons a powerful treant ally", {"minion_hp": 500, "minion_damage": 60, "duration": 120})
	
	register_spell("World Tree Sprout", SpellSchool.NATURE, SpellTier.WORLD, 200, 140, 8.0,
		"Plants a massive tree that grows permanently", {"tree_height": 50, "radius": 30, "alters_terrain": true, "permanent": true})
	
	# === SPATIAL SPELLS ===
	register_spell("Dimension Slash", SpellSchool.SPATIAL, SpellTier.BASIC, 11, 18, 0.6,
		"Cuts through space dealing ignore-armor damage", {"damage": 40, "ignores_armor": true})
	
	register_spell("Portal", SpellSchool.SPATIAL, SpellTier.ADVANCED, 40, 60, 2.0,
		"Creates linked portals", {"portal_duration": 60, "max_distance": 100})
	
	register_spell("Gravity Well", SpellSchool.SPATIAL, SpellTier.EXPERT, 45, 55, 2.5,
		"Creates a gravity field pulling enemies", {"pull_strength": 15, "radius": 10, "duration": 8})
	
	register_spell("Time Dilation", SpellSchool.SPATIAL, SpellTier.MASTER, 95, 110, 4.0,
		"Slows time in an area", {"slow_factor": 0.3, "radius": 15, "duration": 12})
	
	register_spell("Dimension Shift", SpellSchool.SPATIAL, SpellTier.WORLD, 260, 200, 10.0,
		"Permanently shifts an area to another dimension", {"radius": 40, "alters_terrain": true, "dimension": "shadow"})
	
	# === ILLUSION SPELLS ===
	register_spell("Mirror Image", SpellSchool.ILLUSION, SpellTier.BASIC, 12, 20, 0.8,
		"Creates decoy images", {"image_count": 2, "duration": 15})
	
	register_spell("Invisibility", SpellSchool.ILLUSION, SpellTier.ADVANCED, 32, 45, 1.0,
		"Turns target invisible", {"duration": 20, "break_on_attack": true})
	
	register_spell("Mass Confusion", SpellSchool.ILLUSION, SpellTier.EXPERT, 50, 60, 2.5,
		"Causes enemies to attack each other", {"confusion_duration": 10, "radius": 12})
	
	register_spell("Phantom Army", SpellSchool.ILLUSION, SpellTier.MASTER, 85, 95, 3.5,
		"Creates illusionary soldiers that deal partial damage", {"soldier_count": 10, "damage_multiplier": 0.4, "duration": 45})
	
	register_spell("Dreamscape", SpellSchool.ILLUSION, SpellTier.WORLD, 220, 170, 9.0,
		"Overwrites reality with an illusion permanently", {"radius": 70, "alters_terrain": true, "illusion_permanent": true})

func register_spell(name: String, school: SpellSchool, tier: SpellTier, mana_cost: int, cooldown: float, cast_time: float, description: String, effects: Dictionary):
	spell_database[name] = {
		"name": name,
		"school": school,
		"tier": tier,
		"mana_cost": mana_cost,
		"cooldown": cooldown,
		"cast_time": cast_time,
		"description": description,
		"effects": effects,
		"last_cast": -999.0
	}

func get_spell(spell_name: String) -> Dictionary:
	return spell_database.get(spell_name, {})

func can_cast(spell_name: String, current_mana: float, current_time: float) -> bool:
	var spell = get_spell(spell_name)
	if spell.is_empty():
		return false
	
	if current_mana < spell.mana_cost:
		return false
	
	if current_time - spell.last_cast < spell.cooldown:
		return false
	
	return true

func execute_spell(spell_name: String, caster: Node, target_position: Vector3, target_node: Node = null) -> bool:
	var spell = get_spell(spell_name)
	if spell.is_empty():
		print("[MagicSystem] Spell not found: ", spell_name)
		return false
	
	if not can_cast(spell_name, caster.mana if caster.has_property("mana") else 9999, Time.get_ticks_msec() / 1000.0):
		print("[MagicSystem] Cannot cast ", spell_name)
		return false
	
	print("[MagicSystem] Casting: ", spell_name, " (Tier: ", SpellTier.keys()[spell.tier], ", School: ", SpellSchool.keys()[spell.school], ")")
	
	# Apply spell effects
	apply_spell_effects(spell, caster, target_position, target_node)
	
	# Update cooldown
	spell.last_cast = Time.get_ticks_msec() / 1000.0
	
	emit_signal("spell_cast", spell_name, caster, target_node)
	
	# Check for world-altering spells
	if spell.tier == SpellTier.WORLD:
		emit_signal("world_altered", spell_name, target_position)
	
	return true

func apply_spell_effects(spell: Dictionary, caster: Node, target_position: Vector3, target_node: Node):
	var effects = spell.effects
	
	# Damage effects
	if effects.has("damage"):
		deal_damage(target_node, effects.damage, SpellSchool.keys()[spell.school])
	
	# Healing effects
	if effects.has("heal"):
		heal_target(target_node, effects.heal)
	
	# Status effects
	if effects.has("status"):
		apply_status_effect(target_node, effects.status, effects.get("duration", 5))
	
	# Area effects
	if effects.has("radius"):
		apply_area_effects(spell, target_position, effects.radius)
	
	# Terrain alteration
	if effects.get("alters_terrain", false):
		alter_terrain(spell.name, target_position, effects)

func deal_damage(target: Node, amount: float, damage_type: String):
	if target and target.has_method("take_damage"):
		target.take_damage(amount, damage_type)
		print("[MagicSystem] Dealt ", amount, " ", damage_type, " damage")

func heal_target(target: Node, amount: float):
	if target and target.has_method("heal"):
		target.heal(amount)
		print("[MagicSystem] Healed ", amount, " HP")

func apply_status_effect(target: Node, effect_type: String, duration: float):
	if target and target.has_method("add_status_effect"):
		target.add_status_effect(effect_type, duration)
		print("[MagicSystem] Applied status: ", effect_type, " for ", duration, "s")

func apply_area_effects(spell: Dictionary, center: Vector3, radius: float):
	print("[MagicSystem] Area effect: ", spell.name, " with radius ", radius)
	# In real implementation, find all entities in radius and apply effects

func alter_terrain(spell_name: String, location: Vector3, effects: Dictionary):
	print("[MagicSystem] TERRAIN ALTERED by ", spell_name, " at ", location)
	print("  Effects: ", effects)
	# In real implementation, modify voxel data permanently

func get_spells_by_school(school: SpellSchool) -> Array:
	var result = []
	for spell_data in spell_database.values():
		if spell_data.school == school:
			result.append(spell_data)
	return result

func get_spells_by_tier(tier: SpellTier) -> Array:
	var result = []
	for spell_data in spell_database.values():
		if spell_data.tier == tier:
			result.append(spell_data)
	return result
