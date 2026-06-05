extends Node3D

@onready var drone = $"/root/Main/Drone"

const ARROW_COLOR = Color(0.0, 1.0, 0.4)
const LABEL_COLOR = Color(1.0, 1.0, 0.0)

var segments: Array = []

func _ready():
	drone.segment_finished.connect(_on_segment_finished)
	drone.trail_cleared.connect(_on_trail_cleared)

func _on_segment_finished(from_pos: Vector3, to_pos: Vector3, cmd: String):
	var dist_m = from_pos.distance_to(to_pos)
	if dist_m < 0.01:
		return
	var dist_cm = round(dist_m * 100)
	_spawn_arrow(from_pos, to_pos, dist_cm)

func _spawn_arrow(from_pos: Vector3, to_pos: Vector3, dist_cm: float):
	var segment_node = Node3D.new()
	add_child(segment_node)
	segments.append(segment_node)
	
	var direction = to_pos - from_pos
	var length = direction.length()
	var mid = (from_pos + to_pos) / 2.0
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = ARROW_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Trzon strzałki
	var shaft = MeshInstance3D.new()
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.008
	shaft_mesh.bottom_radius = 0.008
	shaft_mesh.height = max(length - 0.06, 0.01)
	shaft.mesh = shaft_mesh
	shaft.material_override = mat
	shaft.position = mid - direction.normalized() * 0.03
	_orient_cylinder(shaft, direction)
	segment_node.add_child(shaft)
	
	# Grot strzałki
	var head = MeshInstance3D.new()
	var head_mesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.025
	head_mesh.height = 0.06
	head.mesh = head_mesh
	head.material_override = mat
	head.position = to_pos - direction.normalized() * 0.03
	_orient_cylinder(head, direction)
	segment_node.add_child(head)
	
	# Etykieta
	var label = Label3D.new()
	label.text = str(int(dist_cm)) + " cm"
	label.position = mid + Vector3(0, 0.08, 0)
	label.font_size = 64
	label.pixel_size = 0.002
	label.modulate = LABEL_COLOR
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	segment_node.add_child(label)

func _orient_cylinder(node: Node3D, direction: Vector3):
	if direction.length() < 0.001:
		return
	var up = Vector3.UP
	var dir_norm = direction.normalized()
	if abs(dir_norm.dot(up)) > 0.999:
		if dir_norm.dot(up) < 0:
			node.rotation_degrees = Vector3(180, 0, 0)
		return
	var axis = up.cross(dir_norm).normalized()
	var angle = up.angle_to(dir_norm)
	node.transform.basis = Basis(axis, angle)

func _on_trail_cleared():
	for s in segments:
		s.queue_free()
	segments.clear()

func clear_trail():
	_on_trail_cleared()
