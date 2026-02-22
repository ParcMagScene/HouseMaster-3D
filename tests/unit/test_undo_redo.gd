extends "res://tests/test_base.gd"

## Tests unitaires — UndoRedoManager

const URScript = preload("res://scripts/undo_redo_manager.gd")


func test_undo_redo_has_methods() -> void:
	var ur = URScript.new()
	assert_has_method(ur, "perform_action", "perform_action existe")
	assert_has_method(ur, "undo", "undo existe")
	assert_has_method(ur, "redo", "redo existe")
	assert_has_method(ur, "can_undo", "can_undo existe")
	assert_has_method(ur, "can_redo", "can_redo existe")
	assert_has_method(ur, "clear", "clear existe")
	assert_has_method(ur, "get_undo_description", "get_undo_description existe")
	assert_has_method(ur, "get_redo_description", "get_redo_description existe")
	ur.free()


func test_undo_redo_initial_state() -> void:
	var ur = URScript.new()
	assert_false(ur.can_undo(), "ne peut pas undo initialement")
	assert_false(ur.can_redo(), "ne peut pas redo initialement")
	assert_equal(ur.get_undo_description(), "", "undo description vide")
	assert_equal(ur.get_redo_description(), "", "redo description vide")
	ur.free()


func test_undo_redo_max_history() -> void:
	var ur = URScript.new()
	assert_equal(ur.max_history, 100, "max_history = 100")
	ur.free()


func test_undo_redo_perform_action() -> void:
	var ur = URScript.new()
	var target := {"val": 1}
	ur.perform_action("test_action", func(): target.val = 2, func(): target.val = 1)
	assert_true(ur.can_undo(), "peut undo après perform_action")
	assert_false(ur.can_redo(), "ne peut pas redo après perform_action")
	assert_equal(target.val, 2, "action exécutée")
	ur.free()


func test_undo_redo_undo() -> void:
	var ur = URScript.new()
	var target := {"val": 0}
	ur.perform_action("set_1", func(): target.val = 1, func(): target.val = 0)
	ur.undo()
	assert_equal(target.val, 0, "undo restaure l'état")
	assert_false(ur.can_undo(), "ne peut plus undo")
	assert_true(ur.can_redo(), "peut redo après undo")
	ur.free()


func test_undo_redo_redo() -> void:
	var ur = URScript.new()
	var target := {"val": 0}
	ur.perform_action("set_1", func(): target.val = 1, func(): target.val = 0)
	ur.undo()
	ur.redo()
	assert_equal(target.val, 1, "redo ré-applique l'action")
	assert_true(ur.can_undo(), "peut undo après redo")
	assert_false(ur.can_redo(), "ne peut plus redo")
	ur.free()


func test_undo_redo_clear() -> void:
	var ur = URScript.new()
	var target := {"val": 0}
	ur.perform_action("a1", func(): target.val = 1, func(): target.val = 0)
	ur.perform_action("a2", func(): target.val = 2, func(): target.val = 1)
	ur.clear()
	assert_false(ur.can_undo(), "après clear, ne peut pas undo")
	assert_false(ur.can_redo(), "après clear, ne peut pas redo")
	ur.free()


func test_undo_redo_descriptions() -> void:
	var ur = URScript.new()
	ur.perform_action("Ajouter mur", func(): pass, func(): pass)
	assert_equal(ur.get_undo_description(), "Ajouter mur", "undo description correcte")
	ur.undo()
	assert_equal(ur.get_redo_description(), "Ajouter mur", "redo description correcte")
	ur.free()


func test_undo_redo_signals() -> void:
	var ur = URScript.new()
	assert_true(ur.has_signal("ACTION_PERFORMED"), "signal ACTION_PERFORMED")
	assert_true(ur.has_signal("UNDO_PERFORMED"), "signal UNDO_PERFORMED")
	assert_true(ur.has_signal("REDO_PERFORMED"), "signal REDO_PERFORMED")
	ur.free()


func test_undo_redo_stack_limit() -> void:
	var ur = URScript.new()
	ur.max_history = 5
	var target := {"val": 0}
	for i in range(10):
		var v = i
		ur.perform_action("action_%d" % i, func(): target.val = v, func(): target.val = v - 1)
	var undo_count := 0
	while ur.can_undo():
		ur.undo()
		undo_count += 1
	assert_true(undo_count <= 5, "stack limité à max_history")
	ur.free()
