extends Node2D
## Script base de un nivel: ajusta la cámara para que no muestre fuera del mapa.

@onready var walls: TileMapLayer = $Walls


func _ready() -> void:
	var camera: Camera2D = $Player/Camera2D
	var used := walls.get_used_rect()       # Rectángulo de baldosas usadas (en celdas)
	var size := walls.tile_set.tile_size    # Tamaño de cada baldosa en píxeles
	camera.limit_left = used.position.x * size.x
	camera.limit_top = used.position.y * size.y
	camera.limit_right = used.end.x * size.x
	camera.limit_bottom = used.end.y * size.y
