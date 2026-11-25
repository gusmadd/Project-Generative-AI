extends Area2D

const MENU_SCENE_PATH := "res://Scene/Main Menu.tscn"

var transitioning: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if transitioning or not body is CharacterBody2D or not body.has_method("activate_checkpoint"):
		return

	AudioManager.play_sfx("portal")
	GameManager.complete_current_level()

	var current := get_tree().current_scene
	var is_final_level := (
		current != null
		and (
			current.scene_file_path.ends_with("Level 6.tscn")
			or current.scene_file_path.ends_with("Level 12.tscn")
		)
	)
	if is_final_level or not GameManager.has_next_level():
		GameManager.open_levels_panel_on_menu = true
		if not SceneTransition.change_scene(MENU_SCENE_PATH):
			GameManager.open_levels_panel_on_menu = false
			return
		transitioning = true
		set_deferred("monitoring", false)
		body.set_physics_process(false)
		body.set_process_unhandled_input(false)
		return

	transitioning = true
	set_deferred("monitoring", false)
	call_deferred("_transition_player", body)


func _transition_player(body: CharacterBody2D) -> void:
	body.velocity = Vector2.ZERO
	body.set_physics_process(false)
	body.set_process_unhandled_input(false)

	var character_sprite := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if character_sprite:
		var transition := create_tween().set_parallel(true)
		transition.tween_property(
			body, "global_position", global_position, 1.5
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		transition.tween_property(
			character_sprite, "scale", Vector2.ZERO, 1.5
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		transition.tween_property(character_sprite, "rotation_degrees", 180.0, 1.5)
		await transition.finished

	GameManager.advance_to_next_level()
