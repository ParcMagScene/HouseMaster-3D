extends Control
class_name ElectricityEditor

## Éditeur Électricité — HouseMaster 3D — Thème dark moderne

signal CIRCUIT_ADDED_REQUEST(data: Dictionary)
signal ELEMENT_ADDED_REQUEST(data: Dictionary)

var electricity_ref: Node3D = null

# UI
var circuit_name_input: LineEdit = null
var circuit_type: OptionButton = null
var breaker_selector: OptionButton = null
var element_type: OptionButton = null
var element_height: SpinBox = null
var circuit_selector: OptionButton = null
var room_selector: OptionButton = null
var panel_summary: RichTextLabel = null
var validation_label: RichTextLabel = null

var circuit_types := ["sockets", "lights", "dedicated"]
var circuit_labels := ["Prises", "Éclairage", "Dédié"]
var element_types := ["socket", "switch", "light", "outlet_32a"]
var element_labels := ["Prise", "Interrupteur", "Point lumineux", "Prise 32A"]
var breaker_sizes := [10, 16, 20, 32]


func _ready() -> void:
	_build_ui()


func setup(electricity: Node3D) -> void:
	electricity_ref = electricity


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
	vbox.add_child(_make_editor_header("ÉLECTRICITÉ", UITheme.WARNING))

	# --- Section circuits ---
	vbox.add_child(_section_label("Circuits"))

	vbox.add_child(_styled_label("Nom du circuit"))
	circuit_name_input = LineEdit.new()
	circuit_name_input.placeholder_text = "Ex: Prises séjour"
	UITheme.apply_input_theme(circuit_name_input)
	vbox.add_child(circuit_name_input)

	vbox.add_child(_styled_label("Type de circuit"))
	circuit_type = OptionButton.new()
	for l in circuit_labels:
		circuit_type.add_item(l)
	UITheme.apply_button_theme(circuit_type)
	vbox.add_child(circuit_type)

	vbox.add_child(_styled_label("Disjoncteur"))
	breaker_selector = OptionButton.new()
	for b in breaker_sizes:
		breaker_selector.add_item("%dA" % b)
	breaker_selector.selected = 1
	UITheme.apply_button_theme(breaker_selector)
	vbox.add_child(breaker_selector)

	var add_circuit_btn := Button.new()
	add_circuit_btn.text = "＋ Ajouter circuit"
	UITheme.apply_button_theme(add_circuit_btn)
	add_circuit_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_circuit_btn.pressed.connect(_on_add_circuit)
	vbox.add_child(add_circuit_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Section éléments ---
	vbox.add_child(_section_label("Éléments"))

	vbox.add_child(_styled_label("Type d'élément"))
	element_type = OptionButton.new()
	for l in element_labels:
		element_type.add_item(l)
	UITheme.apply_button_theme(element_type)
	vbox.add_child(element_type)

	var height_hbox := HBoxContainer.new()
	height_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(height_hbox)

	var h_lbl := _styled_label("Hauteur (m)")
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	height_hbox.add_child(h_lbl)
	element_height = SpinBox.new()
	element_height.min_value = 0.0
	element_height.max_value = 2.5
	element_height.step = 0.05
	element_height.value = 0.30
	element_height.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	element_height.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	height_hbox.add_child(element_height)

	vbox.add_child(_styled_label("Circuit associé"))
	circuit_selector = OptionButton.new()
	circuit_selector.add_item("(aucun)")
	UITheme.apply_button_theme(circuit_selector)
	vbox.add_child(circuit_selector)

	vbox.add_child(_styled_label("Pièce"))
	room_selector = OptionButton.new()
	room_selector.add_item("Séjour + Cuisine")
	room_selector.add_item("Chambre 1")
	room_selector.add_item("Chambre 2")
	room_selector.add_item("Salle de bain")
	room_selector.add_item("WC")
	room_selector.add_item("Cellier")
	UITheme.apply_button_theme(room_selector)
	vbox.add_child(room_selector)

	var add_element_btn := Button.new()
	add_element_btn.text = "＋ Ajouter élément"
	UITheme.apply_button_theme(add_element_btn)
	add_element_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_element_btn.pressed.connect(_on_add_element)
	vbox.add_child(add_element_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Tableau résumé ---
	var panel_btn := Button.new()
	panel_btn.text = "Résumé tableau"
	UITheme.apply_button_theme(panel_btn)
	panel_btn.pressed.connect(_on_show_panel)
	vbox.add_child(panel_btn)

	panel_summary = RichTextLabel.new()
	panel_summary.bbcode_enabled = true
	panel_summary.custom_minimum_size = Vector2(0, 80)
	panel_summary.fit_content = true
	panel_summary.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	panel_summary.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	vbox.add_child(panel_summary)

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


func _on_add_circuit() -> void:
	if not electricity_ref:
		return
	var c_name = circuit_name_input.text if circuit_name_input.text != "" else "Circuit %d" % (electricity_ref.circuits.size() + 1)
	var c_type = circuit_types[circuit_type.selected]
	var breaker = breaker_sizes[breaker_selector.selected]

	var idx = electricity_ref.add_circuit(c_name, c_type, breaker)
	circuit_selector.add_item(c_name)
	CIRCUIT_ADDED_REQUEST.emit({"name": c_name, "type": c_type, "breaker": breaker})


func _on_add_element() -> void:
	if not electricity_ref:
		return
	var e_type = element_types[element_type.selected]
	var height = element_height.value
	var circuit_idx = circuit_selector.selected - 1
	var room = room_selector.get_item_text(room_selector.selected)

	electricity_ref.add_element(e_type, Vector3(1, 0, 1), room, circuit_idx, height)
	ELEMENT_ADDED_REQUEST.emit({"type": e_type, "room": room})


func _on_show_panel() -> void:
	if not electricity_ref:
		return
	var summary = electricity_ref.get_panel_summary()
	panel_summary.clear()
	panel_summary.append_text("[b][color=#f0ad4e]Tableau électrique[/color][/b]\n")
	panel_summary.append_text("Disjoncteur principal : %dA\n" % summary["main_breaker"])
	panel_summary.append_text("Circuits : %d\n" % summary["circuits_count"])
	for c in summary["circuits"]:
		panel_summary.append_text("  • %s (%s, %dA) : %d éléments\n" % [c["name"], c["type"], c["breaker"], c["elements_count"]])


func _on_validate() -> void:
	if not electricity_ref:
		return
	var errors = electricity_ref.validate()
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


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, UITheme.WARNING)
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
