extends "res://tests/test_base.gd"

## Tests SurveillanceSimulator

func _make_surveillance_graph() -> SimulationGraph:
	var g = SimulationGraph.new()
	var nvr = g.add_node("nvr", "surveillance", Vector3.ZERO, "NVR 16ch")
	nvr.properties["max_channels"] = 16
	nvr.properties["storage_tb"] = 4.0

	for i in range(4):
		var cam = g.add_node("camera", "surveillance", Vector3(float(i + 1) * 3, 2.8, 0), "Cam %d" % i)
		cam.properties["resolution"] = "1080p"
		cam.properties["fov_degrees"] = 110.0
		cam.properties["height_m"] = 2.8
		cam.properties["power_w"] = 15.0
		cam.properties["zone_id"] = "zone_%d" % i
		cam.properties["infrared"] = true
		cam.properties["ir_range_m"] = 20.0

		g.add_edge("cable", "surveillance", nvr.id, cam.id, {
			"length_m": float(i + 1) * 8.0, "poe": true,
		})

	return g


func test_simulate_valid() -> void:
	var sim = SurveillanceSimulator.new()
	var g = _make_surveillance_graph()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.network, "surveillance")


func test_simulate_empty() -> void:
	var sim = SurveillanceSimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_cameras"), 0)


func test_detect_no_nvr() -> void:
	var sim = SurveillanceSimulator.new()
	var g = SimulationGraph.new()
	var cam = g.add_node("camera", "surveillance", Vector3.ZERO, "Cam")
	cam.properties["resolution"] = "1080p"
	cam.properties["power_w"] = 15.0

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "pas de NVR détecté")


func test_detect_cable_too_long() -> void:
	var sim = SurveillanceSimulator.new()
	var g = SimulationGraph.new()
	var nvr = g.add_node("nvr", "surveillance", Vector3.ZERO, "NVR")
	nvr.properties["max_channels"] = 16
	var cam = g.add_node("camera", "surveillance", Vector3(100, 0, 0), "Cam")
	cam.properties["resolution"] = "1080p"
	cam.properties["power_w"] = 15.0

	g.add_edge("cable", "surveillance", nvr.id, cam.id, {"length_m": 95.0, "poe": true})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "câble trop long détecté")


func test_metrics() -> void:
	var sim = SurveillanceSimulator.new()
	var g = _make_surveillance_graph()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_cameras"), 4)
	assert_gt(report.get_metric("total_bandwidth_mbps"), 0.0, "bande passante > 0")
	assert_gt(report.get_metric("total_poe_power_w"), 0.0, "puissance PoE > 0")
