extends Control

const MENU_SCENE_PATH := "res://Scene/Main Menu.tscn"

@onready var pause_button: TextureButton = $TextureButton
@onready var pause_panel: Panel = $"Pause Panel"
@onready var panel_bg: TextureRect = $"Pause Panel/BG"
@onready var panel_akar: TextureRect = $"Pause Panel/Akar"
@onready var panel_text: TextureRect = $"Pause Panel/Text"
@onready var resume_button: TextureButton = $"Pause Panel/Resume Button"
@onready var restart_button: TextureButton = $"Pause Panel/Restart Button"
@onready var level_button: TextureButton = $"Pause Panel/Level Buttons"
@onready var settings_button: TextureButton = $"Pause Panel/Settings Button"
@onready var settings_panel: Control = $"Settings Panel"
@onready var settings_close_button: TextureButton = $"Settings Panel/Close Button"
@onready var settings_reset_button: TextureButton = $"Settings Panel/Reset Progres Button"
@onready var music_slider: HSlider = $"Settings Panel/Music Slidder"
@onready var sfx_slider: HSlider = $"Settings Panel/SFX Slidder"
@onready var music_value: Label = $"Settings Panel/Music Slidder/Music Value"
@onready var sfx_value: Label = $"Settings Panel/SFX Slidder/Sfx Value"

