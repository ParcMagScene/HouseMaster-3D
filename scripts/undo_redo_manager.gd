extends Node
class_name UndoRedoManager

## Système Undo / Redo — HouseMaster 3D
## Stack d'actions : { type, target, before, after }

signal ACTION_PERFORMED(action: Dictionary)
signal UNDO_PERFORMED(action: Dictionary)
signal REDO_PERFORMED(action: Dictionary)
signal STACK_CHANGED

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var max_history: int = 100


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			if event.shift_pressed:
				redo()
			else:
				undo()


func perform_action(type: String, target: String, before: Variant, after: Variant) -> void:
	var action := {
		"type": type,
		"target": target,
		"before": before,
		"after": after,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	undo_stack.append(action)
	redo_stack.clear()
	
	if undo_stack.size() > max_history:
		undo_stack.pop_front()
	
	ACTION_PERFORMED.emit(action)
	STACK_CHANGED.emit()


func undo() -> bool:
	if undo_stack.is_empty():
		return false
	
	var action = undo_stack.pop_back()
	redo_stack.append(action)
	
	_apply_state(action["target"], action["before"])
	UNDO_PERFORMED.emit(action)
	STACK_CHANGED.emit()
	return true


func redo() -> bool:
	if redo_stack.is_empty():
		return false
	
	var action = redo_stack.pop_back()
	undo_stack.append(action)
	
	_apply_state(action["target"], action["after"])
	REDO_PERFORMED.emit(action)
	STACK_CHANGED.emit()
	return true


func _apply_state(target_path: String, state: Variant) -> void:
	var node = get_tree().root.get_node_or_null(target_path)
	if node and node.has_method("from_dict") and state is Dictionary:
		node.from_dict(state)
	elif node and state is Dictionary:
		for key in state:
			if key in node:
				node.set(key, state[key])


func can_undo() -> bool:
	return not undo_stack.is_empty()


func can_redo() -> bool:
	return not redo_stack.is_empty()


func get_undo_description() -> String:
	if undo_stack.is_empty():
		return ""
	var action = undo_stack.back()
	return "%s : %s" % [action["type"], action["target"]]


func get_redo_description() -> String:
	if redo_stack.is_empty():
		return ""
	var action = redo_stack.back()
	return "%s : %s" % [action["type"], action["target"]]


func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
	STACK_CHANGED.emit()
