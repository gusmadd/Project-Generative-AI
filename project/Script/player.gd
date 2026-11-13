extends CharacterBody2D

@export var horizontal_speed: float = 250.0
@export var jump_velocity: float = -405.0
@export var double_jump_velocity: float = -405.0
@export var gravity: float = 1100.0
@export var fall_death_y: float = 1000.0

@onready var character_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ufo: Node = $"../UFO"

var spawn_position: Vector2
var jumps_used: int = 0
var dead: bool = false
var pending_direction: int = 0
var spawn_intro_active: bool = true
var spawn_fall_active: bool = false
var character_scale: Vector2
var character_position: Vector2


func _ready() -> void:
	spawn_position = global_position
	character_scale = character_sprite.scale
	character_position = character_sprite.position
	character_sprite.play("Idle")
	character_sprite.animation_finished.connect(_on_animation_finished)
	character_sprite.visible = false
	character_sprite.scale = Vector2.ZERO
	call_deferred("_play_spawn_intro")


func _unhandled_input(event: InputEvent) -> void:
	if dead or spawn_intro_active or not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var direction := 0
	match key_event.keycode:
		KEY_A, KEY_LEFT:
			direction = -1
		KEY_D, KEY_RIGHT:
			direction = 1

	if direction != 0:
		pending_direction = direction


func _physics_process(delta: float) -> void:
	if dead or (spawn_intro_active and not spawn_fall_active):
		return

	var was_on_floor := is_on_floor()
	if not was_on_floor:
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	var incoming_velocity_y := velocity.y
	move_and_slide()

	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider()
		if collider is Node and collider.has_method("handle_player_collision"):
			collider.call("handle_player_collision", self, collision, incoming_velocity_y)
		if collider is Node and collider.has_method("activate_from_player"):
			collider.call("activate_from_player", self)

	if dead:
		return

	if is_on_floor():
		if not was_on_floor:
			velocity.x = 0.0
		jumps_used = 0

	if pending_direction != 0:
		_jump(pending_direction)
		pending_direction = 0

	if velocity.y < 0.0:
		if character_sprite.animation != "Jump":
			character_sprite.play("Jump")
	elif is_on_floor():
		if character_sprite.animation != "Idle":
			character_sprite.play("Idle")
	elif character_sprite.animation != "Jump":
		character_sprite.play("Jump")

	if global_position.y > fall_death_y:
		die()


func _play_spawn_intro() -> void:
	await ufo.call("play_arrival", spawn_position)

	await get_tree().create_timer(0.4).timeout
	character_sprite.visible = true
	var character_appear := create_tween()
	character_appear.tween_property(
		character_sprite, "scale", character_scale, 0.8
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await character_appear.finished

	var character_float := create_tween()
	character_float.tween_property(
		character_sprite, "position:y", character_position.y - 5.0, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character_float.parallel().tween_property(
		character_sprite, "rotation_degrees", -1.5, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character_float.tween_property(
		character_sprite, "position:y", character_position.y, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character_float.parallel().tween_property(
		character_sprite, "rotation_degrees", 0.0, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await character_float.finished

	spawn_fall_active = true
	await ufo.call("play_departure", spawn_position)

	spawn_intro_active = false
	spawn_fall_active = false


func _jump(direction: int) -> void:
	if is_on_floor():
		jumps_used = 0

	if jumps_used >= 2:
		velocity.x = direction * horizontal_speed
		character_sprite.flip_h = direction < 0
		return

	jumps_used += 1
	velocity.x = direction * horizontal_speed
	velocity.y = jump_velocity if jumps_used == 1 else double_jump_velocity
	character_sprite.flip_h = direction < 0
	character_sprite.play("Jump")


func die() -> void:
	if dead:
		return

	dead = true
	velocity = Vector2.ZERO
	character_sprite.play("Death")


func bounce_from_phi(bounce_velocity: float) -> void:
	if dead or spawn_intro_active:
		return

	velocity.y = -absf(bounce_velocity)
	jumps_used = 0
	pending_direction = 0
	character_sprite.play("Jump")


func bounce_from_enemy(bounce_velocity: float) -> void:
	if dead:
		return

	velocity.y = -absf(bounce_velocity)
	jumps_used = 0
	pending_direction = 0
	character_sprite.play("Jump")


func _on_animation_finished() -> void:
	if not dead:
		return

	global_position = spawn_position
	velocity = Vector2.ZERO
	jumps_used = 0
	pending_direction = 0
	dead = false
	character_sprite.play("Idle")
