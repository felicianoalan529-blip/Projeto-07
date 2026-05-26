extends Control

@onready var new_game_btn: Button = $ButtonContainer/NewGameBtn
@onready var load_game_btn: Button = $ButtonContainer/LoadGameBtn
@onready var options_btn: Button = $ButtonContainer/OptionsBtn
@onready var quit_btn: Button = $ButtonContainer/QuitBtn

var test_world_scene: PackedScene

func _ready() -> void:
	# Pre-load test world
	test_world_scene = load("res://scenes/world/test_world.tscn")
	
	# Add hover effects
	new_game_btn.mouse_entered.connect(_on_button_hover.bind(new_game_btn))
	load_game_btn.mouse_entered.connect(_on_button_hover.bind(load_game_btn))
	options_btn.mouse_entered.connect(_on_button_hover.bind(options_btn))
	quit_btn.mouse_entered.connect(_on_button_hover.bind(quit_btn))
	
	new_game_btn.mouse_exited.connect(_on_button_unhover.bind(new_game_btn))
	load_game_btn.mouse_exited.connect(_on_button_unhover.bind(load_game_btn))
	options_btn.mouse_exited.connect(_on_button_unhover.bind(options_btn))
	quit_btn.mouse_exited.connect(_on_button_unhover.bind(quit_btn))

func _on_button_hover(button: Button) -> void:
	button.modulate = Color(1.2, 1.2, 1.2)

func _on_button_unhover(button: Button) -> void:
	button.modulate = Color(1.0, 1.0, 1.0)

func _on_new_game_pressed() -> void:
	print("Starting New Game...")
	# Transition to test world
	if test_world_scene:
		get_tree().change_scene_to_packed(test_world_scene)

func _on_load_game_pressed() -> void:
	print("Load Game pressed - No saves yet")
	# TODO: Implement save system UI

func _on_options_pressed() -> void:
	print("Options pressed")
	# TODO: Implement options menu

func _on_quit_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()

func _input(event: InputEvent) -> void:
	# Allow ESC to quit from main menu
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
