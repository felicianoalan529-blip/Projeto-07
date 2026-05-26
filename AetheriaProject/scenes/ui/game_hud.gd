extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/MainVBox/TopBar/HealthContainer/HealthBar
@onready var mana_bar: ProgressBar = $MarginContainer/MainVBox/TopBar/ManaContainer/ManaBar
@onready var stamina_bar: ProgressBar = $MarginContainer/MainVBox/TopBar/StaminaContainer/StaminaBar
@onready var exp_bar: ProgressBar = $MarginContainer/MainVBox/BottomBar/ExpContainer/ExpBar
@onready var exp_label: Label = $MarginContainer/MainVBox/BottomBar/ExpContainer/ExpLabel
@onready var coords_label: Label = $MarginContainer/InfoPanel/InfoVBox/CoordsLabel
@onready var time_label: Label = $MarginContainer/InfoPanel/InfoVBox/TimeLabel
@onready var biome_label: Label = $MarginContainer/InfoPanel/InfoVBox/BiomeLabel
@onready var target_info: PanelContainer = $MarginContainer/MainVBox/CenterContainer/TargetInfo
@onready var target_name: Label = $MarginContainer/MainVBox/CenterContainer/TargetInfo/TargetName
@onready var target_health_bar: ProgressBar = $MarginContainer/MainVBox/CenterContainer/TargetInfo/TargetHealthBar

var player: CharacterBody3D
var game_manager: Node

func _ready() -> void:
	print("GameHUD: Initializing...")
	
	# Find player
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player = player_node
		print("GameHUD: Connected to player")
	else:
		print("Warning: Player not found in group 'player'")
	
	# Find game manager
	game_manager = get_node_or_null("/root/GameManager")
	
	# Initialize UI values
	_update_ui_values()
	
	# Connect to player signals if available
	if player and player.has_signal("health_changed"):
		player.connect("health_changed", _on_player_health_changed)
	if player and player.has_signal("mana_changed"):
		player.connect("mana_changed", _on_player_mana_changed)
	if player and player.has_signal("stamina_changed"):
		player.connect("stamina_changed", _on_player_stamina_changed)

func _process(_delta: float) -> void:
	if player:
		# Update coordinates
		var pos = player.global_position
		coords_label.text = "Pos: %d, %d, %d" % [pos.x, pos.y, pos.z]
		
		# Update time if game manager exists
		if game_manager:
			var time_value = game_manager.get_current_time() if game_manager.has_method("get_current_time") else 0.5
			var hour = int(time_value * 24) % 24
			var minute = int((time_value * 24 * 60) % 60)
			time_label.text = "Time: %02d:%02d" % [hour, minute]

func _update_ui_values() -> void:
	# Default values if player not connected yet
	health_bar.value = 100.0
	mana_bar.value = 100.0
	stamina_bar.value = 100.0
	exp_bar.value = 0.0
	exp_label.text = "Level 1"
	coords_label.text = "Pos: 0, 0, 0"
	time_label.text = "Time: 12:00"
	biome_label.text = "Biome: Verdant Expanse"

func _on_player_health_changed(new_health: float, max_health: float) -> void:
	health_bar.value = (new_health / max_health) * 100.0

func _on_player_mana_changed(new_mana: float, max_mana: float) -> void:
	mana_bar.value = (new_mana / max_mana) * 100.0

func _on_player_stamina_changed(new_stamina: float, max_stamina: float) -> void:
	stamina_bar.value = (new_stamina / max_stamina) * 100.0

func update_target_info(target_name_text: String, target_health: float, target_max_health: float, visible: bool) -> void:
	target_info.visible = visible
	if visible:
		target_name.text = target_name_text
		target_health_bar.value = (target_health / target_max_health) * 100.0

func update_experience(current_exp: float, max_exp: float, level: int) -> void:
	exp_bar.value = (current_exp / max_exp) * 100.0 if max_exp > 0 else 0.0
	exp_label.text = "Level %d" % level

func update_biome(biome_name: String) -> void:
	biome_label.text = "Biome: " + biome_name
