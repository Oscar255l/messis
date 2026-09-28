class_name HUD
extends CanvasLayer
## Interfaz en pantalla: mensajes cortos y el lector de registros de la historia.

const TYPE_SPEED := 60.0   # Letras por segundo del efecto "máquina de escribir"

@onready var message: Label = $Root/Message
@onready var log_panel: Panel = $Root/LogPanel
@onready var log_title: Label = $Root/LogPanel/Title
@onready var log_body: Label = $Root/LogPanel/Body

var message_tween: Tween
var type_tween: Tween


## Cualquier objeto puede encontrar el HUD con: HUD.find(self)
static func find(from: Node) -> HUD:
	return from.get_tree().get_first_node_in_group("hud")


func _ready() -> void:
	add_to_group("hud")
	# El HUD sigue funcionando aunque el juego esté en pausa (mientras lees un registro).
	process_mode = Node.PROCESS_MODE_ALWAYS
	log_panel.hide()
	message.modulate.a = 0.0


func show_message(text: String) -> void:
	message.text = text
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_property(message, "modulate:a", 1.0, 0.15)
	message_tween.tween_interval(2.0)
	message_tween.tween_property(message, "modulate:a", 0.0, 0.6)


func show_log(title_key: String, body_key: String) -> void:
	# tr() traduce una clave al idioma actual (inglés o español).
	log_title.text = tr(title_key)
	log_body.text = tr(body_key)
	log_body.visible_ratio = 0.0
	log_panel.show()
	get_tree().paused = true
	if type_tween:
		type_tween.kill()
	type_tween = create_tween()
	type_tween.tween_property(log_body, "visible_ratio", 1.0, log_body.text.length() / TYPE_SPEED)


func close_log() -> void:
	log_panel.hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not log_panel.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if log_body.visible_ratio < 1.0:
			# Primer E: mostrar todo el texto de una vez. Segundo E: cerrar.
			type_tween.kill()
			log_body.visible_ratio = 1.0
		else:
			close_log()
