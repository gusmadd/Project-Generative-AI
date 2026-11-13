extends StaticBody2D

const IDLE_ANIMATION: StringName = &"Idle"
const TRIGGER_ANIMATION: StringName = &"Trigger"

@export_range(100.0, 1200.0, 10.0, "suffix:px/s") var trampoline_velocity: float = 700.0

@onready var phi_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if not phi_sprite.sprite_frames.has_animation(IDLE_ANIMATION):
		push_error("PHI AnimatedSprite2D needs an 'Idle' animation.")
	if not phi_sprite.sprite_frames.has_animation(TRIGGER_ANIMATION):
		push_error("PHI AnimatedSprite2D needs a 'Trigger' animation.")

	phi_sprite.animation_finished.connect(_on_animation_finished)
	phi_sprite.play(IDLE_ANIMATION)


func activate_from_player(body: Node2D) -> void:
	if not body is CharacterBody2D or not body.has_method("bounce_from_phi"):
		return

	var player := body as CharacterBody2D
	for collision_index in player.get_slide_collision_count():
		var collision := player.get_slide_collision(collision_index)
		if collision.get_collider() != self or collision.get_normal().y > -0.5:
			continue

		player.call("bounce_from_phi", trampoline_velocity)
		phi_sprite.play(TRIGGER_ANIMATION)
		return


func _on_animation_finished() -> void:
	if phi_sprite.animation == TRIGGER_ANIMATION:
		phi_sprite.play(IDLE_ANIMATION)
