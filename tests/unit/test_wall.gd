extends "res://tests/test_base.gd"

## Tests unitaires — WallCore

const WallScript = preload("res://scripts/core/wall.gd")


func test_wall_default_values() -> void:
	var wall = WallScript.new()
	assert_equal(wall.wall_height, 2.50, "hauteur par défaut = 2.50")
	assert_equal(wall.wall_thickness, 0.20, "épaisseur par défaut = 0.20")
	assert_equal(wall.wall_start, Vector3.ZERO, "start = ZERO")
	wall.free()


func test_wall_length_horizontal() -> void:
	var wall = WallScript.new()
	wall.wall_start = Vector3(0, 0, 0)
	wall.wall_end = Vector3(10.50, 0, 0)
	assert_in_range(wall.get_length(), 10.49, 10.51, "longueur mur nord = 10.50")
	wall.free()


func test_wall_length_vertical() -> void:
	var wall = WallScript.new()
	wall.wall_start = Vector3(0, 0, 0)
	wall.wall_end = Vector3(0, 0, 6.70)
	assert_in_range(wall.get_length(), 6.69, 6.71, "longueur mur ouest = 6.70")
	wall.free()


func test_wall_has_required_methods() -> void:
	var wall = WallScript.new()
	assert_has_method(wall, "generate_mesh", "generate_mesh existe")
	assert_has_method(wall, "add_opening", "add_opening existe")
	assert_has_method(wall, "remove_opening", "remove_opening existe")
	assert_has_method(wall, "get_length", "get_length existe")
	assert_has_method(wall, "to_dict", "to_dict existe")
	assert_has_method(wall, "from_dict", "from_dict existe")
	wall.free()


func test_wall_to_dict_structure() -> void:
	var wall = WallScript.new()
	wall.wall_start = Vector3(1, 0, 2)
	wall.wall_end = Vector3(5, 0, 2)
	var data = wall.to_dict()
	assert_dict_has_key(data, "start", "to_dict contient start")
	assert_dict_has_key(data, "end", "to_dict contient end")
	assert_dict_has_key(data, "height", "to_dict contient height")
	assert_dict_has_key(data, "thickness", "to_dict contient thickness")
	assert_dict_has_key(data, "openings", "to_dict contient openings")
	assert_equal(data["start"]["x"], 1.0, "start.x = 1.0")
	wall.free()


func test_wall_from_dict() -> void:
	var wall = WallScript.new()
	wall.from_dict({
		"start": {"x": 0, "y": 0, "z": 0},
		"end": {"x": 5, "y": 0, "z": 0},
		"height": 3.0,
		"thickness": 0.25,
		"openings": []
	})
	assert_equal(wall.wall_height, 3.0, "from_dict height = 3.0")
	assert_equal(wall.wall_thickness, 0.25, "from_dict thickness = 0.25")
	assert_in_range(wall.get_length(), 4.99, 5.01, "from_dict length ~5.0")
	wall.free()


func test_wall_from_dict_defaults() -> void:
	var wall = WallScript.new()
	wall.from_dict({})
	assert_equal(wall.wall_height, 2.5, "from_dict({}) height par défaut")
	assert_equal(wall.wall_thickness, 0.2, "from_dict({}) thickness par défaut")
	wall.free()


func test_wall_openings_add() -> void:
	var wall = WallScript.new()
	assert_equal(wall.openings.size(), 0, "0 ouvertures initiales")
	wall.openings.append({"type": "door", "position": 0.5, "width": 0.9, "height": 2.1, "elevation": 0.0})
	assert_equal(wall.openings.size(), 1, "1 ouverture ajoutée")
	wall.free()


func test_wall_remove_opening_bounds() -> void:
	var wall = WallScript.new()
	wall.remove_opening(-1)  # ne doit pas crasher
	wall.remove_opening(100)  # ne doit pas crasher
	assert_true(true, "remove_opening out of bounds ne crashe pas")
	wall.free()
