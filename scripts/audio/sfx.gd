class_name Sfx
extends RefCounted
## Ayudante para reproducir efectos de sonido sin crear nodos a mano.
## Uso:  Sfx.play_at(self, "shot", global_position)   o   Sfx.play_ui(self, "ui_open")

const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const AMBIENCE_PATH := "res://assets/audio/ambience/%s.wav"

static func get_stream(path: String) -> AudioStream:
	# load() ya guarda en memoria lo que carga: la segunda vez es instantáneo.
	return load(path)


## Sonido en un punto del mundo: se escucha más fuerte cerca de la cámara y
## de un lado u otro según dónde ocurra.
static func play_at(from: Node, sound: String, pos: Vector2, volume_db := 0.0, pitch_variation := 0.08) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = get_stream(SFX_PATH % sound)
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.max_distance = 700.0
	from.get_tree().root.add_child(player)
	player.global_position = pos
	player.finished.connect(player.queue_free)   # Se borra solo al terminar
	player.play()


## Sonido de interfaz: siempre igual de fuerte y suena aunque el juego esté en pausa.
static func play_ui(from: Node, sound: String, volume_db := 0.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = get_stream(SFX_PATH % sound)
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	from.get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Carga un sonido de ambiente y se asegura de que se repita sin fin.
static func load_loop(path: String) -> AudioStream:
	var stream := get_stream(path)
	if stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	return stream
