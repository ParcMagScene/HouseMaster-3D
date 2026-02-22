extends Camera3D
class_name CameraController

## Caméra orbitale + free-fly — HouseMaster 3D
## - Clic droit + souris : rotation orbitale
## - Molette : zoom
## - Clic milieu + souris : panoramique
## - F : centrer sur sélection
## - Espace : basculer orbite / free-fly

signal CAMERA_MODE_CHANGED(mode: String)

enum CameraMode { ORBIT, FREE_FLY, TOP_2D }

@export var orbit_sensitivity: float = 0.005
@export var pan_sensitivity: float = 0.01
@export var zoom_speed: float = 1.0
@export var fly_speed: float = 5.0
@export var min_distance: float = 1.0
@export var max_distance: float = 50.0

var mode: CameraMode = CameraMode.ORBIT
var orbit_target: Vector3 = Vector3(5.25, 0, 3.35)  # centre de la maison
var orbit_distance: float = 15.0
var orbit_rotation: Vector2 = Vector2(0.6, 0.8)  # pitch, yaw (vue 3/4 dessus)

var is_panning: bool = false
var is_rotating: bool = false


func _ready() -> void:
	current = true
	_update_orbit()


func _input(event: InputEvent) -> void:
	match mode:
		CameraMode.ORBIT:
			_handle_orbit_input(event)
		CameraMode.FREE_FLY:
			_handle_freefly_input(event)
		CameraMode.TOP_2D:
			_handle_2d_input(event)
	
	# Basculer de mode avec Espace
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		cycle_mode()
	
	# F : centrer sur cible
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		focus_on_target(orbit_target)


func _process(delta: float) -> void:
	if mode == CameraMode.FREE_FLY:
		_process_freefly(delta)


func _handle_orbit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				is_rotating = event.pressed
			MOUSE_BUTTON_MIDDLE:
				is_panning = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				orbit_distance = max(min_distance, orbit_distance - zoom_speed)
				_update_orbit()
			MOUSE_BUTTON_WHEEL_DOWN:
				orbit_distance = min(max_distance, orbit_distance + zoom_speed)
				_update_orbit()
	
	if event is InputEventMouseMotion:
		if is_rotating:
			orbit_rotation.y -= event.relative.x * orbit_sensitivity
			orbit_rotation.x -= event.relative.y * orbit_sensitivity
			orbit_rotation.x = clamp(orbit_rotation.x, -PI / 2.2, PI / 2.2)
			_update_orbit()
		elif is_panning:
			var right = global_transform.basis.x
			var up_dir = global_transform.basis.y
			orbit_target -= right * event.relative.x * pan_sensitivity
			orbit_target += up_dir * event.relative.y * pan_sensitivity
			_update_orbit()


func _handle_freefly_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
	
	if event is InputEventMouseMotion and is_rotating:
		rotate_y(-event.relative.x * orbit_sensitivity)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * orbit_sensitivity)


func _handle_2d_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				is_panning = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				orbit_distance = max(min_distance, orbit_distance - zoom_speed)
				_update_2d_view()
			MOUSE_BUTTON_WHEEL_DOWN:
				orbit_distance = min(max_distance, orbit_distance + zoom_speed)
				_update_2d_view()
	
	if event is InputEventMouseMotion and is_panning:
		orbit_target.x -= event.relative.x * pan_sensitivity
		orbit_target.z -= event.relative.y * pan_sensitivity
		_update_2d_view()


func _process_freefly(delta: float) -> void:
	var velocity = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		velocity -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		velocity += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		velocity -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		velocity += global_transform.basis.x
	if Input.is_key_pressed(KEY_Q):
		velocity += Vector3.UP
	if Input.is_key_pressed(KEY_E):
		velocity -= Vector3.UP
	
	var speed = fly_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= 2.0
	
	global_position += velocity.normalized() * speed * delta


func _update_orbit() -> void:
	var offset = Vector3(
		orbit_distance * cos(orbit_rotation.x) * sin(orbit_rotation.y),
		orbit_distance * sin(orbit_rotation.x),
		orbit_distance * cos(orbit_rotation.x) * cos(orbit_rotation.y)
	)
	global_position = orbit_target + offset
	look_at(orbit_target, Vector3.UP)


func _update_2d_view() -> void:
	global_position = Vector3(orbit_target.x, orbit_distance, orbit_target.z)
	rotation = Vector3(-PI / 2, 0, 0)
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = orbit_distance


func cycle_mode() -> void:
	match mode:
		CameraMode.ORBIT:
			mode = CameraMode.FREE_FLY
			CAMERA_MODE_CHANGED.emit("free_fly")
		CameraMode.FREE_FLY:
			mode = CameraMode.TOP_2D
			projection = Camera3D.PROJECTION_ORTHOGONAL
			_update_2d_view()
			CAMERA_MODE_CHANGED.emit("top_2d")
		CameraMode.TOP_2D:
			mode = CameraMode.ORBIT
			projection = Camera3D.PROJECTION_PERSPECTIVE
			_update_orbit()
			CAMERA_MODE_CHANGED.emit("orbit")


func set_mode(new_mode: CameraMode) -> void:
	mode = new_mode
	match mode:
		CameraMode.ORBIT:
			projection = Camera3D.PROJECTION_PERSPECTIVE
			_update_orbit()
		CameraMode.TOP_2D:
			projection = Camera3D.PROJECTION_ORTHOGONAL
			_update_2d_view()
		CameraMode.FREE_FLY:
			projection = Camera3D.PROJECTION_PERSPECTIVE


func focus_on_target(target: Vector3) -> void:
	orbit_target = target
	match mode:
		CameraMode.ORBIT:
			_update_orbit()
		CameraMode.TOP_2D:
			_update_2d_view()
		CameraMode.FREE_FLY:
			look_at(target, Vector3.UP)
