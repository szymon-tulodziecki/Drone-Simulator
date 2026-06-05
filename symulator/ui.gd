extends Node

@onready var drone = $"/root/Main/Drone"
@onready var trail = $"/root/Main/Trail"
@onready var dims = $"/root/Main/Dimensions"

var panel: PanelContainer
var vbox_content: VBoxContainer
var input_x: SpinBox
var input_y: SpinBox
var input_speed: SpinBox
var code_input: TextEdit
var step_checkbox: CheckBox
var btn_step: Button
var btn_dims: Button
var btn_collapse: Button
var collapsed = false

func _ready():
	_build_ui()

func _build_ui():
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(320, 0)

	var vbox_main = VBoxContainer.new()
	panel.add_child(vbox_main)

	# === Pasek tytułowy z przyciskiem zwijania ===
	var header = HBoxContainer.new()
	vbox_main.add_child(header)
	
	var title = Label.new()
	title.text = "Symulator Tello"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	btn_collapse = Button.new()
	btn_collapse.text = "−"
	btn_collapse.custom_minimum_size = Vector2(30, 0)
	btn_collapse.pressed.connect(_on_collapse_pressed)
	header.add_child(btn_collapse)

	# === Zawartość zwijana ===
	vbox_content = VBoxContainer.new()
	vbox_main.add_child(vbox_content)

	var label = Label.new(); label.text = "Pozycja startowa drona"; vbox_content.add_child(label)

	var hbox = HBoxContainer.new(); vbox_content.add_child(hbox)
	var lx = Label.new(); lx.text = "X (0-7):"; hbox.add_child(lx)
	input_x = SpinBox.new(); input_x.min_value = 0; input_x.max_value = 7
	hbox.add_child(input_x)

	var hbox2 = HBoxContainer.new(); vbox_content.add_child(hbox2)
	var ly = Label.new(); ly.text = "Y (0-7):"; hbox2.add_child(ly)
	input_y = SpinBox.new(); input_y.min_value = 0; input_y.max_value = 7
	hbox2.add_child(input_y)

	var btn = Button.new()
	btn.text = "Ustaw pozycję (RESET)"
	btn.pressed.connect(_on_set_pressed)
	vbox_content.add_child(btn)

	vbox_content.add_child(HSeparator.new())

	var hbox3 = HBoxContainer.new(); vbox_content.add_child(hbox3)
	var ls = Label.new(); ls.text = "Prędkość (m/s):"; hbox3.add_child(ls)
	input_speed = SpinBox.new()
	input_speed.min_value = 0.1; input_speed.max_value = 5.0
	input_speed.step = 0.1; input_speed.value = 1.5
	input_speed.value_changed.connect(_on_speed_changed)
	hbox3.add_child(input_speed)

	step_checkbox = CheckBox.new()
	step_checkbox.text = "Krok po kroku"
	step_checkbox.toggled.connect(_on_step_toggled)
	vbox_content.add_child(step_checkbox)

	btn_step = Button.new()
	btn_step.text = "Następny krok"
	btn_step.disabled = true
	btn_step.pressed.connect(_on_next_step_pressed)
	vbox_content.add_child(btn_step)

	btn_dims = Button.new()
	btn_dims.text = "Pokaż wymiary"
	btn_dims.toggle_mode = true
	btn_dims.toggled.connect(_on_dims_toggled)
	vbox_content.add_child(btn_dims)

	vbox_content.add_child(HSeparator.new())

	var label2 = Label.new(); label2.text = "Kod lotu (Python):"
	vbox_content.add_child(label2)

	code_input = TextEdit.new()
	code_input.custom_minimum_size = Vector2(300, 200)
	code_input.text = ""
	code_input.placeholder_text = "Wklej tutaj kod lotu w Pythonie\n\nPrzykład:\nmy_drone.takeoff()\nmy_drone.forward(100)\nmy_drone.land()"
	vbox_content.add_child(code_input)

	var btn_start = Button.new()
	btn_start.text = "Start lotu"
	btn_start.tooltip_text = "Wklej kod Pythona z my_drone.xxx() i kliknij"
	btn_start.pressed.connect(_on_start_pressed)
	vbox_content.add_child(btn_start)

	var btn_clear = Button.new()
	btn_clear.text = "Wyczyść trasę"
	btn_clear.pressed.connect(_on_clear_pressed)
	vbox_content.add_child(btn_clear)

	var canvas = CanvasLayer.new()
	canvas.add_child(panel)
	get_tree().root.call_deferred("add_child", canvas)

func _on_collapse_pressed():
	collapsed = not collapsed
	vbox_content.visible = not collapsed
	btn_collapse.text = "+" if collapsed else "−"

func _on_set_pressed():
	drone.reset()
	drone.set_start_position(int(input_x.value), int(input_y.value))

func _on_speed_changed(val: float):
	drone.set_speed(val)

func _on_step_toggled(enabled: bool):
	drone.set_step_mode(enabled)
	btn_step.disabled = not enabled

func _on_next_step_pressed():
	drone.next_step()

func _on_dims_toggled(pressed: bool):
	dims.set_visibility(pressed)
	btn_dims.text = "Ukryj wymiary" if pressed else "Pokaż wymiary"

func _on_clear_pressed():
	drone.emit_signal("trail_cleared")

func _on_start_pressed():
	drone.reset()
	drone.set_start_position(int(input_x.value), int(input_y.value))
	drone.set_step_mode(step_checkbox.button_pressed)
	var lines = code_input.text.split("\n")
	for line in lines:
		var cmd = _parse_line(line.strip_edges())
		if cmd != "":
			drone.queue_command(cmd)

func _parse_line(line: String) -> String:
	if line.is_empty() or line.begins_with("#"):
		return ""
	var hash_pos = line.find("#")
	if hash_pos != -1:
		line = line.substr(0, hash_pos).strip_edges()
	if line.begins_with("from ") or line.begins_with("import ") or line.contains("tello.Tello()"):
		return ""
	var regex = RegEx.new()
	regex.compile("\\w+\\.(\\w+)\\((\\d*)\\)")
	var result = regex.search(line)
	if result == null:
		return ""
	var cmd = result.get_string(1)
	var arg = result.get_string(2)
	if arg == "":
		return cmd
	return cmd + " " + arg
