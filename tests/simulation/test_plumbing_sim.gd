extends "res://tests/test_base.gd"

## Tests PlumbingSimulator

func _make_plumbing_graph() -> SimulationGraph:
	var g = SimulationGraph.new()
	var main = g.add_node("junction", "plumbing", Vector3.ZERO, "Arrivée")

	var sink = g.add_node("equipment", "plumbing", Vector3(3, 0, 0), "Évier")
	sink.properties["fixture_type"] = "sink"
	sink.properties["has_supply"] = true
	sink.properties["has_evacuation"] = true

	var shower = g.add_node("equipment", "plumbing", Vector3(5, 0, 2), "Douche")
	shower.properties["fixture_type"] = "shower"
	shower.properties["has_supply"] = true
	shower.properties["has_evacuation"] = true

	g.add_edge("pipe", "plumbing", main.id, sink.id, {
		"length_m": 3.0, "diameter_mm": 16.0, "pipe_type": "supply",
	})
	g.add_edge("pipe", "plumbing", main.id, shower.id, {
		"length_m": 5.0, "diameter_mm": 16.0, "pipe_type": "supply",
	})
	g.add_edge("pipe", "plumbing", sink.id, shower.id, {
		"length_m": 2.0, "diameter_mm": 40.0, "pipe_type": "evacuation", "slope": 0.02,
	})

	return g


func test_simulate_valid() -> void:
	var sim = PlumbingSimulator.new()
	var g = _make_plumbing_graph()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.network, "plumbing")
	assert_true(report.errors.size() == 0, "pas d'erreurs sur installation valide")


func test_simulate_empty() -> void:
	var sim = PlumbingSimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_pipes"), 0)
	assert_equal(report.get_metric("total_fixtures"), 0)


func test_detect_slope_error() -> void:
	var sim = PlumbingSimulator.new()
	var g = SimulationGraph.new()
	var n1 = g.add_node("junction", "plumbing", Vector3.ZERO)
	var n2 = g.add_node("equipment", "plumbing", Vector3(3, 0, 0), "Évier")
	n2.properties["fixture_type"] = "sink"
	n2.properties["has_supply"] = true
	n2.properties["has_evacuation"] = true

	g.add_edge("pipe", "plumbing", n1.id, n2.id, {
		"length_m": 3.0, "diameter_mm": 40.0, "pipe_type": "evacuation", "slope": 0.005,
	})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "pente insuffisante détectée")


func test_detect_diameter_error() -> void:
	var sim = PlumbingSimulator.new()
	var g = SimulationGraph.new()
	var n1 = g.add_node("junction", "plumbing", Vector3.ZERO)
	var n2 = g.add_node("equipment", "plumbing", Vector3(3, 0, 0), "WC")
	n2.properties["fixture_type"] = "toilet"
	n2.properties["has_supply"] = true
	n2.properties["has_evacuation"] = true

	g.add_edge("pipe", "plumbing", n1.id, n2.id, {
		"length_m": 2.0, "diameter_mm": 30.0, "pipe_type": "evacuation", "slope": 0.02,
	})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "diamètre insuffisant détecté")


func test_metrics() -> void:
	var sim = PlumbingSimulator.new()
	var g = _make_plumbing_graph()
	var report = sim.simulate(g)
	assert_not_null(report.get_metric("total_fixtures"))
	assert_gt(report.get_metric("total_length_m"), 0.0, "longueur > 0")
