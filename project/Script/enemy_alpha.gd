extends CharacterBody2D

@export_range(0.0, 1000.0, 1.0, "suffix:px") var left_distance: float = 150.0
@export_range(0.0, 1000.0, 1.0, "suffix:px") var right_distance: float = 150.0
@export_range(0.0, 500.0, 1.0, "suffix:px/s") var move_speed: float = 80.0
@export_range(0.0, 3000.0, 1.0, "suffix:px/s²") var gravity: float = 1100.0
@export_range(0.0, 1000.0, 1.0, "suffix:px/s") var stomp_bounce_velocity: float = 350.0

@onready var enemy_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_collision: CollisionShape2D = $CollisionShape2D

var start_position: Vector2
var start_x: float
var direction: int = -1
var dead: bool = false
var idle_animation: StringName
var death_animation: StringName


func _ready() -> void:
	add_to_group("reset_on_player_respawn")
	start_position = global_position
	start_x = start_position.x
	idle_animation = _find_animation(["Idle", "idle", "default", "Ngesot"])
	death_animation = _find_animation(["Death", "death", "Mati", "mati"])

	if idle_animation == &"":
		push_error("Enemy Alpha AnimatedSprite2D needs an Idle or default animation.")
	else:
		enemy_sprite.play(idle_animation)

	if death_animation == &"":
		push_error("Enemy Alpha AnimatedSprite2D needs a Death or Mati animation.")

	enemy_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = direction * move_speed
	move_and_slide()

	var left_limit := start_x - left_distance
	var right_limit := start_x + right_distance
	if is_on_wall() or global_position.x <= left_limit or global_position.x >= right_limit:
		direction *= -1
		global_position.x = clampf(global_position.x, left_limit, right_limit)

	if move_speed > 0.0:
		enemy_sprite.flip_h = direction > 0


func handle_player_collision(
	player: CharacterBody2D,
	collision: KinematicCollision2D,
	incoming_velocity_y: float
) -> void:
	if dead or not player.has_method("die"):
		return

	if incoming_velocity_y > 0.0 and collision.get_normal().y < -0.5:
		player.call("bounce_from_enemy", stomp_bounce_velocity)
		AudioManager.play_sfx("stomp")
		_die()
	else:
		player.call("die", "enemy")


func _die() -> void:
	if dead:
		return

	dead = true
	velocity = Vector2.ZERO
	enemy_collision.set_deferred("disabled", true)

	if death_animation == &"":
		visible = false
		return

	enemy_sprite.play(death_animation)


func _find_animation(animation_names: Array[String]) -> StringName:
	for animation_name in animation_names:
		if enemy_sprite.sprite_frames.has_animation(animation_name):
			return StringName(animation_name)
	return &""


func _on_animation_finished() -> void:
	if dead and enemy_sprite.animation == death_animation:
		visible = false


func reset_after_player_respawn() -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	direction = -1
	dead = false
	visible = true
	enemy_sprite.flip_h = false
	enemy_collision.set_deferred("disabled", false)
	if idle_animation != &"":
		enemy_sprite.play(idle_animation)
