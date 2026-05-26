extends CharacterBody3D
class_name PlayerCharacter

## Player Character Controller - Movimento em terceira pessoa com câmera estilo FF12
## AETHERIA: Echoes of the Supreme

signal health_changed(current: int, max_hp: int)
signal mana_changed(current: int, max_mp: int)
signal stamina_changed(current: int, max_stamina: int)
signal player_died()
signal block_placed(block_type: String, position: Vector3i)
signal block_destroyed(position: Vector3i)

# Configurações de Movimento
@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var air_control: float = 0.3
@export var jump_velocity: float = 8.0
@export var gravity: float = -20.0
@export var climb_speed: float = 3.0

# Configurações de Câmera
@export_group("Camera")
@export var camera_distance: float = 12.0
@export var camera_height: float = 6.0
@export var camera_rotation_speed: float = 3.0
@export var camera_min_angle: float = -60.0
@export var camera_max_angle: float = 30.0
@export var camera_collision_layers: int = 1  # Layer 1 = world_static

# Sistema de Combate
@export_group("Combat")
@export var base_attack_damage: float = 10.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 0.8
@export var block_reach: float = 6.0

# Stats do Personagem
var max_hp: int = 100
var current_hp: int = 100
var max_mp: int = 50
var current_mp: int = 50
var max_stamina: int = 100
var current_stamina: int = 100

# Estado Atual
var is_sprinting: bool = false
var is_climbing: bool = false
var is_interacting: bool = false
var is_dead: bool = false
var current_class_data: ClassData = null
var equipped_spells: Array[SpellData] = []

# Componentes
var camera_pivot: Node3D
var camera_spring: SpringArm3D
var camera_node: Camera3D
var model_container: Node3D
var interaction_raycast: RayCast3D

# Variáveis Internas
var _camera_angle_h: float = 0.0  # Horizontal (yaw)
var _camera_angle_v: float = 10.0  # Vertical (pitch)
var _velocity: Vector3 = Vector3.ZERO
var _last_attack_time: float = -999.0
var _stamina_regen_timer: float = 0.0
var _character_name: String = "Echo"

func _ready() -> void:
	_setup_components()
	_initialize_stats()
	_connect_signals()
	print("[PlayerController] Initialized for %s" % _character_name)

func _setup_components() -> void:
	# Criar pivot da câmera (rotação horizontal)
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.8, 0)  # Altura dos olhos
	add_child(camera_pivot)
	
	# Criar spring arm para distância da câmera
	camera_spring = SpringArm3D.new()
	camera_spring.name = "CameraSpring"
	camera_spring.spring_length = camera_distance
	camera_spring.collision_mask = camera_collision_layers
	camera_spring.position = Vector3(0, camera_height, 0)
	camera_pivot.add_child(camera_spring)
	
	# Criar câmera
	camera_node = Camera3D.new()
	camera_node.name = "MainCamera"
	camera_node.current = true
	camera_spring.add_child(camera_node)
	
	# Container do modelo 3D
	model_container = Node3D.new()
	model_container.name = "ModelContainer"
	add_child(model_container)
	
	# Raycast para interação
	interaction_raycast = RayCast3D.new()
	interaction_raycast.name = "InteractionRaycast"
	interaction_raycast.target_position = Vector3(0, 0, -block_reach)
	interaction_raycast.collision_mask = 1  # World static
	add_child(interaction_raycast)

func _initialize_stats() -> void:
	current_hp = max_hp
	current_mp = max_mp
	current_stamina = max_stamina

func _connect_signals() -> void:
	# Conectar sinais do GameManager se disponível
	if Engine.has_singleton("GameManager"):
		GameManager.connect("game_state_changed", _on_game_state_changed)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_handle_input(delta)
	_apply_gravity(delta)
	_update_movement(delta)
	_update_camera(delta)
	_regenerate_resources(delta)
	
	move_and_slide()

