extends Control
class_name MainUI

## UI principale — HouseMaster 3D — Thème dark moderne

signal ROOM_SELECTED(room_name: String)
signal LAYER_TOGGLED(layer_name: String, visible: bool)
signal SAVE_REQUESTED
signal LOAD_REQUESTED
signal EXPORT_2D_REQUESTED
signal EXPORT_3D_REQUESTED
signal MODE_CHANGED(mode: String)

# --- Références UI ---
var menu_bar: MenuBar = null
var hierarchy_panel: VBoxContainer = null
var hierarchy_tree: Tree = null
var properties_panel: VBoxContainer = null
var log_panel: RichTextLabel = null
var toolbar: HBoxContainer = null
var status_bar: HBoxContainer = null
var status_label: Label = null
var status_mode_label: Label = null
var status_snap_label: Label = null

# --- Layer toggles ---
var layer_buttons: Dictionary = {}

# --- Panneaux résizables ---
var left_panel: PanelContainer = null
var right_panel: PanelContainer = null
var bottom_panel: PanelContainer = null

# --- Références modules ---
var house_ref: Node3D = null


func _ready() -> void:
	_build_ui()


func setup(house: Node3D) -> void:
	house_ref = house
	_refresh_hierarchy()


func _build_ui() -> void:
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# === Background overlay pour les panneaux ===
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color.TRANSPARENT

	# ╔══════════════════════════════════════════════╗
	# ║             MENU BAR (haut)                  ║
	# ╚══════════════════════════════════════════════╝
	var menu_container := PanelContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	menu_container.size = Vector2(0, 28)
	menu_container.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, 0, UITheme.SEPARATOR, 0))
	menu_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_container)

	var menu_hbox := HBoxContainer.new()
	menu_hbox.add_theme_constant_override("separation", 0)
	menu_container.add_child(menu_hbox)

	# Logo / titre
	var logo_label := Label.new()
	logo_label.text = "  HOUSEMASTER 3D"
	UITheme.apply_label_theme(logo_label, UITheme.FONT_SIZE_MD, UITheme.ACCENT)
	menu_hbox.add_child(logo_label)

	menu_hbox.add_child(_make_menu_spacer())

	menu_bar = MenuBar.new()
	menu_bar.name = "MenuBar"
	menu_bar.flat = true
	menu_bar.add_theme_color_override("font_color", UITheme.TEXT)
	menu_bar.add_theme_color_override("font_hover_color", UITheme.TEXT_BRIGHT)
	menu_bar.add_theme_color_override("font_pressed_color", UITheme.ACCENT)
	menu_bar.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
	menu_hbox.add_child(menu_bar)

	var file_menu := PopupMenu.new()
	file_menu.name = "Fichier"
	_style_popup(file_menu)
	file_menu.add_item("Nouveau projet", 0)
	file_menu.add_icon_item(null, "Sauvegarder", 1)
	file_menu.set_item_shortcut(1, _make_shortcut(KEY_S, true), false)
	file_menu.add_item("Charger", 2)
	file_menu.add_separator()
	file_menu.add_item("Exporter Plan 2D", 3)
	file_menu.add_item("Exporter Capture 3D", 4)
	file_menu.add_separator()
	file_menu.add_item("Quitter", 5)
	file_menu.id_pressed.connect(_on_file_menu)
	menu_bar.add_child(file_menu)

	var edit_menu := PopupMenu.new()
	edit_menu.name = "Édition"
	_style_popup(edit_menu)
	edit_menu.add_item("Annuler", 0)
	edit_menu.set_item_shortcut(0, _make_shortcut(KEY_Z, true), false)
	edit_menu.add_item("Refaire", 1)
	edit_menu.add_separator()
	edit_menu.add_item("Ajouter pièce", 2)
	edit_menu.add_item("Supprimer sélection", 3)
	edit_menu.id_pressed.connect(_on_edit_menu)
	menu_bar.add_child(edit_menu)

	var view_menu := PopupMenu.new()
	view_menu.name = "Vue"
	_style_popup(view_menu)
	view_menu.add_item("Vue 3D Orbite", 0)
	view_menu.add_item("Vue 3D Libre", 1)
	view_menu.add_item("Vue 2D", 2)
	view_menu.add_separator()
	view_menu.add_check_item("Grille", 3)
	view_menu.add_check_item("Snapping", 4)
	view_menu.set_item_checked(3, true)
	view_menu.set_item_checked(4, true)
	view_menu.id_pressed.connect(_on_view_menu)
	menu_bar.add_child(view_menu)

	var modules_menu := PopupMenu.new()
	modules_menu.name = "Modules"
	_style_popup(modules_menu)
	modules_menu.add_item("Plomberie  (F1)", 0)
	modules_menu.add_item("Électricité  (F2)", 1)
	modules_menu.add_item("Réseau  (F3)", 2)
	modules_menu.add_item("Domotique  (F4)", 3)
	modules_menu.id_pressed.connect(_on_modules_menu)
	menu_bar.add_child(modules_menu)

	# ╔══════════════════════════════════════════════╗
	# ║               TOOLBAR                       ║
	# ╚══════════════════════════════════════════════╝
	var toolbar_container := PanelContainer.new()
	toolbar_container.name = "ToolbarContainer"
	toolbar_container.position = Vector2(0, 28)
	toolbar_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolbar_container.offset_top = 28
	toolbar_container.offset_bottom = 62
	toolbar_container.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_PANEL, 0, UITheme.SEPARATOR, 0))
	toolbar_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(toolbar_container)

	toolbar = HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_constant_override("separation", 4)
	toolbar_container.add_child(toolbar)

	# Boutons layers avec style moderne
	var layers_data := [
		{"name": "Structure", "key": "structure", "color": UITheme.TEXT},
		{"name": "Plomberie", "key": "plomberie", "color": UITheme.ACCENT},
		{"name": "Électricité", "key": "électricité", "color": UITheme.WARNING},
		{"name": "Réseau", "key": "réseau", "color": UITheme.SUCCESS},
		{"name": "Domotique", "key": "domotique", "color": Color("d966ff")},
	]

	for data in layers_data:
		var btn := CheckButton.new()
		btn.text = data["name"]
		btn.button_pressed = true
		btn.add_theme_color_override("font_color", data["color"])
		btn.add_theme_color_override("font_hover_color", UITheme.TEXT_BRIGHT)
		btn.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
		btn.toggled.connect(_on_layer_toggled.bind(data["key"]))
		toolbar.add_child(btn)
		layer_buttons[data["key"]] = btn

	# Séparateur vertical stylé
	var vsep := VSeparator.new()
	vsep.add_theme_constant_override("separation", 12)
	toolbar.add_child(vsep)

	# Bouton mode caméra
	var cam_btn := Button.new()
	cam_btn.text = "Caméra"
	cam_btn.tooltip_text = "Basculer le mode caméra (Espace)"
	UITheme.apply_button_theme(cam_btn)
	cam_btn.pressed.connect(func(): MODE_CHANGED.emit("cycle"))
	toolbar.add_child(cam_btn)

	# ╔══════════════════════════════════════════════╗
	# ║          PANNEAU GAUCHE : Hiérarchie         ║
	# ╚══════════════════════════════════════════════╝
	left_panel = PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.offset_left = 0
	left_panel.offset_top = 62
	left_panel.offset_right = 250
	left_panel.anchor_bottom = 1.0
	left_panel.offset_bottom = -140
	left_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_PANEL, 0, UITheme.SEPARATOR, 0))
	left_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(left_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 0)
	left_panel.add_child(left_vbox)

	# Header hiérarchie
	var hierarchy_header := PanelContainer.new()
	hierarchy_header.add_theme_stylebox_override("panel", UITheme.header_style())
	hierarchy_header.custom_minimum_size = Vector2(0, UITheme.HEADER_HEIGHT)
	left_vbox.add_child(hierarchy_header)

	var hh_hbox := HBoxContainer.new()
	hierarchy_header.add_child(hh_hbox)
	var hh_label := UITheme.make_header_label("HIÉRARCHIE")
	hh_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh_hbox.add_child(hh_label)

	# Tree pour hiérarchie (remplace les boutons)
	var tree_scroll := ScrollContainer.new()
	tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(tree_scroll)

	hierarchy_panel = VBoxContainer.new()
	hierarchy_panel.name = "HierarchyPanel"
	hierarchy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_scroll.add_child(hierarchy_panel)

	# ╔══════════════════════════════════════════════╗
	# ║         PANNEAU DROIT : Propriétés           ║
	# ╚══════════════════════════════════════════════╝
	right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.offset_left = -300
	right_panel.offset_top = 62
	right_panel.anchor_bottom = 1.0
	right_panel.offset_bottom = -140
	right_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_PANEL, 0, UITheme.SEPARATOR, 0))
	right_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(right_panel)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 0)
	right_panel.add_child(right_vbox)

	# Header propriétés
	var props_header := PanelContainer.new()
	props_header.add_theme_stylebox_override("panel", UITheme.header_style())
	props_header.custom_minimum_size = Vector2(0, UITheme.HEADER_HEIGHT)
	right_vbox.add_child(props_header)

	var ph_label := UITheme.make_header_label("PROPRIÉTÉS")
	props_header.add_child(ph_label)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_scroll)

	properties_panel = VBoxContainer.new()
	properties_panel.name = "PropertiesPanel"
	properties_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(properties_panel)

	# Placeholder
	var empty_lbl := UITheme.make_dim_label("Aucune sélection")
	properties_panel.add_child(empty_lbl)

	# ╔══════════════════════════════════════════════╗
	# ║            PANNEAU BAS : Logs                ║
	# ╚══════════════════════════════════════════════╝
	bottom_panel = PanelContainer.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.offset_top = -140
	bottom_panel.offset_bottom = -24
	bottom_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, 0, UITheme.SEPARATOR, 0))
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom_panel)

	var bottom_vbox := VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 0)
	bottom_panel.add_child(bottom_vbox)

	# Header logs
	var log_header := PanelContainer.new()
	log_header.add_theme_stylebox_override("panel", UITheme.header_style())
	log_header.custom_minimum_size = Vector2(0, UITheme.HEADER_HEIGHT)
	bottom_vbox.add_child(log_header)

	var lh_hbox := HBoxContainer.new()
	log_header.add_child(lh_hbox)
	var lh_label := UITheme.make_header_label("CONSOLE")
	lh_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lh_hbox.add_child(lh_label)

	var clear_btn := Button.new()
	clear_btn.text = "Effacer"
	clear_btn.custom_minimum_size = Vector2(60, 0)
	UITheme.apply_button_theme(clear_btn)
	clear_btn.pressed.connect(func(): log_panel.clear())
	lh_hbox.add_child(clear_btn)

	log_panel = RichTextLabel.new()
	log_panel.name = "LogPanel"
	log_panel.bbcode_enabled = true
	log_panel.scroll_following = true
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	log_panel.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	log_panel.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.BG_DARK, 0))
	bottom_vbox.add_child(log_panel)

	add_log("[color=#5cb85c]HouseMaster 3D initialisé[/color]")
	add_log("Projet Alexandre — Maison 70 m²")

	# ╔══════════════════════════════════════════════╗
	# ║              STATUS BAR                      ║
	# ╚══════════════════════════════════════════════╝
	var status_container := PanelContainer.new()
	status_container.name = "StatusBarContainer"
	status_container.anchor_top = 1.0
	status_container.anchor_bottom = 1.0
	status_container.anchor_right = 1.0
	status_container.offset_top = -24
	status_container.add_theme_stylebox_override("panel", UITheme.panel_style(Color("1a1a1a"), 0, UITheme.SEPARATOR, 0))
	status_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(status_container)

	status_bar = HBoxContainer.new()
	status_bar.name = "StatusBar"
	status_bar.add_theme_constant_override("separation", 16)
	status_container.add_child(status_bar)

	status_label = Label.new()
	status_label.text = "Prêt"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_theme(status_label, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	status_bar.add_child(status_label)

	status_mode_label = Label.new()
	status_mode_label.text = "Mode : Orbite"
	UITheme.apply_label_theme(status_mode_label, UITheme.FONT_SIZE_SM, UITheme.ACCENT)
	status_bar.add_child(status_mode_label)

	status_snap_label = Label.new()
	status_snap_label.text = "Snap : ON"
	UITheme.apply_label_theme(status_snap_label, UITheme.FONT_SIZE_SM, UITheme.SUCCESS)
	status_bar.add_child(status_snap_label)


func _refresh_hierarchy() -> void:
	if not house_ref or not hierarchy_panel:
		return

	# Nettoyer
	for child in hierarchy_panel.get_children():
		child.queue_free()

	# Section Maison
	var house_btn := Button.new()
	house_btn.text = "  Maison (%.1f × %.1f m)" % [house_ref.exterior_width, house_ref.exterior_depth]
	house_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	house_btn.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.BG_HEADER, 0))
	house_btn.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.BG_BUTTON_HOVER, 0))
	house_btn.add_theme_color_override("font_color", UITheme.ACCENT)
	house_btn.add_theme_color_override("font_hover_color", UITheme.ACCENT_HOVER)
	house_btn.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
	hierarchy_panel.add_child(house_btn)

	hierarchy_panel.add_child(UITheme.make_separator())

	# Pièces
	for room in house_ref.rooms:
		var btn := Button.new()
		btn.text = "    %s  (%.1f × %.1f)" % [room.room_name, room.room_width, room.room_depth]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.BG_BUTTON_HOVER, 2))
		btn.add_theme_stylebox_override("pressed", UITheme.panel_style(UITheme.BG_SELECTED, 2))
		btn.add_theme_color_override("font_color", UITheme.TEXT)
		btn.add_theme_color_override("font_hover_color", UITheme.TEXT_BRIGHT)
		btn.add_theme_color_override("font_pressed_color", UITheme.TEXT_BRIGHT)
		btn.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
		btn.custom_minimum_size = Vector2(0, 26)
		btn.pressed.connect(_on_room_clicked.bind(room.room_name))
		hierarchy_panel.add_child(btn)


