extends Control
class_name SimulationPanel

## Panneau de simulation — HouseMaster 3D — Thème dark moderne
## Contrôle et affichage des résultats de simulation

signal SIMULATION_RUN_REQUEST(network: String)
signal SIMULATION_RUN_ALL_REQUEST
signal OPTIMIZATION_REQUEST(network: String)
signal CABLE_ROUTING_REQUEST(network: String)

var simulation_manager_ref = null

# UI
var status_label: RichTextLabel = null
var results_container: VBoxContainer = null
var network_selector: OptionButton = null
var progress_bar: ProgressBar = null
var error_list: RichTextLabel = null
var metrics_container: VBoxContainer = null
var energy_summary: RichTextLabel = null

var networks := ["electricity", "plumbing", "network", "heating", "surveillance", "domotics", "lighting"]
var network_labels := ["Électricité", "Plomberie", "Réseau", "Chauffage", "Surveillance", "Domotique", "Éclairage"]


func _ready() -> void:
	_build_ui()


func setup(sim_manager) -> void:
	simulation_manager_ref = sim_manager
	if simulation_manager_ref:
		if simulation_manager_ref.has_signal("SIMULATION_COMPLETED"):
			simulation_manager_ref.SIMULATION_COMPLETED.connect(_on_simulation_completed)
		if simulation_manager_ref.has_signal("SIMULATION_ERROR"):
			simulation_manager_ref.SIMULATION_ERROR.connect(_on_simulation_error)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.size = Vector2(300, 620)
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
	vbox.add_child(_make_editor_header("SIMULATION", UITheme.ACCENT))

	# --- Sélection réseau ---
	vbox.add_child(_section_label("Réseau"))

	network_selector = OptionButton.new()
	network_selector.add_item("Tous les réseaux")
	for lbl in network_labels:
		network_selector.add_item(lbl)
	UITheme.apply_button_theme(network_selector)
	vbox.add_child(network_selector)

	# --- Boutons d'action ---
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(btn_hbox)

	var run_btn := Button.new()
	run_btn.text = "▶ Simuler"
	run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_accent_button(run_btn)
	run_btn.pressed.connect(_on_run_simulation)
	btn_hbox.add_child(run_btn)

	var optimize_btn := Button.new()
	optimize_btn.text = "⚡ Optimiser"
	optimize_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(optimize_btn)
	optimize_btn.add_theme_color_override("font_color", UITheme.WARNING)
	optimize_btn.pressed.connect(_on_optimize)
	btn_hbox.add_child(optimize_btn)

	var route_btn := Button.new()
	route_btn.text = "🔀 Routage"
	route_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_button_theme(route_btn)
	route_btn.pressed.connect(_on_cable_routing)
	vbox.add_child(route_btn)

	# --- Barre de progression ---
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 4)
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = UITheme.BG_DARK
	bar_style.corner_radius_top_left = 2
	bar_style.corner_radius_top_right = 2
	bar_style.corner_radius_bottom_left = 2
	bar_style.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("background", bar_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = UITheme.ACCENT
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(progress_bar)

	vbox.add_child(UITheme.make_separator())

	# --- Status ---
	status_label = RichTextLabel.new()
	status_label.bbcode_enabled = true
	status_label.custom_minimum_size = Vector2(0, 24)
	status_label.fit_content = true
	status_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	status_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)
	status_label.text = "Prêt"
	vbox.add_child(status_label)

	vbox.add_child(UITheme.make_separator())

	# --- Résultats — Erreurs / Warnings ---
	vbox.add_child(_section_label("Résultats"))

	error_list = RichTextLabel.new()
	error_list.bbcode_enabled = true
	error_list.custom_minimum_size = Vector2(0, 120)
	error_list.fit_content = true
	error_list.scroll_active = true
	error_list.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	error_list.add_theme_color_override("default_color", UITheme.TEXT)
	vbox.add_child(error_list)

	vbox.add_child(UITheme.make_separator())

	# --- Métriques ---
	vbox.add_child(_section_label("Métriques"))

	metrics_container = VBoxContainer.new()
	metrics_container.add_theme_constant_override("separation", 2)
	vbox.add_child(metrics_container)

	vbox.add_child(UITheme.make_separator())

	# --- Énergie ---
	vbox.add_child(_section_label("Bilan Énergétique"))

	energy_summary = RichTextLabel.new()
	energy_summary.bbcode_enabled = true
	energy_summary.custom_minimum_size = Vector2(0, 80)
	energy_summary.fit_content = true
	energy_summary.add_theme_font_size_override("normal_font_size", UITheme.FONT_SIZE_SM)
	energy_summary.add_theme_color_override("default_color", UITheme.TEXT)
	vbox.add_child(energy_summary)


