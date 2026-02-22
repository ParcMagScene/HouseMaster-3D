extends "res://tests/test_base.gd"

## Tests NetworkSimulator

func _make_network_graph() -> SimulationGraph:
	var g = SimulationGraph.new()
	var patch = g.add_node("patch_panel", "network", Vector3.ZERO, "Baie")
	var sw = g.add_node("switch", "network", Vector3(1, 0, 0), "Switch 24p")
	sw.properties["port_count"] = 24

	var ap = g.add_node("wifi_ap", "network", Vector3(5, 2, 3), "AP Salon")
	ap.properties["poe"] = true
	ap.properties["power_w"] = 15.0
	ap.properties["range_m"] = 15.0

	for i in range(4):
		var pt = g.add_node("equipment", "network", Vector3(float(i + 2), 0, 0), "PC %d" % i)
		pt.properties["room_id"] = "room_%d" % i
		g.add_edge("cable", "network", sw.id, pt.id, {
			"length_m": float(i + 2) * 3.0, "cable_type": "cat6",
		})

	g.add_edge("cable", "network", patch.id, sw.id, {"length_m": 1.0, "cable_type": "cat6"})
	g.add_edge("cable", "network", sw.id, ap.id, {"length_m": 8.0, "cable_type": "cat6", "poe": true, "poe_power_w": 15.0})

	return g


func test_simulate_valid() -> void:
	var sim = NetworkSimulator.new()
	var g = _make_network_graph()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.network, "network")


func test_simulate_empty() -> void:
	var sim = NetworkSimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_points"), 0)


func test_detect_cable_too_long() -> void:
	var sim = NetworkSimulator.new()
	var g = SimulationGraph.new()
	var n1 = g.add_node("switch", "network", Vector3.ZERO, "SW")
	n1.properties["port_count"] = 24
	var n2 = g.add_node("equipment", "network", Vector3(100, 0, 0), "PC")
	g.add_edge("cable", "network", n1.id, n2.id, {"length_m": 95.0, "cable_type": "cat6"})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "câble trop long détecté")


func test_detect_bad_category() -> void:
	var sim = NetworkSimulator.new()
	var g = SimulationGraph.new()
	var n1 = g.add_node("switch", "network", Vector3.ZERO, "SW")
	n1.properties["port_count"] = 24
	var n2 = g.add_node("equipment", "network", Vector3(5, 0, 0), "PC")
	g.add_edge("cable", "network", n1.id, n2.id, {"length_m": 10.0, "cable_type": "cat5"})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "catégorie insuffisante détectée")


func test_metrics() -> void:
	var sim = NetworkSimulator.new()
	var g = _make_network_graph()
	var report = sim.simulate(g)
	assert_gt(report.get_metric("total_points"), 0.0, "points > 0")
	assert_gt(report.get_metric("total_switches"), 0.0, "switches > 0")
	assert_gt(report.get_metric("total_wifi_aps"), 0.0, "APs > 0")
