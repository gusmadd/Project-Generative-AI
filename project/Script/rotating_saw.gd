@tool
extends Node2D

enum OrbitDirection {
	CLOCKWISE = 1,
	COUNTER_CLOCKWISE = -1,
}

const SAW_FRAME_PATHS := [
	"res://Asset/Gerigi pisau/x_putar_01.png",
	"res://Asset/Gerigi pisau/x_putar_02.png",
	"res://Asset/Gerigi pisau/x_putar_03.png",
	"res://Asset/Gerigi pisau/x_putar_04.png",
	"res://Asset/Gerigi pisau/x_putar_05.png",
	"res://Asset/Gerigi pisau/x_putar_06.png",
	"res://Asset/Gerigi pisau/x_putar_07.png",
	"res://Asset/Gerigi pisau/x_putar_08.png",
	"res://Asset/Gerigi pisau/x_putar_09.png",
	"res://Asset/Gerigi pisau/x_putar_10.png",
	"res://Asset/Gerigi pisau/x_putar_11.png",
	"res://Asset/Gerigi pisau/x_putar_12.png",
]

@export var orbit_direction: OrbitDirection = OrbitDirection.CLOCKWISE
@export_range(0.0, 720.0, 1.0, "suffix:deg/s") var revolution_speed: float = 90.0
@export_range(0.0, 1000.0, 1.0, "suffix:px") var orbit_radius: float = 150.0:
	set(value):
		orbit_radius = value
		queue_redraw()
@export_range(1.0, 100.0, 1.0, "suffix:px") var hitbox_radius: float = 38.0:
	set(value):
		hitbox_radius = value
		_update_hitbox_radius()
		queue_redraw()
@export var show_orbit_path: bool = true
@export_range(1.0, 60.0, 1.0, "suffix:FPS") var animation_speed: float = 12.0

@onready var orbit_guide: Sprite2D = $OrbitGuide
@onready var saw_sprite: AnimatedSprite2D = $SawSprite
@onready var saw_area: Area2D = $SawArea
@onready var saw_collision: CollisionShape2D = $SawArea/CollisionShape2D

var orbit_angle: float = 0.0


func _ready() -> void:
	_update_hitbox_radius()
	_setup_animation()
	_setup_orbit()

	if Engine.is_editor_hint():
		return

	saw_area.body_entered.connect(_on_body_entered)


func _update_hitbox_radius() -> void:
	var collision := get_node_or_null("SawArea/CollisionShape2D") as CollisionShape2D
	if collision == null:
		return

	var circle := collision.shape as CircleShape2D
	if circle == null:
		push_error("Rotating saw CollisionShape2D must use a CircleShape2D.")
		return
	circle.radius = hitbox_radius


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var collision := get_node_or_null("SawArea/CollisionShape2D") as CollisionShape2D
	var collision_offset := collision.position if collision != null else Vector2.ZERO
	var hitbox_center := Vector2(orbit_radius, 0.0) + collision_offset
	draw_circle(hitbox_center, hitbox_radius, Color(1.0, 0.05, 0.25, 0.14))
	draw_arc(
		hitbox_center,
		hitbox_radius,
		0.0,
		TAU,
		48,
		Color(1.0, 0.05, 0.25, 1.0),
		2.0
	)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	orbit_angle += deg_to_rad(revolution_speed * int(orbit_direction) * delta)
	var saw_position := Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
	saw_sprite.position = saw_position
	saw_area.position = saw_position


func _setup_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("Spin")
	frames.set_animation_speed("Spin", animation_speed)
	frames.set_animation_loop("Spin", true)

	for frame_path in SAW_FRAME_PATHS:
		var texture := load(frame_path) as Texture2D
		if texture == null:
			push_error("Could not load rotating saw frame '%s'." % frame_path)
			return
		frames.add_frame("Spin", texture)

	saw_sprite.sprite_frames = frames
	saw_sprite.play("Spin")


func _setup_orbit() -> void:
	saw_sprite.position = Vector2(orbit_radius, 0.0)
	saw_area.position = saw_sprite.position
	orbit_guide.visible = show_orbit_path
	orbit_guide.scale = Vector2.ONE * (orbit_radius / 256.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.call("die", "blade")
