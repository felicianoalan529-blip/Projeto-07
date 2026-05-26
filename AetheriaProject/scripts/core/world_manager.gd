extends Node3D

class_name WorldManager

@export var chunk_size: int = 16
@export var render_distance: int = 4
@export var seed_value: int = 12345

var chunks: Dictionary = {}
var noise: FastNoiseLite

signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)

func _ready():
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	print("[WorldManager] Initialized with seed: ", seed_value)

func get_chunk_key(chunk_pos: Vector3i) -> String:
	return "%d,%d,%d" % [chunk_pos.x, chunk_pos.y, chunk_pos.z]

func generate_chunk(chunk_pos: Vector3i):
	var key = get_chunk_key(chunk_pos)
	
	if chunks.has(key):
		return # Already generated
	
	print("[WorldManager] Generating chunk at: ", chunk_pos)
	
	var chunk_data = {
		"position": chunk_pos,
		"blocks": {},
		"mesh": null,
		"generated": true
	}
	
	# Generate terrain height using noise
	for x in range(chunk_size):
		for z in range(chunk_size):
			var world_x = chunk_pos.x * chunk_size + x
			var world_z = chunk_pos.z * chunk_size + z
			
			var height = get_terrain_height(world_x, world_z)
			
			for y in range(chunk_size):
				var world_y = chunk_pos.y * chunk_size + y
				
				if world_y < height:
					var block_type = determine_block_type(world_y, height)
					chunk_data["blocks"][Vector3i(x, y, z)] = block_type
	
	chunks[key] = chunk_data
	emit_signal("chunk_loaded", chunk_pos)
	
	return chunk_data

func get_terrain_height(world_x: int, world_z: int) -> int:
	var noise_value = noise.get_noise_2d(world_x, world_z)
	# Map noise (-1 to 1) to height (0 to 20)
	var height = int(map_range(noise_value, -1, 1, 5, 20))
	return height

func determine_block_type(y: int, surface_y: int) -> String:
	if y == surface_y:
		return "grass"
	elif y < surface_y - 3:
		return "stone"
	else:
		return "dirt"

func get_block(world_pos: Vector3i) -> String:
	var chunk_pos = world_to_chunk(world_pos)
	var local_pos = world_to_local(world_pos)
	var key = get_chunk_key(chunk_pos)
	
	if chunks.has(key):
		return chunks[key]["blocks"].get(local_pos, "air")
	
	return "air"

func set_block(world_pos: Vector3i, block_type: String):
	var chunk_pos = world_to_chunk(world_pos)
	var local_pos = world_to_local(world_pos)
	var key = get_chunk_key(chunk_pos)
	
	if chunks.has(key):
		chunks[key]["blocks"][local_pos] = block_type
		print("[WorldManager] Block set at ", world_pos, " to ", block_type)
		# In real implementation, regenerate mesh for this chunk

func world_to_chunk(world_pos: Vector3i) -> Vector3i:
	return Vector3i(
		floori(world_pos.x / float(chunk_size)),
		floori(world_pos.y / float(chunk_size)),
		floori(world_pos.z / float(chunk_size))
	)

func world_to_local(world_pos: Vector3i) -> Vector3i:
	var local = Vector3i(
		wrapi(world_pos.x, 0, chunk_size),
		wrapi(world_pos.y, 0, chunk_size),
		wrapi(world_pos.z, 0, chunk_size)
	)
	return local

func map_range(value: float, from_low: float, from_high: float, to_low: float, to_high: float) -> float:
	return to_low + (value - from_low) * (to_high - to_low) / (from_high - from_low)

func update_chunks_around(player_pos: Vector3):
	var player_chunk = world_to_chunk(Vector3i(floor(player_pos.x), floor(player_pos.y), floor(player_pos.z)))
	
	# Load chunks within render distance
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector3i(player_chunk.x + x, 0, player_chunk.z + z)
			generate_chunk(chunk_pos)
	
	# Unload distant chunks (simplified - would need proper tracking)
	# This is a placeholder for actual LOD/unloading logic

func get_biome_at(world_x: int, world_z: int) -> String:
	# Use a different noise layer for biome determination
	var biome_noise = noise.get_noise_2d(world_x * 0.01, world_z * 0.01)
	
	if biome_noise > 0.6:
		return "crystal_peaks"
	elif biome_noise > 0.3:
		return "verdant_expanse"
	elif biome_noise > 0.0:
		return "whispering_swamp"
	elif biome_noise > -0.3:
		return "ashen_wastes"
	else:
		return "obsidian_desert"
