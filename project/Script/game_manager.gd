extends Node

const LEVEL_SCENES: Array[String] = [
	"res://Scene/Level 1.tscn",
	"res://Scene/Level 2.tscn",
	"res://Scene/Level 3.tscn",
	"res://Scene/Level 4.tscn",
	"res://Scene/Level 5.tscn",
	"res://Scene/Level 6.tscn",
	"res://Scene/Level 7.tscn",
	"res://Scene/Level 8.tscn",
	"res://Scene/Level 9.tscn",
	"res://Scene/Level 10.tscn",
	"res://Scene/Level 11.tscn",
	"res://Scene/Level 12.tscn",
	"res://Scene/Level 13.tscn",
	"res://Scene/Level 14.tscn",
	"res://Scene/Level 15.tscn",
	"res://Scene/Level 16.tscn",
	"res://Scene/Level 17.tscn",
	"res://Scene/Level 18.tscn",
]
const PROGRESS_FILE := "user://progress.cfg"

var highest_unlocked_level: int = 1
var completed_levels: Array[bool] = []


func _ready() -> void:
	completed_levels.resize(LEVEL_SCENES.size())
	completed_levels.fill(false)
	_load_progress()


func get_highest_unlocked_level() -> int:
	return mini(highest_unlocked_level, _get_available_level_count())


func is_level_unlocked(level_number: int) -> bool:
	return (
		level_number >= 1
		and level_number <= get_highest_unlocked_level()
		and _has_level_scene(level_number)
	)


func is_level_complete(level_number: int) -> bool:
	return (
		level_number >= 1
		and level_number <= completed_levels.size()
		and completed_levels[level_number - 1]
	)


func start_highest_unlocked_level() -> bool:
	return start_level(get_highest_unlocked_level())


func start_level(level_number: int) -> bool:
	if not is_level_unlocked(level_number):
		push_warning("Level %d is not unlocked or its scene is not available." % level_number)
		return false

	return _change_to_level(level_number)


func complete_current_level() -> void:
	var current_level := _get_current_level_number()
	if current_level == 0:
		return

	completed_levels[current_level - 1] = true
	var next_level := current_level + 1
	if _has_level_scene(next_level):
		highest_unlocked_level = maxi(highest_unlocked_level, next_level)
	_save_progress()


func has_next_level() -> bool:
	return not _get_next_scene_path().is_empty()


func advance_to_next_level() -> bool:
	var next_scene_path := _get_next_scene_path()
	if next_scene_path.is_empty():
		return false

	return SceneTransition.change_scene(next_scene_path)


func _change_to_level(level_number: int) -> bool:
	var scene_path := LEVEL_SCENES[level_number - 1]
	return SceneTransition.change_scene(scene_path)


func _get_next_scene_path() -> String:
	var current_level := _get_current_level_number()
	if current_level == 0:
		return ""

	var next_level := current_level + 1
	if not _has_level_scene(next_level):
		return ""

	return LEVEL_SCENES[next_level - 1]


func _get_current_level_number() -> int:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return 0

	var current_index := LEVEL_SCENES.find(current_scene.scene_file_path)
	if current_index == -1:
		push_error("Current scene '%s' is not listed in GameManager.LEVEL_SCENES." % current_scene.scene_file_path)
		return 0

	return current_index + 1


func _get_available_level_count() -> int:
	var available_count := 0
	for scene_path in LEVEL_SCENES:
		if not ResourceLoader.exists(scene_path):
			break
		available_count += 1

	return available_count


func _has_level_scene(level_number: int) -> bool:
	return (
		level_number >= 1
		and level_number <= LEVEL_SCENES.size()
		and ResourceLoader.exists(LEVEL_SCENES[level_number - 1])
	)


func _load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(PROGRESS_FILE)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_error("Could not load saved level progress (error %d)." % error)
		return

	highest_unlocked_level = clampi(
		int(config.get_value("progress", "highest_unlocked_level", 1)),
		1,
		LEVEL_SCENES.size()
	)

	var saved_completed: Array = config.get_value("progress", "completed_levels", [])
	for level_index in range(mini(saved_completed.size(), completed_levels.size())):
		completed_levels[level_index] = bool(saved_completed[level_index])


func reset_progress() -> void:
	highest_unlocked_level = 1
	completed_levels.fill(false)
	_save_progress()


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked_level", highest_unlocked_level)
	config.set_value("progress", "completed_levels", completed_levels)
	var error := config.save(PROGRESS_FILE)
	if error != OK:
		push_error("Could not save level progress (error %d)." % error)
