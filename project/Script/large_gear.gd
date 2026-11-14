extends AnimatedSprite2D

@export_range(-1000.0, 1000.0, 1.0, "suffix:px") var left_limit_x: float = -243.76
@export_range(-1000.0, 1000.0, 1.0, "suffix:px") var right_limit_x: float = 56.24
@export_range(1.0, 1000.0, 1.0, "suffix:px/s") var move_speed: float = 120.0

@onready var hazard_area: Area2D = $HazardArea


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if left_limit_x >= right_limit_x:
		push_error("Large gear left_limit_x must be less than right_limit_x.")
		return

	hazard_area.body_entered.connect(_on_body_entered)

	position.x = left_limit_x

	var movement := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_loops()
	var travel_duration := (right_limit_x - left_limit_x) / move_speed
	movement.tween_property(self, "position:x", right_limit_x, travel_duration)
	movement.tween_property(self, "position:x", left_limit_x, travel_duration)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.call("die")
