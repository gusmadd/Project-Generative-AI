extends StaticBody2D

@export var disappear_delay: float = 1.5
@export var flash_opacity: float = 0.4
@export var idle_flash_duration: float = 0.8
@export var flash_duration: float = 0.12
@export var fade_duration: float = 0.3
@export var respawn_delay: float = 3.0

@onready var platform_sprite: Sprite2D = $Sprite2D
@onready var platform_collision: CollisionShape2D = $CollisionShape2D
@onready var trigger: Area2D = $Trigger

var triggered: bool = false
var warning_tween: Tween
var vanish_tween: Tween
var platform_sprite_scale: Vector2
var reset_generation: int = 0


func _ready() -> void:
	add_to_group("reset_on_player_respawn")
	platform_sprite_scale = platform_sprite.scale
	trigger.body_entered.connect(_on_trigger_body_entered)
	warning_tween = _create_flash_tween(idle_flash_duration)


func _on_trigger_body_entered(body: Node2D) -> void:
	activate_from_player(body)


func activate_from_player(body: Node2D) -> void:
	if triggered or not body is CharacterBody2D:
		return

	triggered = true
	warning_tween.kill()
	warning_tween = _create_flash_tween(flash_duration)
	var generation := reset_generation
	get_tree().create_timer(disappear_delay).timeout.connect(
		_on_disappear_delay_timeout.bind(generation),
		CONNECT_ONE_SHOT
	)


func _create_flash_tween(duration: float) -> Tween:
	var flashing := create_tween().set_loops()
	flashing.tween_property(platform_sprite, "modulate:a", flash_opacity, duration)
	flashing.tween_property(platform_sprite, "modulate:a", 1.0, duration)
	return flashing


func _on_disappear_delay_timeout(generation: int) -> void:
	if not _is_current_activation(generation):
		return

	platform_collision.set_deferred("disabled", true)
	trigger.set_deferred("monitoring", false)
	warning_tween.kill()

	vanish_tween = create_tween().set_parallel(true)
	vanish_tween.tween_property(platform_sprite, "modulate:a", 0.0, fade_duration)
	vanish_tween.tween_property(
		platform_sprite,
		"scale:y",
		platform_sprite.scale.y * 0.7,
		fade_duration
	)
	vanish_tween.finished.connect(
		_on_vanish_finished.bind(generation),
		CONNECT_ONE_SHOT
	)


func _on_vanish_finished(generation: int) -> void:
	if not _is_current_activation(generation):
		return

	get_tree().create_timer(respawn_delay).timeout.connect(
		_on_respawn_delay_timeout.bind(generation),
		CONNECT_ONE_SHOT
	)


func _on_respawn_delay_timeout(generation: int) -> void:
	if not _is_current_activation(generation):
		return

	_reset_platform()


func reset_after_player_respawn() -> void:
	_reset_platform()


func _reset_platform() -> void:
	reset_generation += 1
	if warning_tween != null and warning_tween.is_running():
		warning_tween.kill()
	if vanish_tween != null and vanish_tween.is_running():
		vanish_tween.kill()

	platform_sprite.modulate.a = 1.0
	platform_sprite.scale = platform_sprite_scale
	platform_collision.set_deferred("disabled", false)
	trigger.set_deferred("monitoring", true)
	triggered = false
	warning_tween = _create_flash_tween(idle_flash_duration)


func _is_current_activation(generation: int) -> bool:
	return is_inside_tree() and triggered and generation == reset_generation
