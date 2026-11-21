extends Node

const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"
const SFX_DIRECTORY := "res://Audio/SFX/"
const SFX_KEYS := {
	"breath_idle": "Breath For Idle.mp3",
	"jump": "Jump.mp3",
	"double_jump": "Double Jump.mp3",
	"landing": "Landing.mp3",
	"button_click": "SFX Button Clicked.mp3",
	"button_hover": "SFX Button Hover.mp3",
	"checkpoint": "SFX Check Point.mp3",
	"death_fall": "SFX Death Jatuh.mp3",
	"death_blade": "SFX Death Terkena Pisau.mp3",
	"death_enemy": "SFX Death Terkena Enemy.mp3",
	"portal": "SFX Go Portal.mp3",
	"stomp": "SFX Menginjak Enemy.mp3",
	"spawn": "SFX Spawn Player.mp3",
	"ufo_arrival": "SFX UFO Datang.mp3",
	"transition": "Transition SFX.mp3",
	"ui_open": "SFX UI Pop Open.mp3",
}
const SFX_PLAYER_COUNT := 12
const BGM_MENU_PATH := "res://Audio/BGM/BGM Main menu.mp3"
const BGM_GAMEPLAY_PATH := "res://Audio/BGM/BGM Gameplay.mp3"
const MENU_SCENE_PATH := "res://Scene/Main Menu.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const FADE_IN_DURATION := 0.9
const FADE_OUT_DURATION := 0.3
const SILENT_DB := -40.0
const MIN_DB := -80.0

var music_volume: float = 0.8
var sfx_volume: float = 0.5
var music_player: AudioStreamPlayer
var music_bus_index: int = -1
var sfx_bus_index: int = -1
var sfx_streams: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_cursor: int = 0
var _current_bgm_path: String = ""
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_music_bus()
	_ensure_sfx_bus()
	music_player = AudioStreamPlayer.new()
	music_player.name = "BGMPlayer"
	music_player.bus = MUSIC_BUS_NAME
	add_child(music_player)
	_load_settings()
	_apply_music_volume()
	_apply_sfx_volume()
	_load_sfx()
	_setup_sfx_players()
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_start_bgm_for_current_scene")


func _ensure_music_bus() -> void:
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index >= 0:
		return
	AudioServer.add_bus()
	music_bus_index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(music_bus_index, MUSIC_BUS_NAME)
	AudioServer.set_bus_send(music_bus_index, "Master")


func _ensure_sfx_bus() -> void:
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	if sfx_bus_index >= 0:
		return
	AudioServer.add_bus()
	sfx_bus_index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(sfx_bus_index, SFX_BUS_NAME)
	AudioServer.set_bus_send(sfx_bus_index, "Master")


func _load_sfx() -> void:
	for key in SFX_KEYS:
		var path: String = SFX_DIRECTORY + str(SFX_KEYS[key])
		if not ResourceLoader.exists(path):
			push_error("AudioManager: missing SFX '%s'." % path)
			continue
		sfx_streams[key] = load(path) as AudioStream


func _setup_sfx_players() -> void:
	for i in range(SFX_PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % (i + 1)
		player.bus = SFX_BUS_NAME
		add_child(player)
		sfx_players.append(player)


func play_sfx(key: String) -> void:
	var stream: AudioStream = sfx_streams.get(key)
	if stream == null or sfx_players.is_empty():
		return
	var player := sfx_players[sfx_player_cursor]
	sfx_player_cursor = (sfx_player_cursor + 1) % sfx_players.size()
	player.stream = stream
	player.play()


func get_sfx_length(key: String) -> float:
	var stream: AudioStream = sfx_streams.get(key)
	if stream == null:
		return 0.0
	return stream.get_length()


func _on_scene_changed(_scene_root: Node = null) -> void:
	if SceneTransition.transitioning:
		return
	_start_bgm_for_current_scene()


func _start_bgm_for_current_scene() -> void:
	var current := get_tree().current_scene
	if current == null:
		return
	var path := current.scene_file_path
	if path == MENU_SCENE_PATH:
		play_menu_bgm()
	elif GameManager.LEVEL_SCENES.has(path):
		play_gameplay_bgm()


func play_menu_bgm() -> void:
	_play_bgm(BGM_MENU_PATH)


func play_gameplay_bgm() -> void:
	_play_bgm(BGM_GAMEPLAY_PATH)


func _play_bgm(path: String) -> void:
	if music_player == null:
		return
	if _current_bgm_path == path and music_player.playing:
		return

	var stream := load(path) as AudioStream
	if stream == null:
		push_error("AudioManager: failed to load BGM '%s'." % path)
		return

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()

	music_player.stream = stream
	_current_bgm_path = path
	music_player.volume_db = SILENT_DB
	music_player.play()

	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", 0.0, FADE_IN_DURATION)


func fade_out_and_stop() -> void:
	if music_player == null:
		return
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()

	_current_bgm_path = ""
	if not music_player.playing:
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", SILENT_DB, FADE_OUT_DURATION)
	_fade_tween.tween_callback(music_player.stop)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()
	_save_settings()


func get_music_volume() -> float:
	return music_volume


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()
	_save_settings()


func get_sfx_volume() -> float:
	return sfx_volume


func _apply_music_volume() -> void:
	if music_bus_index < 0:
		return
	var db := MIN_DB if music_volume <= 0.0 else linear_to_db(music_volume)
	AudioServer.set_bus_volume_db(music_bus_index, db)


func _apply_sfx_volume() -> void:
	if sfx_bus_index < 0:
		return
	var db := MIN_DB if sfx_volume <= 0.0 else linear_to_db(sfx_volume)
	AudioServer.set_bus_volume_db(sfx_bus_index, db)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = clampf(
		float(config.get_value("audio", "music_volume", 0.8)), 0.0, 1.0
	)
	sfx_volume = clampf(
		float(config.get_value("audio", "sfx_volume", 0.5)), 0.0, 1.0
	)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("AudioManager: could not save settings (error %d)." % error)
