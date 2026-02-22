extends "res://tests/test_base.gd"

## Tests SimulationEdge

func test_create_edge() -> void:
	var edge = SimulationEdge.new()
	assert_not_null(edge, "SimulationEdge créé")
	assert_equal(edge.id, -1, "id par défaut")
	assert_equal(edge.edge_type, "", "type vide")


func test_edge_properties() -> void:
	var edge = SimulationEdge.new()
	edge.id = 1
	edge.edge_type = "cable"
	edge.network = "electricity"
	edge.from_node = 10
	edge.to_node = 20
	edge.properties["length_m"] = 5.0
	edge.properties["section_mm2"] = 2.5
	edge.properties["diameter_mm"] = 16.0
	assert_equal(edge.id, 1)
	assert_equal(edge.get_length(), 5.0, "longueur")
	assert_equal(edge.get_section(), 2.5, "section")
	assert_equal(edge.get_diameter(), 16.0, "diamètre")


func test_edge_default_values() -> void:
	var edge = SimulationEdge.new()
	assert_equal(edge.get_length(), 0.0, "longueur par défaut 0")
	assert_equal(edge.get_section(), 0.0, "section par défaut 0")
	assert_equal(edge.get_diameter(), 0.0, "diamètre par défaut 0")


func test_edge_serialization() -> void:
	var edge = SimulationEdge.new()
	edge.id = 7
	edge.edge_type = "pipe"
	edge.network = "plumbing"
	edge.from_node = 1
	edge.to_node = 2
	edge.properties["length_m"] = 3.5
	edge.properties["diameter_mm"] = 40.0
	var data = edge.to_dict()
	assert_dict_has_key(data, "id")
	assert_dict_has_key(data, "edge_type")
	assert_equal(data["id"], 7)
	assert_equal(data["network"], "plumbing")

	var restored = SimulationEdge.from_dict(data)
	assert_equal(restored.id, 7)
	assert_equal(restored.edge_type, "pipe")
	assert_equal(restored.network, "plumbing")
	assert_equal(restored.from_node, 1)
	assert_equal(restored.to_node, 2)
