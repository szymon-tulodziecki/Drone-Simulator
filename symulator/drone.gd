extends Node3D

const CM = 0.01
const TILE_SIZE = 0.3
var speed: float = 1.5
var command_queue: Array = []
var moving = false
var target_pos: Vector3
var landed = true
var step_mode = false
var waiting_for_step = false
var start_tx = 0
var start_tz = 0

var segment_start_pos: Vector3
var current_cmd: String = ""

signal position_changed(pos: Vector3)
signal segment_finished(from_pos: Vector3, to_pos: Vector3, cmd: String)
signal trail_cleared

func _ready():
	set_start_position(0, 0)
	target_pos = position

func _process(delta):
	if moving:
		var dir = target_pos - position
		if dir.length() < 0.01:
			position = target_pos
			moving = false
			print("  -> dotarł do celu, pozycja: ", position)
			emit_signal("segment_finished", segment_start_pos, position, current_cmd)
			if step_mode:
				waiting_for_step = true
		else:
			position += dir.normalized() * speed * delta
		emit_signal("position_changed", position)
	elif command_queue.size() > 0 and not waiting_for_step:
		_execute(command_queue.pop_front())

func queue_command(cmd: String):
	print("Dodano do kolejki: '", cmd, "'")
	command_queue.append(cmd)

func set_start_position(tx: int, tz: int):
	start_tx = tx
	start_tz = tz
	position.x = tx * TILE_SIZE * 2 + TILE_SIZE
	position.z = tz * TILE_SIZE * 2 + TILE_SIZE
	position.y = 0.05
	target_pos = position

func set_speed(s: float):
	speed = s

func set_step_mode(enabled: bool):
	step_mode = enabled
	waiting_for_step = false

func next_step():
	waiting_for_step = false

func reset():
	print("=== RESET ===")
	command_queue.clear()
	moving = false
	waiting_for_step = false
	landed = true
	set_start_position(start_tx, start_tz)
	emit_signal("trail_cleared")

func _execute(cmd: String):
	print(">>> Wykonuję: '", cmd, "' z pozycji ", position)
	var parts = cmd.split(" ")
	var dist = 0.0
	if parts.size() > 1:
		dist = float(parts[1]) * CM
	landed = false
	match parts[0]:
		"takeoff":
			target_pos = position + Vector3(0, 0.8, 0)
		"land":
			target_pos = Vector3(position.x, 0.05, position.z)
			landed = true
		"up":      target_pos = position + Vector3(0, dist, 0)
		"down":    target_pos = position + Vector3(0, -dist, 0)
		"forward": target_pos = position + Vector3(0, 0, dist)
		"back":    target_pos = position + Vector3(0, 0, -dist)
		"left":    target_pos = position + Vector3(dist, 0, 0)
		"right":   target_pos = position + Vector3(-dist, 0, 0)
	segment_start_pos = position
	current_cmd = cmd
	moving = true
