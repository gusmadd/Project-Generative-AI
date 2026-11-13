extends Node

const LEVEL_SCENES := [
	"res://Scene/Level 1.tscn",
	"res://Scene/Level 2.tscn",
	"res://Scene/Level 3.tscn",
	"res://Scene/Level 4.tscn",
	"res://Scene/Level 5.tscn",
]


func has_next_level() -> bool:
	return not _get_next_scene_path().is_empty()


func advance_to_next_level() -> bool:
	var next_scene_path := _get_next_scene_path()
	if next_scene_path.is_empty():
		return false

	var error := get_tree().change_scene_to_file(next_scene_path)
	if error != OK:
		push_error("Could not load next level '%s' (error %d)." % [next_scene_path, error])
		return false

	return true


func _get_next_scene_path() -> String:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_error("Cannot determine the next level because there is no current scene.")
		return ""

	var current_index := LEVEL_SCENES.find(current_scene.scene_file_path)
	if current_index == -1:
		push_error("Current scene '%s' is not listed in GameManager.LEVEL_SCENES." % current_scene.scene_file_path)
		return ""

	if current_index + 1 >= LEVEL_SCENES.size():
		return ""

	return LEVEL_SCENES[current_index + 1]