func _handle_input(delta: float) -> void:
	# Movimento
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Sprint
	is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 10 and input_dir.length() > 0
	
	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_velocity.y = jump_velocity
		if is_sprinting:
			consume_stamina(15)
	
	# Rotação da câmera
	if Input.is_action_pressed("camera_rotate_left"):
		_camera_angle_h -= camera_rotation_speed * delta * 60.0
	if Input.is_action_pressed("camera_rotate_right"):
		_camera_angle_h += camera_rotation_speed * delta * 60.0
	
	# Zoom da câmera
	var zoom_input = Input.get_axis("camera_zoom_out", "camera_zoom_in")
	if zoom_input != 0:
		camera_spring.spring_length = clamp(
			camera_spring.spring_length + zoom_input * 8.0 * delta,
			5.0,
			20.0
		)
	
	# Interação com blocos
	if Input.is_action_just_pressed("interact") and not is_interacting:
		_try_interact()
	
	# Colocar bloco
	if Input.is_action_just_pressed("place_block"):
		_try_place_block()
	
	# Destruir bloco
	if Input.is_action_just_pressed("destroy_block"):
		_try_destroy_block()
	
	# Lançar magias
	for i in range(3):
		if Input.is_action_just_pressed("cast_spell_%d" % (i + 1)):
			_cast_equipped_spell(i)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		_velocity.y += gravity * delta

func _update_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if input_dir == Vector2.ZERO:
		return
	
	# Determinar velocidade baseada no sprint
	var speed = sprint_speed if is_sprinting else walk_speed
	
	# Obter direção relativa à câmera
	var cam_dir = -camera_pivot.global_transform.basis.z
	cam_dir.y = 0
	cam_dir = cam_dir.normalized()
	
	var cam_right = camera_pivot.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	var move_dir = (cam_dir * input_dir.y + cam_right * input_dir.x).normalized()
	
	# Aplicar controle aéreo reduzido
	if not is_on_floor():
		speed *= air_control
	
	# Suavizar movimento
	_velocity.x = move_dir.x * speed
	_velocity.z = move_dir.z * speed
	
	# Rotacionar modelo na direção do movimento
	if move_dir.length() > 0.1:
		var target_rotation = atan2(move_dir.x, move_dir.z)
		var current_rotation = rotation.y
		var diff = wrapf(target_rotation - current_rotation, -PI, PI)
		rotation.y = lerp_angle(current_rotation, current_rotation + diff, 10.0 * delta)

func _update_camera(_delta: float) -> void:
	# Aplicar ângulos da câmera
	camera_pivot.rotation.y = deg_to_rad(_camera_angle_h)
	camera_spring.position.y = camera_height + sin(deg_to_rad(_camera_angle_v)) * camera_distance * 0.3

func _regenerate_resources(delta: float) -> void:
	# Regeneração de stamina
	if not is_sprinting and current_stamina < max_stamina:
		_stamina_regen_timer += delta
		if _stamina_regen_timer >= 1.0:  # 1 segundo sem ação para começar regen
			current_stamina = min(current_stamina + int(10 * delta), max_stamina)
			stamina_changed.emit(current_stamina, max_stamina)
	else:
		_stamina_regen_timer = 0.0
	
	# Regeneração de MP (mais lenta)
	if current_mp < max_mp and not is_casting:
		current_mp = min(current_mp + int(2 * delta), max_mp)
		mana_changed.emit(current_mp, max_mp)

func _try_interact() -> void:
	interaction_raycast.force_raycast_update()
	
	if interaction_raycast.is_colliding():
		var collider = interaction_raycast.get_collider()
		print("[PlayerController] Interacting with: %s" % collider.name)
		
		# Verificar se é NPC, baú, alavanca, etc.
		if collider.has_method("interact"):
			collider.interact(self)

func _try_place_block() -> void:
	interaction_raycast.force_raycast_update()
	
	if interaction_raycast.is_colliding():
		var collision_point = interaction_raycast.get_collision_point()
		var collision_normal = interaction_raycast.get_collision_normal()
		
		# Calcular posição do voxel
		var place_pos = (collision_point + collision_normal * 0.5).floor()
		
		# Tentar colocar bloco via WorldManager
		if Engine.has_singleton("VoxelWorldManager"):
			var block_type = "stone"  # TODO: Pegar do inventory
			if VoxelWorldManager.place_block(place_pos, block_type):
				block_placed.emit(block_type, place_pos)
				consume_stamina(5)

func _try_destroy_block() -> void:
	interaction_raycast.force_raycast_update()
	
	if interaction_raycast.is_colliding():
		var collision_point = interaction_raycast.get_collision_point()
		var destroy_pos = collision_point.floor()
		
		# Tentar destruir bloco via WorldManager
		if Engine.has_singleton("VoxelWorldManager"):
			if VoxelWorldManager.destroy_block(destroy_pos):
				block_destroyed.emit(destroy_pos)
				# Adicionar item ao inventory
				_add_loot_item("stone", 1)

