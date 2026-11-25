extends CharacterBody2D

signal spawn_intro_finished
signal player_died

@export var horizontal_speed: float = 250.0
@export var jump_velocity: float = -405.0
@export var double_jump_velocity: float = -405.0
@export var gravity: float = 1100.0
@export var fall_death_y: float = 1000.0
@export var slash_texture: Texture2D = preload("res://Asset/Karakter/Efek partikel slash lompat.png")
@export var slash_offset_y: float = 28.0
@export var slash_amount: int = 25
@export var slash_lifetime: float = 0.4
@export var slash_speed_min: float = 120.0
@export var slash_speed_max: float = 230.0
@export var slash_curl: float = 260.0
@export var slash_scale_min: float = 0.01
@export var slash_scale_max: float = 0.03

@onready var character_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ufo: Sprite2D = $"../UFO"

var spawn_position: Vector2
var jumps_used: int = 0
var dead: bool = false
var pending_direction: int = 0
var spawn_intro_active: bool = true
var spawn_fall_active: bool = false
var character_scale: Vector2
var character_position: Vector2
var jump_slash_particles: CPUParticles2D
var breath_countdown: float = 1.0
var narrative_active: bool = false
var skip_respawn_on_death: bool = false


func _ready() -> void:
	add_to_group("player")
	_setup_jump_slash()
	spawn_position = global_position
	character_scale = character_sprite.scale
	character_position = character_sprite.position
	character_sprite.play("Idle")
	character_sprite.animation_finished.connect(_on_animation_finished)
	character_sprite.visible = false
	character_sprite.scale = Vector2.ZERO
	ufo.visible = false
	call_deferred("_play_spawn_intro")


func _unhandled_input(event: InputEvent) -> void:
	if dead or spawn_intro_active or narrative_active or not (event is InputEventKey):
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
	if dead or narrative_active or (spawn_intro_active and not spawn_fall_active):
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
			AudioManager.play_sfx("landing")
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

	_update_idle_breath(delta)

	if global_position.y > fall_death_y:
		die("fall")


func _update_idle_breath(delta: float) -> void:
	var idle_now := is_on_floor() and absf(velocity.x) < 1.0 and pending_direction == 0
	if not idle_now or dead:
		breath_countdown = 1.0
		return

	breath_countdown -= delta
	if breath_countdown <= 0.0:
		AudioManager.play_sfx("breath_idle")
		breath_countdown = 1.0 + AudioManager.get_sfx_length("breath_idle")


func _play_spawn_intro() -> void:
	while SceneTransition.transitioning:
		await get_tree().process_frame
	await ufo.call("play_arrival", spawn_position)

	await get_tree().create_timer(0.4).timeout
	character_sprite.visible = true
	AudioManager.play_sfx("spawn")
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
	spawn_intro_finished.emit()


func die_silent() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	breath_countdown = 1.0
	character_sprite.play("Death")
	player_died.emit()


func restore_after_cancelled_death() -> void:
	dead = false
	skip_respawn_on_death = false
	velocity = Vector2.ZERO
	character_sprite.play("Idle")


func _setup_jump_slash() -> void:
	jump_slash_particles = CPUParticles2D.new()
	jump_slash_particles.name = "JumpSlashParticles"
	jump_slash_particles.texture = slash_texture
	jump_slash_particles.position = Vector2(0.0, slash_offset_y)
	jump_slash_particles.z_index = 2
	jump_slash_particles.amount = slash_amount
	jump_slash_particles.lifetime = slash_lifetime
	jump_slash_particles.lifetime_randomness = 0.2
	jump_slash_particles.one_shot = true
	jump_slash_particles.emitting = false
	jump_slash_particles.explosiveness = 0.7
	jump_slash_particles.local_coords = false
	jump_slash_particles.spread = 42.0
	jump_slash_particles.gravity = Vector2(0.0, 320.0)
	jump_slash_particles.initial_velocity_min = slash_speed_min
	jump_slash_particles.initial_velocity_max = slash_speed_max
	jump_slash_particles.scale_amount_min = slash_scale_min
	jump_slash_particles.scale_amount_max = slash_scale_max
	jump_slash_particles.angular_velocity_min = -90.0
	jump_slash_particles.angular_velocity_max = 90.0
	add_child(jump_slash_particles)


func _emit_jump_slash(direction: int) -> void:
	if jump_slash_particles == null:
		return

	var curl_sign := 1.0 if direction < 0 else -1.0
	jump_slash_particles.direction = Vector2(-float(direction), 0.18).normalized()
	jump_slash_particles.tangential_accel_min = slash_curl * 0.6 * curl_sign
	jump_slash_particles.tangential_accel_max = slash_curl * 1.2 * curl_sign

	if direction < 0:
		jump_slash_particles.angle_min = -60.0
		jump_slash_particles.angle_max = -20.0
	else:
		jump_slash_particles.angle_min = 120.0
		jump_slash_particles.angle_max = 160.0

	jump_slash_particles.position = Vector2(0.0, slash_offset_y)
	jump_slash_particles.restart()


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
	AudioManager.play_sfx("jump" if jumps_used == 1 else "double_jump")
	_emit_jump_slash(direction)


func die(reason: String = "fall") -> void:
	if dead:
		return

	dead = true
	velocity = Vector2.ZERO
	breath_countdown = 1.0
	character_sprite.play("Death")
	player_died.emit()
	match reason:
		"enemy":
			AudioManager.play_sfx("death_enemy")
		"blade":
			AudioManager.play_sfx("death_blade")
		_:
			AudioManager.play_sfx("death_fall")


func activate_checkpoint(checkpoint_position: Vector2) -> bool:
	if dead or spawn_intro_active:
		return false

	spawn_position = checkpoint_position
	return true


func bounce_from_phi(bounce_velocity: float) -> void:
	if dead or spawn_intro_active:
		return

	velocity.y = -absf(bounce_velocity)
	jumps_used = 0
	pending_direction = 0
	character_sprite.play("Jump")
	_emit_jump_slash(1 if velocity.x >= 0.0 else -1)


func bounce_from_enemy(bounce_velocity: float) -> void:
	if dead:
		return

	velocity.y = -absf(bounce_velocity)
	jumps_used = 0
	pending_direction = 0
	character_sprite.play("Jump")
	_emit_jump_slash(1 if velocity.x >= 0.0 else -1)


func _on_animation_finished() -> void:
	if not dead:
		return
	if skip_respawn_on_death:
		skip_respawn_on_death = false
		return

	global_position = spawn_position
	velocity = Vector2.ZERO
	jumps_used = 0
	pending_direction = 0
	breath_countdown = 1.0
	dead = false
	character_sprite.play("Idle")
	AudioManager.play_sfx("spawn")
	_reset_level_objects_after_respawn()


func _reset_level_objects_after_respawn() -> void:
	for resettable in get_tree().get_nodes_in_group("reset_on_player_respawn"):
		if resettable.has_method("reset_after_player_respawn"):
			resettable.call("reset_after_player_respawn")
