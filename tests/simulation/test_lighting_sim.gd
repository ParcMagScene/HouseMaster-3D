extends "res://tests/test_base.gd"

## Tests LightingSimulator

func _make_lighting_graph() -> SimulationGraph:
	var g = SimulationGraph.new()

	var light1 = g.add_node("light", "lighting", Vector3(2, 2.5, 2), "Plafonnier Séjour")
	light1.properties["power_w"] = 20.0
	light1.properties["luminous_flux_lm"] = 2000.0
	light1.properties["light_type"] = "led"
	light1.properties["color_temp_k"] = 4000
	light1.properties["beam_angle_deg"] = 120.0
	light1.properties["room_id"] = "sejour"
	light1.properties["room_type"] = "living_room"
	light1.properties["room_area_m2"] = 25.0
	light1.properties["circuit_id"] = 0
	light1.properties["ip_rating"] = "IP20"

	var light2 = g.add_node("light", "lighting", Vector3(4, 2.5, 2), "Spot Séjour")
	light2.properties["power_w"] = 7.0
	light2.properties["luminous_flux_lm"] = 700.0
	light2.properties["light_type"] = "led"
	light2.properties["circuit_id"] = 0
	light2.properties["room_id"] = "sejour"
	light2.properties["room_type"] = "living_room"
	light2.properties["room_area_m2"] = 25.0

	var sw = g.add_node("switch", "lighting", Vector3(0, 1.2, 0), "Inter Séjour")
	sw.properties["circuit_id"] = 0

	g.add_edge("cable", "lighting", sw.id, light1.id, {
		"length_m": 5.0, "section_mm2": 1.5,
	})
	g.add_edge("cable", "lighting", sw.id, light2.id, {
		"length_m": 7.0, "section_mm2": 1.5,
	})

	return g


func test_simulate_valid() -> void:
	var sim = LightingSimulator.new()
	var g = _make_lighting_graph()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.network, "lighting")


func test_simulate_empty() -> void:
	var sim = LightingSimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_lights"), 0)


func test_detect_too_many_lights() -> void:
	var sim = LightingSimulator.new()
	var g = SimulationGraph.new()

	# 10 luminaires sur 1 circuit (max 8)
	var sw = g.add_node("switch", "lighting", Vector3.ZERO, "Inter")
	for i in range(10):
		var l = g.add_node("light", "lighting", Vector3(float(i), 2.5, 0), "L%d" % i)
		l.properties["power_w"] = 10.0
		l.properties["luminous_flux_lm"] = 1000.0
		l.properties["circuit_id"] = 0
		g.add_edge("cable", "lighting", sw.id, l.id, {"length_m": 3.0, "section_mm2": 1.5})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "trop de luminaires détecté")


func test_detect_section_too_small() -> void:
	var sim = LightingSimulator.new()
	var g = SimulationGraph.new()
	var sw = g.add_node("switch", "lighting", Vector3.ZERO, "Inter")
	var l = g.add_node("light", "lighting", Vector3(3, 2.5, 0), "Luminaire")
	l.properties["power_w"] = 20.0
	l.properties["luminous_flux_lm"] = 2000.0
	l.properties["circuit_id"] = 0

	g.add_edge("cable", "lighting", sw.id, l.id, {"length_m": 5.0, "section_mm2": 0.75})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "section trop petite détectée")


func test_detect_no_switch() -> void:
	var sim = LightingSimulator.new()
	var g = SimulationGraph.new()
	var l = g.add_node("light", "lighting", Vector3.ZERO, "Luminaire")
	l.properties["power_w"] = 20.0
	l.properties["luminous_flux_lm"] = 2000.0

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "pas d'interrupteur détecté")


func test_metrics() -> void:
	var sim = LightingSimulator.new()
	var g = _make_lighting_graph()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_lights"), 2)
	assert_equal(report.get_metric("total_switches"), 1)
	assert_gt(report.get_metric("total_power_w"), 0.0, "puissance > 0")
	assert_gt(report.get_metric("total_flux_lm"), 0.0, "flux > 0")


func test_detect_ip_insufficient() -> void:
	var sim = LightingSimulator.new()
	var g = SimulationGraph.new()
	var sw = g.add_node("switch", "lighting", Vector3.ZERO, "Inter")
	var l = g.add_node("light", "lighting", Vector3(2, 2.5, 0), "Luminaire SDB")
	l.properties["power_w"] = 15.0
	l.properties["luminous_flux_lm"] = 1500.0
	l.properties["circuit_id"] = 0
	l.properties["room_type"] = "bathroom"
	l.properties["ip_rating"] = "IP20"

	g.add_edge("cable", "lighting", sw.id, l.id, {"length_m": 3.0, "section_mm2": 1.5})

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "IP insuffisant en SDB détecté")
