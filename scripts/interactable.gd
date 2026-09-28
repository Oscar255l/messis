class_name Interactable
extends Area2D
## Zona de interacción reutilizable. Cuando Gabriel entra, muestra el icono [E].
## Si el jugador presiona E, emite la señal "interacted" para que el objeto dueño reaccione.

signal interacted(player: Node)
signal player_entered(player: Node)

@export var enabled := true:
	set(value):
		enabled = value
		if prompt and not value:
			prompt.hide()

@onready var prompt: Sprite2D = get_node_or_null("Prompt")
var prompt_base_y := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt:
		prompt.hide()
		prompt_base_y = prompt.position.y


func _process(_delta: float) -> void:
	# El icono sube y baja suavemente para llamar la atención.
	if prompt and prompt.visible:
		prompt.position.y = prompt_base_y + round(sin(Time.get_ticks_msec() / 200.0))


func _on_body_entered(body: Node) -> void:
	if enabled and body.has_method("set_interactable"):
		body.set_interactable(self)
		player_entered.emit(body)
		if prompt:
			prompt.show()


func _on_body_exited(body: Node) -> void:
	if body.has_method("clear_interactable"):
		body.clear_interactable(self)
		if prompt:
			prompt.hide()


## El jugador llama a esta función al presionar E.
func interact(player: Node) -> void:
	if enabled:
		interacted.emit(player)
