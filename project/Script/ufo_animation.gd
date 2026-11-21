extends Sprite2D

@export var arrival_height: float = 80.0
@export var travel_distance: float = 400.0
@export var arrival_duration: float = 1.5
@export var departure_duration: float = 1.0

var base_scale: Vector2


func _ready() -> void:
	base_scale = scale


func play_arrival(spawn_position: Vector2) -> void:
	AudioManager.play_sfx("ufo_arrival")
	visible = true
	modulate = Color.WHITE
	global_position = spawn_position + Vector2(0, -travel_distance)
	scale = base_scale * Vector2(0.8, 1.2)

	var arrival := create_tween().set_parallel(true)
	arrival.tween_property(
		self,
		"global_position",
		spawn_position + Vector2(0, -arrival_height),
		arrival_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.tween_property(
		self,
		"scale",
		base_scale * Vector2(1.15, 0.85),
		arrival_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await arrival.finished

	var landing := create_tween()
	landing.tween_property(
		self, "scale", base_scale * Vector2(1.25, 0.72), 0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	landing.tween_property(
		self, "scale", base_scale * Vector2(0.88, 1.14), 0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	landing.tween_property(
		self, "scale", base_scale, 0.24
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await landing.finished


func play_departure(spawn_position: Vector2) -> void:
	var departure := create_tween().set_parallel(true)
	departure.tween_property(
		self,
		"global_position",
		spawn_position + Vector2(0, -travel_distance),
		departure_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	departure.tween_property(
		self,
		"scale",
		base_scale * Vector2(0.78, 1.22),
		departure_duration * 0.35
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await departure.finished

	var vanish := create_tween().set_parallel(true)
	vanish.tween_property(
		self, "scale", base_scale * 0.65, 0.25
	)
	vanish.tween_property(
		self, "modulate:a", 0.0, 0.25
	)
	await vanish.finished

	visible = false
	scale = base_scale
	modulate = Color.WHITE
