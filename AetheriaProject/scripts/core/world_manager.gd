extends Node
## World Manager - Handles voxel world generation, chunk management, and terrain manipulation
## AETHERIA: Echoes of the Supreme

signal chunk_loaded(chunk_coords: Vector3i)
signal chunk_unloaded(chunk_coords: Vector3i)
signal block_changed(global_pos: Vector3i, block_id: int)
signal structure_generated(structure_id: String, position: Vector3i)

# World Configuration
const CHUNK_SIZE: int = 16
const CHUNK_HEIGHT: int = 256
const RENDER_DISTANCE: int = 8
const WORLD_SEED: int = 1234567890

# Block Types Registry
var block_registry: Dictionary = {
	0: {"name": "Air", "solid": false, "transparent": true, "light_emission": 0},
	1: {"name": "Grass", "solid": true, "transparent": false, "light_emission": 0, "category": "natural"},
	2: {"name": "Dirt", "solid": true, "transparent": false, "light_emission": 0, "category": "natural"},
	3: {"name": "Stone", "solid": true, "transparent": false, "light_emission": 0, "category": "natural"},
	4: {"name": "Bedrock", "solid": true, "transparent": false, "light_emission": 0, "indestructible": true},
	5: {"name": "Wood", "solid": true, "transparent": false, "light_emission": 0, "category": "organic"},
	6: {"name": "Leaves", "solid": true, "transparent": true, "light_emission": 0, "category": "organic"},
	7: {"name": "Water", "solid": false, "transparent": true, "light_emission": 0, "fluid": true},
	8: {"name": "Sand", "solid": true, "transparent": false, "light_emission": 0, "category": "natural"},
	9: {"name": "Crystal", "solid": true, "transparent": true, "light_emission": 5, "category": "magical"},
	10: {"name": "Obsidian", "solid": true, "transparent": false, "light_emission": 0, "hardness": 50},
	11: {"name": "Mana Stone", "solid": true, "transparent": false, "light_emission": 8, "category": "magical"},
	12: {"name": "Ancient Brick", "solid": true, "transparent": false, "light_emission": 0, "category": "constructed"},
	13: {"name": "Rune Block", "solid": true, "transparent": false, "light_emission": 3, "category": "magical"},
	14: {"name": "Void Block", "solid": true, "transparent": true, "light_emission": 2, "category": "void"},
	15: {"name": "Fire Block", "solid": false, "transparent": true, "light_emission": 15, "damaging": true}
}

# Active Chunks Storage: Map[chunk_coords] = ChunkData
var loaded_chunks: Dictionary = {}
var pending_chunk_updates: Array = []

# Noise Generators for Terrain
var terrain_noise: FastNoiseLite
var cave_noise: FastNoiseLite
var biome_noise: FastNoiseLite
var structure_noise: FastNoiseLite

# Time and Weather
var current_time: float = 0.0 # 0.0-1.0 (day cycle)
var weather_state: Dictionary = {"type": "clear", "intensity": 0.0}

# Singleton Instance
static var instance: WorldManager

func _ready() -> void:
	instance = self
	initialize_noise_generators()
	print("[WorldManager] Initialized - Voxel World System Ready")

func initialize_noise_generators() -> void:
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = WORLD_SEED
	terrain_noise.frequency = 0.01
	terrain_noise.fractal_octaves = 4
	
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = WORLD_SEED + 1
	cave_noise.frequency = 0.03
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = WORLD_SEED + 2
	biome_noise.frequency = 0.005
	
	structure_noise = FastNoiseLite.new()
	structure_noise.seed = WORLD_SEED + 3
	structure_noise.frequency = 0.002

func update_time(normalized_time: float) -> void:
	current_time = normalized_time
	# Update lighting, mob spawning, etc based on time

func get_block(global_pos: Vector3i) -> int:
	var chunk_coords = world_to_chunk(global_pos)
	var local_pos = world_to_local(global_pos)
	
	if loaded_chunks.has(chunk_coords):
		var chunk_data = loaded_chunks[chunk_coords]
		return chunk_data.get_block(local_pos)
	
	return 0 # Air

