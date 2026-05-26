extends Node

class_name GameManager

static var instance: GameManager

var game_state: Dictionary = {
	"current_zone": "starter_island",
	"quest_log": [],
	"faction_reputation": {},
	"player_data": {},
	"world_flags": {}
}

var time_of_day: float = 0.6 # 0.0 = midnight, 0.5 = noon
var day_number: int = 1
var weather_state: String = "clear"

signal state_changed(new_state: String)
signal time_updated(progress: float)
signal weather_changed(new_weather: String)

func _ready():
	if GameManager.instance == null:
		GameManager.instance = self
		print("[GameManager] Initialized as singleton")
	else:
		queue_free()
		return
	
	load_game()

func _process(delta):
	update_time(delta)

func update_time(delta):
	var day_duration_seconds = 120.0 # 2 minutes per full day
	time_of_day += delta / day_duration_seconds
	
	if time_of_day >= 1.0:
		time_of_day = 0.0
		day_number += 1
		on_new_day()
	
	emit_signal("time_updated", time_of_day)

func on_new_day():
	print("[GameManager] Day ", day_number, " began")
	# Trigger daily events, NPC schedules, etc.

func change_state(new_state: String):
	game_state["current_state"] = new_state
	emit_signal("state_changed", new_state)
	print("[GameManager] State changed to: ", new_state)

func set_weather(new_weather: String):
	weather_state = new_weather
	emit_signal("weather_changed", new_weather)
	print("[GameManager] Weather changed to: ", new_weather)

func update_faction_reputation(faction_id: String, amount: int):
	if not game_state["faction_reputation"].has(faction_id):
		game_state["faction_reputation"][faction_id] = 0
	
	game_state["faction_reputation"][faction_id] += amount
	print("[GameManager] Reputation with ", faction_id, " changed by ", amount)

func get_faction_reputation(faction_id: String) -> int:
	return game_state["faction_reputation"].get(faction_id, 0)

func set_world_flag(flag_name: String, value: bool = true):
	game_state["world_flags"][flag_name] = value
	print("[GameManager] World flag set: ", flag_name, " = ", value)

func get_world_flag(flag_name: String) -> bool:
	return game_state["world_flags"].get(flag_name, false)

func save_game():
	var save_data = {
		"game_state": game_state,
		"time_of_day": time_of_day,
		"day_number": day_number,
		"weather_state": weather_state
	}
	
	var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[GameManager] Game saved successfully")

func load_game():
	if not FileAccess.file_exists("user://savegame.dat"):
		print("[GameManager] No save file found, starting new game")
		initialize_new_game()
		return
	
	var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		game_state = save_data.get("game_state", game_state)
		time_of_day = save_data.get("time_of_day", 0.6)
		day_number = save_data.get("day_number", 1)
		weather_state = save_data.get("weather_state", "clear")
		
		print("[GameManager] Game loaded successfully")

func initialize_new_game():
	game_state = {
		"current_zone": "starter_island",
		"quest_log": [],
		"faction_reputation": {
			"radiant_order": 0,
			"shadow_covenant": 0,
			"free_cities": 0
		},
		"player_data": {},
		"world_flags": {
			"met_first_npc": false,
			"defeated_first_boss": false,
			"unlocked_magic": false
		}
	}
	time_of_day = 0.6
	day_number = 1
	weather_state = "clear"
	print("[GameManager] New game initialized")
