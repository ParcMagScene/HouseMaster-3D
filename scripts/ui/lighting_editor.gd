extends Control
class_name LightingEditor

## Éditeur Éclairage — HouseMaster 3D — Thème dark moderne

signal LIGHT_ADDED_REQUEST(data: Dictionary)
signal SWITCH_ADDED_REQUEST(data: Dictionary)
signal DIMMER_ADDED_REQUEST(data: Dictionary)
signal DETECTOR_ADDED_REQUEST(data: Dictionary)

var simulation_manager_ref = null

# UI
var light_type: OptionButton = null
var power_input: SpinBox = null
var flux_input: SpinBox = null
var color_temp: SpinBox = null
var beam_angle: SpinBox = null
var height_input: SpinBox = null
var dimmable_check: CheckBox = null
var room_selector: OptionButton = null
var circuit_selector: OptionButton = null
var ip_selector: OptionButton = null
var validation_label: RichTextLabel = null
var summary_label: RichTextLabel = null

var light_types := ["led", "halogen", "fluorescent", "incandescent"]
var light_labels := ["LED", "Halogène", "Fluorescent", "Incandescent"]
var ip_ratings := ["IP20", "IP44", "IP65", "IP67", "IP68"]


func _ready() -> void:
	_build_ui()


func setup(sim_manager) -> void:
	simulation_manager_ref = sim_manager


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size = Vector2(280, 620)
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
	vbox.add_child(_make_editor_header("ÉCLAIRAGE", Color(1.0, 0.85, 0.3)))

	# --- Luminaire ---
	vbox.add_child(_section_label("Luminaire"))

	vbox.add_child(_styled_label("Type"))
	light_type = OptionButton.new()
	for l in light_labels:
		light_type.add_item(l)
	UITheme.apply_button_theme(light_type)
	vbox.add_child(light_type)

	var power_hbox := HBoxContainer.new()
	power_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(power_hbox)

	var pw_lbl := _styled_label("Puissance (W)")
	pw_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_hbox.add_child(pw_lbl)
	power_input = SpinBox.new()
	power_input.min_value = 1
	power_input.max_value = 2000
	power_input.step = 1
	power_input.value = 10
	power_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_input.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	power_hbox.add_child(power_input)

	var flux_hbox := HBoxContainer.new()
	flux_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(flux_hbox)

	var fl_lbl := _styled_label("Flux (lm)")
	fl_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flux_hbox.add_child(fl_lbl)
	flux_input = SpinBox.new()
	flux_input.min_value = 0
	flux_input.max_value = 50000
	flux_input.step = 50
	flux_input.value = 1000
	flux_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flux_input.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	flux_hbox.add_child(flux_input)

	var ct_hbox := HBoxContainer.new()
	ct_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(ct_hbox)

	var ct_lbl := _styled_label("Temp. couleur (K)")
	ct_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ct_hbox.add_child(ct_lbl)
	color_temp = SpinBox.new()
	color_temp.min_value = 2700
	color_temp.max_value = 6500
	color_temp.step = 100
	color_temp.value = 4000
	color_temp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_temp.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	ct_hbox.add_child(color_temp)

	var angle_hbox := HBoxContainer.new()
	angle_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(angle_hbox)

	var a_lbl := _styled_label("Angle (°)")
	a_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	angle_hbox.add_child(a_lbl)
	beam_angle = SpinBox.new()
	beam_angle.min_value = 15
	beam_angle.max_value = 360
	beam_angle.step = 5
	beam_angle.value = 120
	beam_angle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	beam_angle.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	angle_hbox.add_child(beam_angle)

	var h_hbox := HBoxContainer.new()
	h_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(h_hbox)

	var h_lbl := _styled_label("Hauteur (m)")
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_hbox.add_child(h_lbl)
	height_input = SpinBox.new()
	height_input.min_value = 0.3
	height_input.max_value = 6.0
	height_input.step = 0.1
	height_input.value = 2.5
	height_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	height_input.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	h_hbox.add_child(height_input)

	dimmable_check = CheckBox.new()
	dimmable_check.text = "Variateur (dimmable)"
	dimmable_check.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	dimmable_check.add_theme_color_override("font_color", UITheme.TEXT)
	vbox.add_child(dimmable_check)

	vbox.add_child(_styled_label("Indice IP"))
	ip_selector = OptionButton.new()
	for ip in ip_ratings:
		ip_selector.add_item(ip)
	UITheme.apply_button_theme(ip_selector)
	vbox.add_child(ip_selector)

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

	vbox.add_child(_styled_label("Circuit"))
	circuit_selector = OptionButton.new()
	circuit_selector.add_item("(auto)")
	UITheme.apply_button_theme(circuit_selector)
	vbox.add_child(circuit_selector)

	vbox.add_child(UITheme.make_separator())

	# --- Boutons d'ajout ---
	var add_light_btn := Button.new()
	add_light_btn.text = "＋ Ajouter luminaire"
	UITheme.apply_button_theme(add_light_btn)
	add_light_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_light_btn.pressed.connect(_on_add_light)
	vbox.add_child(add_light_btn)

	var add_switch_btn := Button.new()
	add_switch_btn.text = "＋ Ajouter interrupteur"
	UITheme.apply_button_theme(add_switch_btn)
	add_switch_btn.pressed.connect(_on_add_switch)
	vbox.add_child(add_switch_btn)

	var add_dimmer_btn := Button.new()
	add_dimmer_btn.text = "＋ Ajouter variateur"
	UITheme.apply_button_theme(add_dimmer_btn)
	add_dimmer_btn.pressed.connect(_on_add_dimmer)
	vbox.add_child(add_dimmer_btn)

	var add_detector_btn := Button.new()
	add_detector_btn.text = "＋ Ajouter détecteur"
	UITheme.apply_button_theme(add_detector_btn)
	add_detector_btn.pressed.connect(_on_add_detector)
	vbox.add_child(add_detector_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Validation ---
	var validate_btn := Button.new()
	validate_btn.text = "Valider éclairage"
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

	# --- Résumé ---
	summary_label = RichTextLabel.new()
	summary_label.bbcode_enabled = true
	summary_label.custom_minimum_size = Vector2(0, 60)
	summary_label.fit_content = true
	summary_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	summary_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	vbox.add_child(summary_label)


# --- Actions ---

func _on_add_light() -> void:
	var data := {
		"type": light_types[light_type.selected],
		"power_w": power_input.value,
		"luminous_flux_lm": flux_input.value,
		"color_temp_k": int(color_temp.value),
		"beam_angle_deg": beam_angle.value,
		"height_m": height_input.value,
		"dimmable": dimmable_check.button_pressed,
		"ip_rating": ip_ratings[ip_selector.selected],
		"room_index": room_selector.selected,
		"circuit_index": circuit_selector.selected,
	}
	LIGHT_ADDED_REQUEST.emit(data)


func _on_add_switch() -> void:
	SWITCH_ADDED_REQUEST.emit({"room_index": room_selector.selected})


func _on_add_dimmer() -> void:
	DIMMER_ADDED_REQUEST.emit({"room_index": room_selector.selected, "max_power_w": power_input.value * 2})


func _on_add_detector() -> void:
	DETECTOR_ADDED_REQUEST.emit({"room_index": room_selector.selected, "range_m": 6.0, "angle_deg": 180.0})


func _on_validate() -> void:
	if not simulation_manager_ref:
		validation_label.text = "[color=#FF6B6B]SimulationManager non connecté[/color]"
		return

	simulation_manager_ref.run_simulation("lighting")
	var report = simulation_manager_ref.get_report("lighting")
	if report:
		_display_validation(report)


func _display_validation(report) -> void:
	var text := ""
	if report.errors.size() > 0:
		text += "[color=#FF6B6B][b]Erreurs (%d)[/b][/color]\n" % report.errors.size()
		for err in report.errors:
			text += "  • %s\n" % err.get("message", "")

	if report.warnings.size() > 0:
		text += "[color=#FFB347][b]Avertissements (%d)[/b][/color]\n" % report.warnings.size()
		for warn in report.warnings:
			text += "  • %s\n" % warn.get("message", "")

	if report.suggestions.size() > 0:
		text += "[color=#4DA3FF][b]Suggestions (%d)[/b][/color]\n" % report.suggestions.size()
		for sug in report.suggestions:
			text += "  • %s\n" % sug.get("message", "")

	if report.errors.size() == 0 and report.warnings.size() == 0:
		text = "[color=#4CAF50]✓ Éclairage conforme NF C 15-100[/color]"

	validation_label.text = text

	# Résumé métriques
	var summary := "[b]Résumé[/b]\n"
	for key in report.metrics:
		var val = report.metrics[key]
		if val is Dictionary or val is Array:
			continue
		summary += "%s : %s\n" % [key.replace("_", " ").capitalize(), str(val)]
	summary_label.text = summary


# --- UI Helpers ---

func _make_editor_header(title: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_LG)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
	lbl.add_theme_color_override("font_color", UITheme.TEXT)
	return lbl


func _styled_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	lbl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	return lbl