func update_properties(object: Node3D) -> void:
	# Nettoyer
	for child in properties_panel.get_children():
		child.queue_free()

	if not object:
		var empty_label := UITheme.make_dim_label("Aucune sélection")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		properties_panel.add_child(UITheme.make_spacer(20))
		properties_panel.add_child(empty_label)
		return

	if object.has_method("get_surface"):
		_add_property("Surface", "%.1f m²" % object.get_surface())

	if "room_name" in object:
		# Section titre
		var title_lbl := UITheme.make_header_label(object.room_name)
		title_lbl.add_theme_color_override("font_color", UITheme.ACCENT)
		properties_panel.add_child(title_lbl)
		properties_panel.add_child(UITheme.make_separator())

		_add_property("Largeur", "%.2f m" % object.room_width)
		_add_property("Profondeur", "%.2f m" % object.room_depth)
		_add_property("Type", object.room_type)

		properties_panel.add_child(UITheme.make_spacer(8))

		var resize_btn := Button.new()
		resize_btn.text = "Redimensionner"
		UITheme.apply_accent_button(resize_btn)
		properties_panel.add_child(resize_btn)

	if "wall_start" in object:
		var title_lbl := UITheme.make_header_label("Mur")
		properties_panel.add_child(title_lbl)
		properties_panel.add_child(UITheme.make_separator())

		_add_property("Longueur", "%.2f m" % object.get_length())
		_add_property("Hauteur", "%.2f m" % object.wall_height)
		_add_property("Épaisseur", "%.2f m" % object.wall_thickness)
		_add_property("Ouvertures", "%d" % object.openings.size())


