extends Node
## Game Manager - Core singleton managing game state, player data, and global systems
## AETHERIA: Echoes of the Supreme

signal player_level_changed(new_level: int)
signal quest_updated(quest_id: String, status: String)
signal world_state_changed(event_id: String)
signal base_reputation_changed(faction_id: String, new_reputation: int)

# Game State Enums
enum GameState { LOADING, MENU, PLAYING, PAUSED, DIALOGUE, COMBAT, BUILDING }
enum Difficulty { STORY, NORMAL, VETERAN, SUPREME }

# Core Variables
var current_state: GameState = GameState.LOADING
var difficulty: Difficulty = Difficulty.NORMAL
var game_time: float = 0.0
var real_time_elapsed: float = 0.0

# Player Data
var player_data: Dictionary = {
	"id": "",
	"name": "Echo",
	"level": 1,
	"exp": 0,
	"exp_to_next": 100,
	"primary_class": null,
	"secondary_class": null,
	"hybrid_class": null,
	"stats": {
		"hp": 100,
		"hp_max": 100,
		"mp": 50,
		"mp_max": 50,
		"stamina": 100,
		"stamina_max": 100,
		"strength": 10,
		"magic": 10,
		"defense": 10,
		"spirit": 10,
		"agility": 10,
		"luck": 10
	},
	"classes_unlocked": [],
	"spells_known": [],
	"spells_equipped": [],
	"inventory": [],
	"equipment": {
		"weapon": null,
		"offhand": null,
		"head": null,
		"chest": null,
		"legs": null,
		"feet": null,
		"accessory_1": null,
		"accessory_2": null
	},
	"gambits": [],
	"base_location": null,
	"factions_reputation": {},
	"quests_completed": [],
	"world_events_triggered": []
}

# World State
var world_events: Dictionary = {}
var active_quests: Array = []
var discovered_locations: Array = []

# Singleton Instance
static var instance: GameManager

func _ready() -> void:
	instance = self
	print("[GameManager] Initialized - AETHERIA: Echoes of the Supreme")
	change_state(GameState.MENU)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING or current_state == GameState.COMBAT:
		game_time += delta
		real_time_elapsed += delta
		_process_day_night_cycle(delta)
		_process_regeneration(delta)

func _process_day_night_cycle(delta: float) -> void:
	# 24-minute day cycle (1 game second = 1 real second)
	var day_duration: float = 1440.0 # 24 minutes in seconds
	var normalized_time: float = fmod(game_time, day_duration) / day_duration
	
	# Update world manager with time data
	if WorldManager:
		WorldManager.update_time(normalized_time)

func _process_regeneration(delta: float) -> void:
	# Natural HP/MP/Stamina regeneration
	if player_data.stats.hp < player_data.stats.hp_max:
		player_data.stats.hp = minf(player_data.stats.hp_max, 
			player_data.stats.hp + (player_data.stats.spirit * 0.1 * delta))
	
	if player_data.stats.mp < player_data.stats.mp_max:
		player_data.stats.mp = minf(player_data.stats.mp_max, 
			player_data.stats.mp + (player_data.stats.spirit * 0.15 * delta))
	
	if player_data.stats.stamina < player_data.stats.stamina_max:
		player_data.stats.stamina = minf(player_data.stats.stamina_max, 
			player_data.stats.stamina + (player_data.stats.agility * 0.2 * delta))

