extends "res://tests/test_base.gd"

## Tests d'intégration — Workflow complet
## Teste le cycle : créer house → ajouter modules → modifier → sauvegarder → charger

const HouseScript = preload("res://scripts/core/house.gd")
const PlumbingScript = preload("res://scripts/modules/plumbing_module.gd")
const ElectricityScript = preload("res://scripts/modules/electricity_module.gd")
const NetworkScript = preload("res://scripts/modules/network_module.gd")
const DomoticsScript = preload("res://scripts/modules/domotics_module.gd")
const UndoRedoScript = preload("res://scripts/undo_redo_manager.gd")


func test_house_creation_and_rooms() -> void:
	var house = HouseScript.new()
	house._ready()
	assert_equal(house.rooms.size(), 6, "house créée avec 6 pièces")
	var names := []
	for r in house.rooms:
		names.append(r.room_name)
	assert_true("Séjour + Cuisine" in names, "Séjour + Cuisine présent")
	assert_true("Chambre 1" in names, "Chambre 1 présent")
	assert_true("SdB" in names, "SdB présent")
	house.free()


func test_house_total_surface() -> void:
	var house = HouseScript.new()
	house._ready()
	var total := 0.0
	for r in house.rooms:
		total += r.get_surface()
	assert_gt(total, 50.0, "surface totale > 50 m²")
	assert_lt(total, 75.0, "surface totale < 75 m²")
	house.free()


func test_house_to_dict_and_back() -> void:
	var house = HouseScript.new()
	house._ready()
	var data = house.to_dict()
	var house2 = HouseScript.new()
	house2.from_dict(data)
	assert_equal(house2.rooms.size(), house.rooms.size(), "même nb de pièces après serialization")
	assert_equal(house2.exterior_width, house.exterior_width, "même largeur")
	assert_equal(house2.exterior_depth, house.exterior_depth, "même profondeur")
	house2.free()
	house.free()


func test_plumbing_add_and_serialize() -> void:
	var pm = PlumbingScript.new()
	pm.add_pipe(Vector3.ZERO, Vector3(1, 0, 0), 40, "evacuation")
	pm.add_fixture(Vector3(0.5, 0, 0), "sink")
	var data = pm.to_dict()
	assert_equal(data.get("pipes", []).size(), 1, "1 pipe sérialisé")
	assert_equal(data.get("fixtures", []).size(), 1, "1 fixture sérialisée")
	var pm2 = PlumbingScript.new()
	pm2.from_dict(data)
	assert_equal(pm2.pipes.size(), 1, "pipe restauré")
	assert_equal(pm2.fixtures.size(), 1, "fixture restaurée")
	pm2.free()
	pm.free()


func test_electricity_circuit_workflow() -> void:
	var em = ElectricityScript.new()
	em.add_circuit("Prises Séjour", 16)
	em.add_element(0, Vector3.ZERO, "socket")
	em.add_element(0, Vector3(1, 0, 0), "socket")
	var data = em.to_dict()
	assert_equal(data.get("circuits", []).size(), 1, "1 circuit sérialisé")
	var circuit_data = data["circuits"][0]
	assert_equal(circuit_data.get("elements", []).size(), 2, "2 éléments dans le circuit")
	var em2 = ElectricityScript.new()
	em2.from_dict(data)
	assert_equal(em2.circuits.size(), 1, "circuit restauré")
	em2.free()
	em.free()


func test_network_full_setup() -> void:
	var nm = NetworkScript.new()
	nm.add_point(Vector3.ZERO, "rj45")
	nm.add_point(Vector3(2, 0, 0), "rj45")
	nm.add_cable(0, 1, "cat6")
	var data = nm.to_dict()
	var nm2 = NetworkScript.new()
	nm2.from_dict(data)
	assert_equal(nm2.points.size(), 2, "2 points réseau restaurés")
	assert_equal(nm2.cables.size(), 1, "1 câble restauré")
	nm2.free()
	nm.free()


func test_domotics_scenario_workflow() -> void:
	var dm = DomoticsScript.new()
	dm.add_sensor(Vector3.ZERO, "motion")
	dm.add_actuator(Vector3(1, 0, 0), "light")
	dm.add_scenario("Auto light", [{"sensor_index": 0, "operator": "==", "value": true}], [{"actuator_index": 0, "action": "turn_on", "value": null}])
	assert_equal(dm.scenarios.size(), 1, "1 scénario ajouté")
	var data = dm.to_dict()
	var dm2 = DomoticsScript.new()
	dm2.from_dict(data)
	assert_equal(dm2.sensors.size(), 1, "capteur restauré")
	assert_equal(dm2.actuators.size(), 1, "actionneur restauré")
	assert_equal(dm2.scenarios.size(), 1, "scénario restauré")
	dm2.free()
	dm.free()


func test_all_modules_combined_dict() -> void:
	var pm = PlumbingScript.new()
	var em = ElectricityScript.new()
	var nm = NetworkScript.new()
	var dm = DomoticsScript.new()

	pm.add_pipe(Vector3.ZERO, Vector3(1, 0, 0), 40, "evacuation")
	em.add_circuit("C1", 16)
	nm.add_point(Vector3.ZERO, "rj45")
	dm.add_sensor(Vector3.ZERO, "temperature")

	var combined := {
		"plumbing": pm.to_dict(),
		"electricity": em.to_dict(),
		"network": nm.to_dict(),
		"domotics": dm.to_dict(),
	}

	assert_dict_has_key(combined, "plumbing", "plumbing présent")
	assert_dict_has_key(combined, "electricity", "electricity présent")
	assert_dict_has_key(combined, "network", "network présent")
	assert_dict_has_key(combined, "domotics", "domotics présent")

	assert_gt(combined["plumbing"].get("pipes", []).size(), 0, "pipe dans combined")
	assert_gt(combined["electricity"].get("circuits", []).size(), 0, "circuit dans combined")
	assert_gt(combined["network"].get("points", []).size(), 0, "point dans combined")
	assert_gt(combined["domotics"].get("sensors", []).size(), 0, "sensor dans combined")

	dm.free()
	nm.free()
	em.free()
	pm.free()


func test_undo_redo_with_house() -> void:
	var ur = UndoRedoScript.new()
	var house = HouseScript.new()
	house._ready()
	var original_count := house.rooms.size()

	ur.perform_action(
		"Ajouter pièce",
		func():
			house.add_room("Test", Vector3(8, 0, 0), Vector2(2, 2), "other"),
		func():
			if house.rooms.size() > original_count:
				var last = house.rooms.pop_back()
				if is_instance_valid(last):
					last.queue_free()
	)
	assert_equal(house.rooms.size(), original_count + 1, "pièce ajoutée")

	ur.undo()
	assert_equal(house.rooms.size(), original_count, "pièce supprimée après undo")

	ur.redo()
	assert_equal(house.rooms.size(), original_count + 1, "pièce re-ajoutée après redo")

	ur.free()
	house.free()
