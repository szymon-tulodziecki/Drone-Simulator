extends Node

@onready var drone = $"/root/Main/Drone"
@onready var trail = $"/root/Main/Trail"
@onready var dims = $"/root/Main/Dimensions"

const C_BG       = Color("1e1e1e")
const C_SIDEBAR  = Color("252526")
const C_TOOLBAR  = Color("323233")
const C_TAB      = Color("2d2d2d")
const C_TEXT     = Color("cccccc")
const C_GREEN    = Color("2ea043")
const C_RED      = Color("c0392b")
const C_BLUE     = Color("0e639c")

const SIDEBAR_W = 220
const TOOLBAR_H = 38
const TAB_H = 30

var sidebar: PanelContainer
var sidebar_visible = true
var tabbar: PanelContainer
var tab_kod_panel: PanelContainer
var code_edit: CodeEdit
var status_label: Label
var error_label: Label
var btn_tab_scena: Button
var btn_tab_kod: Button
var btn_step_toolbar: Button

var input_x: SpinBox
var input_y: SpinBox
var input_speed: SpinBox
var btn_step: Button
var btn_dims: Button
var step_enabled = false

func _ready():
	_build_ui()

func _build_ui():
	var canvas = CanvasLayer.new()
	get_tree().root.call_deferred("add_child", canvas)
	await get_tree().process_frame

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	# === 1. ZAKŁADKA KOD (Na samym spodzie Z-index) ===
	tab_kod_panel = PanelContainer.new()
	tab_kod_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_kod_panel.offset_left = SIDEBAR_W
	tab_kod_panel.offset_top = TOOLBAR_H + TAB_H
	tab_kod_panel.offset_bottom = -24
	_style_panel(tab_kod_panel, C_BG, false)
	root.add_child(tab_kod_panel)
	_build_editor(tab_kod_panel)

	# === 2. PASEK ZAKŁADEK (Rysowany nad Panelem z kodem) ===
	tabbar = PanelContainer.new()
	tabbar.custom_minimum_size = Vector2(0, TAB_H)
	tabbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabbar.offset_left = SIDEBAR_W
	tabbar.offset_top = TOOLBAR_H
	tabbar.offset_bottom = TOOLBAR_H + TAB_H
	_style_panel(tabbar, C_TAB, false)
	root.add_child(tabbar)

	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 1)
	tabbar.add_child(tabs)

	btn_tab_scena = _mk_tab("Scena")
	btn_tab_scena.pressed.connect(func(): _switch_view("scena"))
	tabs.add_child(btn_tab_scena)

	btn_tab_kod = _mk_tab("Kod lotu")
	btn_tab_kod.pressed.connect(func(): _switch_view("kod"))
	tabs.add_child(btn_tab_kod)

	# === 3. LEWY PANEL (zwijany, nad zakładkami) ===
	sidebar = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(SIDEBAR_W, 0)
	sidebar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sidebar.offset_top = TOOLBAR_H
	sidebar.offset_bottom = -24
	sidebar.offset_right = SIDEBAR_W
	_style_panel(sidebar, C_SIDEBAR, true)
	root.add_child(sidebar)
	_build_sidebar(sidebar)

	# === 4. TOOLBAR (na samej górze, nad wszystkim) ===
	var toolbar = PanelContainer.new()
	toolbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolbar.custom_minimum_size = Vector2(0, TOOLBAR_H)
	toolbar.offset_bottom = TOOLBAR_H
	_style_panel(toolbar, C_TOOLBAR, true)
	root.add_child(toolbar)

	var tb = HBoxContainer.new()
	tb.add_theme_constant_override("separation", 6)
	toolbar.add_child(tb)

	var btn_collapse = _mk_button("☰", 38)
	btn_collapse.pressed.connect(_toggle_sidebar)
	tb.add_child(btn_collapse)

	var title = Label.new()
	title.text = "Tello Simulator"
	title.add_theme_color_override("font_color", C_TEXT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tb.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_child(spacer)

	btn_step_toolbar = _mk_button("> Krok: OFF", 110)
	btn_step_toolbar.toggle_mode = true
	_color_button(btn_step_toolbar, C_BLUE)
	btn_step_toolbar.toggled.connect(_on_step_toggled)
	tb.add_child(btn_step_toolbar)

	var btn_run = _mk_button(">> Uruchom", 110)
	_color_button(btn_run, C_GREEN)
	btn_run.pressed.connect(_on_start_pressed)
	tb.add_child(btn_run)

	var btn_reset = _mk_button("Reset", 90)
	_color_button(btn_reset, C_RED)
	btn_reset.pressed.connect(_on_set_pressed)
	tb.add_child(btn_reset)

	# === 5. PASEK STATUSU ===
	var status_bar = PanelContainer.new()
	status_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status_bar.custom_minimum_size = Vector2(0, 24)
	status_bar.offset_top = -24
	_style_panel(status_bar, C_TOOLBAR, false)
	root.add_child(status_bar)
	status_label = Label.new()
	status_label.text = "Gotowy"
	status_label.add_theme_color_override("font_color", C_TEXT)
	status_label.add_theme_font_size_override("font_size", 11)
	status_bar.add_child(status_label)

	_switch_view("scena")

func _build_sidebar(sb_panel: PanelContainer):
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	sb_panel.add_child(box)

	var hdr = Label.new()
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", Color("888888"))
	box.add_child(hdr)

	var lbl = Label.new(); lbl.text = "Pozycja startowa"
	lbl.add_theme_color_override("font_color", C_TEXT)
	box.add_child(lbl)

	var h = HBoxContainer.new(); box.add_child(h)
	var lx = Label.new(); lx.text = "X:"; lx.add_theme_color_override("font_color", C_TEXT); h.add_child(lx)
	input_x = SpinBox.new(); input_x.min_value = 0; input_x.max_value = 7; h.add_child(input_x)
	var ly = Label.new(); ly.text = " Y:"; ly.add_theme_color_override("font_color", C_TEXT); h.add_child(ly)
	input_y = SpinBox.new(); input_y.min_value = 0; input_y.max_value = 7; h.add_child(input_y)

	var btn_set = _mk_button("Ustaw pozycję", 0)
	btn_set.pressed.connect(_on_set_pressed)
	box.add_child(btn_set)

	box.add_child(HSeparator.new())

	var h2 = HBoxContainer.new(); box.add_child(h2)
	var ls = Label.new(); ls.text = "Prędkość:"; ls.add_theme_color_override("font_color", C_TEXT); h2.add_child(ls)
	input_speed = SpinBox.new()
	input_speed.min_value = 0.1; input_speed.max_value = 5.0; input_speed.step = 0.1; input_speed.value = 1.5
	input_speed.value_changed.connect(_on_speed_changed)
	h2.add_child(input_speed)

	btn_step = _mk_button("Następny krok", 0)
	btn_step.disabled = true
	btn_step.pressed.connect(_on_next_step_pressed)
	box.add_child(btn_step)

	box.add_child(HSeparator.new())

	btn_dims = _mk_button("Pokaż wymiary", 0)
	btn_dims.toggle_mode = true
	btn_dims.toggled.connect(_on_dims_toggled)
	box.add_child(btn_dims)

	# --- NOWA SEKCJA WIDOCZNOŚCI I SIATKI ---
	box.add_child(HSeparator.new())

	var lbl_vis = Label.new(); lbl_vis.text = "Widoczność"
	lbl_vis.add_theme_color_override("font_color", C_TEXT)
	box.add_child(lbl_vis)

	var cb_obstacles = CheckBox.new()
	cb_obstacles.text = "Pokaż przeszkody"
	cb_obstacles.button_pressed = true
	cb_obstacles.add_theme_color_override("font_color", C_TEXT)
	cb_obstacles.toggled.connect(func(on): 
		get_node("/root/Main/Obstacles").set_hidden(not on)
		get_node("/root/Main/Obstacle2").set_hidden(not on)
	)
	box.add_child(cb_obstacles)

	var cb_helipads = CheckBox.new()
	cb_helipads.text = "Pokaż helipady"
	cb_helipads.button_pressed = true
	cb_helipads.add_theme_color_override("font_color", C_TEXT)
	cb_helipads.toggled.connect(func(on): get_node("/root/Main/Helipads").set_hidden(not on))
	box.add_child(cb_helipads)

	var cb_trail = CheckBox.new()
	cb_trail.text = "Pokaż trasę"
	cb_trail.button_pressed = true
	cb_trail.add_theme_color_override("font_color", C_TEXT)
	cb_trail.toggled.connect(func(on): trail.visible = on)
	box.add_child(cb_trail)

	box.add_child(HSeparator.new())

	var lbl_grid = Label.new(); lbl_grid.text = "Rozmiar siatki"
	lbl_grid.add_theme_color_override("font_color", C_TEXT)
	box.add_child(lbl_grid)

	var hgrid = HBoxContainer.new(); box.add_child(hgrid)
	var btn_8 = _mk_button("8x8", 0)
	btn_8.pressed.connect(func(): get_node("/root/Main/Grid").rebuild(8))
	hgrid.add_child(btn_8)
	var btn_16 = _mk_button("16x16", 0)
	btn_16.pressed.connect(func(): get_node("/root/Main/Grid").rebuild(16))
	hgrid.add_child(btn_16)
	
	box.add_child(HSeparator.new())
	# -----------------------------------------

	var btn_clear = _mk_button("Wyczyść trasę", 0)
	btn_clear.pressed.connect(_on_clear_pressed)
	box.add_child(btn_clear)

func _build_editor(panel: PanelContainer):
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var box = VBoxContainer.new()
	margin.add_child(box)

	code_edit = CodeEdit.new()
	code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_edit.placeholder_text = "# Wklej kod lotu w Pythonie\nmy_drone.takeoff()\nmy_drone.forward(100)\nmy_drone.land()"
	code_edit.gutters_draw_line_numbers = true
	code_edit.add_theme_color_override("background_color", C_BG)
	code_edit.add_theme_color_override("font_color", C_TEXT)
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	code_edit.text_changed.connect(_on_code_changed)
	_setup_highlighter()
	box.add_child(code_edit)

	error_label = Label.new()
	error_label.text = ""
	error_label.add_theme_font_size_override("font_size", 12)
	box.add_child(error_label)

func _setup_highlighter():
	var hl = CodeHighlighter.new()
	hl.number_color = Color("b5cea8")
	hl.symbol_color = Color("cccccc")
	hl.function_color = Color("dcdcaa")
	hl.member_variable_color = Color("9cdcfe")
	var cmd_color = Color("4ec9b0")
	for c in ["takeoff", "land", "up", "down", "left", "right", "forward", "back", "cw", "ccw", "go", "curve", "set_speed"]:
		hl.add_keyword_color(c, cmd_color)
	for k in ["from", "import", "for", "in", "range", "if", "else", "while", "def"]:
		hl.add_keyword_color(k, Color("c586c0"))
	hl.add_keyword_color("my_drone", Color("9cdcfe"))
	hl.add_keyword_color("dron", Color("9cdcfe"))
	hl.add_keyword_color("tello", Color("4ec9b0"))
	hl.add_keyword_color("Tello", Color("4ec9b0"))
	hl.add_keyword_color("Tello_Unity", Color("4ec9b0"))
	hl.add_color_region("#", "", Color("6a9955"), true)
	hl.add_color_region("\"", "\"", Color("ce9178"))
	hl.add_color_region("'", "'", Color("ce9178"))
	code_edit.syntax_highlighter = hl

func _mk_button(txt: String, min_w: float) -> Button:
	var b = Button.new()
	b.text = txt
	if min_w > 0:
		b.custom_minimum_size = Vector2(min_w, 0)
	b.add_theme_color_override("font_color", C_TEXT)
	return b

func _color_button(b: Button, col: Color):
	var sb = StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	b.add_theme_stylebox_override("normal", sb)
	var sb_h = sb.duplicate()
	sb_h.bg_color = col.lightened(0.15)
	b.add_theme_stylebox_override("hover", sb_h)
	var sb_p = sb.duplicate()
	sb_p.bg_color = col.darkened(0.2)
	b.add_theme_stylebox_override("pressed", sb_p)
	b.add_theme_color_override("font_color", Color.WHITE)

func _mk_tab(txt: String) -> Button:
	var b = Button.new()
	b.text = txt
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(100, 0)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	return b

func _style_panel(p: PanelContainer, col: Color, shadow: bool):
	var sb = StyleBoxFlat.new()
	sb.bg_color = col
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)