func _on_run_simulation() -> void:
	var selected = network_selector.selected
	progress_bar.value = 10

	if selected == 0:
		SIMULATION_RUN_ALL_REQUEST.emit()
	else:
		var net = networks[selected - 1]
		SIMULATION_RUN_REQUEST.emit(net)

	_set_status("[color=#4DA3FF]Simulation en cours...[/color]")


func _on_optimize() -> void:
	var selected = network_selector.selected
	if selected == 0:
		OPTIMIZATION_REQUEST.emit("all")
	else:
		OPTIMIZATION_REQUEST.emit(networks[selected - 1])
	_set_status("[color=#FFB347]Optimisation en cours...[/color]")


func _on_cable_routing() -> void:
	var selected = network_selector.selected
	if selected == 0:
		CABLE_ROUTING_REQUEST.emit("all")
	else:
		CABLE_ROUTING_REQUEST.emit(networks[selected - 1])
	_set_status("[color=#FFB347]Routage en cours...[/color]")


func _on_simulation_completed(reports: Array) -> void:
	progress_bar.value = 100
	_set_status("[color=#4CAF50]✓ Simulation terminée (%d rapports)[/color]" % reports.size())
	_refresh_results()


func _on_simulation_error(network: String, message: String) -> void:
	progress_bar.value = 100
	_set_status("[color=#FF6B6B]✗ Erreur %s : %s[/color]" % [network, message])


func _refresh_results() -> void:
	if not simulation_manager_ref:
		return

	# Erreurs / Warnings
	var all_errors = simulation_manager_ref.get_all_errors()
	var all_warnings = simulation_manager_ref.get_all_warnings()
	var text := ""

	if all_errors.size() > 0:
		text += "[color=#FF6B6B][b]Erreurs (%d)[/b][/color]\n" % all_errors.size()
		for err in all_errors:
			text += "  • %s\n" % err.get("message", "")

	if all_warnings.size() > 0:
		text += "[color=#FFB347][b]Avertissements (%d)[/b][/color]\n" % all_warnings.size()
		for warn in all_warnings:
			text += "  • %s\n" % warn.get("message", "")

	if all_errors.size() == 0 and all_warnings.size() == 0:
		text = "[color=#4CAF50]✓ Aucun problème détecté[/color]"

	error_list.text = text

	# Métriques
	_refresh_metrics()

	# Énergie
	_refresh_energy()


func _refresh_metrics() -> void:
	for child in metrics_container.get_children():
		child.queue_free()

	if not simulation_manager_ref:
		return

	for net in networks:
		var report = simulation_manager_ref.get_report(net)
		if report == null:
			continue
		var metrics = report.metrics
		if metrics.size() == 0:
			continue

		var header = _metric_header(net)
		metrics_container.add_child(header)

		for key in metrics:
			var value = metrics[key]
			if value is Dictionary or value is Array:
				continue
			var row = _metric_row(key, str(value))
			metrics_container.add_child(row)


func _refresh_energy() -> void:
	if not simulation_manager_ref:
		return

	# Utiliser EnergySimulator si disponible
	var energy_text := "[b]Bilan estimé[/b]\n"
	var total_errors := simulation_manager_ref.get_all_errors().size()
	var total_warnings := simulation_manager_ref.get_all_warnings().size()

	if total_errors == 0:
		energy_text += "[color=#4CAF50]✓ Installation conforme[/color]\n"
	else:
		energy_text += "[color=#FF6B6B]✗ %d erreur(s) à corriger[/color]\n" % total_errors

	energy_text += "Avertissements : %d\n" % total_warnings
	energy_summary.text = energy_text


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func update_results(report) -> void:
	if report:
		_refresh_results()
		progress_bar.value = 100


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


func _metric_header(network: String) -> Label:
	var idx = networks.find(network)
	var display = network_labels[idx] if idx >= 0 else network
	var lbl := Label.new()
	lbl.text = "— %s —" % display
	lbl.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	lbl.add_theme_color_override("font_color", UITheme.ACCENT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


func _metric_row(key: String, value: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	var k := Label.new()
	k.text = key.replace("_", " ").capitalize()
	k.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	k.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
	v.add_theme_color_override("font_color", UITheme.TEXT)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(v)

	return hbox