func _add_property(label_text: String, value_text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 24)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_theme(label, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)

	var value := Label.new()
	value.text = value_text
	UITheme.apply_label_theme(value, UITheme.FONT_SIZE_SM, UITheme.TEXT)

	hbox.add_child(label)
	hbox.add_child(value)
	properties_panel.add_child(hbox)


func add_log(message: String) -> void:
	if log_panel:
		var time_str := Time.get_time_string_from_system()
		log_panel.append_text("[color=#555555]%s[/color]  %s\n" % [time_str, message])


func update_status(text: String) -> void:
	if status_label:
		status_label.text = text
	if "Mode" in text and status_mode_label:
		status_mode_label.text = text


func _on_room_clicked(room_name: String) -> void:
	ROOM_SELECTED.emit(room_name)
	add_log("Sélection : [color=#4DA3FF]%s[/color]" % room_name)


func _on_layer_toggled(is_visible: bool, layer_name: String) -> void:
	LAYER_TOGGLED.emit(layer_name, is_visible)
	var state_color := "#5cb85c" if is_visible else "#d9534f"
	var state_text := "visible" if is_visible else "masqué"
	add_log("Layer %s : [color=%s]%s[/color]" % [layer_name, state_color, state_text])


func _on_file_menu(id: int) -> void:
	match id:
		1: SAVE_REQUESTED.emit()
		2: LOAD_REQUESTED.emit()
		3: EXPORT_2D_REQUESTED.emit()
		4: EXPORT_3D_REQUESTED.emit()
		5: get_tree().quit()