func _switch_view(view: String):
	tab_kod_panel.visible = (view == "kod")
	btn_tab_scena.button_pressed = (view == "scena")
	btn_tab_kod.button_pressed = (view == "kod")

func _toggle_sidebar():
	sidebar_visible = not sidebar_visible
	sidebar.visible = sidebar_visible
	var x = SIDEBAR_W if sidebar_visible else 0
	tabbar.offset_left = x
	tab_kod_panel.offset_left = x

func _on_set_pressed():
	drone.reset()
	drone.set_start_position(int(input_x.value), int(input_y.value))
	status_label.text = "Pozycja ustawiona: (%d, %d)" % [int(input_x.value), int(input_y.value)]

func _on_speed_changed(val: float):
	drone.set_speed(val)

func _on_step_toggled(enabled: bool):
	step_enabled = enabled
	drone.set_step_mode(enabled)
	btn_step.disabled = not enabled
	btn_step_toolbar.text = "> Krok: ON" if enabled else "> Krok: OFF"

func _on_next_step_pressed():
	drone.next_step()

func _on_dims_toggled(pressed: bool):
	dims.set_visibility(pressed)
	btn_dims.text = "Ukryj wymiary" if pressed else "Pokaż wymiary"

func _on_clear_pressed():
	drone.emit_signal("trail_cleared")


# ==========================================
# === KORZYSTANIE Z INTERPRETERA ===
# ==========================================

func _on_code_changed():
	var interp = PyInterpreter.new()
	var res = interp.run(code_edit.text)
	if res.error == "":
		error_label.text = "Kod poprawny (%d komend)" % res.commands.size()
		error_label.add_theme_color_override("font_color", Color("4ec9b0"))
	else:
		error_label.text = res.error
		error_label.add_theme_color_override("font_color", Color("f48771"))

func _on_start_pressed():
	var interp = PyInterpreter.new()
	var res = interp.run(code_edit.text)
	if res.error != "":
		status_label.text = "BŁĄD: " + res.error
		_switch_view("kod")
		return
		
	_switch_view("scena")
	drone.reset()
	drone.set_start_position(int(input_x.value), int(input_y.value))
	drone.set_step_mode(step_enabled)
	
	for cmd in res.commands:
		drone.queue_command(cmd)
		
	status_label.text = "Uruchomiono lot: %d komend" % res.commands.size()
