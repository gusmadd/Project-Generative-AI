extends Control

const ROUND_COUNT := 3
const LEVELS_PER_ROUND := 6
const LEVEL_BUTTON_COUNT := ROUND_COUNT * LEVELS_PER_ROUND
const LEVEL_ASSET_DIRECTORY := "res://Asset/Menu/Buttton levels"
const ROUND_TEXT_COLOR := Color(0.75, 0.95, 1.0, 1.0)
const NAV_COLOR_ENABLED := Color(1.0, 1.0, 1.0, 1.0)
const NAV_COLOR_DISABLED := Color(0.42, 0.45, 0.55, 0.75)

@onready var menu_buttons: VBoxContainer = $MenuButtons
@onready var play_button: TextureButton = $MenuButtons/PlayButton
@onready var levels_button: TextureButton = $MenuButtons/LevelsButton
@onready var settings_button: TextureButton = $MenuButtons/SettingsButton
@onready var quit_button: TextureButton = $MenuButtons/QuitButton
@onready var levels_panel: Control = $"Panel panel"
@onready var close_button: TextureButton = $"Panel panel/Close Button"
@onready var next_button: TextureButton = $"Panel panel/Next Button"
@onready var back_button: TextureButton = $"Panel panel/Bacck Button"
@onready var round_text: TextureRect = $"Panel panel/Round Text"
@onready var round_label: Label = $"Panel panel/Round Text/Round Label"
@onready var settings_panel: Control = $"Settings Panel"
@onready var settings_close_button: TextureButton = $"Settings Panel/Close Button"
@onready var reset_button: TextureButton = $"Settings Panel/Reset Progres Button"
@onready var music_slider: HSlider = $"Settings Panel/Music Slidder"
@onready var sfx_slider: HSlider = $"Settings Panel/SFX Slidder"
@onready var music_value: Label = $"Settings Panel/Music Slidder/Music Value"
@onready var sfx_value: Label = $"Settings Panel/SFX Slidder/Sfx Value"

var round_nodes: Dictionary = {}
var level_buttons: Dictionary = {}
var current_round: int = 1
var button_tweens: Dictionary = {}
var hovered_buttons: Dictionary = {}
var panel_tween: Tween
var round_text_tween: Tween
var round_pulse_tween: Tween
var nav_color_tweens: Dictionary = {}
var settings_tween: Tween
var settings_initializing: bool = false


func _ready() -> void:
	settings_panel.visible = false
	_start_round_label_pulse()
	for button in [
		play_button,
		levels_button,
		settings_button,
		quit_button,
		close_button,
		next_button,
		back_button,
		settings_close_button,
		reset_button,
	]:
		_connect_animated_button(button)

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	settings_close_button.pressed.connect(_on_settings_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)

	for round_number in range(1, ROUND_COUNT + 1):
		var round_node := levels_panel.get_node_or_null("Round %d" % round_number) as Control
		if round_node == null:
			push_error("Levels panel is missing Round %d." % round_number)
			continue
		round_nodes[round_number] = round_node

		var first_level := (round_number - 1) * LEVELS_PER_ROUND + 1
		for level_number in range(first_level, first_level + LEVELS_PER_ROUND):
			var level_button := round_node.get_node_or_null("Level %d" % level_number) as TextureButton
			if level_button == null:
				push_error("Round %d is missing the Level %d button." % [round_number, level_number])
				continue
			level_buttons[level_number] = level_button
			_connect_animated_button(level_button)
			level_button.pressed.connect(_on_level_pressed.bind(level_button, level_number))

	levels_panel.visible = false
	_apply_round_state(1)
	for number in round_nodes:
		var node: Control = round_nodes[number]
		node.visible = number == current_round
	_initialize_settings()


