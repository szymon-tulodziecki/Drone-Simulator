extends Node3D

const TILE_SIZE = 0.3

@onready var grid = $"/root/Main/Grid"

var built_for_size: int = -1

func _ready():
	_rebuild()
	# odśwież dekoracje, gdy gracz zmieni rozmiar siatki
	set_process(true)

func _process(_delta):
	if grid and grid.grid_size != built_for_size:
		_rebuild()

func _clear():
	for c in get_children():
		c.queue_free()

func _rebuild():
	_clear()
	built_for_size = grid.grid_size if grid else 16
	var side = built_for_size * TILE_SIZE  # długość boku siatki w metrach
	var cx = side / 2.0                    # środek siatki
	var cz = side / 2.0

	_spawn_hangar_floor(cx, cz, side)
	_spawn_safety_border(cx, cz, side)
	_spawn_corner_cones(side)

# --- studyjna podłoga z teksturą betonu ---
func _spawn_hangar_floor(cx: float, cz: float, side: float):
	var floor_size = side * 6.0
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(floor_size, 0.05, floor_size)
	floor_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	var tex = load("res://floor_diff.jpg")
	if tex:
		mat.albedo_texture = tex
		# powtarzaj teksturę co ~1 m, żeby nie była rozmazana
		mat.uv1_scale = Vector3(floor_size, floor_size, 1.0)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.albedo_color = Color(0.95, 0.95, 0.97)
	mat.roughness = 0.85
	mat.metallic = 0.02
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(cx, -0.03, cz)
	add_child(floor_mesh)

# --- żółto-czarna taśma ostrzegawcza wokół obszaru lotu ---
func _spawn_safety_border(cx: float, cz: float, side: float):
	var stripe_w = 0.12
	var stripe_h = 0.012
	var off = side / 2.0 + stripe_w / 2.0 + 0.02

	# 4 paski obwodu
	_stripe_segment(Vector3(cx, stripe_h / 2.0 + 0.001, cz - off), side + stripe_w * 2.0, stripe_w, false)
	_stripe_segment(Vector3(cx, stripe_h / 2.0 + 0.001, cz + off), side + stripe_w * 2.0, stripe_w, false)
	_stripe_segment(Vector3(cx - off, stripe_h / 2.0 + 0.001, cz), stripe_w, side + stripe_w * 2.0, true)
	_stripe_segment(Vector3(cx + off, stripe_h / 2.0 + 0.001, cz), stripe_w, side + stripe_w * 2.0, true)

func _stripe_segment(pos: Vector3, len_x: float, len_z: float, vertical: bool):
	# rysuje naprzemiennie czarne/żółte segmenty wzdłuż dłuższej osi
	var n_segments = int(max(len_x, len_z) / 0.15)
	var step_x = len_x / float(n_segments) if not vertical else len_x
	var step_z = len_z / float(n_segments) if vertical else len_z
	for i in range(n_segments):
		var seg = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(step_x, 0.012, step_z)
		seg.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.0) if i % 2 == 0 else Color(0.05, 0.05, 0.05)
		mat.roughness = 0.6
		seg.material_override = mat
		if vertical:
			seg.position = pos + Vector3(0, 0, (i - n_segments / 2.0 + 0.5) * step_z)
		else:
			seg.position = pos + Vector3((i - n_segments / 2.0 + 0.5) * step_x, 0, 0)
		add_child(seg)

# --- pomarańczowe pachołki w 4 rogach ---
func _spawn_corner_cones(side: float):
	var off = 0.35
	_spawn_cone(Vector3(-off, 0, -off))
	_spawn_cone(Vector3(side + off, 0, -off))
	_spawn_cone(Vector3(-off, 0, side + off))
	_spawn_cone(Vector3(side + off, 0, side + off))

func _spawn_cone(pos: Vector3):
	var cone = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.005
	mesh.bottom_radius = 0.09
	mesh.height = 0.25
	cone.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.35, 0.05)
	mat.roughness = 0.5
	cone.material_override = mat
	cone.position = pos + Vector3(0, 0.125, 0)
	add_child(cone)

	# biały pas odblaskowy
	var band = MeshInstance3D.new()
	var bmesh = CylinderMesh.new()
	bmesh.top_radius = 0.055
	bmesh.bottom_radius = 0.065
	bmesh.height = 0.03
	band.mesh = bmesh
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.95, 0.95)
	band.material_override = bmat
	band.position = pos + Vector3(0, 0.18, 0)
	add_child(band)

	# kwadratowa podstawa
	var base = MeshInstance3D.new()
	var basem = BoxMesh.new()
	basem.size = Vector3(0.18, 0.015, 0.18)
	base.mesh = basem
	var basemat = StandardMaterial3D.new()
	basemat.albedo_color = Color(0.1, 0.1, 0.1)
	base.material_override = basemat
	base.position = pos + Vector3(0, 0.008, 0)
	add_child(base)

