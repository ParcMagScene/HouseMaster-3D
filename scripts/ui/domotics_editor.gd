extends Control
class_name DomoticsEditor

## Éditeur Domotique — HouseMaster 3D — Thème dark moderne

signal SENSOR_ADDED_REQUEST(data: Dictionary)
signal ACTUATOR_ADDED_REQUEST(data: Dictionary)
signal SCENARIO_ADDED_REQUEST(data: Dictionary)

var domotics_ref: Node3D = null

# UI
var sensor_type: OptionButton = null
var actuator_type: OptionButton = null
var room_selector: OptionButton = null
var label_input: LineEdit = null
var scenario_name_input: LineEdit = null
var scenario_sensor_selector: OptionButton = null
var scenario_operator: OptionButton = null
var scenario_value_input: LineEdit = null
var scenario_actuator_selector: OptionButton = null
var scenario_action: OptionButton = null
var time_condition_input: LineEdit = null
var validation_label: RichTextLabel = null

var sensor_types := ["motion", "temperature", "opening", "humidity", "light_level"]
var sensor_labels := ["Mouvement", "Température", "Ouverture", "Humidité", "Luminosité"]
var actuator_types := ["light", "shutter", "heating", "alarm", "lock"]
var actuator_labels := ["Lumière", "Volet", "Chauffage", "Alarme", "Serrure"]
var operators := ["==", ">", "<", ">=", "<="]
var actions := ["turn_on", "turn_off", "toggle", "set_value"]
var action_labels := ["Allumer", "Éteindre", "Basculer", "Définir valeur"]

const DOMOTICS_COLOR := Color("d966ff")


func _ready() -> void:
	_build_ui()


