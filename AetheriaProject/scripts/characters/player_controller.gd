extends CharacterBody3D

@export var movement_speed: float = 8.0
@export var sprint_speed: float = 14.0
@export var jump_velocity: float = 6.0
@export var gravity: float = -20.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var mouse_sensitivity: float = 0.002
var camera_pitch: float = 0.0
var is_sprinting: bool = false
var is_targeting: bool = false

var current_class: Resource
var equipped_spell: Resource
var health: float = 100.0
var mana: float = 100.0
var max_health: float = 100.0
var max_mana: float = 100.0

signal health_changed(new_value: float, max_value: float)
signal mana_changed(new_value: float, max_value: float)
signal spell_cast(spell_name: String)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[PlayerController] Initialized")

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative)
	
	if event.is_action_pressed("toggle_target"):
		is_targeting = !is_targeting
		print("[Player] Targeting: ", is_targeting)

func rotate_camera(mouse_delta: Vector2):
	# Yaw (horizontal rotation)
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	
	# Pitch (vertical rotation)
	camera_pitch -= mouse_delta.y * mouse_sensitivity
	camera_pitch = clamp(camera_pitch, deg_to_rad(-70), deg_to_rad(70))
	camera_pivot.rotation.x = camera_pitch

func _physics_process(delta):
	handle_movement(delta)
	apply_gravity(delta)
	move_and_slide()

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_sprinting = Input.is_action_pressed("sprint") and input_dir.length() > 0
	var current_speed = sprint_speed if is_sprinting else movement_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 5)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 5)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func cast_spell(spell: Resource, target: Node3D = null):
	if not spell:
		print("[Player] No spell equipped")
		return
	
	if mana < spell.mana_cost:
		print("[Player] Not enough mana!")
		return
	
	mana -= spell.mana_cost
	emit_signal("mana_changed", mana, max_mana)
	emit_signal("spell_cast", spell.spell_name)
	
	print("[Player] Casting: ", spell.spell_name, " at cost: ", spell.mana_cost, " MP")
	
	if has_node("MagicSystem"):
		$MagicSystem.execute_spell(spell, global_position, target)

func take_damage(amount: float, damage_type: String = "physical"):
	health = max(0, health - amount)
	emit_signal("health_changed", health, max_health)
	print("[Player] Took ", amount, " damage (", damage_type, "). HP: ", health, "/", max_health)
	
	if health <= 0:
		die()

func heal(amount: float):
	health = min(max_health, health + amount)
	emit_signal("health_changed", health, max_health)
	print("[Player] Healed ", amount, ". HP: ", health, "/", max_health)

func regenerate_mana(amount: float):
	mana = min(max_mana, mana + amount)
	emit_signal("mana_changed", mana, max_mana)

func die():
	print("[Player] PLAYER DIED")
	get_tree().reload_current_scene()

func set_class(class_resource: Resource):
	current_class = class_resource
	max_health = class_resource.base_health
	max_mana = class_resource.base_mana
	health = max_health
	mana = max_mana
	print("[Player] Class set to: ", class_resource.class_name)
	emit_signal("health_changed", health, max_health)
	emit_signal("mana_changed", mana, max_mana)

func equip_spell(spell_resource: Resource):
	equipped_spell = spell_resource
	print("[Player] Equipped spell: ", spell_resource.spell_name)
