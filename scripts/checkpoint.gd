extends Area2D
## Punto de control: guarda el progreso la primera vez que Gabriel pasa por aquí.

var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	# Guardar el centro de la zona (a la altura de los pies de Gabriel) como lugar de reaparición.
	var spawn_x: float = $CollisionShape2D.global_position.x
	GameState.save_checkpoint(Vector2(spawn_x, body.global_position.y))
