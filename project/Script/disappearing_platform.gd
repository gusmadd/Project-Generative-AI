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
var platform_sprite_scale: Vector2


func _ready() -> void:
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
	_disappear_after_delay()


func _create_flash_tween(duration: float) -> Tween:
	var flashing := create_tween().set_loops()
	flashing.tween_property(platform_sprite, "modulate:a", flash_opacity, duration)
	flashing.tween_property(platform_sprite, "modulate:a", 1.0, duration)
	return flashing


func _disappear_after_delay() -> void:
	await get_tree().create_timer(disappear_delay).timeout
	if not is_inside_tree():
		return

	platform_collision.set_deferred("disabled", true)
	trigger.set_deferred("monitoring", false)
	warning_tween.kill()

	var vanish := create_tween().set_parallel(true)
	vanish.tween_property(platform_sprite, "modulate:a", 0.0, fade_duration)
	vanish.tween_property(
		platform_sprite,
		"scale:y",
		platform_sprite.scale.y * 0.7,
		fade_duration
	)
	await vanish.finished

	await get_tree().create_timer(respawn_delay).timeout
	if not is_inside_tree():
		return

	platform_sprite.modulate.a = 1.0
	platform_sprite.scale = platform_sprite_scale
	platform_collision.set_deferred("disabled", false)
	trigger.set_deferred("monitoring", true)
	triggered = false
	warning_tween = _create_flash_tween(idle_flash_duration)
