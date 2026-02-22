extends Node3D
class_name RoomCore

## Représente une pièce de la maison

signal ROOM_UPDATED

# --- Propriétés de la pièce ---
@export var room_name: String = "Pièce"
@export var room_width: float = 3.0
@export var room_depth: float = 3.0
@export var room_height: float = 2.5
@export var room_type: String = "generic"  # living, bedroom, bathroom, wc, storage, kitchen

# --- Matériaux ---
var floor_material: StandardMaterial3D = null
var wall_material: StandardMaterial3D = null
var ceiling_material: StandardMaterial3D = null

# --- Réseaux techniques associés ---
var plumbing_points: Array[Dictionary] = []
var electricity_points: Array[Dictionary] = []
var network_points: Array[Dictionary] = []
var domotics_points: Array[Dictionary] = []

# --- Mesh interne ---
var floor_mesh: MeshInstance3D = null
var walls_container: Node3D = null

# --- Couleurs par type ---
var type_colors := {
	"living": Color(0.85, 0.75, 0.55),
	"bedroom": Color(0.55, 0.65, 0.80),
	"bathroom": Color(0.50, 0.78, 0.82),
	"wc": Color(0.65, 0.65, 0.72),
	"storage": Color(0.72, 0.65, 0.55),
	"kitchen": Color(0.82, 0.75, 0.55),
	"generic": Color(0.70, 0.70, 0.70),
}


func _ready() -> void:
	walls_container = Node3D.new()
	walls_container.name = "WallsContainer"
	add_child(walls_container)


func generate_mesh() -> void:
	if not is_inside_tree():
		await ready
	_clear_meshes()
	_generate_floor_mesh()
	_generate_room_walls()
	ROOM_UPDATED.emit()


func _clear_meshes() -> void:
	if floor_mesh and is_instance_valid(floor_mesh):
		floor_mesh.queue_free()
		floor_mesh = null
	if walls_container:
		for child in walls_container.get_children():
			child.queue_free()


func _generate_floor_mesh() -> void:
	floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(room_width, room_depth)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(room_width / 2.0, 0.01, room_depth / 2.0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = type_colors.get(room_type, Color(0.70, 0.70, 0.70))
	floor_mesh.material_override = mat

	add_child(floor_mesh)


func _generate_room_walls() -> void:
	var w := room_width
	var d := room_depth
	var h := room_height
	var t := 0.10  # murs intérieurs plus fins

	# Mur Nord (face avant)
	_create_wall_mesh(Vector3(w / 2.0, h / 2.0, 0), Vector3(w, h, t))
	# Mur Sud (face arrière)
	_create_wall_mesh(Vector3(w / 2.0, h / 2.0, d), Vector3(w, h, t))
	# Mur Ouest
	_create_wall_mesh(Vector3(0, h / 2.0, d / 2.0), Vector3(t, h, d))
	# Mur Est
	_create_wall_mesh(Vector3(w, h / 2.0, d / 2.0), Vector3(t, h, d))


func _create_wall_mesh(pos: Vector3, size: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.85, 0.80)
	mesh_instance.material_override = mat

	walls_container.add_child(mesh_instance)


func get_surface() -> float:
	return room_width * room_depth


func resize(new_width: float, new_depth: float) -> void:
	room_width = new_width
	room_depth = new_depth
	generate_mesh()


func set_type(new_type: String) -> void:
	room_type = new_type
	generate_mesh()


func add_plumbing_point(point: Dictionary) -> void:
	plumbing_points.append(point)


func add_electricity_point(point: Dictionary) -> void:
	electricity_points.append(point)


func add_network_point(point: Dictionary) -> void:
	network_points.append(point)


func add_domotics_point(point: Dictionary) -> void:
	domotics_points.append(point)


func to_dict() -> Dictionary:
	return {
		"name": room_name,
		"width": room_width,
		"depth": room_depth,
		"height": room_height,
		"type": room_type,
		"pos_x": position.x,
		"pos_z": position.z,
		"plumbing": plumbing_points,
		"electricity": electricity_points,
		"network": network_points,
		"domotics": domotics_points,
	}


func from_dict(data: Dictionary) -> void:
	room_name = data.get("name", "Pièce")
	room_width = data.get("width", 3.0)
	room_depth = data.get("depth", 3.0)
	room_height = data.get("height", 2.5)
	room_type = data.get("type", "generic")
	position = Vector3(data.get("pos_x", 0.0), 0.0, data.get("pos_z", 0.0))
	plumbing_points = data.get("plumbing", [])
	electricity_points = data.get("electricity", [])
	network_points = data.get("network", [])
	domotics_points = data.get("domotics", [])
	generate_mesh()