func setup(domotics: Node3D) -> void:
	domotics_ref = domotics


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.size = Vector2(300, 680)
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
	vbox.add_child(_make_editor_header("DOMOTIQUE", DOMOTICS_COLOR))

	# ══════════ CAPTEURS ══════════
	vbox.add_child(_section_label("Capteurs"))

	vbox.add_child(_styled_label("Type"))
	sensor_type = OptionButton.new()
	for l in sensor_labels:
		sensor_type.add_item(l)
	UITheme.apply_button_theme(sensor_type)
	vbox.add_child(sensor_type)

	vbox.add_child(_styled_label("Pièce"))
	room_selector = OptionButton.new()
	room_selector.add_item("Séjour + Cuisine")
	room_selector.add_item("Chambre 1")
	room_selector.add_item("Chambre 2")
	room_selector.add_item("Salle de bain")
	room_selector.add_item("WC")
	room_selector.add_item("Cellier")
	room_selector.add_item("Entrée")
	UITheme.apply_button_theme(room_selector)
	vbox.add_child(room_selector)

	vbox.add_child(_styled_label("Label"))
	label_input = LineEdit.new()
	label_input.placeholder_text = "Ex: motion_entree"
	UITheme.apply_input_theme(label_input)
	vbox.add_child(label_input)

	var add_sensor_btn := Button.new()
	add_sensor_btn.text = "＋ Ajouter capteur"
	UITheme.apply_button_theme(add_sensor_btn)
	add_sensor_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_sensor_btn.pressed.connect(_on_add_sensor)
	vbox.add_child(add_sensor_btn)

	vbox.add_child(UITheme.make_separator())

	# ══════════ ACTIONNEURS ══════════
	vbox.add_child(_section_label("Actionneurs"))

	vbox.add_child(_styled_label("Type"))
	actuator_type = OptionButton.new()
	for l in actuator_labels:
		actuator_type.add_item(l)
	UITheme.apply_button_theme(actuator_type)
	vbox.add_child(actuator_type)

	var add_actuator_btn := Button.new()
	add_actuator_btn.text = "＋ Ajouter actionneur"
	UITheme.apply_button_theme(add_actuator_btn)
	add_actuator_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_actuator_btn.pressed.connect(_on_add_actuator)
	vbox.add_child(add_actuator_btn)

	vbox.add_child(UITheme.make_separator())

	# ══════════ SCÉNARIOS ══════════
	vbox.add_child(_section_label("Scénarios"))

	vbox.add_child(_styled_label("Nom du scénario"))
	scenario_name_input = LineEdit.new()
	scenario_name_input.placeholder_text = "Ex: Éclairage auto entrée"
	UITheme.apply_input_theme(scenario_name_input)
	vbox.add_child(scenario_name_input)

	# Condition : SI capteur + opérateur + valeur
	var cond_panel := PanelContainer.new()
	cond_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, UITheme.CORNER_RADIUS))
	vbox.add_child(cond_panel)

	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 4)
	cond_panel.add_child(cond_vbox)

	var cond_title := Label.new()
	cond_title.text = "SI"
	UITheme.apply_label_theme(cond_title, UITheme.FONT_SIZE_SM, DOMOTICS_COLOR)
	cond_vbox.add_child(cond_title)

	scenario_sensor_selector = OptionButton.new()
	scenario_sensor_selector.add_item("(sélectionner)")
	UITheme.apply_button_theme(scenario_sensor_selector)
	cond_vbox.add_child(scenario_sensor_selector)

	var op_val_hbox := HBoxContainer.new()
	op_val_hbox.add_theme_constant_override("separation", 4)
	cond_vbox.add_child(op_val_hbox)

	scenario_operator = OptionButton.new()
	for op in operators:
		scenario_operator.add_item(op)
	scenario_operator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(scenario_operator)
	op_val_hbox.add_child(scenario_operator)

	scenario_value_input = LineEdit.new()
	scenario_value_input.placeholder_text = "true / 20.0"
	scenario_value_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_input_theme(scenario_value_input)
	op_val_hbox.add_child(scenario_value_input)

	# Action : ALORS actionneur + action
	var action_panel := PanelContainer.new()
	action_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, UITheme.CORNER_RADIUS))
	vbox.add_child(action_panel)

	var action_vbox := VBoxContainer.new()
	action_vbox.add_theme_constant_override("separation", 4)
	action_panel.add_child(action_vbox)

	var action_title := Label.new()
	action_title.text = "ALORS"
	UITheme.apply_label_theme(action_title, UITheme.FONT_SIZE_SM, UITheme.ACCENT)
	action_vbox.add_child(action_title)

	scenario_actuator_selector = OptionButton.new()
	scenario_actuator_selector.add_item("(sélectionner)")
	UITheme.apply_button_theme(scenario_actuator_selector)
	action_vbox.add_child(scenario_actuator_selector)

	scenario_action = OptionButton.new()
	for l in action_labels:
		scenario_action.add_item(l)
	UITheme.apply_button_theme(scenario_action)
	action_vbox.add_child(scenario_action)

	# Condition horaire
	vbox.add_child(_styled_label("Condition horaire"))
	time_condition_input = LineEdit.new()
	time_condition_input.placeholder_text = "any / 20:00-06:00"
	time_condition_input.text = "any"
	UITheme.apply_input_theme(time_condition_input)
	vbox.add_child(time_condition_input)

	# Boutons
	var scenario_btns := HBoxContainer.new()
	scenario_btns.add_theme_constant_override("separation", 6)
	vbox.add_child(scenario_btns)

	var add_scenario_btn := Button.new()
	add_scenario_btn.text = "＋ Créer scénario"
	add_scenario_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(add_scenario_btn)
	add_scenario_btn.add_theme_color_override("font_color", UITheme.SUCCESS)
	add_scenario_btn.pressed.connect(_on_add_scenario)
	scenario_btns.add_child(add_scenario_btn)

	var test_btn := Button.new()
	test_btn.text = "Tester"
	test_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_accent_button(test_btn)
	test_btn.pressed.connect(_on_test_scenarios)
	scenario_btns.add_child(test_btn)

	vbox.add_child(UITheme.make_separator())

	# --- Résultats ---
	validation_label = RichTextLabel.new()
	validation_label.bbcode_enabled = true
	validation_label.custom_minimum_size = Vector2(0, 80)
	validation_label.fit_content = true
	validation_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	validation_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	vbox.add_child(validation_label)

	# --- Exemple ---
	vbox.add_child(UITheme.make_separator())

	var example_panel := PanelContainer.new()
	example_panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG_DARK, UITheme.CORNER_RADIUS))
	vbox.add_child(example_panel)

	var example := Label.new()
	example.text = "Exemple :\nIF motion_detected\nAND time > 20:00\nTHEN turn_on_light"
	example.autowrap_mode = TextServer.AUTOWRAP_WORD
	UITheme.apply_label_theme(example, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	example_panel.add_child(example)


func _on_add_sensor() -> void:
	if not domotics_ref:
		return
	var type := sensor_types[sensor_type.selected]
	var room := room_selector.get_item_text(room_selector.selected)
	var label_text := label_input.text

	var idx := domotics_ref.add_sensor(type, Vector3(1, 2.0, 1), room, label_text)
	scenario_sensor_selector.add_item(label_text if label_text != "" else "%s_%d" % [type, idx])
	SENSOR_ADDED_REQUEST.emit({"type": type, "room": room})


func _on_add_actuator() -> void:
	if not domotics_ref:
		return
	var type := actuator_types[actuator_type.selected]
	var room := room_selector.get_item_text(room_selector.selected)
	var label_text := label_input.text

	var idx := domotics_ref.add_actuator(type, Vector3(1, 1.5, 1), room, label_text)
	scenario_actuator_selector.add_item(label_text if label_text != "" else "%s_%d" % [type, idx])
	ACTUATOR_ADDED_REQUEST.emit({"type": type, "room": room})


func _on_add_scenario() -> void:
	if not domotics_ref:
		return

	var s_name := scenario_name_input.text
	if s_name == "":
		s_name = "Scénario %d" % (domotics_ref.scenarios.size() + 1)

	var sensor_idx := scenario_sensor_selector.selected - 1
	var actuator_idx := scenario_actuator_selector.selected - 1
	var op := operators[scenario_operator.selected]
	var value_text := scenario_value_input.text
	var action := actions[scenario_action.selected]
	var time_cond := time_condition_input.text

	# Parser la valeur
	var value: Variant = null
	if value_text == "true":
		value = true
	elif value_text == "false":
		value = false
	elif value_text.is_valid_float():
		value = value_text.to_float()
	else:
		value = value_text

	var conditions := [{"sensor_index": sensor_idx, "operator": op, "value": value}]
	var action_list := [{"actuator_index": actuator_idx, "action": action, "value": value}]

	domotics_ref.add_scenario(s_name, conditions, action_list, time_cond)

	validation_label.clear()
	validation_label.append_text("[color=#5cb85c]Scénario '%s' créé[/color]\n" % s_name)
	SCENARIO_ADDED_REQUEST.emit({"name": s_name})


func _on_test_scenarios() -> void:
	if not domotics_ref:
		return
	var triggered := domotics_ref.evaluate_scenarios()
	validation_label.clear()
	if triggered.is_empty():
		validation_label.append_text("[color=#888888]Aucun scénario déclenché[/color]")
	else:
		validation_label.append_text("[color=#5cb85c]%d actions déclenchées :[/color]\n" % triggered.size())
		for act in triggered:
			validation_label.append_text("  • %s → actionneur %d\n" % [act.get("action", "?"), act.get("actuator_index", -1)])


# --- Helpers thème ---

func _styled_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, UITheme.TEXT_DIM)
	return l


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	UITheme.apply_label_theme(l, UITheme.FONT_SIZE_SM, DOMOTICS_COLOR)
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
