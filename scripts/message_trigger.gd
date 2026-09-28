extends Area2D
## Muestra un mensaje en pantalla la primera vez que Gabriel entra en esta zona.

@export var message_key := "MSG_END_DEMO"
@export var require_enemies_dead := false   # Solo se activa si no quedan enemigos vivos

var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if used or not body.is_in_group("player"):
		return
	if require_enemies_dead:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.state != enemy.State.DEAD:
				return
	used = true
	HUD.find(self).show_message(tr(message_key))