func set_block(global_pos: Vector3i, block_id: int, update_meshes: bool = true) -> void:
	var chunk_coords = world_to_chunk(global_pos)
	var local_pos = world_to_local(global_pos)
	
	if loaded_chunks.has(chunk_coords):
		var chunk_data = loaded_chunks[chunk_coords]
		chunk_data.set_block(local_pos, block_id)
		emit_signal("block_changed", global_pos, block_id)
		
		if update_meshes:
			update_chunk_mesh(chunk_coords)
			# Update neighboring chunks if on border
			update_neighboring_chunks(global_pos, chunk_coords)

func update_neighboring_chunks(global_pos: Vector3i, center_chunk: Vector3i) -> void:
	var local_pos = world_to_local(global_pos)
	
	# Check each axis for border blocks
	if local_pos.x == 0:
		update_chunk_mesh(center_chunk + Vector3i(-1, 0, 0))
	elif local_pos.x == CHUNK_SIZE - 1:
		update_chunk_mesh(center_chunk + Vector3i(1, 0, 0))
	
	if local_pos.y == 0:
		update_chunk_mesh(center_chunk + Vector3i(0, -1, 0))
	elif local_pos.y == CHUNK_SIZE - 1:
		update_chunk_mesh(center_chunk + Vector3i(0, 1, 0))
	
	if local_pos.z == 0:
		update_chunk_mesh(center_chunk + Vector3i(0, 0, -1))
	elif local_pos.z == CHUNK_SIZE - 1:
		update_chunk_mesh(center_chunk + Vector3i(0, 0, 1))

func world_to_chunk(global_pos: Vector3i) -> Vector3i:
	return Vector3i(
		floori(float(global_pos.x) / CHUNK_SIZE),
		floori(float(global_pos.y) / CHUNK_SIZE),
		floori(float(global_pos.z) / CHUNK_SIZE)
	)

func world_to_local(global_pos: Vector3i) -> Vector3i:
	var local_x = wrapi(global_pos.x, 0, CHUNK_SIZE)
	var local_y = wrapi(global_pos.y, 0, CHUNK_SIZE)
	var local_z = wrapi(global_pos.z, 0, CHUNK_SIZE)
	return Vector3i(local_x, local_y, local_z)

func load_chunk(chunk_coords: Vector3i) -> void:
	if loaded_chunks.has(chunk_coords):
		return
	
	var chunk_data = generate_chunk(chunk_coords)
	loaded_chunks[chunk_coords] = chunk_data
	
	emit_signal("chunk_loaded", chunk_coords)
	update_chunk_mesh(chunk_coords)

func unload_chunk(chunk_coords: Vector3i) -> void:
	if loaded_chunks.has(chunk_coords):
		loaded_chunks.erase(chunk_coords)
		emit_signal("chunk_unloaded", chunk_coords)

func generate_chunk(chunk_coords: Vector3i) -> Node:
	var chunk = Node.new()
	chunk.name = "Chunk_%d_%d_%d" % [chunk_coords.x, chunk_coords.y, chunk_coords.z]
	chunk.set_meta("chunk_coords", chunk_coords)
	
	# Initialize block array (CHUNK_SIZE^3)
	var blocks = PackedInt32Array()
	blocks.resize(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE)
	
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var global_y = chunk_coords.y * CHUNK_SIZE + y
				var global_x = chunk_coords.x * CHUNK_SIZE + x
				var global_z = chunk_coords.z * CHUNK_SIZE + z
				
				var block_id = generate_block_at(Vector3i(global_x, global_y, global_z))
				var index = x + y * CHUNK_SIZE + z * CHUNK_SIZE * CHUNK_SIZE
				blocks[index] = block_id
	
	chunk.set_meta("blocks", blocks)
	return chunk

