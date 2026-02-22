extends "res://tests/test_base.gd"

## Tests unitaires — HouseCore

const HouseScript = preload("res://scripts/core/house.gd")


func test_house_default_dimensions() -> void:
	var house = HouseScript.new()
	assert_equal(house.exterior_width, 10.50, "largeur extérieure = 10.50")
	assert_equal(house.exterior_depth, 6.70, "profondeur extérieure = 6.70")
	assert_equal(house.wall_height, 2.50, "hauteur murs = 2.50")
	assert_equal(house.wall_thickness, 0.20, "épaisseur murs = 0.20")
	house.free()


func test_house_default_rooms_count() -> void:
	var house = HouseScript.new()
	assert_equal(house.default_rooms.size(), 6, "6 pièces par défaut")
	house.free()


func test_house_default_rooms_names() -> void:
	var house = HouseScript.new()
	var names := []
	for r in house.default_rooms:
		names.append(r["name"])
	assert_true("Séjour + Cuisine" in names, "Séjour+Cuisine présent")
	assert_true("Chambre 1" in names, "Chambre 1 présente")
	assert_true("Chambre 2" in names, "Chambre 2 présente")
	assert_true("Salle de bain" in names, "SdB présente")
	assert_true("WC" in names, "WC présent")
	assert_true("Cellier" in names, "Cellier présent")
	house.free()


func test_house_total_surface() -> void:
	var house = HouseScript.new()
	var expected = 10.50 * 6.70
	assert_in_range(house.get_total_surface(), expected - 0.01, expected + 0.01, "surface totale ~70.35")
	house.free()


func test_house_has_required_methods() -> void:
	var house = HouseScript.new()
	assert_has_method(house, "add_room", "add_room existe")
	assert_has_method(house, "remove_room", "remove_room existe")
	assert_has_method(house, "add_wall", "add_wall existe")
	assert_has_method(house, "remove_wall", "remove_wall existe")
	assert_has_method(house, "to_dict", "to_dict existe")
	assert_has_method(house, "from_dict", "from_dict existe")
	assert_has_method(house, "get_room_by_name", "get_room_by_name existe")
	assert_has_method(house, "get_total_surface", "get_total_surface existe")
	house.free()


func test_house_to_dict_structure() -> void:
	var house = HouseScript.new()
	var data = house.to_dict()
	assert_dict_has_key(data, "exterior_width", "to_dict contient exterior_width")
	assert_dict_has_key(data, "exterior_depth", "to_dict contient exterior_depth")
	assert_dict_has_key(data, "wall_height", "to_dict contient wall_height")
	assert_dict_has_key(data, "wall_thickness", "to_dict contient wall_thickness")
	assert_dict_has_key(data, "rooms", "to_dict contient rooms")
	assert_dict_has_key(data, "walls", "to_dict contient walls")
	assert_dict_has_key(data, "openings", "to_dict contient openings")
	house.free()


func test_house_room_dimensions_sejour() -> void:
	var house = HouseScript.new()
	var sejour = house.default_rooms[0]
	assert_equal(sejour["name"], "Séjour + Cuisine", "nom séjour")
	assert_equal(sejour["width"], 5.50, "largeur séjour = 5.50")
	assert_equal(sejour["depth"], 6.70, "profondeur séjour = 6.70")
	house.free()


func test_house_room_dimensions_chambre1() -> void:
	var house = HouseScript.new()
	var ch1 = house.default_rooms[1]
	assert_equal(ch1["name"], "Chambre 1", "nom chambre 1")
	assert_equal(ch1["width"], 3.00, "largeur ch1 = 3.00")
	assert_equal(ch1["depth"], 4.00, "profondeur ch1 = 4.00")
	house.free()


func test_house_room_dimensions_sdb() -> void:
	var house = HouseScript.new()
	var sdb = house.default_rooms[3]
	assert_equal(sdb["name"], "Salle de bain", "nom SdB")
	assert_equal(sdb["width"], 2.00, "largeur SdB = 2.00")
	assert_equal(sdb["depth"], 3.00, "profondeur SdB = 3.00")
	house.free()


func test_house_remove_room_null_safe() -> void:
	var house = HouseScript.new()
	house.remove_room(null)  # Ne doit pas crasher
	assert_true(true, "remove_room(null) ne crashe pas")
	house.free()
