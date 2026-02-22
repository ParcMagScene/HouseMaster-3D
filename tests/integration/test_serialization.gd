extends "res://tests/test_base.gd"

## Tests d'intégration — Sérialisation round-trip complète
## Vérifie que to_dict() → from_dict() préserve toutes les données

const HouseScript = preload("res://scripts/core/house.gd")
const RoomScript = preload("res://scripts/core/room.gd")
const WallScript = preload("res://scripts/core/wall.gd")
const PlumbingScript = preload("res://scripts/modules/plumbing_module.gd")
const ElectricityScript = preload("res://scripts/modules/electricity_module.gd")
const NetworkScript = preload("res://scripts/modules/network_module.gd")
const DomoticsScript = preload("res://scripts/modules/domotics_module.gd")


func test_room_round_trip() -> void:
	var r = RoomScript.new()
	r.room_name = "Chambre Test"
	r.room_type = "bedroom"
	r.position = Vector3(2.5, 0, 1.0)
	r.room_size = Vector2(3.5, 4.0)
	var data = r.to_dict()
	var r2 = RoomScript.new()
	r2.from_dict(data)
	assert_equal(r2.room_name, "Chambre Test", "nom préservé")
	assert_equal(r2.room_type, "bedroom", "type préservé")
	assert_equal(r2.room_size.x, 3.5, "taille x préservée")
	assert_equal(r2.room_size.y, 4.0, "taille y préservée")
	r2.free()
	r.free()


func test_room_round_trip_with_technical_points() -> void:
	var r = RoomScript.new()
	r.room_name = "SdB"
	r.room_type = "bathroom"
	r.room_size = Vector2(2, 3)
	r.add_technical_point(Vector3(0.5, 1.0, 0.5), "plumbing", "Arrivée eau")
	r.add_technical_point(Vector3(1.0, 0.2, 1.0), "electricity", "Prise")
	var data = r.to_dict()
	var r2 = RoomScript.new()
	r2.from_dict(data)
	assert_equal(r2.technical_points.size(), 2, "2 points techniques restaurés")
	assert_equal(r2.technical_points[0].get("label", ""), "Arrivée eau", "label pt 1")
	assert_equal(r2.technical_points[1].get("label", ""), "Prise", "label pt 2")
	r2.free()
	r.free()


func test_wall_round_trip() -> void:
	var w = WallScript.new()
	w.start_pos = Vector3(0, 0, 0)
	w.end_pos = Vector3(5, 0, 0)
	w.wall_height = 2.5
	w.wall_thickness = 0.20
	w.add_opening(1.0, 1.2, 2.1, "door")
	w.add_opening(3.0, 1.0, 1.2, "window")
	var data = w.to_dict()
	var w2 = WallScript.new()
	w2.from_dict(data)
	assert_equal(w2.get_length(), w.get_length(), "longueur préservée")
	assert_equal(w2.wall_height, 2.5, "hauteur préservée")
	assert_equal(w2.openings.size(), 2, "2 ouvertures restaurées")
	assert_equal(w2.openings[0].get("type", ""), "door", "type porte")
	assert_equal(w2.openings[1].get("type", ""), "window", "type fenêtre")
	w2.free()
	w.free()


func test_house_full_round_trip() -> void:
	var h = HouseScript.new()
	h._ready()
	var data = h.to_dict()
	var h2 = HouseScript.new()
	h2.from_dict(data)
	assert_equal(h2.exterior_width, h.exterior_width, "largeur ext identique")
	assert_equal(h2.exterior_depth, h.exterior_depth, "profondeur ext identique")
	assert_equal(h2.rooms.size(), h.rooms.size(), "même nb pièces")
	for i in range(min(h.rooms.size(), h2.rooms.size())):
		assert_equal(h2.rooms[i].room_name, h.rooms[i].room_name, "nom pièce %d" % i)
		assert_equal(h2.rooms[i].room_type, h.rooms[i].room_type, "type pièce %d" % i)
	h2.free()
	h.free()


func test_plumbing_round_trip_complex() -> void:
	var pm = PlumbingScript.new()
	pm.add_pipe(Vector3(0, 0, 0), Vector3(2, 0, 0), 40, "evacuation")
	pm.add_pipe(Vector3(0, 0, 0), Vector3(0, 0, 3), 100, "evacuation")
	pm.add_pipe(Vector3(1, 1, 0), Vector3(1, 1, 2), 12, "supply_hot")
	pm.add_fixture(Vector3(0, 0, 0), "sink")
	pm.add_fixture(Vector3(2, 0, 0), "toilet")
	pm.add_fixture(Vector3(0, 0, 3), "shower")
	var data = pm.to_dict()
	var pm2 = PlumbingScript.new()
	pm2.from_dict(data)
	assert_equal(pm2.pipes.size(), 3, "3 tuyaux restaurés")
	assert_equal(pm2.fixtures.size(), 3, "3 fixtures restaurées")
	for i in range(3):
		assert_equal(pm2.pipes[i].get("diameter"), pm.pipes[i].get("diameter"), "diamètre pipe %d" % i)
		assert_equal(pm2.pipes[i].get("type"), pm.pipes[i].get("type"), "type pipe %d" % i)
	pm2.free()
	pm.free()


