extends Node3D
class_name HouseCore

## Représente la maison complète — Projet Alexandre (70 m²)
## Dimensions extérieures : 10.50 × 6.70 m

signal HOUSE_UPDATED
signal ROOM_ADDED(room: Node3D)
signal ROOM_REMOVED(room: Node3D)
signal WALL_ADDED(wall: Node3D)
signal WALL_REMOVED(wall: Node3D)

# --- Dimensions extérieures ---
@export var exterior_width: float = 10.50
@export var exterior_depth: float = 6.70
@export var wall_height: float = 2.50
@export var wall_thickness: float = 0.20

# --- Données internes ---
var rooms: Array[Node3D] = []
var walls: Array[Node3D] = []
var openings: Array[Dictionary] = []  # portes, fenêtres

# --- Matériaux ---
var exterior_material: StandardMaterial3D = null
var roof_material: StandardMaterial3D = null

# --- Scène templates ---
var room_scene: PackedScene = preload("res://scenes/Room.tscn")
var wall_scene: PackedScene = preload("res://scenes/Wall.tscn")

# --- Pièces par défaut du projet Alexandre ---
var default_rooms := [
	{"name": "Séjour + Cuisine", "width": 5.50, "depth": 6.70, "type": "living", "pos_x": 0.0, "pos_z": 0.0},
	{"name": "Chambre 1", "width": 3.00, "depth": 4.00, "type": "bedroom", "pos_x": 5.50, "pos_z": 0.0},
	{"name": "Chambre 2", "width": 2.75, "depth": 4.00, "type": "bedroom", "pos_x": 5.50, "pos_z": 4.00},
	{"name": "Salle de bain", "width": 2.00, "depth": 3.00, "type": "bathroom", "pos_x": 8.50, "pos_z": 0.0},
	{"name": "WC", "width": 1.00, "depth": 2.00, "type": "wc", "pos_x": 8.50, "pos_z": 3.00},
	{"name": "Cellier", "width": 1.50, "depth": 2.00, "type": "storage", "pos_x": 8.50, "pos_z": 5.00},
]


func _ready() -> void:
	_generate_default_house()


func _generate_default_house() -> void:
	for room_data in default_rooms:
		add_room(room_data)
	_generate_exterior_walls()
	_generate_floor()
	HOUSE_UPDATED.emit()


func add_room(data: Dictionary) -> Node3D:
	var room_instance = room_scene.instantiate()
	add_child(room_instance)
	room_instance.room_name = data.get("name", "Pièce")
	room_instance.room_width = data.get("width", 3.0)
	room_instance.room_depth = data.get("depth", 3.0)
	room_instance.room_type = data.get("type", "generic")
	room_instance.position = Vector3(data.get("pos_x", 0.0), 0.0, data.get("pos_z", 0.0))
	room_instance.generate_mesh()
	rooms.append(room_instance)
	ROOM_ADDED.emit(room_instance)
	return room_instance


func remove_room(room: Node3D) -> void:
	if room and room in rooms:
		rooms.erase(room)
		room.queue_free()
		ROOM_REMOVED.emit(room)
		HOUSE_UPDATED.emit()


func add_wall(start_pos: Vector3, end_pos: Vector3, height: float = 2.5, thickness: float = 0.2) -> Node3D:
	var wall_instance = wall_scene.instantiate()
	add_child(wall_instance)
	wall_instance.wall_start = start_pos
	wall_instance.wall_end = end_pos
	wall_instance.wall_height = height
	wall_instance.wall_thickness = thickness
	wall_instance.generate_mesh()
	walls.append(wall_instance)
	WALL_ADDED.emit(wall_instance)
	return wall_instance


func remove_wall(wall: Node3D) -> void:
	if wall and wall in walls:
		walls.erase(wall)
		wall.queue_free()
		WALL_REMOVED.emit(wall)
		HOUSE_UPDATED.emit()


func _generate_exterior_walls() -> void:
	var w := exterior_width
	var d := exterior_depth
	var h := wall_height
	var t := wall_thickness
	# Mur Nord
	add_wall(Vector3(0, 0, 0), Vector3(w, 0, 0), h, t)
	# Mur Sud
	add_wall(Vector3(0, 0, d), Vector3(w, 0, d), h, t)
	# Mur Ouest
	add_wall(Vector3(0, 0, 0), Vector3(0, 0, d), h, t)
	# Mur Est
	add_wall(Vector3(w, 0, 0), Vector3(w, 0, d), h, t)


func _generate_floor() -> void:
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(exterior_width, exterior_depth)
	mesh_instance.mesh = plane_mesh
	mesh_instance.position = Vector3(exterior_width / 2.0, 0.0, exterior_depth / 2.0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.70, 0.62)
	mesh_instance.material_override = mat
	add_child(mesh_instance)


func get_total_surface() -> float:
	return exterior_width * exterior_depth


func get_room_by_name(target_name: String) -> Node3D:
	for room in rooms:
		if room.room_name == target_name:
			return room
	return null


func to_dict() -> Dictionary:
	var data := {
		"exterior_width": exterior_width,
		"exterior_depth": exterior_depth,
		"wall_height": wall_height,
		"wall_thickness": wall_thickness,
		"rooms": [],
		"walls": [],
		"openings": openings
	}
	for room in rooms:
		data["rooms"].append(room.to_dict())
	for wall in walls:
		data["walls"].append(wall.to_dict())
	return data


func from_dict(data: Dictionary) -> void:
	for room in rooms:
		if is_instance_valid(room):
			room.queue_free()
	rooms.clear()
	for wall in walls:
		if is_instance_valid(wall):
			wall.queue_free()
	walls.clear()
	
	exterior_width = data.get("exterior_width", 10.50)
	exterior_depth = data.get("exterior_depth", 6.70)
	wall_height = data.get("wall_height", 2.50)
	wall_thickness = data.get("wall_thickness", 0.20)
	openings = data.get("openings", [])
	
	for room_data in data.get("rooms", []):
		add_room(room_data)
	_generate_exterior_walls()
	_generate_floor()
	HOUSE_UPDATED.emit()