func generate_block_at(global_pos: Vector3i) -> int:
	var x = global_pos.x
	var y = global_pos.y
	var z = global_pos.z
	
	# Bedrock layer
	if y <= 0:
		return 4 # Bedrock
	
	# Cave generation
	var cave_value = cave_noise.get_noise_3d(x, y, z)
	if cave_value > 0.6 and y > 5:
		return 0 # Air (cave)
	
	# Terrain height
	var terrain_height = get_terrain_height(x, z)
	
	if y > terrain_height:
		return 0 # Air
	
	# Surface blocks
	if y == terrain_height:
		var biome = get_biome_at(x, z)
		match biome:
			"verdant": return 1 # Grass
			"crystal_peaks": return 9 # Crystal
			"ashen": return 10 # Obsidian
			"swamp": return 8 # Sand/Mud
			"desert": return 8 # Sand
			_: return 1 # Default grass
	elif y > terrain_height - 3:
		return 2 # Dirt
	else:
		# Underground - chance for ores and magical blocks
		var ore_noise = terrain_noise.get_noise_3d(x * 2, y * 2, z * 2)
		if ore_noise > 0.85 and y < 50:
			return 11 # Mana Stone
		elif ore_noise > 0.80 and y < 30:
			return 9 # Crystal
		else:
			return 3 # Stone

func get_terrain_height(x: int, z: int) -> int:
	var noise_value = terrain_noise.get_noise_2d(x, z)
	var base_height = 64
	var height_variation = int(noise_value * 40)
	return base_height + height_variation

func get_biome_at(x: int, z: int) -> String:
	var noise_value = biome_noise.get_noise_2d(x, z)
	var temperature = terrain_noise.get_noise_2d(x * 0.5, z * 0.5)
	
	if noise_value > 0.5:
		if temperature > 0.3:
			return "crystal_peaks"
		else:
			return "verdant"
	elif noise_value > 0.0:
		if temperature < -0.3:
			return "ashen"
		else:
			return "swamp"
	else:
		if temperature > 0.5:
			return "desert"
		else:
			return "verdant"

func update_chunk_mesh(chunk_coords: Vector3i) -> void:
	if not loaded_chunks.has(chunk_coords):
		return
	
	var chunk = loaded_chunks[chunk_coords]
	var mesh_instance = chunk.get_node_or_null("MeshInstance3D")
	
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		chunk.add_child(mesh_instance)
	
	var mesh_data = build_chunk_mesh(chunk)
	if mesh_data:
		mesh_instance.mesh = mesh_data

func build_chunk_mesh(chunk: Node) -> ArrayMesh:
	var blocks = chunk.get_meta("blocks")
	if not blocks:
		return null
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var vertex_count = 0
	
	var chunk_coords = chunk.get_meta("chunk_coords")
	
	# Greedy meshing would go here for optimization
	# For now, simple face culling
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var index = x + y * CHUNK_SIZE + z * CHUNK_SIZE * CHUNK_SIZE
				var block_id = blocks[index]
				
				if block_id == 0 or not block_registry.get(block_id, {}).get("solid", false):
					continue
				
				var global_x = chunk_coords.x * CHUNK_SIZE + x
				var global_y = chunk_coords.y * CHUNK_SIZE + y
				var global_z = chunk_coords.z * CHUNK_SIZE + z
				
				# Check each face for visibility
				add_cube_faces(vertices, normals, uvs, indices, 
					Vector3(global_x, global_y, global_z), block_id, vertex_count)
				vertex_count += 24 # 6 faces * 4 vertices per face (triangles)
	
	if vertices.size() == 0:
		return null
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func add_cube_faces(vertices: PackedVector3Array, normals: PackedVector3Array, 
	uvs: PackedVector2Array, indices: PackedInt32Array, 
	position: Vector3, block_id: int, vertex_offset: int) -> void:
	
	var block_info = block_registry.get(block_id, {})
	
	# Simple face culling - check neighbors
	var directions = [
		Vector3i.RIGHT, Vector3i.LEFT,
		Vector3i.UP, Vector3i.DOWN,
		Vector3i.FORWARD, Vector3i.BACK
	]
	
	var face_normals = [
		Vector3.RIGHT, Vector3.LEFT,
		Vector3.UP, Vector3.DOWN,
		Vector3.FORWARD, Vector3.BACK
	]
	
	for i in range(6):
		var neighbor_pos = Vector3i(position) + directions[i]
		var neighbor_block = get_block(neighbor_pos)
		var neighbor_info = block_registry.get(neighbor_block, {})
		
		# Only add face if neighbor is air or transparent
		if neighbor_block == 0 or neighbor_info.get("transparent", false):
			add_face(vertices, normals, uvs, indices, position, face_normals[i], 
				block_id, vertex_offset + indices.size())

