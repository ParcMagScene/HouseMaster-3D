extends "res://tests/test_base.gd"

## Tests ElectricitySimulator

func _make_graph_with_circuit() -> SimulationGraph:
	var g = SimulationGraph.new()
	var panel = g.add_node("panel", "electricity", Vector3.ZERO, "Tableau")
	panel.properties["type"] = "panel"

	var circuit_breaker = g.add_node("breaker", "electricity", Vector3(0.5, 0, 0), "Disj16A")
	circuit_breaker.properties["breaker_a"] = 16
	circuit_breaker.properties["circuit_id"] = 0

	# 3 prises sur le circuit
	for i in range(3):
		var socket = g.add_node("socket", "electricity", Vector3(float(i + 1), 0, 0), "Prise %d" % i)
		socket.properties["circuit_id"] = 0
		socket.properties["power_w"] = 200.0
		var edge = g.add_edge("cable", "electricity", circuit_breaker.id, socket.id, {
			"length_m": float(i + 1) * 2.0,
			"section_mm2": 2.5,
		})

	return g


func test_simulate_valid() -> void:
	var sim = ElectricitySimulator.new()
	var g = _make_graph_with_circuit()
	var report = sim.simulate(g)
	assert_not_null(report, "rapport créé")
	assert_equal(report.network, "electricity")
	assert_true(report.errors.size() == 0, "pas d'erreur")


func test_simulate_empty() -> void:
	var sim = ElectricitySimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.get_metric("total_circuits"), 0)


func test_detect_overload() -> void:
	var sim = ElectricitySimulator.new()
	var g = SimulationGraph.new()
	var breaker = g.add_node("breaker", "electricity", Vector3.ZERO, "Disj10A")
	breaker.properties["breaker_a"] = 10
	breaker.properties["circuit_id"] = 0

	# Surcharge : 2500W sur un 10A (2300W max)
	for i in range(5):
		var s = g.add_node("socket", "electricity", Vector3(float(i), 0, 0), "S%d" % i)
		s.properties["circuit_id"] = 0
		s.properties["power_w"] = 500.0
		g.add_edge("cable", "electricity", breaker.id, s.id, {"length_m": 3.0, "section_mm2": 1.5})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0 or report.warnings.size() > 0, "surcharge détectée")


func test_detect_too_many_sockets() -> void:
	var sim = ElectricitySimulator.new()
	var g = SimulationGraph.new()
	var breaker = g.add_node("breaker", "electricity", Vector3.ZERO, "Disj16A")
	breaker.properties["breaker_a"] = 16
	breaker.properties["circuit_id"] = 0

	# 10 prises (max 8)
	for i in range(10):
		var s = g.add_node("socket", "electricity", Vector3(float(i), 0, 0), "S%d" % i)
		s.properties["circuit_id"] = 0
		s.properties["power_w"] = 100.0
		g.add_edge("cable", "electricity", breaker.id, s.id, {"length_m": 3.0, "section_mm2": 2.5})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "trop de prises détecté")


func test_metrics() -> void:
	var sim = ElectricitySimulator.new()
	var g = _make_graph_with_circuit()
	var report = sim.simulate(g)
	assert_not_null(report.get_metric("total_circuits"), "métrique circuits")
	assert_not_null(report.get_metric("total_elements"), "métrique éléments")
