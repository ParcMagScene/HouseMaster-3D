extends Control
class_name NetworkEditor

## Éditeur Réseau — HouseMaster 3D — Thème dark moderne

signal POINT_ADDED_REQUEST(data: Dictionary)
signal CABLE_ADDED_REQUEST(data: Dictionary)

var network_ref: Node3D = null

# UI
var point_type: OptionButton = null
var cable_type: OptionButton = null
var room_selector: OptionButton = null
var label_input: LineEdit = null
var wifi_ssid: LineEdit = null
var wifi_band: OptionButton = null
var wifi_radius: SpinBox = null
var patch_panel_toggle: CheckButton = null
var validation_label: RichTextLabel = null

var point_types := ["rj45", "fiber_inlet", "router", "switch", "access_point"]
var point_labels := ["Prise RJ45", "Arrivée fibre", "Routeur", "Switch", "Point d'accès Wi-Fi"]
var cable_types := ["cat5e", "cat6", "cat6a", "cat7", "fiber"]
var cable_labels := ["Cat 5e", "Cat 6", "Cat 6a", "Cat 7", "Fibre optique"]
var wifi_bands := ["2.4GHz", "5GHz", "6GHz"]


func _ready() -> void:
	_build_ui()


func setup(network: Node3D) -> void:
	network_ref = network


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size = Vector2(280, 580)
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_PANEL, UITheme.CORNER_RADIUS, UITheme.BORDER, 1))
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# --- Header ---
	vbox.add_child(_make_editor_header("RÉSEAU", UITheme.SUCCESS))

	# --- Section points réseau ---
	vbox.add_child(_section_label("Points réseau"))

	vbox.add_child(_styled_label("Type de point"))
	point_type = OptionButton.new()
	for l in point_labels:
		point_type.add_item(l)
	UITheme.apply_button_theme(point_type)
	vbox.add_child(point_type)

	vbox.add_child(_styled_label("Câblage"))
	cable_type = OptionButton.new()
	for l in cable_labels:
		cable_type.add_item(l)
	cable_type.selected = 1
	UITheme.apply_button_theme(cable_type)
	vbox.add_child(cable_type)

	vbox.add_child(_styled_label("Pièce"))
	room_selector = OptionButton.new()
	room_selector.add_item("Séjour + Cuisine")
	room_selector.add_item("Chambre 1")
	room_selector.add_item("Chambre 2")
	room_selector.add_item("Salle de bain")
	room_selector.add_item("Cellier")
	UITheme.apply_button_theme(room_selector)
	vbox.add_child(room_selector)

	vbox.add_child(_styled_label("Label"))
	label_input = LineEdit.new()
	label_input.placeholder_text = "Ex: RJ45_CH1_01"
	UITheme.apply_input_theme(label_input)
	vbox.add_child(label_input)

	var add_point_btn := Button.new()
	add_point_btn.text = "＋ Ajouter point réseau"
	UITheme.apply_button_theme(add_point_btn)
	add_point_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_point_btn.pressed.connect(_on_add_point)
	vbox.add_child(add_point_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Section Wi-Fi ---
	vbox.add_child(_section_label("Zone Wi-Fi"))

	vbox.add_child(_styled_label("SSID"))
	wifi_ssid = LineEdit.new()
	wifi_ssid.text = "HouseMaster_WiFi"
	UITheme.apply_input_theme(wifi_ssid)
	vbox.add_child(wifi_ssid)

	var wifi_grid := GridContainer.new()
	wifi_grid.columns = 2
	wifi_grid.add_theme_constant_override("h_separation", 8)
	wifi_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(wifi_grid)

	wifi_grid.add_child(_dim_label("Bande"))
	wifi_band = OptionButton.new()
	for b in wifi_bands:
		wifi_band.add_item(b)
	wifi_band.selected = 1
	wifi_band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(wifi_band)
	wifi_grid.add_child(wifi_band)

	wifi_grid.add_child(_dim_label("Rayon (m)"))
	wifi_radius = SpinBox.new()
	wifi_radius.min_value = 1.0
	wifi_radius.max_value = 20.0
	wifi_radius.step = 0.5
	wifi_radius.value = 5.0
	wifi_radius.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wifi_radius.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	wifi_grid.add_child(wifi_radius)

	var add_wifi_btn := Button.new()
	add_wifi_btn.text = "＋ Ajouter zone Wi-Fi"
	UITheme.apply_button_theme(add_wifi_btn)
	add_wifi_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_wifi_btn.pressed.connect(_on_add_wifi)
	vbox.add_child(add_wifi_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Baie de brassage ---
	patch_panel_toggle = CheckButton.new()
	patch_panel_toggle.text = "Baie de brassage"
	patch_panel_toggle.add_theme_color_override("font_color", UITheme.TEXT)
	patch_panel_toggle.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	patch_panel_toggle.toggled.connect(_on_patch_panel_toggled)
	vbox.add_child(patch_panel_toggle)

	vbox.add_child(UITheme.make_separator())

	# --- Validation ---
	var validate_btn := Button.new()
	validate_btn.text = "Valider installation"
	UITheme.apply_accent_button(validate_btn)
	validate_btn.pressed.connect(_on_validate)
	vbox.add_child(validate_btn)

	validation_label = RichTextLabel.new()
	validation_label.bbcode_enabled = true
	validation_label.custom_minimum_size = Vector2(0, 60)
	validation_label.fit_content = true
	validation_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	validation_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	vbox.add_child(validation_label)

	# --- Règles ---
	vbox.add_child(UITheme.make_separator())

	var rules_panel := PanelContainer.new()
	rules_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, UITheme.CORNER_RADIUS))
	vbox.add_child(rules_panel)

	var rules := Label.new()
	rules.text = "Règles :\n• RJ45 Cat 6 min\n• Fibre en entrée\n• Baie optionnelle"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD
	UITheme.apply_label_theme(rules, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	rules_panel.add_child(rules)


func _on_add_point() -> void:
	if not network_ref:
		return
	var type = point_types[point_type.selected]
	var cable = cable_types[cable_type.selected]
	var room = room_selector.get_item_text(room_selector.selected)
	var label_text = label_input.text

	network_ref.add_point(type, Vector3(1, 0.3, 1), room, cable, label_text)
	POINT_ADDED_REQUEST.emit({"type": type, "room": room})


func _on_add_wifi() -> void:
	if not network_ref:
		return
	var ssid = wifi_ssid.text
	var band = wifi_bands[wifi_band.selected]
	var radius = wifi_radius.value

	network_ref.add_wifi_zone(Vector3(5.25, 1.5, 3.35), radius, ssid, band)


func _on_patch_panel_toggled(enabled: bool) -> void:
	if not network_ref:
		return
	if enabled:
		network_ref.enable_patch_panel(Vector3(9.0, 1.0, 5.5), 24)


func _on_validate() -> void:
	if not network_ref:
		return
	var errors = network_ref.validate()
	validation_label.clear()
	if errors.is_empty():
		validation_label.append_text("[color=#5cb85c]Installation conforme[/color]")
	else:
		validation_label.append_text("[color=#d9534f]Erreurs :[/color]\n")
		for error in errors:
			validation_label.append_text("[color=#f0ad4e]• %s[/color]\n" % error)


# --- Helpers thème ---

func _styled_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	return l


func _dim_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	return l


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, UITheme.SUCCESS)
	return l


func _make_editor_header(title_text: String, accent_color: Color) -> PanelContainer:
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UITheme.header_style())
	header.custom_minimum_size = Vector2(0, UITheme.HEADER_HEIGHT)

	var hbox := HBoxContainer.new()
	header.add_child(hbox)

	var title := UITheme.make_header_label(title_text)
	title.add_theme_color_override("font_color", accent_color)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 28)
	UITheme.apply_button_theme(close_btn)
	close_btn.pressed.connect(func(): visible = false)
	hbox.add_child(close_btn)

	return header
