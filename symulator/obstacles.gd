extends Node3D

const TILE_SIZE = 0.3

func _ready():
	# Słupek A (koniec przeszkody 1)
	_spawn_pole(0.415, 2.215)
	
	# Słupek wspólny B (róg)
	_spawn_pole(0.415, 3.185)
	
	# Słupek C (koniec przeszkody 2)
	_spawn_pole(1.385, 3.185)
	
	# Kółka przeszkody 1
	_spawn_ring(Vector3(0.415, 0.875, 2.7), Vector3(90, 90, 0))
	_spawn_ring(Vector3(0.415, 1.800, 2.7), Vector3(90, 90, 0))
	
	# Kółka przeszkody 2
	_spawn_ring(Vector3(0.9, 0.875, 3.185), Vector3(0, 90, 90))
	_spawn_ring(Vector3(0.9, 1.800, 3.185), Vector3(0, 90, 90))

func _spawn_pole(px: float, pz: float):
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.height = 2.25
	mesh.top_radius = 0.04
	mesh.bottom_radius = 0.04
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(px, 2.25 / 2.0, pz)
	add_child(mesh_instance)
	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 2.25
	shape.radius = 0.04
	col.shape = shape
	body.add_child(col)
	body.position = mesh_instance.position
	add_child(body)

func _spawn_ring(pos: Vector3, rot_deg: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.425
	mesh.outer_radius = 0.485
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0)
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rot_deg
	add_child(mesh_instance)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	for i in range(8):
		var angle = i * PI * 2.0 / 8.0
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.06
		col.shape = shape
		col.position = Vector3(cos(angle) * 0.455, sin(angle) * 0.455, 0)
		body.add_child(col)
	add_child(body)
