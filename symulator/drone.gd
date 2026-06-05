extends Node3D

const CM = 0.01
const TILE_SIZE = 0.3
var speed: float = 1.5
var rot_speed: float = 120.0
var command_queue: Array = []
var moving = false
var rotating = false
var curving = false
var target_pos: Vector3
var target_yaw: float = 0.0
var current_yaw: float = 0.0
var landed = true
var step_mode = false
var waiting_for_step = false
var start_tx = 0
var start_tz = 0

var curve_p0: Vector3
var curve_p1: Vector3
var curve_p2: Vector3
var curve_t: float = 0.0
var curve_duration: float = 0.0

var segment_start_pos: Vector3
var current_cmd: String = ""

signal position_changed(pos: Vector3)
signal segment_finished(from_pos: Vector3, to_pos: Vector3, cmd: String)
signal trail_cleared

func _ready():
	set_start_position(0, 0)
	target_pos = position

func _process(delta):
	if rotating:
		var diff = target_yaw - current_yaw
		if abs(diff) < 0.5:
			current_yaw = target_yaw
			rotation_degrees.y = current_yaw
			rotating = false
			if step_mode:
				waiting_for_step = true
		else:
			var step = sign(diff) * rot_speed * delta
			if abs(step) > abs(diff):
				step = diff
			current_yaw += step
			rotation_degrees.y = current_yaw
	elif curving:
		if curve_duration > 0:
			curve_t += (speed / curve_duration) * delta
		else:
			curve_t = 1.0
		if curve_t >= 1.0:
			curve_t = 1.0
			position = curve_p2
			curving = false
			print("  -> dotarł do celu (curve), pozycja: ", position)
			emit_signal("segment_finished", segment_start_pos, position, current_cmd)
			if step_mode:
				waiting_for_step = true
		else:
			var t = curve_t
			position = (1.0 - t) * (1.0 - t) * curve_p0 \
				+ 2.0 * (1.0 - t) * t * curve_p1 \
				+ t * t * curve_p2
		emit_signal("position_changed", position)
	elif moving:
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
	current_yaw = 0.0
	target_yaw = 0.0
	rotation_degrees.y = 0.0
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
	rotating = false
	curving = false
	waiting_for_step = false
	landed = true
	set_start_position(start_tx, start_tz)
	emit_signal("trail_cleared")

# wektor ruchu względem orientacji drona (yaw)
func _local_dir(local: Vector3) -> Vector3:
	var rad = deg_to_rad(current_yaw)
	var cos_y = cos(rad)
	var sin_y = sin(rad)
	return Vector3(
		local.x * cos_y + local.z * sin_y,
		local.y,
		-local.x * sin_y + local.z * cos_y
	)

func _execute(cmd: String):
	print(">>> Wykonuję: '", cmd, "' z pozycji ", position, " yaw=", current_yaw)
	var parts = cmd.split(" ")
	var dist = 0.0
	if parts.size() > 1:
		dist = float(parts[1]) * CM
	landed = false
	segment_start_pos = position
	current_cmd = cmd

	match parts[0]:
		"takeoff":
			target_pos = position + Vector3(0, 0.8, 0)
			moving = true
		"land":
			target_pos = Vector3(position.x, 0.05, position.z)
			landed = true
			moving = true
		"up":
			target_pos = position + Vector3(0, dist, 0)
			moving = true
		"down":
			target_pos = position + Vector3(0, -dist, 0)
			moving = true
		"forward":
			target_pos = position + _local_dir(Vector3(0, 0, dist))
			moving = true
		"back":
			target_pos = position + _local_dir(Vector3(0, 0, -dist))
			moving = true
		"left":
			target_pos = position + _local_dir(Vector3(dist, 0, 0))
			moving = true
		"right":
			target_pos = position + _local_dir(Vector3(-dist, 0, 0))
			moving = true
		"cw":
			target_yaw = current_yaw - float(parts[1])
			rotating = true
		"ccw":
			target_yaw = current_yaw + float(parts[1])
			rotating = true
		"go":
			if parts.size() >= 4:
				var gx = float(parts[1]) * CM
				var gy = float(parts[2]) * CM
				var gz = float(parts[3]) * CM
				target_pos = position + _local_dir(Vector3(gx, gz, gy))
				moving = true
		"curve":
			if parts.size() >= 7:
				var x1 = float(parts[1]) * CM
				var y1 = float(parts[2]) * CM
				var z1 = float(parts[3]) * CM
				var x2 = float(parts[4]) * CM
				var y2 = float(parts[5]) * CM
				var z2 = float(parts[6]) * CM
				curve_p0 = position
				curve_p1 = position + _local_dir(Vector3(x1, z1, y1))
				curve_p2 = position + _local_dir(Vector3(x2, z2, y2))
				var approx_len = curve_p0.distance_to(curve_p1) + curve_p1.distance_to(curve_p2)
				curve_duration = max(approx_len, 0.01)
				curve_t = 0.0
				curving = true
		_:
			print("    nieznana komenda, pomijam")
			moving = false
