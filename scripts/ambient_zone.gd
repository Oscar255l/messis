extends Area2D
## Zona de ambiente: cuando Gabriel entra, la luz general del nivel cambia suavemente a este color.
## Así la oficina se ve iluminada y los pasillos sin energía se ven oscuros.

@export var ambient_color := Color(0.12, 0.13, 0.18)
@export var hint_key := ""   # Mensaje de ayuda opcional que aparece la primera vez
@export var ambience := ""   # Sonido de fondo de esta zona (archivo en assets/audio/ambience)

var hint_shown := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("level", "set_ambient", ambient_color, ambience)
		if hint_key != "" and not hint_shown:
			hint_shown = true
			HUD.find(self).show_message(tr(hint_key))
