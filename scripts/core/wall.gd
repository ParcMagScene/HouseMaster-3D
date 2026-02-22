extends Node3D
class_name WallCore

## Représente un mur (intérieur ou extérieur)

signal WALL_UPDATED

# --- Propriétés géométriques ---
@export var wall_start: Vector3 = Vector3.ZERO
@export var wall_end: Vector3 = Vector3(1, 0, 0)
@export var wall_height: float = 2.50
@export var wall_thickness: float = 0.20

# --- Matériau ---
var wall_material: StandardMaterial3D = null

# --- Ouvertures (portes, fenêtres) ---
var openings: Array[Dictionary] = []
# Format : {"type": "door"/"window", "position": float (0-1 le long du mur), "width": float, "height": float, "elevation": float}

# --- Mesh ---
var mesh_instance: MeshInstance3D = null


func _ready() -> void:
	pass


func generate_mesh() -> void:
	_clear_mesh()
	
	var direction = wall_end - wall_start
	var wall_length = Vector2(direction.x, direction.z).length()
	var angle = atan2(direction.x, direction.z)
	
	# Position centrale du mur
	var center = (wall_start + wall_end) / 2.0
	center.y = wall_height / 2.0
	
	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(wall_length, wall_height, wall_thickness)
	mesh_instance.mesh = box
	mesh_instance.position = center
	mesh_instance.rotation.y = angle
	
	# Matériau
	var mat = wall_material
	if not mat:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.92, 0.90, 0.85)
	mesh_instance.material_override = mat
	
	add_child(mesh_instance)
	
	# Générer les ouvertures
	for opening in openings:
		_create_opening(opening, wall_length, angle)
	
	WALL_UPDATED.emit()


func _clear_mesh() -> void:
	if is_instance_valid(mesh_instance):
		mesh_instance.queue_free()
		mesh_instance = null
	for child in get_children():
		if child is MeshInstance3D and is_instance_valid(child):
			child.queue_free()


func _create_opening(opening: Dictionary, wall_length: float, angle: float) -> void:
	var opening_type = opening.get("type", "door")
	var pos_ratio = opening.get("position", 0.5)
	var opening_width = opening.get("width", 0.9)
	var opening_height = opening.get("height", 2.1 if opening_type == "door" else 1.2)
	var elevation = opening.get("elevation", 0.0 if opening_type == "door" else 1.0)
	
	# CSG soustractif pour l'ouverture (simplifié avec un mesh visible)
	var opening_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(opening_width, opening_height, wall_thickness + 0.02)
	opening_mesh.mesh = box
	
	var offset_along = (pos_ratio - 0.5) * wall_length
	var center = (wall_start + wall_end) / 2.0
	center.y = elevation + opening_height / 2.0
	
	opening_mesh.position = center
	opening_mesh.position.x += offset_along * sin(angle + PI / 2)
	opening_mesh.position.z += offset_along * cos(angle + PI / 2)
	opening_mesh.rotation.y = angle
	
	var mat = StandardMaterial3D.new()
	if opening_type == "door":
		mat.albedo_color = Color(0.55, 0.35, 0.2)
	else:
		mat.albedo_color = Color(0.7, 0.85, 0.95, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	opening_mesh.material_override = mat
	
	add_child(opening_mesh)


func add_opening(type: String, pos: float, width: float, height: float, elevation: float = 0.0) -> void:
	openings.append({
		"type": type,
		"position": pos,
		"width": width,
		"height": height,
		"elevation": elevation
	})
	generate_mesh()


func remove_opening(index: int) -> void:
	if index >= 0 and index < openings.size():
		openings.remove_at(index)
		generate_mesh()


func get_length() -> float:
	return Vector2(wall_end.x - wall_start.x, wall_end.z - wall_start.z).length()


func to_dict() -> Dictionary:
	return {
		"start": {"x": wall_start.x, "y": wall_start.y, "z": wall_start.z},
		"end": {"x": wall_end.x, "y": wall_end.y, "z": wall_end.z},
		"height": wall_height,
		"thickness": wall_thickness,
		"openings": openings,
	}


func from_dict(data: Dictionary) -> void:
	var s = data.get("start", {})
	wall_start = Vector3(s.get("x", 0), s.get("y", 0), s.get("z", 0))
	var e = data.get("end", {})
	wall_end = Vector3(e.get("x", 1), e.get("y", 0), e.get("z", 0))
	wall_height = data.get("height", 2.5)
	wall_thickness = data.get("thickness", 0.2)
	openings = data.get("openings", [])
	generate_mesh()
