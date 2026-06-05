extends Node3D

const TILE_SIZE = 0.3

func _ready():
	# Helipad na pozycji startowej (x=1, y=2 w dużych kaflach)
	_spawn_helipad(1, 2)
	# Helipad lądowania (x=4, y=1)
	_spawn_helipad(4, 1)

func _spawn_helipad(tx: int, tz: int):
	# środek dużego kafla
	var cx = tx * TILE_SIZE * 2 + TILE_SIZE
	var cz = tz * TILE_SIZE * 2 + TILE_SIZE
	var y = 0.025  # tuż nad podłogą żeby nie z-fighting'owało
	
	# Żółty kwadrat 50x50cm
	var pad = MeshInstance3D.new()
	var pad_mesh = BoxMesh.new()
	pad_mesh.size = Vector3(0.5, 0.005, 0.5)
	pad.mesh = pad_mesh
	var pad_mat = StandardMaterial3D.new()
	pad_mat.albedo_color = Color(1.0, 0.85, 0.0)
	pad.material_override = pad_mat
	pad.position = Vector3(cx, y, cz)
	add_child(pad)
	
	# Litera H - 3 białe paski tworzące H
	var h_color = Color(1, 1, 1)
	var h_height = 0.006
	
	# Lewy słupek H
	_spawn_bar(cx - 0.10, y + 0.001, cz, 0.05, h_height, 0.30, h_color)
	# Prawy słupek H
	_spawn_bar(cx + 0.10, y + 0.001, cz, 0.05, h_height, 0.30, h_color)
	# Pozioma belka H
	_spawn_bar(cx, y + 0.001, cz, 0.25, h_height, 0.05, h_color)

func _spawn_bar(px: float, py: float, pz: float, sx: float, sy: float, sz: float, c: Color):
	var bar = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(sx, sy, sz)
	bar.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = c
	bar.material_override = mat
	bar.position = Vector3(px, py, pz)
	add_child(bar)