func _cast_equipped_spell(slot: int) -> void:
	if slot >= equipped_spells.size():
		return
	
	var spell = equipped_spells[slot]
	if spell == null:
		return
	
	if current_mp < spell.mp_cost:
		print("[PlayerController] Not enough MP for %s" % spell.spell_name)
		return
	
	# Usar MagicSystem singleton
	if Engine.has_singleton("MagicSystem"):
		MagicSystem.cast_spell(spell, self, get_global_mouse_position())

func perform_attack() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_attack_time < attack_cooldown:
		return
	
	_last_attack_time = current_time
	
	# Detectar inimigos no alcance
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	query.shape.radius = attack_range
	query.transform = global_transform
	query.collision_mask = 4  # Characters layer
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result.collider
		if collider.has_method("take_damage"):
			collider.take_damage(base_attack_damage, DamageType.PHYSICAL, self)
	
	# TODO: Tocar animação de ataque e VFX
	print("[PlayerController] Performed attack, hit %d targets" % results.size())

func take_damage(amount: float, damage_type: DamageType, attacker: Node = null) -> void:
	if is_dead:
		return
	
	# Aplicar redução de defesa
	var actual_damage = amount * (100.0 / (100.0 + get_stat("defense")))
	actual_damage = max(1, int(actual_damage))
	
	current_hp = max(0, current_hp - actual_damage)
	health_changed.emit(current_hp, max_hp)
	
	print("[PlayerController] Took %d damage (%s)" % [actual_damage, damage_type])
	
	if current_hp <= 0:
		die(attacker)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func consume_stamina(amount: int) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_changed.emit(current_stamina, max_stamina)
		return true
	return false

func consume_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		mana_changed.emit(current_mp, max_mp)
		return true
	return false

func get_stat(stat_name: String) -> int:
	match stat_name:
		"strength":
			return 10 + (current_class_data.strength_bonus if current_class_data else 0)
		"magic":
			return 10 + (current_class_data.magic_bonus if current_class_data else 0)
		"defense":
			return 10 + (current_class_data.defense_bonus if current_class_data else 0)
		"agility":
			return 10 + (current_class_data.agility_bonus if current_class_data else 0)
		_:
			return 10

func die(killer: Node = null) -> void:
	is_dead = true
	player_died.emit()
	print("[PlayerController] %s died!" % _character_name)
	
	# TODO: Spawn effect, trigger respawn, etc.
	
	if killer:
		# Award exp to killer
		pass

func respawn(spawn_point: Vector3) -> void:
	is_dead = false
	current_hp = max_hp
	current_mp = max_mp
	current_stamina = max_stamina
	global_position = spawn_point
	
	health_changed.emit(current_hp, max_hp)
	mana_changed.emit(current_mp, max_mp)
	stamina_changed.emit(current_stamina, max_stamina)
	
	print("[PlayerController] Respawned at %s" % spawn_point)

func apply_character_data(data: CharacterData) -> void:
	_character_name = data.character_name
	max_hp = data.base_hp
	max_mp = data.base_mp
	current_hp = max_hp
	current_mp = max_mp
	
	if data.primary_class:
		current_class_data = data.primary_class
		_apply_class_bonuses(data.primary_class)

func _apply_class_bonuses(class_data: ClassData) -> void:
	max_hp += class_data.hp_bonus
	max_mp += class_data.mp_bonus
	# Aplicar outros bônus...

func _add_loot_item(item_id: String, quantity: int) -> void:
	# TODO: Adicionar ao inventory
	print("[PlayerController] Received %d x %s" % [quantity, item_id])

func get_global_mouse_position() -> Vector3:
	# Raycast do mouse para obter posição 3D
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera_node.project_ray_origin(mouse_pos)
	var to = from + camera_node.project_ray_normal(mouse_pos) * 100.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 4  # World + Characters
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return to

func _on_game_state_changed(old_state: int, new_state: int) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			set_process(false)
			set_physics_process(false)
		GameManager.GameState.PLAYING, GameManager.GameState.COMBAT:
			set_process(true)
			set_physics_process(true)

# Classe auxiliar para tipos de dano
enum DamageType {
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	HOLY,
	DARK,
	NATURE,
	ARCANE
}
