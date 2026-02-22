extends "res://tests/test_base.gd"

## Tests HeatingSimulator

func _make_heating_graph() -> SimulationGraph:
	var g = SimulationGraph.new()
	var boiler = g.add_node("boiler", "heating", Vector3.ZERO, "Chaudière")
	boiler.properties["power_w"] = 25000.0

	var radiator = g.add_node("emitter", "heating", Vector3(5, 0, 3), "Radiateur Séjour")
	radiator.properties["power_w"] = 2000.0
	radiator.properties["room_id"] = "sejour"
	radiator.properties["room_area_m2"] = 25.0
	radiator.properties["room_height_m"] = 2.5
	radiator.properties["insulation"] = "standard"

	var thermo = g.add_node("thermostat", "heating", Vector3(5, 1.5, 3), "Thermostat Séjour")
	thermo.properties["room_id"] = "sejour"

	g.add_edge("pipe", "heating", boiler.id, radiator.id, {
		"length_m": 8.0, "diameter_mm": 16.0, "pipe_type": "standard",
	})

	return g


func test_simulate_valid() -> void:
	var sim = HeatingSimulator.new()
	var g = _make_heating_graph()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.network, "heating")


func test_simulate_empty() -> void:
	var sim = HeatingSimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_emitters"), 0)


func test_detect_no_boiler() -> void:
	var sim = HeatingSimulator.new()
	var g = SimulationGraph.new()
	var rad = g.add_node("emitter", "heating", Vector3.ZERO, "Rad")
	rad.properties["power_w"] = 1000.0

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "pas de chaudière détecté")


func test_detect_floor_loop_too_long() -> void:
	var sim = HeatingSimulator.new()
	var g = SimulationGraph.new()
	var boiler = g.add_node("boiler", "heating", Vector3.ZERO, "Chaudière")
	boiler.properties["power_w"] = 20000.0
	var rad = g.add_node("emitter", "heating", Vector3(10, 0, 0), "Plancher")
	rad.properties["power_w"] = 3000.0

	g.add_edge("pipe", "heating", boiler.id, rad.id, {
		"length_m": 90.0, "pipe_type": "floor_heating",
	})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "boucle trop longue détectée")


func test_metrics() -> void:
	var sim = HeatingSimulator.new()
	var g = _make_heating_graph()
	var report = sim.simulate(g)
	assert_gt(report.get_metric("total_power_w"), 0.0, "puissance > 0")
	assert_gt(report.get_metric("total_emitters"), 0.0, "émetteurs > 0")