func _connect_animated_button(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0
	button.resized.connect(_sync_button_pivot.bind(button))
	call_deferred("_sync_button_pivot", button)
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


func _sync_button_pivot(button: Control) -> void:
	button.pivot_offset = button.size / 2.0


func _on_button_mouse_entered(button: TextureButton) -> void:
	hovered_buttons[button] = true
	if not button.disabled or button == next_button or button == back_button:
		_animate_button(button, 1.2, 0.2)


func _on_button_mouse_exited(button: TextureButton) -> void:
	hovered_buttons.erase(button)
	_animate_button(button, 1.0, 0.12)


func _animate_button(button: TextureButton, target_scale: float, duration: float) -> Tween:
	var existing_tween := button_tweens.get(button) as Tween
	if existing_tween != null and existing_tween.is_running():
		existing_tween.kill()

	var animation := create_tween()
	button_tweens[button] = animation
	animation.tween_property(
		button,
		"scale",
		Vector2.ONE * target_scale,
		duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return animation


func _play_click_animation(button: TextureButton) -> void:
	var animation := _animate_button(button, 0.88, 0.06)
	animation.tween_property(button, "scale", Vector2.ONE * 1.14, 0.09)
	animation.tween_property(
		button,
		"scale",
		Vector2.ONE * (1.12 if hovered_buttons.has(button) else 1.0),
		0.09
	)
	await animation.finished


func _on_play_pressed() -> void:
	await _play_click_animation(play_button)
	GameManager.start_highest_unlocked_level()


func _on_levels_pressed() -> void:
	await _play_click_animation(levels_button)
	_apply_round_state(current_round)
	menu_buttons.visible = false
	levels_panel.visible = true
	levels_panel.pivot_offset = levels_panel.size / 2.0
	levels_panel.scale = Vector2.ONE * 0.85
	levels_panel.modulate.a = 0.0

	panel_tween = create_tween().set_parallel(true)
	panel_tween.tween_property(levels_panel, "scale", Vector2.ONE, 0.24).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(levels_panel, "modulate:a", 1.0, 0.18)

	_play_round_text_intro()


func _on_settings_pressed() -> void:
	await _play_click_animation(settings_button)
	_open_settings()


func _open_settings() -> void:
	menu_buttons.visible = false
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
	await _play_click_animation(settings_close_button)
	if settings_tween != null and settings_tween.is_running():
		settings_tween.kill()

	settings_tween = create_tween().set_parallel(true)
	settings_tween.tween_property(settings_panel, "scale", Vector2.ONE * 0.8, 0.18)
	settings_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.18)
	await settings_tween.finished

	settings_panel.visible = false
	settings_panel.scale = Vector2.ONE
	settings_panel.modulate.a = 1.0
	menu_buttons.visible = true


func _on_reset_pressed() -> void:
	await _play_click_animation(reset_button)
	GameManager.reset_progress()
	_update_level_buttons()


func _initialize_settings() -> void:
	settings_initializing = true
	var music := clampf(AudioManager.get_music_volume() * 100.0, 0.0, 100.0)
	var sfx := clampf(AudioManager.get_sfx_volume() * 100.0, 0.0, 100.0)
	music_slider.value = music
	sfx_slider.value = sfx
	_update_value_text(music_value, music)
	_update_value_text(sfx_value, sfx)
	settings_initializing = false


func _on_music_slider_changed(value: float) -> void:
	_update_value_text(music_value, value)
	if settings_initializing:
		return
	AudioManager.set_music_volume(value / 100.0)


func _on_sfx_slider_changed(value: float) -> void:
	_update_value_text(sfx_value, value)
	if settings_initializing:
		return
	AudioManager.set_sfx_volume(value / 100.0)


func _update_value_text(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value)


func _on_quit_pressed() -> void:
	await _play_click_animation(quit_button)
	get_tree().quit()


func _on_close_pressed() -> void:
	await _play_click_animation(close_button)
	if panel_tween != null and panel_tween.is_running():
		panel_tween.kill()

	panel_tween = create_tween().set_parallel(true)
	panel_tween.tween_property(levels_panel, "scale", Vector2.ONE * 0.85, 0.16)
	panel_tween.tween_property(levels_panel, "modulate:a", 0.0, 0.16)
	await panel_tween.finished

	levels_panel.visible = false
	levels_panel.scale = Vector2.ONE
	levels_panel.modulate.a = 1.0
	menu_buttons.visible = true


func _on_level_pressed(button: TextureButton, level_number: int) -> void:
	await _play_click_animation(button)
	GameManager.start_level(level_number)


func _on_next_pressed() -> void:
	await _play_click_animation(next_button)
	_switch_to_round(current_round + 1)


func _on_back_pressed() -> void:
	await _play_click_animation(back_button)
	_switch_to_round(current_round - 1)


func _switch_to_round(target_round: int) -> void:
	if target_round == current_round or target_round < 1 or target_round > ROUND_COUNT:
		return

	var current_node: Control = round_nodes.get(current_round)
	var next_node: Control = round_nodes.get(target_round)
	if current_node == null or next_node == null:
		return

	current_node.visible = false
	next_node.visible = true

	_apply_round_state(target_round)
	_play_round_text_intro()


func _apply_round_state(round_number: int) -> void:
	current_round = clampi(round_number, 1, ROUND_COUNT)
	round_label.text = "ROUND %d" % current_round
	_update_level_buttons()
	_update_navigation_buttons()


func _update_navigation_buttons() -> void:
	back_button.visible = current_round > 1
	back_button.disabled = current_round <= 1
	next_button.disabled = (
		current_round >= ROUND_COUNT
		or not _is_round_complete(current_round)
	)
	_apply_navigation_color(next_button)
	_apply_navigation_color(back_button)


func _apply_navigation_color(button: TextureButton) -> void:
	var target := NAV_COLOR_ENABLED if not button.disabled else NAV_COLOR_DISABLED
	var existing := nav_color_tweens.get(button) as Tween
	if existing != null and existing.is_running():
		existing.kill()

	var color_tween := create_tween()
	nav_color_tweens[button] = color_tween
	color_tween.tween_property(button, "modulate", target, 0.15)


func _start_round_label_pulse() -> void:
	if round_pulse_tween != null and round_pulse_tween.is_running():
		round_pulse_tween.kill()

	round_label.scale = Vector2.ONE
	round_label.modulate = ROUND_TEXT_COLOR
	round_pulse_tween = create_tween().set_loops()
	round_pulse_tween.tween_property(
		round_label, "scale", Vector2.ONE * 1.06, 0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	round_pulse_tween.parallel().tween_property(
		round_label, "modulate", Color.WHITE, 0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	round_pulse_tween.tween_property(
		round_label, "scale", Vector2.ONE, 0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	round_pulse_tween.parallel().tween_property(
		round_label, "modulate", ROUND_TEXT_COLOR, 0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _is_round_complete(round_number: int) -> bool:
	var first_level := (round_number - 1) * LEVELS_PER_ROUND + 1
	for level_number in range(first_level, first_level + LEVELS_PER_ROUND):
		if not GameManager.is_level_complete(level_number):
			return false
	return true


func _play_round_text_intro() -> void:
	if round_text_tween != null and round_text_tween.is_running():
		round_text_tween.kill()

	round_text.modulate = Color(
		ROUND_TEXT_COLOR.r, ROUND_TEXT_COLOR.g, ROUND_TEXT_COLOR.b, 0.0
	)
	round_text.scale = Vector2.ONE * 0.88
	round_text_tween = create_tween().set_parallel(true)
	round_text_tween.tween_property(round_text, "modulate:a", 1.0, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	round_text_tween.tween_property(round_text, "scale", Vector2.ONE, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	round_text_tween.chain().tween_property(round_text, "modulate:a", 0.75, 0.9).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	round_text_tween.chain().tween_property(round_text, "modulate:a", 1.0, 0.9).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _update_level_buttons() -> void:
	for level_number in range(1, LEVEL_BUTTON_COUNT + 1):
		var button := level_buttons.get(level_number) as TextureButton
		if button == null:
			continue

		var state := "Lock"
		if GameManager.is_level_complete(level_number):
			state = "Complete"
		elif GameManager.is_level_unlocked(level_number):
			state = "Unlock"

		var texture_path := "%s/State=%s, Level=%d.png" % [
			LEVEL_ASSET_DIRECTORY,
			state,
			level_number,
		]
		if ResourceLoader.exists(texture_path):
			var texture := load(texture_path) as Texture2D
			if texture != null:
				button.texture_normal = texture
				button.texture_hover = texture
				button.texture_pressed = texture
				button.texture_disabled = texture
		button.disabled = state == "Lock"
