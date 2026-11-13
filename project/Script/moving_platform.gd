extends AnimatableBody2D

enum StartDirection { RIGHT, LEFT }

@export var travel_distance: float = 200.0
@export var move_speed: float = 100.0
@export var start_direction: StartDirection = StartDirection.RIGHT

var start_position: Vector2


func _ready() -> void:
	start_position = global_position
	sync_to_physics = true

	var direction_sign := 1.0 if start_direction == StartDirection.RIGHT else -1.0
	var end_position_x := start_position.x + travel_distance * direction_sign
	var half_trip_duration := travel_distance / move_speed
	var movement := create_tween().set_loops()
	movement.tween_property(
		self,
		"global_position:x",
		end_position_x,
		half_trip_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement.tween_property(
		self,
		"global_position:x",
		start_position.x,
		half_trip_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
