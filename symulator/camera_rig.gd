extends Node3D

@onready var camera = $Camera3D

var target = Vector3(2.4, 0, 2.4)  # środek siatki 8x8
var distance = 6.0
var yaw = 45.0
var pitch = -35.0

var mouse_sensitivity = 0.3
var zoom_speed = 0.5
var is_rotating = false

func _ready():
	_update_camera()

func _input(event):
	# prawy przycisk myszy - obracanie
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
		
		# scroll - zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(1.0, distance - zoom_speed)
			_update_camera()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(20.0, distance + zoom_speed)
			_update_camera()
	
	# ruch myszy podczas trzymania prawego przycisku
	if event is InputEventMouseMotion and is_rotating:
		yaw   -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch  = clamp(pitch, -80.0, -5.0)  # żeby nie wejść pod podłogę
		_update_camera()

func _update_camera():
	var yaw_rad   = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)
	
	var offset = Vector3(
		distance * cos(pitch_rad) * sin(yaw_rad),
		distance * sin(-pitch_rad),
		distance * cos(pitch_rad) * cos(yaw_rad)
	)
	
	position = target + offset
	look_at(target, Vector3.UP)
