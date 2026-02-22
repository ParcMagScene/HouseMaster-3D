extends Node3D

## Point d'entrée principal — HouseMaster 3D
## Orchestre tous les modules, l'UI, la caméra, les systèmes

# --- Preloads scènes ---
var house_scene := preload("res://scenes/House.tscn")
var plumbing_scene := preload("res://scenes/Plumbing/PlumbingModule.tscn")
var electricity_scene := preload("res://scenes/Electricity/ElectricityModule.tscn")
var network_scene := preload("res://scenes/Network/NetworkModule.tscn")
var domotics_scene := preload("res://scenes/Domotics/DomoticsModule.tscn")

# --- Preloads scripts ---
const CameraControllerScript = preload("res://scripts/camera_controller.gd")
const SelectionManagerScript = preload("res://scripts/selection_manager.gd")
const UndoRedoManagerScript = preload("res://scripts/undo_redo_manager.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")
const MainUIScript = preload("res://scripts/ui/main_ui.gd")
const RoomEditorScript = preload("res://scripts/ui/room_editor.gd")
const PlumbingEditorScript = preload("res://scripts/ui/plumbing_editor.gd")
const ElectricityEditorScript = preload("res://scripts/ui/electricity_editor.gd")
const NetworkEditorScript = preload("res://scripts/ui/network_editor.gd")
const DomoticsEditorScript = preload("res://scripts/ui/domotics_editor.gd")
const UIAnimationsScript = preload("res://scripts/ui/ui_animations.gd")

# --- Nœuds principaux ---
var house: Node3D = null
var plumbing: Node3D = null
var electricity: Node3D = null
var network: Node3D = null
var domotics: Node3D = null

# --- Systèmes ---
var camera: Camera3D = null
var selection_manager: Node = null
var undo_redo: Node = null
var save_manager: Node = null

# --- UI ---
var main_ui: Control = null
var room_editor: Control = null
var plumbing_editor: Control = null
var electricity_editor: Control = null
var network_editor: Control = null
var domotics_editor: Control = null

# --- Éclairage ---
var sun: DirectionalLight3D = null
var environment: WorldEnvironment = null


func _ready() -> void:
	print("═══════════════════════════════════════")
	print("  HouseMaster 3D — Projet Alexandre")
	print("  Maison 70 m² | Godot 4")
	print("═══════════════════════════════════════")
	
	_setup_environment()
	_setup_lighting()
	_setup_camera()
	_setup_house()
	_setup_modules()
	_setup_systems()
	_setup_ui()
	_connect_signals()
	_setup_grid()
	
	print("✅ Initialisation terminée.")


func _setup_environment() -> void:
	environment = WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.75, 0.8, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = 3  # ACES
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.3
	environment.environment = env
	add_child(environment)


func _setup_lighting() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 50.0
	add_child(sun)


func _setup_camera() -> void:
	camera = CameraControllerScript.new()
	camera.name = "Camera"
	camera.orbit_target = Vector3(5.25, 0.0, 3.35)  # Centre maison
	camera.orbit_distance = 18.0
	add_child(camera)


func _setup_house() -> void:
	house = house_scene.instantiate()
	house.name = "House"
	add_child(house)
	print("🏠 Maison générée (%.1f × %.1f m)" % [house.exterior_width, house.exterior_depth])


func _setup_modules() -> void:
	# Plomberie
	plumbing = plumbing_scene.instantiate()
	plumbing.name = "PlumbingModule"
	house.add_child(plumbing)
	
	# Électricité
	electricity = electricity_scene.instantiate()
	electricity.name = "ElectricityModule"
	house.add_child(electricity)
	
	# Réseau
	network = network_scene.instantiate()
	network.name = "NetworkModule"
	house.add_child(network)
	
	# Domotique
	domotics = domotics_scene.instantiate()
	domotics.name = "DomoticsModule"
	house.add_child(domotics)
	
	print("🔧 Modules techniques chargés")


func _setup_systems() -> void:
	# Sélection
	selection_manager = SelectionManagerScript.new()
	selection_manager.name = "SelectionManager"
	selection_manager.setup(camera)
	add_child(selection_manager)
	
	# Undo/Redo
	undo_redo = UndoRedoManagerScript.new()
	undo_redo.name = "UndoRedoManager"
	add_child(undo_redo)
	
	# Sauvegarde
	save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	save_manager.setup(house, plumbing, electricity, network, domotics)
	add_child(save_manager)
	
	print("⚙️ Systèmes initialisés")


func _setup_ui() -> void:
	# Canvas Layer pour l'UI
	var canvas = CanvasLayer.new()
	canvas.name = "UILayer"
	add_child(canvas)
	
	# UI principale
	main_ui = MainUIScript.new()
	main_ui.name = "MainUI"
	main_ui.setup(house)
	canvas.add_child(main_ui)
	
	# Position des éditeurs : panneau flottant centré-droit
	var editor_pos := Vector2(260, 70)
	
	# Éditeur pièces (caché par défaut)
	room_editor = RoomEditorScript.new()
	room_editor.name = "RoomEditor"
	room_editor.setup(house)
	room_editor.visible = false
	room_editor.position = editor_pos
	canvas.add_child(room_editor)
	
	# Éditeur plomberie (caché par défaut)
	plumbing_editor = PlumbingEditorScript.new()
	plumbing_editor.name = "PlumbingEditor"
	plumbing_editor.setup(plumbing)
	plumbing_editor.visible = false
	plumbing_editor.position = editor_pos
	canvas.add_child(plumbing_editor)
	
	# Éditeur électricité (caché par défaut)
	electricity_editor = ElectricityEditorScript.new()
	electricity_editor.name = "ElectricityEditor"
	electricity_editor.setup(electricity)
	electricity_editor.visible = false
	electricity_editor.position = editor_pos
	canvas.add_child(electricity_editor)
	
	# Éditeur réseau (caché par défaut)
	network_editor = NetworkEditorScript.new()
	network_editor.name = "NetworkEditor"
	network_editor.setup(network)
	network_editor.visible = false
	network_editor.position = editor_pos
	canvas.add_child(network_editor)
	
	# Éditeur domotique (caché par défaut)
	domotics_editor = DomoticsEditorScript.new()
	domotics_editor.name = "DomoticsEditor"
	domotics_editor.setup(domotics)
	domotics_editor.visible = false
	domotics_editor.position = editor_pos
	canvas.add_child(domotics_editor)
	
	print("🖥️ Interface utilisateur prête")