func add_face(vertices: PackedVector3Array, normals: PackedVector3Array,
	uvs: PackedVector2Array, indices: PackedInt32Array,
	position: Vector3, normal: Vector3, block_id: int, index_offset: int) -> void:
	
	# Define face vertices based on normal
	var face_vertices = get_face_vertices(position, normal)
	
	for v in face_vertices:
		vertices.append(v)
		normals.append(normal)
		uvs.append(Vector2(0, 0)) # Placeholder UV
	
	# Add triangle indices
	var base = index_offset
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)

func get_face_vertices(position: Vector3, normal: Vector3) -> Array:
	var size = 1.0
	var half = size / 2.0
	
	match normal:
		Vector3.UP:
			return [
				position + Vector3(-half, half, -half),
				position + Vector3(half, half, -half),
				position + Vector3(half, half, half),
				position + Vector3(-half, half, half)
			]
		Vector3.DOWN:
			return [
				position + Vector3(-half, -half, -half),
				position + Vector3(-half, -half, half),
				position + Vector3(half, -half, half),
				position + Vector3(half, -half, -half)
			]
		Vector3.FORWARD:
			return [
				position + Vector3(-half, -half, half),
				position + Vector3(half, -half, half),
				position + Vector3(half, half, half),
				position + Vector3(-half, half, half)
			]
		Vector3.BACK:
			return [
				position + Vector3(half, -half, -half),
				position + Vector3(-half, -half, -half),
				position + Vector3(-half, half, -half),
				position + Vector3(half, half, -half)
			]
		Vector3.RIGHT:
			return [
				position + Vector3(half, -half, -half),
				position + Vector3(half, half, -half),
				position + Vector3(half, half, half),
				position + Vector3(half, -half, half)
			]
		Vector3.LEFT:
			return [
				position + Vector3(-half, -half, -half),
				position + Vector3(-half, -half, half),
				position + Vector3(-half, half, half),
				position + Vector3(-half, half, -half)
			]
	
	return []

func update_player_chunks(player_position: Vector3) -> void:
	var player_chunk = world_to_chunk(Vector3i(player_position))
	
	# Load chunks within render distance
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			for y in range(-2, 2): # Limited vertical range
				var chunk_coords = player_chunk + Vector3i(x, y, z)
				load_chunk(chunk_coords)
	
	# Unload distant chunks
	var chunks_to_unload = []
	for chunk_coords in loaded_chunks.keys():
		var distance = chunk_coords.distance_to(player_chunk)
		if distance > RENDER_DISTANCE + 2:
			chunks_to_unload.append(chunk_coords)
	
	for chunk_coords in chunks_to_unload:
		unload_chunk(chunk_coords)

func generate_structure(structure_type: String, position: Vector3i) -> bool:
	# Structure generation logic for dungeons, ruins, player bases
	var structure_templates = load_structure_templates()
	
	if structure_templates.has(structure_type):
		var template = structure_templates[structure_type]
		place_structure(template, position)
		emit_signal("structure_generated", structure_type, position)
		return true
	
	return false

func load_structure_templates() -> Dictionary:
	# Load structure definitions from resources
	return {
		"ancient_ruin": {"size": Vector3i(32, 16, 32), "blocks": []},
		"player_tower": {"size": Vector3i(16, 48, 16), "blocks": []},
		"dungeon_entrance": {"size": Vector3i(24, 24, 24), "blocks": []}
	}

func place_structure(template: Dictionary, origin: Vector3i) -> void:
	var size = template.size
	var blocks = template.blocks
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var index = x + y * size.x + z * size.x * size.y
				if index < blocks.size():
					var block_id = blocks[index]
					if block_id != 0:
						set_block(origin + Vector3i(x, y, z), block_id, false)
