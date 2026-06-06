extends Node3D

# func _ready():
#     # === SŁUPKI (wysokość 1.9m) ===
#     var pole_h = 1.9
#     var pole_r = 0.04
#     
#     _spawn_pole(3.6, 1.2, pole_h, pole_r)
#     _spawn_pole(3.6, 4.2, pole_h, pole_r)
#     
#     # === POPRZECZKA NA SZCZYCIE ===
#     _spawn_crossbar(3.6, 2.7, 3.0, 1.9)
#     
#     # === KOŁA (średnica 70cm, obręcz 2cm) ===
#     var r_outer = 0.36
#     var r_inner = 0.34
#     var color = Color(0.9, 0.1, 0.1)
#     
#     # Górny rząd: 4 koła pionowo (prostopadle do osi Z)
#     var upper_y = 1.52
#     var upper_z = [1.67, 2.37, 3.07, 3.77]
#     for z in upper_z:
#         _spawn_ring(Vector3(3.6, upper_y, z), Vector3(0, 0, 90), r_inner, r_outer, color)
#     # Dolny rząd: 3 koła w "zagłębieniach"
#     var lower_y = upper_y - 0.6062
#     var lower_z = [2.02, 2.72, 3.42]
#     
#     for z in lower_z:
#         _spawn_ring(Vector3(3.6, lower_y, z), Vector3(0, 0, 90), r_inner, r_outer, color)
# 
#     # --- ZAPIS DO OBIEKTU ---
#     call_deferred("save_to_scene")
# 
# func _spawn_pole(px: float, pz: float, h: float, r: float):
#     var mesh_instance = MeshInstance3D.new()
#     var mesh = CylinderMesh.new()
#     mesh.height = h
#     mesh.top_radius = r
#     mesh.bottom_radius = r
#     mesh_instance.mesh = mesh
#     
#     var mat = StandardMaterial3D.new()
#     mat.albedo_color = Color(0.2, 0.2, 0.2)
#     mesh_instance.material_override = mat
#     
#     mesh_instance.position = Vector3(px, h / 2.0, pz)
#     add_child(mesh_instance)
#     
#     var body = StaticBody3D.new()
#     var col = CollisionShape3D.new()
#     var shape = CylinderShape3D.new()
#     shape.height = h
#     shape.radius = r
#     col.shape = shape
#     body.add_child(col)
#     body.position = mesh_instance.position
#     add_child(body)
# 
# func _spawn_crossbar(px: float, pz: float, length: float, y: float):
#     var mesh_instance = MeshInstance3D.new()
#     var mesh = CylinderMesh.new()
#     mesh.height = length
#     mesh.top_radius = 0.02
#     mesh.bottom_radius = 0.02
#     mesh_instance.mesh = mesh
#     
#     var mat = StandardMaterial3D.new()
#     mat.albedo_color = Color(0.2, 0.2, 0.2)
#     mesh_instance.material_override = mat
#     
#     mesh_instance.position = Vector3(px, y, pz)
#     mesh_instance.rotation_degrees = Vector3(90, 0, 0)
#     add_child(mesh_instance)
#     
#     var body = StaticBody3D.new()
#     var col = CollisionShape3D.new()
#     var shape = CylinderShape3D.new()
#     shape.height = length
#     shape.radius = 0.02
#     col.shape = shape
#     body.add_child(col)
#     body.position = mesh_instance.position
#     body.rotation_degrees = mesh_instance.rotation_degrees
#     add_child(body)
# 
# func _spawn_ring(pos: Vector3, rot_deg: Vector3, r_in: float, r_out: float, color: Color):
#     var mesh_instance = MeshInstance3D.new()
#     var mesh = TorusMesh.new()
#     mesh.inner_radius = r_in
#     mesh.outer_radius = r_out
#     mesh_instance.mesh = mesh
#     
#     var mat = StandardMaterial3D.new()
#     mat.albedo_color = color
#     mesh_instance.material_override = mat
#     
#     mesh_instance.position = pos
#     mesh_instance.rotation_degrees = rot_deg
#     add_child(mesh_instance)
#     
#     var body = StaticBody3D.new()
#     body.position = pos
#     body.rotation_degrees = rot_deg
#     var ring_radius = (r_in + r_out) / 2.0
#     for i in range(8):
#         var angle = i * PI * 2.0 / 8.0
#         var col = CollisionShape3D.new()
#         var shape = SphereShape3D.new()
#         shape.radius = (r_out - r_in) / 2.0
#         col.shape = shape
#         col.position = Vector3(cos(angle) * ring_radius, sin(angle) * ring_radius, 0)
#         body.add_child(col)
#     add_child(body)
# 
# # === FUNKCJE ZAPISUJĄCE DO PLIKU TSCN ===
# func save_to_scene():
#     _set_owner_recursive(self, self)
#     var packed = PackedScene.new()
#     packed.pack(self)
#     ResourceSaver.save(packed, "res://Przeszkoda2_Gotowa.tscn")
#     print("Przeszkoda 2 zapisana pomyślnie jako gotowy obiekt!")
# 
# func _set_owner_recursive(node: Node, root_node: Node):
#     for child in node.get_children():
#         child.owner = root_node
#         _set_owner_recursive(child, root_node)

func _ready():
	_fix_ring_collisions()

# Kolizje obręczy były generowane w płaszczyźnie XY, a TorusMesh leży w XZ,
# przez co kolizyjny pierścień był obrócony o 90° i blokował środek otworu.
# Zamieniamy Y<->Z każdej kuli, żeby kolizja pokryła widoczną obręcz.
func _fix_ring_collisions():
	for body in get_children():
		if not (body is StaticBody3D):
			continue
		var is_ring = false
		for c in body.get_children():
			if c is CollisionShape3D and c.shape is SphereShape3D:
				is_ring = true
				break
		if not is_ring:
			continue
		for c in body.get_children():
			if c is CollisionShape3D and c.shape is SphereShape3D:
				var p = c.position
				c.position = Vector3(p.x, p.z, p.y)

func set_hidden(h: bool):
	visible = not h
	for child in get_children():
		if child is StaticBody3D:
			child.process_mode = Node.PROCESS_MODE_DISABLED if h else Node.PROCESS_MODE_INHERIT
