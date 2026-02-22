@tool
extends EditorPlugin

## HouseMaster 3D — Quality Tools
## Plugin éditeur pour l'analyse statique, les conventions de code
## et la validation de l'architecture du projet.

const PLUGIN_NAME := "HouseMaster Quality"

var _dock: Control
var _output: RichTextLabel


func _enter_tree() -> void:
	_dock = _build_dock()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
	print("[%s] Plugin chargé." % PLUGIN_NAME)


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _build_dock() -> Control:
	var panel := VBoxContainer.new()
	panel.name = "QualityTools"

	var title := Label.new()
	title.text = "HouseMaster Quality"
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	var sep := HSeparator.new()
	panel.add_child(sep)

	var btn_lint := Button.new()
	btn_lint.text = "Analyse statique (lint)"
	btn_lint.pressed.connect(_run_lint)
	panel.add_child(btn_lint)

	var btn_arch := Button.new()
	btn_arch.text = "Vérifier architecture"
	btn_arch.pressed.connect(_run_architecture_check)
	panel.add_child(btn_arch)

	var btn_signals := Button.new()
	btn_signals.text = "Vérifier signaux modernes"
	btn_signals.pressed.connect(_run_signal_check)
	panel.add_child(btn_signals)

	var btn_null := Button.new()
	btn_null.text = "Vérifier null-safety"
	btn_null.pressed.connect(_run_null_safety_check)
	panel.add_child(btn_null)

	var btn_naming := Button.new()
	btn_naming.text = "Vérifier conventions nommage"
	btn_naming.pressed.connect(_run_naming_check)
	panel.add_child(btn_naming)

	var btn_all := Button.new()
	btn_all.text = "▶ Tout vérifier"
	btn_all.pressed.connect(_run_all_checks)
	panel.add_child(btn_all)

	var sep2 := HSeparator.new()
	panel.add_child(sep2)

	_output = RichTextLabel.new()
	_output.custom_minimum_size = Vector2(300, 400)
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.fit_content = false
	panel.add_child(_output)

	return panel


# ── Checks ──────────────────────────────────────────────

func _run_all_checks() -> void:
	_clear_output()
	_log_header("Analyse complète")
	_run_lint()
	_run_architecture_check()
	_run_signal_check()
	_run_null_safety_check()
	_run_naming_check()
	_log_footer()


func _run_lint() -> void:
	_log_section("LINT — Analyse statique")
	var scripts := _collect_scripts("res://scripts/")
	var warnings := 0
	for path in scripts:
		var content := _read_text(path)
		if content.is_empty():
			continue
		var lines := content.split("\n")
		for i in range(lines.size()):
			var line: String = lines[i]
			# Lignes trop longues
			if line.length() > 120:
				_log_warn("%s:%d — Ligne > 120 caractères (%d)" % [path.get_file(), i + 1, line.length()])
				warnings += 1
			# Tabs vs spaces
			if line.begins_with("\t") and line.contains("  \t"):
				_log_warn("%s:%d — Mélange tabs/espaces" % [path.get_file(), i + 1])
				warnings += 1
			# Trailing whitespace
			if line.ends_with(" ") or line.ends_with("\t"):
				_log_warn("%s:%d — Espace en fin de ligne" % [path.get_file(), i + 1])
				warnings += 1
			# print() restant (hors tests)
			if not "test" in path.to_lower() and line.strip_edges().begins_with("print("):
				_log_warn("%s:%d — print() trouvé (utiliser un logger)" % [path.get_file(), i + 1])
				warnings += 1
	if warnings == 0:
		_log_ok("Aucun avertissement lint.")
	else:
		_log_info("%d avertissement(s) lint." % warnings)


func _run_architecture_check() -> void:
	_log_section("ARCHITECTURE — Vérification structure")
	var issues := 0
	# Dossiers attendus
	var expected_dirs := ["res://scripts/core/", "res://scripts/modules/", "res://scripts/ui/", "res://scenes/", "res://materials/"]
	for d in expected_dirs:
		if DirAccess.dir_exists_absolute(d):
			_log_ok("Dossier trouvé : %s" % d)
		else:
			_log_error("Dossier manquant : %s" % d)
			issues += 1
	# Fichiers core attendus
	var core_files := ["house.gd", "room.gd", "wall.gd", "material.gd"]
	for f in core_files:
		if FileAccess.file_exists("res://scripts/core/%s" % f):
			_log_ok("Core : %s" % f)
		else:
			_log_error("Core manquant : %s" % f)
			issues += 1
	# Fichiers modules attendus
	var mod_files := ["plumbing_module.gd", "electricity_module.gd", "network_module.gd", "domotics_module.gd"]
	for f in mod_files:
		if FileAccess.file_exists("res://scripts/modules/%s" % f):
			_log_ok("Module : %s" % f)
		else:
			_log_error("Module manquant : %s" % f)
			issues += 1
	if issues == 0:
		_log_ok("Architecture conforme.")


