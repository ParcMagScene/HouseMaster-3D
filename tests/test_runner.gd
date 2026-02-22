extends SceneTree

## Test Runner — HouseMaster 3D
## Lance automatiquement tous les tests unitaires et affiche les résultats
## Usage : godot --headless -s tests/test_runner.gd

var test_scripts := [
	"res://tests/unit/test_house.gd",
	"res://tests/unit/test_room.gd",
	"res://tests/unit/test_wall.gd",
	"res://tests/unit/test_material.gd",
	"res://tests/unit/test_plumbing.gd",
	"res://tests/unit/test_electricity.gd",
	"res://tests/unit/test_network.gd",
	"res://tests/unit/test_domotics.gd",
	"res://tests/unit/test_save_manager.gd",
	"res://tests/unit/test_undo_redo.gd",
	"res://tests/integration/test_full_workflow.gd",
	"res://tests/integration/test_serialization.gd",
	"res://tests/performance/test_performance.gd",
]

var total_passed := 0
var total_failed := 0
var total_skipped := 0
var failed_tests: Array[String] = []


func _init() -> void:
	print("")
	print("╔══════════════════════════════════════════════╗")
	print("║  HouseMaster 3D — Test Runner               ║")
	print("╚══════════════════════════════════════════════╝")
	print("")
	
	for script_path in test_scripts:
		_run_test_script(script_path)
	
	_print_summary()
	quit(1 if total_failed > 0 else 0)


func _run_test_script(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("⏭️  SKIP : %s (fichier introuvable)" % path)
		total_skipped += 1
		return
	
	var script = load(path)
	if not script:
		print("⏭️  SKIP : %s (chargement échoué)" % path)
		total_skipped += 1
		return
	
	var test_instance = script.new()
	if not test_instance.has_method("run_tests"):
		print("⏭️  SKIP : %s (pas de méthode run_tests)" % path)
		total_skipped += 1
		test_instance.free()
		return
	
	print("━━━ %s ━━━" % path.get_file())
	var results: Dictionary = test_instance.run_tests()
	total_passed += results.get("passed", 0)
	total_failed += results.get("failed", 0)
	
	for f in results.get("failures", []):
		failed_tests.append("%s::%s" % [path.get_file(), f])
	
	if test_instance is Node:
		test_instance.queue_free()
	else:
		test_instance.free()


func _print_summary() -> void:
	print("")
	print("╔══════════════════════════════════════════════╗")
	print("║  RÉSULTATS                                   ║")
	print("╠══════════════════════════════════════════════╣")
	print("║  ✅ Passés  : %d" % total_passed)
	print("║  ❌ Échoués : %d" % total_failed)
	print("║  ⏭️  Ignorés : %d" % total_skipped)
	print("╚══════════════════════════════════════════════╝")
	
	if failed_tests.size() > 0:
		print("")
		print("Tests échoués :")
		for t in failed_tests:
			print("  ❌ %s" % t)
	print("")