func change_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	print("[GameManager] State changed: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
	
	match new_state:
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.COMBAT:
			# Activate combat UI and gambit system
			if GambitController:
				GambitController.enable_combat_mode(true)

func add_exp(amount: int) -> void:
	player_data.exp += amount
	while player_data.exp >= player_data.exp_to_next:
		level_up()

func level_up() -> void:
	player_data.level += 1
	player_data.exp -= player_data.exp_to_next
	player_data.exp_to_next = int(player_data.exp_to_next * 1.5)
	
	# Stat growth based on class
	var growth_multiplier = 1.0
	if player_data.primary_class:
		growth_multiplier = player_data.primary_class.get("growth_multiplier", 1.0)
	
	player_data.stats.hp_max = int(player_data.stats.hp_max * 1.1 * growth_multiplier)
	player_data.stats.mp_max = int(player_data.stats.mp_max * 1.1 * growth_multiplier)
	player_data.stats.hp = player_data.stats.hp_max
	player_data.stats.mp = player_data.stats.mp_max
	
	print("[GameManager] Level up! New level: ", player_data.level)
	emit_signal("player_level_changed", player_data.level)

func set_class(primary: String, secondary: String = "") -> void:
	player_data.primary_class = load_class_data(primary)
	if secondary != "":
		player_data.secondary_class = load_class_data(secondary)
		check_hybrid_class()
	
	# Apply class stat bonuses
	apply_class_bonuses()

func load_class_data(class_name: String) -> Dictionary:
	var class_path = "res://resources/classes/%s.tres" % class_name
	if ResourceLoader.exists(class_path):
		return ResourceLoader.load(class_path)
	return {}

func check_hybrid_class() -> void:
	if player_data.primary_class and player_data.secondary_class:
		var hybrid_key = "%s_%s" % [player_data.primary_class.get("class_name", ""), 
			player_data.secondary_class.get("class_name", "")]
		var hybrid_path = "res://resources/classes/hybrids/%s.tres" % hybrid_key
		
		if ResourceLoader.exists(hybrid_path):
			player_data.hybrid_class = ResourceLoader.load(hybrid_path)
			print("[GameManager] Hybrid class unlocked: ", hybrid_key)

func apply_class_bonuses() -> void:
	# Reset to base stats
	var base_stats = player_data.stats.duplicate()
	
	# Apply primary class bonuses
	if player_data.primary_class:
		for stat in player_data.primary_class.get("stat_bonuses", {}):
			player_data.stats[stat] = int(base_stats[stat] * player_data.primary_class.stat_bonuses[stat])
	
	# Apply secondary class bonuses (50% effect)
	if player_data.secondary_class:
		for stat in player_data.secondary_class.get("stat_bonuses", {}):
			var bonus = player_data.secondary_class.stat_bonuses[stat] * 0.5
			player_data.stats[stat] = int(player_data.stats[stat] * (1 + bonus))
	
	# Apply hybrid class bonuses
	if player_data.hybrid_class:
		for stat in player_data.hybrid_class.get("stat_bonuses", {}):
			player_data.stats[stat] = int(player_data.stats[stat] * player_data.hybrid_class.stat_bonuses[stat])

func modify_reputation(faction_id: String, amount: int) -> void:
	if faction_id not in player_data.factions_reputation:
		player_data.factions_reputation[faction_id] = 0
	
	player_data.factions_reputation[faction_id] += amount
	emit_signal("base_reputation_changed", faction_id, player_data.factions_reputation[faction_id])

func save_game(slot: int = 1) -> bool:
	var save_path = "user://save_slot_%d.save" % slot
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if save_file:
		save_file.store_var(player_data)
		save_file.store_var(world_events)
		save_file.close()
		print("[GameManager] Game saved to slot ", slot)
		return true
	else:
		print("[GameManager] Failed to save game")
		return false

func load_game(slot: int = 1) -> bool:
	var save_path = "user://save_slot_%d.save" % slot
	
	if not FileAccess.file_exists(save_path):
		print("[GameManager] No save file found in slot ", slot)
		return false
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	player_data = save_file.get_var()
	world_events = save_file.get_var()
	save_file.close()
	
	print("[GameManager] Game loaded from slot ", slot)
	change_state(GameState.PLAYING)
	return true

func trigger_world_event(event_id: String) -> void:
	if event_id not in world_events:
		world_events[event_id] = {
			"triggered": true,
			"timestamp": game_time,
			"consequences": []
		}
		emit_signal("world_state_changed", event_id)
		print("[GameManager] World event triggered: ", event_id)

func get_reputation_level(faction_id: String) -> String:
	var rep = player_data.factions_reputation.get(faction_id, 0)
	
	if rep >= 1000: return "Exalted"
	elif rep >= 500: return "Revered"
	elif rep >= 200: return "Honored"
	elif rep >= 50: return "Friendly"
	elif rep >= 0: return "Neutral"
	elif rep >= -50: return "Unfriendly"
	elif rep >= -200: return "Hostile"
	else: return "Hated"
