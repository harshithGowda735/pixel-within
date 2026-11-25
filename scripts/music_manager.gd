extends Node

# Background Music Manager for Pixel Within (Milestone M7)
# Plays the original 8-bit/16-bit theme continuously across scenes and transitions.
# M toggles mute.

var player: AudioStreamPlayer
var stream: AudioStreamWAV
var is_muted: bool = false

signal mute_toggled(muted: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	add_child(player)

	load_and_play()

func load_and_play() -> void:
	var path := "res://audio/pixel_within_theme.wav"
	if FileAccess.file_exists(path):
		var res = load(path)
		if res is AudioStreamWAV:
			stream = res
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			# Seamless loop covering the full sample count
			stream.loop_begin = 0
			stream.loop_end = 0
			player.stream = stream
			player.volume_db = -2.0
			if not is_muted and is_inside_tree():
				player.play()
	else:
		push_warning("Theme audio file not found at " + path)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			toggle_mute()

func toggle_mute() -> void:
	is_muted = !is_muted
	if player != null:
		if is_muted:
			player.stop()
		else:
			if not player.playing and stream != null and is_inside_tree():
				player.play()
	mute_toggled.emit(is_muted)
