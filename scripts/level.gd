extends Node2D
## Script base de un nivel: cámara, luz ambiente y punto de control.

@onready var walls: TileMapLayer = $Walls
@onready var darkness: CanvasModulate = $Darkness
@onready var player: Node2D = $Player

var ambient_tween: Tween


func _ready() -> void:
	add_to_group("level")
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


## Las zonas de ambiente llaman a esta función para cambiar la luz general.
func set_ambient(color: Color) -> void:
	if ambient_tween:
		ambient_tween.kill()
	ambient_tween = create_tween()
	ambient_tween.tween_property(darkness, "color", color, 1.2)
