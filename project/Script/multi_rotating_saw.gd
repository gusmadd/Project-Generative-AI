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
@export_range(2, 3, 1) var blade_count: int = 2:
	set(value):
		blade_count = clampi(value, 2, 3)
		if is_node_ready():
			_rebuild_blades()
		queue_redraw()
@export_range(0.0, 1000.0, 1.0, "suffix:px") var orbit_radius: float = 150.0:
	set(value):
		orbit_radius = value
		_update_blade_positions()
		queue_redraw()
@export_range(1.0, 100.0, 1.0, "suffix:px") var hitbox_radius: float = 25.0:
	set(value):
		hitbox_radius = value
		_update_hitboxes()
		queue_redraw()
@export var show_orbit_path: bool = true:
	set(value):
		show_orbit_path = value
		_update_orbit_guide()
@export_range(1.0, 60.0, 1.0, "suffix:FPS") var animation_speed: float = 12.0

var orbit_guide: Sprite2D
var blades_container: Node2D
var blade_sprites: Array[AnimatedSprite2D] = []
var blade_areas: Array[Area2D] = []
var orbit_angle: float = 0.0
var saw_frames: SpriteFrames


func _ready() -> void:
	orbit_guide = get_node_or_null("OrbitGuide") as Sprite2D
	blades_container = get_node_or_null("Blades") as Node2D
	if orbit_guide == null or blades_container == null:
		push_error("MultiRotatingSaw requires OrbitGuide and Blades child nodes.")
		return

	_setup_animation_frames()
	_update_orbit_guide()
	_rebuild_blades()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	orbit_angle += deg_to_rad(revolution_speed * int(orbit_direction) * delta)
	_update_blade_positions()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	for blade_index in range(blade_count):
		var angle := TAU * float(blade_index) / float(blade_count)
		var blade_position := Vector2.RIGHT.rotated(angle) * orbit_radius
		draw_circle(blade_position, hitbox_radius, Color(1.0, 0.05, 0.25, 0.14))
		draw_arc(
			blade_position,
			hitbox_radius,
			0.0,
			TAU,
			48,
			Color(1.0, 0.05, 0.25, 1.0),
			2.0
		)


func _setup_animation_frames() -> void:
	saw_frames = SpriteFrames.new()
	saw_frames.add_animation("Spin")
	saw_frames.set_animation_speed("Spin", animation_speed)
	saw_frames.set_animation_loop("Spin", true)

	for frame_path in SAW_FRAME_PATHS:
		var texture := load(frame_path) as Texture2D
		if texture == null:
			push_error("Could not load rotating saw frame '%s'." % frame_path)
			return
		saw_frames.add_frame("Spin", texture)


func _rebuild_blades() -> void:
	if blades_container == null or saw_frames == null:
		return

	blade_sprites.clear()
	blade_areas.clear()
	for child in blades_container.get_children():
		child.free()

	for blade_index in range(blade_count):
		var blade_sprite := AnimatedSprite2D.new()
		blade_sprite.name = "Blade%d" % (blade_index + 1)
		blade_sprite.sprite_frames = saw_frames
		blade_sprite.play("Spin")
		blades_container.add_child(blade_sprite)
		blade_sprites.append(blade_sprite)

		var blade_area := Area2D.new()
		blade_area.name = "BladeArea%d" % (blade_index + 1)
		blade_area.body_entered.connect(_on_body_entered)
		blades_container.add_child(blade_area)
		blade_areas.append(blade_area)

		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		collision.shape = CircleShape2D.new()
		blade_area.add_child(collision)

	_update_hitboxes()
	_update_blade_positions()
	queue_redraw()


func _update_blade_positions() -> void:
	if blade_sprites.size() != blade_areas.size():
		return

	for blade_index in range(blade_sprites.size()):
		var angle := orbit_angle + TAU * float(blade_index) / float(blade_sprites.size())
		var blade_position := Vector2.RIGHT.rotated(angle) * orbit_radius
		blade_sprites[blade_index].position = blade_position
		blade_areas[blade_index].position = blade_position


func _update_hitboxes() -> void:
	for blade_area in blade_areas:
		var collision := blade_area.get_node("CollisionShape2D") as CollisionShape2D
		var circle := collision.shape as CircleShape2D
		circle.radius = hitbox_radius


func _update_orbit_guide() -> void:
	if not is_instance_valid(orbit_guide):
		return

	orbit_guide.visible = show_orbit_path
	orbit_guide.scale = Vector2.ONE * (orbit_radius / 256.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.call("die")