var button_tweens: Dictionary = {}
var hovered_buttons: Dictionary = {}
var base_scales: Dictionary = {}
var panel_tween: Tween
var settings_tween: Tween
var settings_initializing: bool = false
var panel_alpha: float = 0.75
var bg_base_y: float = 0.0
var akar_base_y: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel_alpha = pause_panel.self_modulate.a
	bg_base_y = panel_bg.position.y
	akar_base_y = panel_akar.position.y
	pause_panel.visible = false
	settings_panel.visible = false

	for button in [
		pause_button,
		resume_button,
		restart_button,
		level_button,
		settings_button,
		settings_close_button,
		settings_reset_button,
	]:
		_connect_button(button)
	base_scales[panel_text] = panel_text.scale

	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	level_button.pressed.connect(_on_level_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_close_button.pressed.connect(_on_settings_close_pressed)
	settings_reset_button.pressed.connect(_on_settings_reset_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	_initialize_settings()


func _set_pause_controls_enabled(enabled: bool) -> void:
	for button in [
		pause_button,
		resume_button,
		restart_button,
		level_button,
		settings_button,
		settings_close_button,
		settings_reset_button,
	]:
		button.disabled = not enabled
	music_slider.editable = enabled
	sfx_slider.editable = enabled


func _connect_button(button: TextureButton) -> void:
	base_scales[button] = button.scale
	button.pivot_offset = button.size / 2.0
	button.resized.connect(_sync_pivot.bind(button))
	call_deferred("_sync_pivot", button)
	button.mouse_entered.connect(_on_hover_in.bind(button))
	button.mouse_exited.connect(_on_hover_out.bind(button))


func _sync_pivot(control: Control) -> void:
	control.pivot_offset = control.size / 2.0


func _on_hover_in(button: TextureButton) -> void:
	if button.disabled:
		return
	hovered_buttons[button] = true
	_animate_pop(button, 1.1, 0.12)
	AudioManager.play_sfx("button_hover")


func _on_hover_out(button: TextureButton) -> void:
	hovered_buttons.erase(button)
	_animate_pop(button, 1.0, 0.12)


func _animate_pop(control: Control, factor: float, duration: float) -> Tween:
	var base: Vector2 = base_scales.get(control, Vector2.ONE)
	var existing := button_tweens.get(control) as Tween
	if existing != null and existing.is_running():
		existing.kill()

	var animation := create_tween()
	button_tweens[control] = animation
	animation.tween_property(
		control, "scale", base * factor, duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return animation


func _click_pop(button: TextureButton) -> void:
	AudioManager.play_sfx("button_click")
	var base: Vector2 = base_scales.get(button, Vector2.ONE)
	var animation := _animate_pop(button, 0.88, 0.06)
	animation.tween_property(button, "scale", base * 1.12, 0.08)
	animation.tween_property(
		button,
		"scale",
		base * (1.1 if hovered_buttons.has(button) else 1.0),
		0.08
	)
	await animation.finished


func _on_pause_pressed() -> void:
	await _click_pop(pause_button)
	_open_pause_panel()


func _open_pause_panel() -> void:
	AudioManager.play_sfx("ui_open")
	_set_pause_controls_enabled(true)
	get_tree().paused = true
	pause_panel.visible = true
	settings_panel.visible = false
	pause_panel.scale = Vector2.ONE
	pause_panel.self_modulate = Color(0, 0, 0, 0)

	if panel_tween != null and panel_tween.is_running():
		panel_tween.kill()
	panel_tween = create_tween()
	panel_tween.tween_property(
		pause_panel, "self_modulate", Color(0, 0, 0, panel_alpha), 0.12
	)

	panel_bg.position.y = bg_base_y - 60.0
	panel_akar.position.y = akar_base_y - 60.0
	panel_bg.scale = Vector2.ONE * 0.8
	panel_akar.scale = Vector2.ONE * 0.8

	var fall := create_tween().set_parallel(true)
	fall.tween_property(panel_bg, "position:y", bg_base_y + 10.0, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	fall.tween_property(panel_akar, "position:y", akar_base_y + 10.0, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	fall.tween_property(panel_bg, "scale", Vector2.ONE * 1.06, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	fall.tween_property(panel_akar, "scale", Vector2.ONE * 1.06, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	await fall.finished

	var settle := create_tween().set_parallel(true)
	settle.tween_property(panel_bg, "position:y", bg_base_y, 0.14)
	settle.tween_property(panel_akar, "position:y", akar_base_y, 0.14)
	settle.tween_property(panel_bg, "scale", Vector2.ONE, 0.14)
	settle.tween_property(panel_akar, "scale", Vector2.ONE, 0.14)
	await settle.finished

	for node in [panel_text, restart_button, level_button, settings_button, resume_button]:
		await _pop_in(node)


func _pop_in(control: Control) -> void:
	var base: Vector2 = base_scales.get(control, Vector2.ONE)
	control.visible = true
	control.scale = Vector2.ZERO
	control.modulate.a = 0.0
	var animation := create_tween().set_parallel(true)
	animation.tween_property(control, "scale", base, 0.2).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	animation.tween_property(control, "modulate:a", 1.0, 0.16)
	await animation.finished


func _pop_out(control: Control) -> void:
	var base: Vector2 = base_scales.get(control, Vector2.ONE)
	if control.pivot_offset == Vector2.ZERO and control.size != Vector2.ZERO:
		control.pivot_offset = control.size / 2.0
	var animation := create_tween().set_parallel(true)
	animation.tween_property(control, "scale", base * 1.15, 0.06).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	animation.chain().tween_property(control, "scale", Vector2.ZERO, 0.14).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_IN)
	animation.tween_property(control, "modulate:a", 0.0, 0.16)
	await animation.finished
	control.visible = false
	control.scale = base
	control.modulate.a = 1.0


func _on_resume_pressed() -> void:
	await _click_pop(resume_button)

	for node in [resume_button, settings_button, level_button, restart_button, panel_text]:
		await _pop_out(node)

	if panel_tween != null and panel_tween.is_running():
		panel_tween.kill()

	panel_tween = create_tween()
	panel_tween.tween_property(
		pause_panel, "self_modulate", Color(0, 0, 0, 0), 0.16
	)
	panel_tween.tween_property(pause_panel, "scale", Vector2.ONE * 1.05, 0.1).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(pause_panel, "scale", Vector2.ONE * 0.9, 0.1)
	await panel_tween.finished

	pause_panel.visible = false
	settings_panel.visible = false
	pause_panel.self_modulate = Color(0, 0, 0, panel_alpha)
	pause_panel.scale = Vector2.ONE
	_set_pause_controls_enabled(true)
	get_tree().paused = false


func _on_restart_pressed() -> void:
	await _click_pop(restart_button)
	get_tree().paused = false
	var current := get_tree().current_scene
	if current != null:
		SceneTransition.change_scene(current.scene_file_path)


func _on_level_pressed() -> void:
	await _click_pop(level_button)
	get_tree().paused = false
	GameManager.open_levels_panel_on_menu = true
	SceneTransition.change_scene(MENU_SCENE_PATH)


func _on_settings_pressed() -> void:
	await _click_pop(settings_button)
	AudioManager.play_sfx("ui_open")
	settings_panel.visible = true
	settings_panel.pivot_offset = settings_panel.size / 2.0
	settings_panel.scale = Vector2.ONE * 0.8
	settings_panel.modulate.a = 0.0

	if settings_tween != null and settings_tween.is_running():
		settings_tween.kill()
	settings_tween = create_tween().set_parallel(true)
	settings_tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.26).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	settings_tween.tween_property(settings_panel, "modulate:a", 1.0, 0.2)


func _on_settings_close_pressed() -> void:
	await _click_pop(settings_close_button)
	if settings_tween != null and settings_tween.is_running():
		settings_tween.kill()

	settings_tween = create_tween().set_parallel(true)
	settings_tween.tween_property(settings_panel, "scale", Vector2.ONE * 0.8, 0.18)
	settings_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.18)
	await settings_tween.finished

	settings_panel.visible = false
	settings_panel.scale = Vector2.ONE
	settings_panel.modulate.a = 1.0


func _on_settings_reset_pressed() -> void:
	await _click_pop(settings_reset_button)
	GameManager.reset_progress()
	get_tree().paused = false
	SceneTransition.change_scene(MENU_SCENE_PATH)


func _initialize_settings() -> void:
	settings_initializing = true
	var music := clampf(AudioManager.get_music_volume() * 100.0, 0.0, 100.0)
	var sfx := clampf(AudioManager.get_sfx_volume() * 100.0, 0.0, 100.0)
	music_slider.value = music
	sfx_slider.value = sfx
	music_value.text = "%d%%" % roundi(music)
	sfx_value.text = "%d%%" % roundi(sfx)
	settings_initializing = false


func _on_music_changed(value: float) -> void:
	music_value.text = "%d%%" % roundi(value)
	if settings_initializing:
		return
	AudioManager.set_music_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	sfx_value.text = "%d%%" % roundi(value)
	if settings_initializing:
		return
	AudioManager.set_sfx_volume(value / 100.0)