func _on_edit_menu(id: int) -> void:
	match id:
		0: add_log("Annuler (Ctrl+Z)")
		1: add_log("Refaire (Ctrl+Shift+Z)")


func _on_view_menu(id: int) -> void:
	match id:
		0: MODE_CHANGED.emit("orbit")
		1: MODE_CHANGED.emit("free_fly")
		2: MODE_CHANGED.emit("top_2d")


func _on_modules_menu(id: int) -> void:
	match id:
		0: add_log("Ouverture éditeur [color=#4DA3FF]Plomberie[/color]")
		1: add_log("Ouverture éditeur [color=#f0ad4e]Électricité[/color]")
		2: add_log("Ouverture éditeur [color=#5cb85c]Réseau[/color]")
		3: add_log("Ouverture éditeur [color=#d966ff]Domotique[/color]")


# --- Utilitaires ---

func _style_popup(popup: PopupMenu) -> void:
	popup.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_PANEL, UITheme.CORNER_RADIUS, UITheme.BORDER, 1))
	popup.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.BG_BUTTON_HOVER, 2))
	popup.add_theme_color_override("font_color", UITheme.TEXT)
	popup.add_theme_color_override("font_hover_color", UITheme.TEXT_BRIGHT)
	popup.add_theme_color_override("font_separator_color", UITheme.SEPARATOR)
	popup.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)


func _make_shortcut(key: Key, ctrl := false) -> Shortcut:
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()
	event.keycode = key
	event.ctrl_pressed = ctrl
	shortcut.events = [event]
	return shortcut


func _make_menu_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	return spacer
