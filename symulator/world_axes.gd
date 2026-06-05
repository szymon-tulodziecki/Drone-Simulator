extends Node3D

const AXIS_LENGTH = 0.5
const AXIS_RADIUS = 0.015

func _ready():
	position = Vector3(-0.8, 0.0, -0.8)
	# Twój układ: X=lewo/prawo, Y=przód/tył (po podłodze), Z=wysokość
	_spawn_axis(Vector3(1, 0, 0), Color(1, 0.2, 0.2), "X")   # Godot X = twój X
	_spawn_axis(Vector3(0, 0, 1), Color(0.2, 1, 0.2), "Y")   # Godot Z = twój Y
	_spawn_axis(Vector3(0, 1, 0), Color(0.3, 0.5, 1), "Z")   # Godot Y = twój Z (wysokość)

func _spawn_axis(dir: Vector3, color: Color, label_text: String):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var shaft = MeshInstance3D.new()
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = AXIS_RADIUS
	shaft_mesh.bottom_radius = AXIS_RADIUS
	shaft_mesh.height = AXIS_LENGTH
	shaft.mesh = shaft_mesh
	shaft.material_override = mat
	shaft.position = dir * AXIS_LENGTH / 2.0
	_orient(shaft, dir)
	add_child(shaft)

	var head = MeshInstance3D.new()
	var head_mesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = AXIS_RADIUS * 2.5
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.material_override = mat
	head.position = dir * AXIS_LENGTH
	_orient(head, dir)
	add_child(head)

	var label = Label3D.new()
	label.text = label_text
	label.position = dir * (AXIS_LENGTH + 0.1)
	label.font_size = 48
	label.pixel_size = 0.002
	label.modulate = color
	label.outline_size = 6
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)

func _orient(node: Node3D, direction: Vector3):
	var up = Vector3.UP
	var dir_norm = direction.normalized()
	if abs(dir_norm.dot(up)) > 0.999:
		if dir_norm.dot(up) < 0:
			node.rotation_degrees = Vector3(180, 0, 0)
		return
	var axis = up.cross(dir_norm).normalized()
	var angle = up.angle_to(dir_norm)
	node.transform.basis = Basis(axis, angle)