func test_electricity_round_trip_complex() -> void:
	var em = ElectricityScript.new()
	em.add_circuit("Prises Séjour", 16)
	em.add_circuit("Éclairage", 10)
	em.add_element(0, Vector3(1, 0.3, 0), "socket")
	em.add_element(0, Vector3(2, 0.3, 0), "socket")
	em.add_element(0, Vector3(3, 0.3, 0), "socket")
	em.add_element(1, Vector3(2.5, 2.4, 2), "light")
	var data = em.to_dict()
	var em2 = ElectricityScript.new()
	em2.from_dict(data)
	assert_equal(em2.circuits.size(), 2, "2 circuits restaurés")
	assert_equal(em2.circuits[0].get("elements", []).size(), 3, "3 éléments circuit 0")
	assert_equal(em2.circuits[1].get("elements", []).size(), 1, "1 élément circuit 1")
	assert_equal(em2.circuits[0].get("name", ""), "Prises Séjour", "nom circuit 0")
	assert_equal(em2.circuits[0].get("breaker_amps", 0), 16, "ampérage circuit 0")
	em2.free()
	em.free()


func test_network_round_trip_complex() -> void:
	var nm = NetworkScript.new()
	nm.add_point(Vector3(0, 0.3, 0), "rj45")
	nm.add_point(Vector3(3, 0.3, 0), "rj45")
	nm.add_point(Vector3(5, 0.3, 2), "fiber_outlet")
	nm.add_cable(0, 1, "cat6")
	nm.add_cable(1, 2, "cat6a")
	var data = nm.to_dict()
	var nm2 = NetworkScript.new()
	nm2.from_dict(data)
	assert_equal(nm2.points.size(), 3, "3 points restaurés")
	assert_equal(nm2.cables.size(), 2, "2 câbles restaurés")
	assert_equal(nm2.cables[0].get("category", ""), "cat6", "catégorie câble 0")
	assert_equal(nm2.cables[1].get("category", ""), "cat6a", "catégorie câble 1")
	nm2.free()
	nm.free()


func test_domotics_round_trip_complex() -> void:
	var dm = DomoticsScript.new()
	dm.add_sensor(Vector3(2, 2.3, 2), "motion")
	dm.add_sensor(Vector3(1, 1.5, 1), "temperature")
	dm.add_actuator(Vector3(2.5, 2.4, 2), "light")
	dm.add_actuator(Vector3(0, 1.0, 0), "heating")
	dm.add_scenario(
		"Chauffage auto",
		[{"sensor_index": 1, "operator": "<", "value": 19.0}],
		[{"actuator_index": 1, "action": "set_value", "value": 21.0}]
	)
	var data = dm.to_dict()
	var dm2 = DomoticsScript.new()
	dm2.from_dict(data)
	assert_equal(dm2.sensors.size(), 2, "2 capteurs restaurés")
	assert_equal(dm2.actuators.size(), 2, "2 actionneurs restaurés")
	assert_equal(dm2.scenarios.size(), 1, "1 scénario restauré")
	assert_equal(dm2.scenarios[0].get("name", ""), "Chauffage auto", "nom scénario")
	dm2.free()
	dm.free()


func test_full_save_data_structure() -> void:
	var h = HouseScript.new()
	h._ready()
	var pm = PlumbingScript.new()
	var em = ElectricityScript.new()
	var nm = NetworkScript.new()
	var dm = DomoticsScript.new()
	pm.add_pipe(Vector3.ZERO, Vector3(1, 0, 0), 40, "evacuation")
	em.add_circuit("C1", 16)
	nm.add_point(Vector3.ZERO, "rj45")
	dm.add_sensor(Vector3.ZERO, "motion")

	var save_data := {
		"version": "1.0.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"house": h.to_dict(),
		"modules": {
			"plumbing": pm.to_dict(),
			"electricity": em.to_dict(),
			"network": nm.to_dict(),
			"domotics": dm.to_dict(),
		}
	}

	assert_dict_has_key(save_data, "version", "version dans save_data")
	assert_dict_has_key(save_data, "timestamp", "timestamp dans save_data")
	assert_dict_has_key(save_data, "house", "house dans save_data")
	assert_dict_has_key(save_data, "modules", "modules dans save_data")

	var house_data = save_data["house"]
	assert_dict_has_key(house_data, "rooms", "rooms dans house_data")

	var h2 = HouseScript.new()
	h2.from_dict(house_data)
	assert_equal(h2.rooms.size(), h.rooms.size(), "round-trip complet OK")

	h2.free()
	dm.free()
	nm.free()
	em.free()
	pm.free()
	h.free()
