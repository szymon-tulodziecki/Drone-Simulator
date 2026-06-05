extends Node3D

var labels: Array = []
var visible_state = false

func _ready():
	_create_labels()
	set_visibility(false)

func _create_labels():
	# === PRZESZKODA 1 ===
	_add_label(Vector3(0.415, 2.4, 2.215), "Słupek A\n≈225 cm")
	_add_label(Vector3(0.415, 2.4, 3.185), "Słupek B (wspólny)\n≈225 cm")
	_add_label(Vector3(1.385, 2.4, 3.185), "Słupek C\n≈225 cm")
	_add_label(Vector3(0.415, 0.875, 2.7), "Obręcz dolna\n≈Ø97 cm, h≈87 cm")
	_add_label(Vector3(0.415, 1.800, 2.7), "Obręcz górna\n≈Ø97 cm, h≈180 cm")
	_add_label(Vector3(0.9, 0.875, 3.185), "Obręcz dolna\n≈Ø97 cm, h≈87 cm")
	_add_label(Vector3(0.9, 1.800, 3.185), "Obręcz górna\n≈Ø97 cm, h≈180 cm")
	
	# === PRZESZKODA 2 ===
	_add_label(Vector3(3.6, 2.05, 1.2), "Słupek 1\n≈190 cm")
	_add_label(Vector3(3.6, 2.05, 4.2), "Słupek 2\n≈190 cm")
	_add_label(Vector3(3.6, 2.0, 2.7), "Poprzeczka\n≈300 cm")
	_add_label(Vector3(3.6, 1.52, 2.7), "Rząd górny: 4× ≈Ø70 cm")
	_add_label(Vector3(3.6, 0.92, 2.7), "Rząd dolny: 3× ≈Ø70 cm")

func _add_label(pos: Vector3, text: String):
	var label = Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 48
	label.pixel_size = 0.0025
	label.modulate = Color(0.3, 1.0, 1.0)
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	labels.append(label)

func set_visibility(v: bool):
	visible_state = v
	for l in labels:
		l.visible = v

func toggle():
	set_visibility(not visible_state)
