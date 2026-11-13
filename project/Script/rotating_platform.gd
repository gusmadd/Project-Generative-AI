extends AnimatableBody2D

enum RotationDirection {
	CLOCKWISE = 1,
	COUNTER_CLOCKWISE = -1,
}

@export var rotation_direction: RotationDirection = RotationDirection.CLOCKWISE
@export var rotation_speed_degrees: float = 90.0


func _ready() -> void:
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	rotation_degrees += rotation_speed_degrees * int(rotation_direction) * delta
