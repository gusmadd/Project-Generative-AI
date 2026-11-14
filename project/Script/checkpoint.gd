extends AnimatedSprite2D

const BEFORE_ANIMATION: StringName = &"Sebelum"
const AFTER_ANIMATION: StringName = &"Sesudah"

@onready var checkpoint_area: Area2D = $CheckpointArea

var activated: bool = false


func _ready() -> void:
	if not sprite_frames.has_animation(BEFORE_ANIMATION):
		push_error("Checkpoint AnimatedSprite2D needs a 'Sebelum' animation.")
		return
	if not sprite_frames.has_animation(AFTER_ANIMATION):
		push_error("Checkpoint AnimatedSprite2D needs a 'Sesudah' animation.")
		return

	play(BEFORE_ANIMATION)
	checkpoint_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if activated or not body.has_method("activate_checkpoint"):
		return
	if not bool(body.call("activate_checkpoint", body.global_position)):
		return

	activated = true
	play(AFTER_ANIMATION)
