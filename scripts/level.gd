extends Node2D
## Script base de un nivel: cámara, luz ambiente y punto de control.

@onready var walls: TileMapLayer = $Walls
@onready var darkness: CanvasModulate = $Darkness
@onready var player: Node2D = $Player

var ambient_tween: Tween
var current_ambience := ""
var ambience_players: Array[AudioStreamPlayer] = []
var active_player := 0


func _ready() -> void:
	add_to_group("level")
	# Pixel art: redondear las posiciones a píxeles enteros al dibujar.
	# Sin esto, al moverse en posiciones como 62.5 se "pierden" columnas del sprite.
	get_viewport().snap_2d_transforms_to_pixel = true
	get_viewport().snap_2d_vertices_to_pixel = true

	# Dos reproductores de ambiente para pasar de uno a otro suavemente (crossfade).
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		ambience_players.append(p)
	# Si hay un punto de control guardado (Gabriel murió), empezar ahí.
	if not GameState.checkpoint.is_empty():
		player.global_position = GameState.checkpoint.pos

	# Ajustar la cámara para que no muestre fuera del mapa.
	var camera: Camera2D = $Player/Camera2D
	var used := walls.get_used_rect()       # Rectángulo de baldosas usadas (en celdas)
	var size := walls.tile_set.tile_size    # Tamaño de cada baldosa en píxeles
	camera.limit_left = used.position.x * size.x
	camera.limit_top = used.position.y * size.y
	camera.limit_right = used.end.x * size.x
	camera.limit_bottom = used.end.y * size.y
	camera.reset_smoothing()


## Las zonas de ambiente llaman a esta función para cambiar la luz y el sonido de fondo.
func set_ambient(color: Color, ambience := "") -> void:
	if ambient_tween:
		ambient_tween.kill()
	ambient_tween = create_tween()
	ambient_tween.tween_property(darkness, "color", color, 1.2)
	if ambience != "" and ambience != current_ambience:
		crossfade_ambience(ambience)


func crossfade_ambience(ambience: String) -> void:
	current_ambience = ambience
	var old_player := ambience_players[active_player]
	active_player = 1 - active_player
	var new_player := ambience_players[active_player]
	new_player.stream = Sfx.load_loop(Sfx.AMBIENCE_PATH % ambience)
	new_player.volume_db = -40.0
	new_player.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(new_player, "volume_db", 0.0, 2.0)
	tween.tween_property(old_player, "volume_db", -60.0, 2.0)


func _exit_tree() -> void:
	for p in ambience_players:
		p.stop()
