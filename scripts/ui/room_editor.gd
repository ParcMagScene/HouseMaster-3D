extends Control
class_name RoomEditor

## Éditeur de pièces — HouseMaster 3D — Thème dark moderne

signal ROOM_MODIFIED(room_name: String, data: Dictionary)
signal ROOM_CREATED(data: Dictionary)
signal ROOM_DELETED(room_name: String)

var current_room: Node3D = null
var house_ref: Node3D = null

# --- UI Elements ---
var name_input: LineEdit = null
var width_input: SpinBox = null
var depth_input: SpinBox = null
var height_input: SpinBox = null
var type_selector: OptionButton = null
var apply_btn: Button = null
var delete_btn: Button = null
var add_btn: Button = null
var surface_label: Label = null

var room_types := ["living", "bedroom", "bathroom", "wc", "storage", "kitchen", "generic"]
var room_type_labels := ["Séjour/Cuisine", "Chambre", "Salle de bain", "WC", "Cellier", "Cuisine", "Générique"]


func _ready() -> void:
	_build_editor_ui()


func setup(house: Node3D) -> void:
	house_ref = house


func _build_editor_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "RoomEditorPanel"
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size = Vector2(280, 420)
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_PANEL, UITheme.CORNER_RADIUS, UITheme.BORDER, 1))
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# --- Header ---
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UITheme.header_style())
	header.custom_minimum_size = Vector2(0, UITheme.HEADER_HEIGHT)
	vbox.add_child(header)

	var header_hbox := HBoxContainer.new()
	header.add_child(header_hbox)
	var title := UITheme.make_header_label("ÉDITEUR PIÈCE")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 28)
	UITheme.apply_button_theme(close_btn)
	close_btn.pressed.connect(func(): visible = false)
	header_hbox.add_child(close_btn)

	# --- Nom ---
	vbox.add_child(_styled_label("Nom"))
	name_input = LineEdit.new()
	name_input.placeholder_text = "Nom de la pièce"
	UITheme.apply_input_theme(name_input)
	vbox.add_child(name_input)

	# --- Dimensions en grille 2 colonnes ---
	vbox.add_child(_styled_label("Dimensions"))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	grid.add_child(_dim_label("Largeur (m)"))
	width_input = _styled_spinbox(1.0, 20.0, 0.25, 3.0)
	width_input.value_changed.connect(func(_v): _update_surface())
	grid.add_child(width_input)

	grid.add_child(_dim_label("Profondeur (m)"))
	depth_input = _styled_spinbox(1.0, 20.0, 0.25, 3.0)
	depth_input.value_changed.connect(func(_v): _update_surface())
	grid.add_child(depth_input)

	grid.add_child(_dim_label("Hauteur (m)"))
	height_input = _styled_spinbox(2.0, 4.0, 0.1, 2.5)
	grid.add_child(height_input)

	# --- Type ---
	vbox.add_child(_styled_label("Type"))
	type_selector = OptionButton.new()
	for i in room_type_labels.size():
		type_selector.add_item(room_type_labels[i], i)
	UITheme.apply_button_theme(type_selector)
	vbox.add_child(type_selector)

	# --- Surface ---
	vbox.add_child(UITheme.make_separator())

	var surface_hbox := HBoxContainer.new()
	var surf_title := UITheme.make_dim_label("Surface :")
	surf_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface_hbox.add_child(surf_title)
	surface_label = Label.new()
	surface_label.text = "9.0 m²"
	UITheme.apply_label_theme(surface_label, UITheme.FONT_SIZE_LG, UITheme.ACCENT)
	surface_hbox.add_child(surface_label)
	vbox.add_child(surface_hbox)

	vbox.add_child(UITheme.make_separator())

	# --- Boutons action ---
	var btn_grid := GridContainer.new()
	btn_grid.columns = 2
	btn_grid.add_theme_constant_override("h_separation", 6)
	btn_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(btn_grid)

	apply_btn = Button.new()
	apply_btn.text = "Appliquer"
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_accent_button(apply_btn)
	apply_btn.pressed.connect(_on_apply)
	btn_grid.add_child(apply_btn)

	delete_btn = Button.new()
	delete_btn.text = "Supprimer"
	delete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(delete_btn)
	delete_btn.add_theme_color_override("font_color", UITheme.ERROR)
	delete_btn.pressed.connect(_on_delete)
	btn_grid.add_child(delete_btn)

	add_btn = Button.new()
	add_btn.text = "＋ Nouvelle pièce"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(add_btn)
	add_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_btn.pressed.connect(_on_add_room)
	vbox.add_child(add_btn)


func edit_room(room: Node3D) -> void:
	current_room = room
	if room:
		name_input.text = room.room_name
		width_input.value = room.room_width
		depth_input.value = room.room_depth
		height_input.value = room.room_height
		var type_idx := room_types.find(room.room_type)
		if type_idx >= 0:
			type_selector.selected = type_idx
		_update_surface()
		visible = true


func _update_surface() -> void:
	var surface := width_input.value * depth_input.value
	if surface_label:
		surface_label.text = "%.1f m²" % surface


func _on_apply() -> void:
	if not current_room:
		return

	var data := {
		"name": name_input.text,
		"width": width_input.value,
		"depth": depth_input.value,
		"height": height_input.value,
		"type": room_types[type_selector.selected]
	}

	current_room.room_name = data["name"]
	current_room.resize(data["width"], data["depth"])
	current_room.room_height = data["height"]
	current_room.set_type(data["type"])

	ROOM_MODIFIED.emit(data["name"], data)


func _on_delete() -> void:
	if current_room and house_ref:
		var room_name := current_room.room_name
		house_ref.remove_room(current_room)
		current_room = null
		visible = false
		ROOM_DELETED.emit(room_name)


func _on_add_room() -> void:
	if not house_ref:
		return

	var data := {
		"name": name_input.text if name_input.text != "" else "Nouvelle pièce",
		"width": width_input.value,
		"depth": depth_input.value,
		"type": room_types[type_selector.selected],
		"pos_x": 0.0,
		"pos_z": 0.0,
	}

	house_ref.add_room(data)
	ROOM_CREATED.emit(data)


# --- Helpers thème ---

func _styled_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	UITheme.apply_label_theme(label, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	return label


func _dim_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_theme(label, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	return label


func _styled_spinbox(min_v: float, max_v: float, step_v: float, default_v: float) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_v
	sb.max_value = max_v
	sb.step = step_v
	sb.value = default_v
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	return sb
