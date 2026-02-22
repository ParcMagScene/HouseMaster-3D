extends Control
class_name PlumbingEditor

## Éditeur Plomberie — HouseMaster 3D — Thème dark moderne

signal PIPE_ADDED_REQUEST(data: Dictionary)
signal FIXTURE_ADDED_REQUEST(data: Dictionary)

var plumbing_ref: Node3D = null

# UI
var pipe_type: OptionButton = null
var pipe_diameter: SpinBox = null
var fixture_type: OptionButton = null
var room_selector: OptionButton = null
var validation_label: RichTextLabel = null

var pipe_types := ["supply", "hot_supply", "evacuation"]
var pipe_labels := ["Eau froide", "Eau chaude", "Évacuation"]
var fixture_types := ["sink", "toilet", "shower", "bathtub", "washing_machine"]
var fixture_labels := ["Évier/Lavabo", "WC", "Douche", "Baignoire", "Lave-linge"]


func _ready() -> void:
	_build_ui()


func setup(plumbing: Node3D) -> void:
	plumbing_ref = plumbing


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size = Vector2(280, 500)
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
	var header := _make_editor_header("PLOMBERIE", UITheme.ACCENT)
	vbox.add_child(header)

	# --- Section tuyaux ---
	vbox.add_child(_section_label("Tuyaux"))

	vbox.add_child(_styled_label("Type de tuyau"))
	pipe_type = OptionButton.new()
	for l in pipe_labels:
		pipe_type.add_item(l)
	UITheme.apply_button_theme(pipe_type)
	vbox.add_child(pipe_type)

	vbox.add_child(_styled_label("Diamètre (mm)"))
	pipe_diameter = SpinBox.new()
	pipe_diameter.min_value = 12
	pipe_diameter.max_value = 100
	pipe_diameter.step = 1
	pipe_diameter.value = 40
	pipe_diameter.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	vbox.add_child(pipe_diameter)

	var add_pipe_btn := Button.new()
	add_pipe_btn.text = "＋ Ajouter tuyau"
	UITheme.apply_button_theme(add_pipe_btn)
	add_pipe_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_pipe_btn.pressed.connect(_on_add_pipe)
	vbox.add_child(add_pipe_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Section appareils ---
	vbox.add_child(_section_label("Appareils sanitaires"))

	vbox.add_child(_styled_label("Appareil"))
	fixture_type = OptionButton.new()
	for l in fixture_labels:
		fixture_type.add_item(l)
	UITheme.apply_button_theme(fixture_type)
	vbox.add_child(fixture_type)

	vbox.add_child(_styled_label("Pièce"))
	room_selector = OptionButton.new()
	room_selector.add_item("Salle de bain")
	room_selector.add_item("WC")
	room_selector.add_item("Cuisine")
	room_selector.add_item("Cellier")
	UITheme.apply_button_theme(room_selector)
	vbox.add_child(room_selector)

	var add_fixture_btn := Button.new()
	add_fixture_btn.text = "＋ Ajouter appareil"
	UITheme.apply_button_theme(add_fixture_btn)
	add_fixture_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_fixture_btn.pressed.connect(_on_add_fixture)
	vbox.add_child(add_fixture_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Validation ---
	var validate_btn := Button.new()
	validate_btn.text = "Valider installation"
	UITheme.apply_accent_button(validate_btn)
	validate_btn.pressed.connect(_on_validate)
	vbox.add_child(validate_btn)

	validation_label = RichTextLabel.new()
	validation_label.bbcode_enabled = true
	validation_label.custom_minimum_size = Vector2(0, 80)
	validation_label.fit_content = true
	validation_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	validation_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	vbox.add_child(validation_label)

	# --- Règles métier ---
	vbox.add_child(UITheme.make_separator())

	var rules_panel := PanelContainer.new()
	rules_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, UITheme.CORNER_RADIUS))
	vbox.add_child(rules_panel)

	var rules := Label.new()
	rules.text = "Règles NF :\n• Pente min : 1%\n• Évac : 40–100 mm\n• Arrivée : 12–16 mm"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD
	UITheme.apply_label_theme(rules, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	rules_panel.add_child(rules)


func _on_add_pipe() -> void:
	if not plumbing_ref:
		return
	var type = pipe_types[pipe_type.selected]
	var diameter := pipe_diameter.value
	plumbing_ref.add_pipe(type, Vector3(0, 0.1, 0), Vector3(2, 0.08, 0), diameter, "")
	PIPE_ADDED_REQUEST.emit({"type": type, "diameter": diameter})


func _on_add_fixture() -> void:
	if not plumbing_ref:
		return
	var type = fixture_types[fixture_type.selected]
	var room = room_selector.get_item_text(room_selector.selected)
	plumbing_ref.add_fixture(type, Vector3(1, 0, 1), room)
	FIXTURE_ADDED_REQUEST.emit({"type": type, "room": room})


func _on_validate() -> void:
	if not plumbing_ref:
		return
	var errors = plumbing_ref.validate()
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
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, UITheme.ACCENT)
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
