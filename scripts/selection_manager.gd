extends Node
class_name SelectionManager

## Système de sélection 3D par raycast — HouseMaster 3D

signal OBJECT_SELECTED(object: Node3D)
signal OBJECT_DESELECTED
signal SELECTION_CHANGED(object: Node3D)

var selected_object: Node3D = null
var highlight_material: StandardMaterial3D = null
var original_materials: Dictionary = {}  # {node_id: material}

var camera: Camera3D = null
var snap_enabled: bool = true
var snap_grid_size: float = 0.25  # 25 cm


func _ready() -> void:
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(0.2, 0.6, 1.0, 0.4)
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(0.2, 0.6, 1.0)
	highlight_material.emission_energy_multiplier = 0.8


func setup(cam: Camera3D) -> void:
	camera = cam


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not Input.is_key_pressed(KEY_ALT):
			_try_select(event.position)
	
	# Toggle snapping
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		snap_enabled = not snap_enabled
		print("Snapping : %s" % ("activé" if snap_enabled else "désactivé"))


func _try_select(screen_pos: Vector2) -> void:
	if not camera:
		return
	
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 100.0
	
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider is Node3D:
			select(collider)
	else:
		deselect()


func select(object: Node3D) -> void:
	if selected_object == object:
		return
	
	deselect()
	selected_object = object
	_apply_highlight(object)
	OBJECT_SELECTED.emit(object)
	SELECTION_CHANGED.emit(object)


func deselect() -> void:
	if selected_object:
		_remove_highlight(selected_object)
		selected_object = null
		OBJECT_DESELECTED.emit()
		SELECTION_CHANGED.emit(null)


func _apply_highlight(node: Node3D) -> void:
	if node is MeshInstance3D:
		original_materials[node.get_instance_id()] = node.material_override
		# On ne remplace pas, on ajoute un outline visuel
		var outline = MeshInstance3D.new()
		outline.name = "_selection_highlight"
		outline.mesh = node.mesh
		outline.scale = Vector3(1.02, 1.02, 1.02)
		outline.material_override = highlight_material
		node.add_child(outline)


func _remove_highlight(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	var highlight = node.get_node_or_null("_selection_highlight")
	if highlight:
		highlight.queue_free()
	if node.get_instance_id() in original_materials:
		original_materials.erase(node.get_instance_id())


func snap_position(pos: Vector3) -> Vector3:
	if not snap_enabled:
		return pos
	return Vector3(
		snapped(pos.x, snap_grid_size),
		snapped(pos.y, snap_grid_size),
		snapped(pos.z, snap_grid_size)
	)


func snap_to_wall(pos: Vector3, walls: Array) -> Vector3:
	if not snap_enabled:
		return pos
	
	var closest_dist := INF
	var closest_pos := pos
	
	for wall in walls:
		if not wall is Node3D:
			continue
		var wall_start: Vector3 = wall.wall_start
		var wall_end: Vector3 = wall.wall_end
		
		var wall_dir = (wall_end - wall_start).normalized()
		var to_point = pos - wall_start
		var projection = to_point.dot(wall_dir)
		projection = clamp(projection, 0.0, wall_start.distance_to(wall_end))
		var closest_on_wall = wall_start + wall_dir * projection
		var dist = pos.distance_to(closest_on_wall)
		
		if dist < closest_dist and dist < snap_grid_size * 2:
			closest_dist = dist
			closest_pos = closest_on_wall
	
	return closest_pos
