extends "res://tests/test_base.gd"

## Tests SimulationNode

func test_create_node() -> void:
	var node = SimulationNode.new()
	assert_not_null(node, "SimulationNode créé")
	assert_equal(node.id, -1, "id par défaut")
	assert_equal(node.node_type, "", "type par défaut vide")
	node.queue_free()


func test_node_properties() -> void:
	var node = SimulationNode.new()
	node.id = 1
	node.node_type = "socket"
	node.network = "electricity"
	node.label = "Prise séjour"
	node.position = Vector3(1, 2, 3)
	node.properties["power_w"] = 3680
	assert_equal(node.id, 1)
	assert_equal(node.node_type, "socket")
	assert_equal(node.network, "electricity")
	assert_equal(node.label, "Prise séjour")
	assert_equal(node.position, Vector3(1, 2, 3))
	assert_equal(node.properties["power_w"], 3680)
	node.queue_free()


func test_node_edges() -> void:
	var node = SimulationNode.new()
	node.add_edge_in(10)
	node.add_edge_in(20)
	node.add_edge_out(30)
	assert_array_size(node.edges_in, 2, "2 edges in")
	assert_array_size(node.edges_out, 1, "1 edge out")
	node.remove_edge(10)
	assert_array_size(node.edges_in, 1, "1 edge in après remove")
	node.queue_free()


func test_node_serialization() -> void:
	var node = SimulationNode.new()
	node.id = 42
	node.node_type = "switch"
	node.network = "network"
	node.label = "Switch 1"
	node.position = Vector3(5, 0, 3)
	node.properties["ports"] = 24
	var data = node.to_dict()
	assert_dict_has_key(data, "id")
	assert_dict_has_key(data, "node_type")
	assert_dict_has_key(data, "network")
	assert_dict_has_key(data, "label")
	assert_equal(data["id"], 42)
	assert_equal(data["node_type"], "switch")
	node.queue_free()

	var restored = SimulationNode.from_dict(data)
	assert_equal(restored.id, 42)
	assert_equal(restored.node_type, "switch")
	assert_equal(restored.network, "network")
	assert_equal(restored.label, "Switch 1")
	restored.queue_free()