func _connect_signals() -> void:
	# UI -> Système
	main_ui.SAVE_REQUESTED.connect(_on_save_requested)
	main_ui.LOAD_REQUESTED.connect(_on_load_requested)
	main_ui.EXPORT_2D_REQUESTED.connect(_on_export_2d)
	main_ui.EXPORT_3D_REQUESTED.connect(_on_export_3d)
	main_ui.LAYER_TOGGLED.connect(_on_layer_toggled)
	main_ui.MODE_CHANGED.connect(_on_mode_changed)
	main_ui.ROOM_SELECTED.connect(_on_room_selected)
	
	# Sélection -> UI
	selection_manager.OBJECT_SELECTED.connect(_on_object_selected)
	selection_manager.OBJECT_DESELECTED.connect(_on_object_deselected)
	
	# House -> UI
	house.HOUSE_UPDATED.connect(func(): main_ui._refresh_hierarchy())
	
	# Save -> UI
	save_manager.SAVE_COMPLETED.connect(func(path): main_ui.add_log("[color=green]Sauvegardé : %s[/color]" % path))
	save_manager.LOAD_COMPLETED.connect(func(path): main_ui.add_log("[color=green]Chargé : %s[/color]" % path))
	save_manager.SAVE_ERROR.connect(func(msg): main_ui.add_log("[color=red]Erreur : %s[/color]" % msg))


func _setup_grid() -> void:
	# Grille de référence au sol
	var grid = MeshInstance3D.new()
	grid.name = "Grid"
	var plane = PlaneMesh.new()
	plane.size = Vector2(30, 30)
	plane.subdivide_width = 60
	plane.subdivide_depth = 60
	grid.mesh = plane
	grid.position = Vector3(5.25, -0.01, 3.35)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grid.material_override = mat
	
	add_child(grid)


func _input(event: InputEvent) -> void:
	# Ctrl+S : Sauvegarder
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_S:
		_on_save_requested()
		get_viewport().set_input_as_handled()
	
	# Ctrl+O : Charger
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_O:
		_on_load_requested()
		get_viewport().set_input_as_handled()
	
	# F1-F4 : Ouvrir éditeurs modules
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_toggle_editor(plumbing_editor)
			KEY_F2:
				_toggle_editor(electricity_editor)
			KEY_F3:
				_toggle_editor(network_editor)
			KEY_F4:
				_toggle_editor(domotics_editor)


# --- Callbacks ---

func _on_save_requested() -> void:
	save_manager.save_project()


func _on_load_requested() -> void:
	save_manager.load_project()


func _on_export_2d() -> void:
	save_manager.export_2d_plan("user://plan_2d.png")


func _on_export_3d() -> void:
	save_manager.export_3d_capture("user://capture_3d.png")


func _on_layer_toggled(layer_name: String, is_visible: bool) -> void:
	match layer_name:
		"plomberie":
			plumbing.set_layer_visible(is_visible)
		"électricité":
			electricity.set_layer_visible(is_visible)
		"réseau":
			network.set_layer_visible(is_visible)
		"domotique":
			domotics.set_layer_visible(is_visible)
		"structure":
			house.visible = is_visible
	main_ui.add_log("Layer '%s' : %s" % [layer_name, "visible" if is_visible else "masqué"])


func _on_mode_changed(mode: String) -> void:
	match mode:
		"orbit":
			camera.set_mode(CameraControllerScript.CameraMode.ORBIT)
		"free_fly":
			camera.set_mode(CameraControllerScript.CameraMode.FREE_FLY)
		"top_2d":
			camera.set_mode(CameraControllerScript.CameraMode.TOP_2D)
		"cycle":
			camera.cycle_mode()
	main_ui.update_status("Mode : %s" % mode)


func _on_room_selected(room_name: String) -> void:
	var room = house.get_room_by_name(room_name)
	if room:
		selection_manager.select(room)
		room_editor.edit_room(room)
		if not room_editor.visible:
			UIAnimationsScript.slide_in_right(room_editor, 200, 0.2)
		camera.focus_on_target(room.global_position + Vector3(room.room_width / 2, 0, room.room_depth / 2))


func _on_object_selected(object: Node3D) -> void:
	main_ui.update_properties(object)
	main_ui.add_log("Sélection : %s" % object.name)


func _on_object_deselected() -> void:
	main_ui.update_properties(null)
	room_editor.visible = false


func _toggle_editor(editor: Control) -> void:
	var editors := [plumbing_editor, electricity_editor, network_editor, domotics_editor, room_editor]
	var should_show := not editor.visible
	
	# Masquer tous les éditeurs avec animation
	for e in editors:
		if e != editor and e.visible:
			UIAnimationsScript.fade_out(e, 0.15)
	
	# Afficher/masquer celui demandé avec animation
	if should_show:
		UIAnimationsScript.slide_in_right(editor, 200, 0.2)
	else:
		UIAnimationsScript.fade_out(editor, 0.15)
