extends Node3D

const TILE_SIZE = 0.3
var grid_size = 16   # małe kafle (16 = 8 dużych)
var tiles: Array = []
var bodies: Array = []

func _ready():
	rebuild(8)

func rebuild(big_tiles: int):
	# big_tiles = 8 lub 16 (liczba dużych kafli na bok)
	for t in tiles:
		t.queue_free()
	tiles.clear()
	for b in bodies:
		b.queue_free()
	bodies.clear()
	
	grid_size = big_tiles * 2
	for x in range(grid_size):
		for z in range(grid_size):
			_spawn_tile(x, z)

func _spawn_tile(x: int, z: int):
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(TILE_SIZE - 0.01, 0.02, TILE_SIZE - 0.01)
	mesh_instance.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	if (int(x / 2) + int(z / 2)) % 2 == 0:
		mat.albedo_color = Color(0.85, 0.85, 0.85)
	else:
		mat.albedo_color = Color(0.6, 0.6, 0.6)
	mesh_instance.material_override = mat
	
	# offset TILE_SIZE/2 żeby kafel [0,0] zaczynał się od (0,0)
	mesh_instance.position = Vector3(
		x * TILE_SIZE + TILE_SIZE / 2.0,
		0.0,
		z * TILE_SIZE + TILE_SIZE / 2.0
	)
	add_child(mesh_instance)
	tiles.append(mesh_instance)
	
	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(TILE_SIZE - 0.01, 0.02, TILE_SIZE - 0.01)
	col.shape = shape
	body.add_child(col)
	body.position = mesh_instance.position
	get_parent().call_deferred("add_child", body)
	bodies.append(body)