func _run_signal_check() -> void:
	_log_section("SIGNAUX — Vérification syntaxe moderne")
	var scripts := _collect_scripts("res://scripts/")
	var old_count := 0
	for path in scripts:
		var content := _read_text(path)
		var lines := content.split("\n")
		for i in range(lines.size()):
			if lines[i].contains("emit_signal("):
				_log_error("%s:%d — emit_signal() obsolète (utiliser SIGNAL.emit())" % [path.get_file(), i + 1])
				old_count += 1
	if old_count == 0:
		_log_ok("Tous les signaux utilisent la syntaxe moderne .emit().")
	else:
		_log_error("%d appel(s) emit_signal() à moderniser." % old_count)


func _run_null_safety_check() -> void:
	_log_section("NULL-SAFETY — Vérification gardes null")
	var scripts := _collect_scripts("res://scripts/")
	var warnings := 0
	var risky_patterns := [".get_children()", ".get_child(", ".get_child_count()"]
	for path in scripts:
		var content := _read_text(path)
		var lines := content.split("\n")
		for i in range(lines.size()):
			var line: String = lines[i].strip_edges()
			if line.begins_with("#"):
				continue
			for pat in risky_patterns:
				if pat in line:
					# Vérifier s'il y a un guard dans les 3 lignes précédentes
					var guarded := false
					for j in range(max(0, i - 3), i):
						if "if " in lines[j] and ("null" in lines[j] or "is_instance_valid" in lines[j]):
							guarded = true
							break
					if not guarded and not "if " in line:
						_log_warn("%s:%d — %s sans garde null visible" % [path.get_file(), i + 1, pat])
						warnings += 1
	if warnings == 0:
		_log_ok("Accès enfants correctement gardés.")
	else:
		_log_info("%d accès enfant(s) potentiellement non gardés." % warnings)


func _run_naming_check() -> void:
	_log_section("NOMMAGE — Conventions GDScript")
	var scripts := _collect_scripts("res://scripts/")
	var issues := 0
	for path in scripts:
		var content := _read_text(path)
		var lines := content.split("\n")
		for i in range(lines.size()):
			var line: String = lines[i]
			# Signaux en SCREAMING_SNAKE_CASE
			if line.strip_edges().begins_with("signal "):
				var sig_name := line.strip_edges().replace("signal ", "").split("(")[0].strip_edges()
				if sig_name != sig_name.to_upper():
					_log_warn("%s:%d — Signal '%s' devrait être SCREAMING_SNAKE_CASE" % [path.get_file(), i + 1, sig_name])
					issues += 1
			# Constantes en SCREAMING_SNAKE_CASE
			if line.strip_edges().begins_with("const "):
				var parts := line.strip_edges().split("=")[0].replace("const ", "").split(":")[0].strip_edges()
				if parts != parts.to_upper() and not parts.begins_with("_"):
					# Autorise les preloads (PascalCase acceptable pour types)
					if not "preload(" in line and not "load(" in line:
						_log_warn("%s:%d — Constante '%s' devrait être SCREAMING_SNAKE_CASE" % [path.get_file(), i + 1, parts])
						issues += 1
	if issues == 0:
		_log_ok("Conventions de nommage respectées.")
	else:
		_log_info("%d écart(s) de convention." % issues)


# ── Utilitaires ─────────────────────────────────────────

func _collect_scripts(root: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(root)
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full := root + file_name
		if dir.current_is_dir():
			result.append_array(_collect_scripts(full + "/"))
		elif file_name.ends_with(".gd"):
			result.append(full)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var content := f.get_as_text()
	f.close()
	return content


func _clear_output() -> void:
	if _output:
		_output.clear()


func _log_header(title: String) -> void:
	_output.append_text("\n[b]══════ %s ══════[/b]\n" % title)


func _log_footer() -> void:
	_output.append_text("\n[b]══════ Fin de l'analyse ══════[/b]\n")


func _log_section(title: String) -> void:
	_output.append_text("\n[b]── %s ──[/b]\n" % title)


func _log_ok(msg: String) -> void:
	_output.append_text("[color=green]✅ %s[/color]\n" % msg)


func _log_warn(msg: String) -> void:
	_output.append_text("[color=yellow]⚠️ %s[/color]\n" % msg)


func _log_error(msg: String) -> void:
	_output.append_text("[color=red]❌ %s[/color]\n" % msg)


func _log_info(msg: String) -> void:
	_output.append_text("[color=cyan]ℹ️ %s[/color]\n" % msg)
