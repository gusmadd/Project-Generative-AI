extends Control

const TYPE_DELAY := 0.05
const ERASE_DELAY := 0.001
const MENU_SCENE_PATH := "res://Scene/Main Menu.tscn"
const NARRATIVE_FONT_PATH := "res://Asset/Intro Level/Madiosa.ttf"
const COUNTDOWN_FONT_SIZE := 50
const URGENT_SECONDS := 20.0

@export var countdown_seconds: float = 60.0
@export var shake_duration: float = 0.7
@export var fail_pause_seconds: float = 1.0

@onready var main_text: Label = $"Main Text"
@onready var click_enter: Label = $"Click enter"
@onready var yes_button: TextureButton = $"Yes Button"
@onready var back_button: TextureButton = $"Back To menu Button"

var lines: Array[String] = []
var line_index: int = 0
var typing: bool = false
var active: bool = false
var finished: bool = false
var choice_visible: bool = false
var counting: bool = false
var time_left: float = 0.0
var is_level_six: bool = false
var player: Node2D
var click_tween: Tween
var button_tweens: Dictionary = {}
var erasing: bool = false
var choice_processing: bool = false
var urgent_tween: Tween
var urgent_active: bool = false
var base_text_color: Color = Color.WHITE


func _ready() -> void:
	var scene_path := ""
	if get_tree().current_scene != null:
		scene_path = get_tree().current_scene.scene_file_path
	is_level_six = scene_path.ends_with("Level 6.tscn")
	lines = _build_lines()

	player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.connect("spawn_intro_finished", Callable(self, "_on_spawn_finished"))

	_apply_countdown_font()
	base_text_color = main_text.get_theme_color("font_color")
	main_text.text = ""
	click_enter.modulate.a = 0.0
	click_enter.visible = false
	yes_button.visible = false
	back_button.visible = false

	yes_button.pressed.connect(_on_yes_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_connect_button(yes_button)
	_connect_button(back_button)


func _apply_countdown_font() -> void:
	var font: FontFile = load(NARRATIVE_FONT_PATH) as FontFile
	if font == null:
		return
	main_text.add_theme_font_override("font", font)
	click_enter.add_theme_font_override("font", font)


func _build_lines() -> Array[String]:
	if is_level_six:
		return [
			"Gerbang menuju sektor selanjutnya ada tepat di depan mata, namun ruang ini tidak mengenal kata berhenti.",
			"Jalurnya singkat, tetapi tidak ada titik simpan , waktu tidak dapat dijeda (Pause terkunci), dan detik terus berhitung mundur.",
			"Satu kesalahan atau kehabisan waktu berarti mengulang dari nol.",
			"Melompatlah tanpa ragu!",
			"apakah kamu yakin ingin lanjut",
		]
	return [
		"Enam jalur simbolik mengunci gerbang menuju sektor berikutnya.",
		"Gunakan lompatanmu untuk menaklukkan setiap rintangan dan mencapai portal.",
		"Hanya mereka yang menyelesaikan seluruh rangkaian ini yang diizinkan melangkah lebih jauh.",
	]


func _on_spawn_finished() -> void:
	if active or finished or counting:
		return
	if player != null:
		player.set("narrative_active", true)
	active = true
	main_text.visible = true
	click_enter.visible = true
	_start_click_fade()
	call_deferred("_type_current_line")


func _type_current_line() -> void:
	if not active or finished:
		return
	typing = true
	var text := lines[line_index]
	main_text.text = ""
	for i in range(text.length()):
		main_text.text = text.substr(0, i + 1)
		AudioManager.play_sfx("text_intro")
		await get_tree().create_timer(TYPE_DELAY).timeout
		if not typing:
			return
	typing = false
	main_text.text = text
	if is_level_six and line_index == lines.size() - 1:
		_show_choice_buttons()


func _erase_current_line() -> void:
	erasing = true
	var text := main_text.text
	for i in range(text.length(), 0, -1):
		main_text.text = text.substr(0, i - 1)
		await get_tree().create_timer(ERASE_DELAY).timeout
	main_text.text = ""
	erasing = false


func _unhandled_input(event: InputEvent) -> void:
	if not active or finished or counting or choice_visible or erasing:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ENTER:
		return

	if typing:
		typing = false
		main_text.text = lines[line_index]
		if is_level_six and line_index == lines.size() - 1:
			_show_choice_buttons()
		return

	await _erase_current_line()
	if line_index + 1 < lines.size():
		line_index += 1
		await _type_current_line()
	else:
		_finish_intro()


func _show_choice_buttons() -> void:
	choice_visible = true
	_stop_click_fade()
	click_enter.visible = false
	for button in [yes_button, back_button]:
		button.visible = true
		button.scale = Vector2.ZERO
		var animation := create_tween()
		animation.tween_property(button, "scale", Vector2.ONE, 0.28).set_trans(
			Tween.TRANS_BACK
		).set_ease(Tween.EASE_OUT)
		await animation.finished


func _finish_intro() -> void:
	finished = true
	active = false
	_stop_click_fade()
	click_enter.visible = false
	main_text.text = ""
	yes_button.visible = false
	back_button.visible = false
	if player != null:
		player.set("narrative_active", false)


func _on_yes_pressed() -> void:
	if choice_processing or not choice_visible:
		return
	choice_processing = true
	_click_pop(yes_button)
	_hide_choice_buttons()
	_start_countdown()
	choice_processing = false


func _on_back_pressed() -> void:
	if choice_processing or not choice_visible:
		return
	choice_processing = true
	_click_pop(back_button)
	if not SceneTransition.change_scene(MENU_SCENE_PATH):
		choice_processing = false


func _hide_choice_buttons() -> void:
	choice_visible = false
	for button in [yes_button, back_button]:
		var animation := create_tween()
		animation.tween_property(button, "scale", Vector2.ZERO, 0.16).set_trans(
			Tween.TRANS_BACK
		).set_ease(Tween.EASE_IN)
		await animation.finished
		button.visible = false


func _start_countdown() -> void:
	finished = true
	active = false
	counting = true
	time_left = countdown_seconds
	urgent_active = false
	if urgent_tween != null and urgent_tween.is_running():
		urgent_tween.kill()
	main_text.visible = true
	main_text.pivot_offset = main_text.size / 2.0
	main_text.add_theme_font_size_override("font_size", COUNTDOWN_FONT_SIZE)
	main_text.add_theme_color_override("font_color", base_text_color)
	main_text.scale = Vector2.ZERO
	var pop := create_tween()
	pop.tween_property(main_text, "scale", Vector2.ONE * 1.12, 0.25).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	pop.tween_property(main_text, "scale", Vector2.ONE, 0.15)
	await pop.finished
	if player != null:
		player.set("narrative_active", false)


func _process(delta: float) -> void:
	if not counting:
		return
	time_left -= delta
	var total := maxi(0, int(ceil(time_left)))
	main_text.text = "%02d:%02d" % [total / 60, total % 60]
	if not urgent_active and time_left <= URGENT_SECONDS:
		_start_urgent_countdown()
	if time_left <= 0.0:
		_on_time_out()


func _start_urgent_countdown() -> void:
	urgent_active = true
	main_text.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15, 1.0))
	if urgent_tween != null and urgent_tween.is_running():
		urgent_tween.kill()
	urgent_tween = create_tween().set_loops()
	urgent_tween.tween_property(
		main_text, "scale", Vector2.ONE * 1.2, 0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	urgent_tween.tween_property(
		main_text, "scale", Vector2.ONE, 0.22
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_time_out() -> void:
	counting = false
	if urgent_tween != null and urgent_tween.is_running():
		urgent_tween.kill()
	GameManager.open_levels_panel_on_menu = true

	if player != null:
		player.set("narrative_active", true)
		_shake_camera()
		await get_tree().create_timer(shake_duration + fail_pause_seconds).timeout

		var was_dead := bool(player.get("dead"))
		player.set("skip_respawn_on_death", true)
		player.call("die_silent")
		if not was_dead:
			var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if sprite != null:
				await sprite.animation_finished
		await get_tree().create_timer(fail_pause_seconds).timeout
		if not SceneTransition.change_scene(MENU_SCENE_PATH):
			player.call("restore_after_cancelled_death")
	else:
		GameManager.open_levels_panel_on_menu = false
		SceneTransition.change_scene(MENU_SCENE_PATH)


func _shake_camera() -> void:
	if player == null:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var base := camera.offset
	var step := shake_duration / 7.0
	var shake := create_tween()
	for i in range(6):
		var dx := 14.0 if i % 2 == 0 else -14.0
		shake.tween_property(camera, "offset", base + Vector2(dx, 0.0), step)
	shake.tween_property(camera, "offset", base, step)


func _start_click_fade() -> void:
	_stop_click_fade()
	click_tween = create_tween().set_loops()
	click_tween.tween_property(click_enter, "modulate:a", 0.25, 0.6)
	click_tween.tween_property(click_enter, "modulate:a", 1.0, 0.6)


func _stop_click_fade() -> void:
	if click_tween != null and click_tween.is_running():
		click_tween.kill()


func _connect_button(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_unhover.bind(button))


func _on_button_hover(button: TextureButton) -> void:
	AudioManager.play_sfx("button_hover")
	_animate_button(button, 1.12, 0.12)


func _on_button_unhover(button: TextureButton) -> void:
	_animate_button(button, 1.0, 0.12)


func _animate_button(button: TextureButton, factor: float, duration: float) -> void:
	var existing := button_tweens.get(button) as Tween
	if existing != null and existing.is_running():
		existing.kill()
	var animation := create_tween()
	button_tweens[button] = animation
	animation.tween_property(
		button, "scale", Vector2.ONE * factor, duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _click_pop(button: TextureButton) -> void:
	AudioManager.play_sfx("button_click")
	var existing := button_tweens.get(button) as Tween
	if existing != null and existing.is_running():
		existing.kill()
	var animation := create_tween()
	button_tweens[button] = animation
	animation.tween_property(button, "scale", Vector2.ONE * 0.88, 0.06)
	animation.tween_property(button, "scale", Vector2.ONE * 1.14, 0.09)
	animation.tween_property(button, "scale", Vector2.ONE, 0.09)
