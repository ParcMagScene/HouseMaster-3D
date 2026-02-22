extends "res://tests/test_base.gd"

## Tests SimulationGraph

func _make_graph() -> SimulationGraph:
	var g = SimulationGraph.new()
	return g


func test_create_graph() -> void:
	var g = _make_graph()
	assert_not_null(g, "Graph créé")
	assert_equal(g.get_nodes_by_network("electricity").size(), 0, "pas de noeuds")


func test_add_remove_node() -> void:
	var g = _make_graph()
	var n1 = g.add_node("socket", "electricity", Vector3.ZERO, "Prise 1")
	var n2 = g.add_node("panel", "electricity", Vector3(1, 0, 0), "Tableau")
	assert_not_null(n1)
	assert_not_null(n2)
	assert_equal(g.get_nodes_by_network("electricity").size(), 2, "2 noeuds")

	g.remove_node(n1.id)
	assert_equal(g.get_nodes_by_network("electricity").size(), 1, "1 noeud après suppression")


func test_add_remove_edge() -> void:
	var g = _make_graph()
	var n1 = g.add_node("socket", "electricity", Vector3.ZERO, "N1")
	var n2 = g.add_node("panel", "electricity", Vector3(5, 0, 0), "N2")
	var edge = g.add_edge("cable", "electricity", n1.id, n2.id, {"length_m": 5.0})
	assert_not_null(edge)
	assert_equal(g.get_edges_by_network("electricity").size(), 1, "1 arête")

	g.remove_edge(edge.id)
	assert_equal(g.get_edges_by_network("electricity").size(), 0, "0 arête après suppression")


func test_get_neighbors() -> void:
	var g = _make_graph()
	var n1 = g.add_node("a", "net", Vector3.ZERO)
	var n2 = g.add_node("b", "net", Vector3(1, 0, 0))
	var n3 = g.add_node("c", "net", Vector3(2, 0, 0))
	g.add_edge("link", "net", n1.id, n2.id)
	g.add_edge("link", "net", n1.id, n3.id)
	var neighbors = g.get_neighbors(n1.id)
	assert_equal(neighbors.size(), 2, "2 voisins de n1")


func test_find_path() -> void:
	var g = _make_graph()
	var n1 = g.add_node("a", "net", Vector3.ZERO)
	var n2 = g.add_node("b", "net", Vector3(1, 0, 0))
	var n3 = g.add_node("c", "net", Vector3(2, 0, 0))
	g.add_edge("link", "net", n1.id, n2.id)
	g.add_edge("link", "net", n2.id, n3.id)
	var path = g.find_path(n1.id, n3.id)
	assert_true(path.size() >= 2, "chemin trouvé n1->n3")
	assert_equal(path[0], n1.id, "part de n1")


func test_connected_components() -> void:
	var g = _make_graph()
	var n1 = g.add_node("a", "net", Vector3.ZERO)
	var n2 = g.add_node("b", "net", Vector3(1, 0, 0))
	var n3 = g.add_node("c", "net", Vector3(5, 0, 0))
	g.add_edge("link", "net", n1.id, n2.id)
	# n3 est isolé
	var comps = g.get_connected_components("net")
	assert_equal(comps.size(), 2, "2 composantes")


func test_total_edge_length() -> void:
	var g = _make_graph()
	var n1 = g.add_node("a", "net", Vector3.ZERO)
	var n2 = g.add_node("b", "net", Vector3(1, 0, 0))
	g.add_edge("link", "net", n1.id, n2.id, {"length_m": 3.0})
	g.add_edge("link", "net", n1.id, n2.id, {"length_m": 7.0})
	var total = g.get_total_edge_length("net")
	assert_equal(total, 10.0, "longueur totale 10m")


func test_graph_serialization() -> void:
	var g = _make_graph()
	var n1 = g.add_node("socket", "elec", Vector3.ZERO, "S1")
	var n2 = g.add_node("panel", "elec", Vector3(3, 0, 0), "P1")
	g.add_edge("cable", "elec", n1.id, n2.id, {"length_m": 3.0})

	var data = g.to_dict()
	assert_dict_has_key(data, "nodes")
	assert_dict_has_key(data, "edges")

	var g2 = SimulationGraph.new()
	g2.from_dict(data)
	assert_equal(g2.get_nodes_by_network("elec").size(), 2, "2 noeuds restaurés")
	assert_equal(g2.get_edges_by_network("elec").size(), 1, "1 arête restaurée")


func test_clear() -> void:
	var g = _make_graph()
	g.add_node("a", "net", Vector3.ZERO)
	g.add_node("b", "net", Vector3(1, 0, 0))
	g.clear()
	assert_equal(g.get_nodes_by_network("net").size(), 0, "vide après clear")
