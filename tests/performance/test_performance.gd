extends "res://tests/test_base.gd"

## Tests de performance — HouseMaster 3D
## Mesure les temps d'exécution des opérations critiques

const HouseScript = preload("res://scripts/core/house.gd")
const RoomScript = preload("res://scripts/core/room.gd")
const WallScript = preload("res://scripts/core/wall.gd")
const PlumbingScript = preload("res://scripts/modules/plumbing_module.gd")
const ElectricityScript = preload("res://scripts/modules/electricity_module.gd")
const NetworkScript = preload("res://scripts/modules/network_module.gd")
const DomoticsScript = preload("res://scripts/modules/domotics_module.gd")

const PERF_THRESHOLD_MS := 500.0  # seuil max en ms


func _measure_ms(callable: Callable) -> float:
	var start := Time.get_ticks_msec()
	callable.call()
	return Time.get_ticks_msec() - start


func test_perf_house_creation() -> void:
	var elapsed := _measure_ms(func():
		for i in range(100):
			var h = HouseScript.new()
			h._ready()
			h.free()
	)
	assert_lt(elapsed, PERF_THRESHOLD_MS, "100 créations House < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])


func test_perf_room_creation_batch() -> void:
	var elapsed := _measure_ms(func():
		for i in range(500):
			var r = RoomScript.new()
			r.room_name = "Room_%d" % i
			r.room_size = Vector2(3, 4)
			r.free()
	)
	assert_lt(elapsed, PERF_THRESHOLD_MS, "500 créations Room < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])


func test_perf_wall_creation_batch() -> void:
	var elapsed := _measure_ms(func():
		for i in range(500):
			var w = WallScript.new()
			w.start_pos = Vector3(0, 0, 0)
			w.end_pos = Vector3(float(i % 10), 0, 0)
			w.free()
	)
	assert_lt(elapsed, PERF_THRESHOLD_MS, "500 créations Wall < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])


func test_perf_serialization_house() -> void:
	var h = HouseScript.new()
	h._ready()
	var elapsed := _measure_ms(func():
		for i in range(1000):
			var _d = h.to_dict()
	)
	h.free()
	assert_lt(elapsed, PERF_THRESHOLD_MS, "1000 to_dict House < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])


func test_perf_deserialization_house() -> void:
	var h = HouseScript.new()
	h._ready()
	var data = h.to_dict()
	var elapsed := _measure_ms(func():
		for i in range(200):
			var h2 = HouseScript.new()
			h2.from_dict(data)
			h2.free()
	)
	h.free()
	assert_lt(elapsed, PERF_THRESHOLD_MS * 2, "200 from_dict House < %dms (actual: %dms)" % [PERF_THRESHOLD_MS * 2, elapsed])


func test_perf_plumbing_large_network() -> void:
	var pm = PlumbingScript.new()
	var elapsed := _measure_ms(func():
		for i in range(200):
			pm.add_pipe(
				Vector3(float(i), 0, 0),
				Vector3(float(i) + 1, 0, 0),
				40,
				"evacuation"
			)
		for i in range(100):
			pm.add_fixture(Vector3(float(i) * 0.5, 0, 0), "sink")
	)
	pm.free()
	assert_lt(elapsed, PERF_THRESHOLD_MS, "200 pipes + 100 fixtures < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])


func test_perf_electricity_large_installation() -> void:
	var em = ElectricityScript.new()
	var elapsed := _measure_ms(func():
		for c in range(20):
			em.add_circuit("Circuit_%d" % c, 16)
			for e in range(8):
				em.add_element(c, Vector3(float(e), 0.3, float(c)), "socket")
	)
	em.free()
	assert_lt(elapsed, PERF_THRESHOLD_MS, "20 circuits × 8 éléments < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])


func test_perf_serialization_all_modules() -> void:
	var pm = PlumbingScript.new()
	var em = ElectricityScript.new()
	var nm = NetworkScript.new()
	var dm = DomoticsScript.new()

	for i in range(50):
		pm.add_pipe(Vector3(float(i), 0, 0), Vector3(float(i) + 1, 0, 0), 40, "evacuation")
	for i in range(5):
		em.add_circuit("C%d" % i, 16)
		for j in range(5):
			em.add_element(i, Vector3(float(j), 0, float(i)), "socket")
	for i in range(20):
		nm.add_point(Vector3(float(i), 0, 0), "rj45")
	for i in range(10):
		dm.add_sensor(Vector3(float(i), 2, 0), "motion")
		dm.add_actuator(Vector3(float(i), 2.4, 0), "light")

	var elapsed := _measure_ms(func():
		for _iter in range(500):
			var _d = {
				"plumbing": pm.to_dict(),
				"electricity": em.to_dict(),
				"network": nm.to_dict(),
				"domotics": dm.to_dict(),
			}
	)
	dm.free()
	nm.free()
	em.free()
	pm.free()
	assert_lt(elapsed, PERF_THRESHOLD_MS * 2, "500 sérialisations modules < %dms (actual: %dms)" % [PERF_THRESHOLD_MS * 2, elapsed])


func test_perf_scenario_evaluation() -> void:
	var dm = DomoticsScript.new()
	for i in range(20):
		dm.add_sensor(Vector3(float(i), 2, 0), "motion")
		dm.add_actuator(Vector3(float(i), 2.4, 0), "light")
		dm.add_scenario(
			"Auto_%d" % i,
			[{"sensor_index": i, "operator": "==", "value": true}],
			[{"actuator_index": i, "action": "turn_on", "value": null}]
		)
	var elapsed := _measure_ms(func():
		for _iter in range(1000):
			dm.evaluate_scenarios()
	)
	dm.free()
	assert_lt(elapsed, PERF_THRESHOLD_MS, "1000 évaluations 20 scénarios < %dms (actual: %dms)" % [PERF_THRESHOLD_MS, elapsed])
