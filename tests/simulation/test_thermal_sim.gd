extends "res://tests/test_base.gd"

## Tests ThermalSimulator

func test_simulate_room() -> void:
	var sim = ThermalSimulator.new()
	var room = {
		"id": "sejour",
		"name": "Séjour",
		"area_m2": 30.0,
		"height_m": 2.5,
		"is_ground_floor": true,
		"is_top_floor": false,
		"walls": [
			{"area_m2": 15.0, "type": "wall_standard"},
			{"area_m2": 10.0, "type": "wall_insulated"},
		],
		"windows": [
			{"area_m2": 3.0, "type": "window_double", "orientation": "south"},
			{"area_m2": 2.0, "type": "window_double", "orientation": "west"},
		],
		"floor_type": "floor_standard",
	}

	var result = sim.simulate_room(room)
	assert_not_null(result)
	assert_gt(result["total_loss_w"], 0.0, "pertes > 0")
	assert_gt(result["heating_power_w"], 0.0, "puissance chauffage > 0")
	assert_gt(result["wall_loss_w"], 0.0, "pertes murs > 0")
	assert_gt(result["window_loss_w"], 0.0, "pertes fenêtres > 0")
	assert_gt(result["air_loss_w"], 0.0, "pertes air > 0")


func test_simulate_room_well_insulated() -> void:
	var sim = ThermalSimulator.new()
	var room_well = {
		"id": "r1", "name": "Bien isolé",
		"area_m2": 20.0, "height_m": 2.5,
		"walls": [{"area_m2": 10.0, "type": "wall_insulated"}],
		"windows": [{"area_m2": 2.0, "type": "window_triple", "orientation": "south"}],
	}
	var room_old = {
		"id": "r2", "name": "Mal isolé",
		"area_m2": 20.0, "height_m": 2.5,
		"walls": [{"area_m2": 10.0, "type": "wall_old"}],
		"windows": [{"area_m2": 2.0, "type": "window_single", "orientation": "north"}],
	}

	var result_well = sim.simulate_room(room_well)
	var result_old = sim.simulate_room(room_old)
	assert_lt(result_well["total_loss_w"], result_old["total_loss_w"], "bien isolé < mal isolé")


func test_simulate_house() -> void:
	var sim = ThermalSimulator.new()
	var rooms = [
		{
			"id": "r1", "name": "Séjour",
			"area_m2": 30.0, "height_m": 2.5,
			"is_ground_floor": true,
			"walls": [{"area_m2": 20.0, "type": "wall_standard"}],
			"windows": [{"area_m2": 4.0, "type": "window_double", "orientation": "south"}],
			"floor_type": "floor_standard",
		},
		{
			"id": "r2", "name": "Chambre",
			"area_m2": 15.0, "height_m": 2.5,
			"is_top_floor": true,
			"walls": [{"area_m2": 12.0, "type": "wall_standard"}],
			"windows": [{"area_m2": 2.0, "type": "window_double", "orientation": "north"}],
			"roof_type": "roof_standard",
		},
	]

	var result = sim.simulate_house(rooms)
	assert_not_null(result)
	assert_gt(result["total_loss_w"], 0.0, "pertes totales > 0")
	assert_gt(result["total_heating_power_w"], 0.0, "puissance chauffage > 0")
	assert_equal(result["rooms"].size(), 2, "2 pièces")
	assert_true(result["energy_class"] in ["A", "B", "C", "D", "E", "F", "G"], "classe valide")
	assert_gt(result["estimated_kwh_per_year"], 0.0, "estimation kWh > 0")


func test_energy_class() -> void:
	var sim = ThermalSimulator.new()
	# Maison mal isolée = mauvaise classe
	var rooms = [{
		"id": "r1", "name": "Grande pièce",
		"area_m2": 100.0, "height_m": 2.5,
		"is_ground_floor": true, "is_top_floor": true,
		"walls": [{"area_m2": 80.0, "type": "wall_old"}],
		"windows": [{"area_m2": 15.0, "type": "window_single", "orientation": "north"}],
		"floor_type": "floor_old", "roof_type": "roof_old",
	}]

	var result = sim.simulate_house(rooms)
	# Doit être classe E, F ou G (mal isolé)
	assert_true(result["energy_class"] in ["D", "E", "F", "G"], "mal isolé = classe D-G")


func test_solar_gain() -> void:
	var sim = ThermalSimulator.new()
	var room_south = {
		"id": "r1", "name": "Sud",
		"area_m2": 20.0, "height_m": 2.5,
		"walls": [{"area_m2": 10.0, "type": "wall_standard"}],
		"windows": [{"area_m2": 5.0, "type": "window_double", "orientation": "south"}],
	}
	var room_north = {
		"id": "r2", "name": "Nord",
		"area_m2": 20.0, "height_m": 2.5,
		"walls": [{"area_m2": 10.0, "type": "wall_standard"}],
		"windows": [{"area_m2": 5.0, "type": "window_double", "orientation": "north"}],
	}

	var result_south = sim.simulate_room(room_south)
	var result_north = sim.simulate_room(room_north)
	assert_gt(result_south["solar_gain_w"], result_north["solar_gain_w"], "sud > nord en apport solaire")
