extends "res://tests/test_base.gd"

## Tests SimulationReport

func test_create_report() -> void:
	var r = SimulationReport.new("electricity")
	assert_not_null(r, "Report créé")
	assert_equal(r.network, "electricity")
	assert_true(r.valid, "valide par défaut")


func test_add_error() -> void:
	var r = SimulationReport.new("plumbing")
	r.add_error("ERR_01", "Tuyau trop court", 5)
	assert_equal(r.errors.size(), 1, "1 erreur")
	assert_false(r.valid, "invalide après erreur")
	assert_equal(r.errors[0]["code"], "ERR_01")
	assert_equal(r.errors[0]["message"], "Tuyau trop court")
	assert_equal(r.errors[0]["node_id"], 5)


func test_add_warning() -> void:
	var r = SimulationReport.new("network")
	r.add_warning("WARN_01", "Câble proche du max")
	assert_equal(r.warnings.size(), 1, "1 warning")
	assert_true(r.valid, "toujours valide avec un warning")


func test_add_suggestion() -> void:
	var r = SimulationReport.new("domotics")
	r.add_suggestion("SUG_01", "Ajouter un hub")
	assert_equal(r.suggestions.size(), 1, "1 suggestion")


func test_metrics() -> void:
	var r = SimulationReport.new("heating")
	r.set_metric("total_power_w", 5000.0)
	r.set_metric("rooms", 4)
	assert_equal(r.get_metric("total_power_w"), 5000.0)
	assert_equal(r.get_metric("rooms"), 4)
	assert_null(r.get_metric("inexistant"), "null si clé absente")


func test_merge() -> void:
	var r1 = SimulationReport.new("elec")
	r1.add_error("E1", "Erreur 1")
	r1.add_warning("W1", "Warning 1")
	r1.set_metric("power", 100)

	var r2 = SimulationReport.new("elec")
	r2.add_error("E2", "Erreur 2")
	r2.add_suggestion("S1", "Suggestion 1")
	r2.set_metric("cables", 5)

	r1.merge(r2)
	assert_equal(r1.errors.size(), 2, "2 erreurs après merge")
	assert_equal(r1.warnings.size(), 1, "1 warning")
	assert_equal(r1.suggestions.size(), 1, "1 suggestion")
	assert_equal(r1.get_metric("power"), 100)
	assert_equal(r1.get_metric("cables"), 5)


func test_to_dict() -> void:
	var r = SimulationReport.new("net")
	r.add_error("E1", "Test error")
	r.set_metric("total", 42)
	var data = r.to_dict()
	assert_dict_has_key(data, "network")
	assert_dict_has_key(data, "errors")
	assert_dict_has_key(data, "metrics")
	assert_equal(data["network"], "net")
	assert_equal(data["valid"], false)


func test_summary_text() -> void:
	var r = SimulationReport.new("test")
	r.add_error("E1", "Err")
	r.add_warning("W1", "Warn")
	r.add_suggestion("S1", "Sug")
	var text = r.get_summary_text()
	assert_true(text.length() > 0, "résumé non vide")
	assert_true("1 erreur" in text or "erreur" in text.to_lower(), "contient info erreur")
