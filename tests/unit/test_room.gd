extends "res://tests/test_base.gd"

## Tests unitaires — RoomCore

const RoomScript = preload("res://scripts/core/room.gd")


func test_room_default_values() -> void:
	var room = RoomScript.new()
	assert_equal(room.room_name, "Pièce", "nom par défaut")
	assert_equal(room.room_width, 3.0, "largeur par défaut = 3.0")
	assert_equal(room.room_depth, 3.0, "profondeur par défaut = 3.0")
	assert_equal(room.room_height, 2.5, "hauteur par défaut = 2.5")
	assert_equal(room.room_type, "generic", "type par défaut = generic")
	room.free()


func test_room_surface() -> void:
	var room = RoomScript.new()
	room.room_width = 5.50
	room.room_depth = 6.70
	var s = room.get_surface()
	assert_in_range(s, 36.84, 36.86, "surface séjour ~36.85")
	room.free()


func test_room_has_required_methods() -> void:
	var room = RoomScript.new()
	assert_has_method(room, "generate_mesh", "generate_mesh existe")
	assert_has_method(room, "resize", "resize existe")
	assert_has_method(room, "set_type", "set_type existe")
	assert_has_method(room, "get_surface", "get_surface existe")
	assert_has_method(room, "to_dict", "to_dict existe")
	assert_has_method(room, "from_dict", "from_dict existe")
	assert_has_method(room, "add_technical_point", "add_technical_point existe")
	room.free()


func test_room_type_color_mapping() -> void:
	var room = RoomScript.new()
	var colors = {
		"living": Color(0.95, 0.92, 0.85),
		"bedroom": Color(0.85, 0.90, 0.95),
		"bathroom": Color(0.80, 0.92, 0.95),
		"wc": Color(0.90, 0.88, 0.95),
		"kitchen": Color(0.95, 0.90, 0.80),
		"storage": Color(0.88, 0.88, 0.85),
	}
	for t in colors:
		assert_true(t in room.TYPE_COLORS, "TYPE_COLORS contient %s" % t)
	room.free()


func test_room_to_dict_structure() -> void:
	var room = RoomScript.new()
	room.room_name = "Test"
	room.room_width = 4.0
	room.room_depth = 5.0
	room.room_type = "bedroom"
	var data = room.to_dict()
	assert_dict_has_key(data, "name", "to_dict contient name")
	assert_dict_has_key(data, "width", "to_dict contient width")
	assert_dict_has_key(data, "depth", "to_dict contient depth")
	assert_dict_has_key(data, "height", "to_dict contient height")
	assert_dict_has_key(data, "type", "to_dict contient type")
	assert_equal(data["name"], "Test", "name = Test")
	assert_equal(data["width"], 4.0, "width = 4.0")
	assert_equal(data["depth"], 5.0, "depth = 5.0")
	room.free()


func test_room_from_dict() -> void:
	var room = RoomScript.new()
	room.from_dict({"name": "Chambre X", "width": 3.5, "depth": 4.2, "height": 2.7, "type": "bedroom"})
	assert_equal(room.room_name, "Chambre X", "from_dict name")
	assert_equal(room.room_width, 3.5, "from_dict width")
	assert_equal(room.room_depth, 4.2, "from_dict depth")
	assert_equal(room.room_height, 2.7, "from_dict height")
	assert_equal(room.room_type, "bedroom", "from_dict type")
	room.free()


func test_room_from_dict_defaults() -> void:
	var room = RoomScript.new()
	room.from_dict({})
	assert_equal(room.room_name, "Pièce", "from_dict({}) name par défaut")
	assert_equal(room.room_width, 3.0, "from_dict({}) width par défaut")
	room.free()


func test_room_resize() -> void:
	var room = RoomScript.new()
	room.resize(5.0, 6.0)
	assert_equal(room.room_width, 5.0, "resize width")
	assert_equal(room.room_depth, 6.0, "resize depth")
	room.free()


func test_room_add_technical_point() -> void:
	var room = RoomScript.new()
	room.add_technical_point("electricity", Vector3(1, 0, 1))
	assert_equal(room.technical_points.size(), 1, "1 point technique ajouté")
	assert_equal(room.technical_points[0]["type"], "electricity", "type = electricity")
	room.free()
