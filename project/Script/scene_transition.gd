extends Node

const TRANSITION_SCENE: PackedScene = preload("res://Asset/Transisi/Transisi.tscn")
const CURTAIN_COLOR := Color("#030817")
const CURTAIN_DURATION := 0.3
const TRANSITION_SPEED_SCALE := 1.0
const TRANSITION_LAYER := 100
const TRANSITION_TIMEOUT := 15.0

var transitioning: bool = false


func change_scene(scene_path: String) -> bool:
	if transitioning:
		return false
	if not ResourceLoader.exists(scene_path):
		push_error("Cannot transition to missing scene '%s'." % scene_path)
		return false

	AudioManager.play_sfx("transition")
	AudioManager.fade_out_and_stop()
	transitioning = true
	call_deferred("_run_transition", scene_path)
	_watchdog()
	return true


func _watchdog() -> void:
	await get_tree().create_timer(TRANSITION_TIMEOUT).timeout
	if transitioning:
		push_error("Scene transition timed out; releasing lock.")
		transitioning = false


func _run_transition(scene_path: String) -> void:
	var previous_scene_path := ""
	if get_tree().current_scene != null:
		previous_scene_path = get_tree().current_scene.scene_file_path
	var viewport_size := get_viewport().get_visible_rect().size
	var overlay := CanvasLayer.new()
	overlay.layer = TRANSITION_LAYER
	get_tree().root.add_child(overlay)

	# 1. Buat tirai kiri dan kanan di luar layar
	var left_curtain := _create_curtain(
		overlay,
		Vector2(-viewport_size.x / 2.0, 0.0),
		Vector2(viewport_size.x / 2.0, viewport_size.y)
	)
	var right_curtain := _create_curtain(
		overlay,
		Vector2(viewport_size.x, 0.0),
		Vector2(viewport_size.x / 2.0, viewport_size.y)
	)

	# 2. Geser tirai kiri & kanan untuk MENUTUP layar
	var close_curtains := create_tween().set_parallel(true)
	close_curtains.tween_property(
		left_curtain, "position:x", 0.0, CURTAIN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	close_curtains.tween_property(
		right_curtain, "position:x", viewport_size.x / 2.0, CURTAIN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await close_curtains.finished

	# 3. Ganti scene di balik layar yang tertutup
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not load scene '%s' (error %d)." % [scene_path, error])
		await _open_curtains(left_curtain, right_curtain, viewport_size.x)
		overlay.queue_free()
		_start_bgm_for_scene(previous_scene_path)
		transitioning = false
		return

	await get_tree().process_frame
	await get_tree().process_frame

	# 4. Putar adegan animasi Transisi.tscn di atas tirai
	var transition_visual := TRANSITION_SCENE.instantiate() as Node2D
	if transition_visual == null:
		push_error("Transition scene root must be a Node2D.")
	else:
		var transition_sprite := transition_visual.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D
		if transition_sprite == null or transition_sprite.sprite_frames == null:
			push_error("Transition scene needs an AnimatedSprite2D with SpriteFrames.")
		elif not transition_sprite.sprite_frames.has_animation("default"):
			push_error("Transition AnimatedSprite2D needs a 'default' animation.")
		else:
			var frame_texture := transition_sprite.sprite_frames.get_frame_texture(
				"default", 0
			)
			if frame_texture == null:
				push_error("Transition animation has no first frame.")
			else:
				var fit_scale := minf(
					viewport_size.x / frame_texture.get_width(),
					viewport_size.y / frame_texture.get_height()
				)
				transition_sprite.position = viewport_size / 2.0
				transition_sprite.scale = Vector2.ONE * fit_scale
				transition_sprite.speed_scale = TRANSITION_SPEED_SCALE
				
				# Pastikan animasi tidak looping agar sinyal selesai bisa terpicu
				transition_sprite.sprite_frames.set_animation_loop("default", false)
				
				overlay.add_child(transition_visual)
				transition_sprite.play("default")

				# Tunggu sampai animasi benar-benar selesai diputar!
				await transition_sprite.animation_finished
				
				# Hapus visual animasi transisi sebelum tirai dibuka
				transition_visual.queue_free()

	# 5. Baru buka tirai kiri & kanan setelah adegan transisi selesai
	await _open_curtains(left_curtain, right_curtain, viewport_size.x)
	overlay.queue_free()
	_start_bgm_for_scene(scene_path)
	transitioning = false


func _start_bgm_for_scene(scene_path: String) -> void:
	if GameManager.LEVEL_SCENES.has(scene_path):
		AudioManager.play_gameplay_bgm()
	else:
		AudioManager.play_menu_bgm()


func _create_curtain(
	overlay: CanvasLayer,
	curtain_position: Vector2,
	curtain_size: Vector2
) -> ColorRect:
	var curtain := ColorRect.new()
	curtain.color = CURTAIN_COLOR
	curtain.position = curtain_position
	curtain.size = curtain_size
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(curtain)
	return curtain


func _open_curtains(
	left_curtain: ColorRect,
	right_curtain: ColorRect,
	viewport_width: float
) -> void:
	var open_curtains := create_tween().set_parallel(true)
	open_curtains.tween_property(
		left_curtain, "position:x", -viewport_width / 2.0, CURTAIN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	open_curtains.tween_property(
		right_curtain, "position:x", viewport_width, CURTAIN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await open_curtains.finished
