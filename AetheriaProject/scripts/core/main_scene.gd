extends Node3D

@export var chunk_size: int = 16
@export var render_distance: int = 4
@export var seed: int = 12345

var world_manager: Node
var player: CharacterBody3D
var hud: CanvasLayer

signal world_loaded

func _ready() -> void:
	print("TestWorld: Initializing...")
	
	# Get references
	world_manager = get_node_or_null("/root/GameManager")
	if not world_manager:
		print("Warning: GameManager not found, creating temporary reference")
	
	# Find player
	player = $PlayerSpawn/Player
	if not player:
		print("Error: Player not found!")
	
	# Find HUD
	hud = $GameHUD
	if not hud:
		print("Warning: HUD not found")
	
	# Initialize world generation
	await _generate_initial_world()
	
	# Connect to game manager for day/night cycle
	if world_manager:
		world_manager.connect("time_changed", _on_time_changed)
	
	emit_signal("world_loaded")
	print("TestWorld: World loaded successfully!")

func _generate_initial_world() -> void:
	print("Generating initial voxel world...")
	
	# Create a simple test platform
	var voxel_world = $VoxelWorld
	if voxel_world:
		# Generate flat terrain for testing
		for x in range(-chunk_size, chunk_size):
			for z in range(-chunk_size, chunk_size):
				# Surface block
				_create_voxel_block(voxel_world, x, 0, z, "grass")
				# Dirt below
				_create_voxel_block(voxel_world, x, -1, z, "dirt")
				# Stone deeper
				_create_voxel_block(voxel_world, x, -2, z, "stone")
		
		# Add some test structures
		_create_test_structure(voxel_world, Vector3i(5, 1, 5))
		_create_test_structure(voxel_world, Vector3i(-5, 1, -5))
	
	await get_tree().create_timer(0.5).timeout

func _create_voxel_block(parent: Node3D, x: int, y: int, z: int, block_type: String) -> void:
	# Placeholder: In real implementation, this would use the WorldManager
	# For now, we create simple MeshInstance3D blocks for testing
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Block_%d_%d_%d" % [x, y, z]
	mesh_instance.transform.origin = Vector3(x, y, z)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1)
	mesh_instance.mesh = box_mesh
	
	# Simple color based on block type
	var material = StandardMaterial3D.new()
	match block_type:
		"grass":
			material.albedo_color = Color(0.2, 0.7, 0.3, 1)
		"dirt":
			material.albedo_color = Color(0.5, 0.35, 0.2, 1)
		"stone":
			material.albedo_color = Color(0.5, 0.5, 0.5, 1)
		_:
			material.albedo_color = Color(1, 1, 1, 1)
	
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _create_test_structure(parent: Node3D, center: Vector3i) -> void:
	# Create a small tower for testing
	for y in range(1, 4):
		_create_voxel_block(parent, center.x, y, center.z, "stone")
		_create_voxel_block(parent, center.x + 1, y, center.z, "stone")
		_create_voxel_block(parent, center.x, y, center.z + 1, "stone")
		_create_voxel_block(parent, center.x + 1, y, center.z + 1, "stone")
	
	# Add a torch on top
	_create_voxel_block(parent, center.x, 4, center.z, "torch")

func _on_time_changed(new_time: float) -> void:
	# Update lighting based on time of day
	var light = $DirectionalLight3D
	if light:
		var hour_angle = new_time * TAU
		light.rotation.x = hour_angle
		light.light_energy = max(0.2, sin(hour_angle))

func _input(event: InputEvent) -> void:
	# Debug: Press F5 to regenerate world
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		print("Regenerating world...")
		_clear_world()
		await _generate_initial_world()
	
	# Debug: Press F6 to teleport player to spawn
	if event is InputEventKey and event.pressed and event.keycode == KEY_F6:
		if player:
			player.global_transform.origin = $PlayerSpawn.global_transform.origin
			print("Player teleported to spawn")

func _clear_world() -> void:
	var voxel_world = $VoxelWorld
	if voxel_world:
		for child in voxel_world.get_children():
			child.queue_free()
