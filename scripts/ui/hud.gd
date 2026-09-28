class_name HUD
extends CanvasLayer
## Interfaz en pantalla: vida, munición, mensajes cortos, lector de registros y pantalla de muerte.

const TYPE_SPEED := 60.0   # Letras por segundo del efecto "máquina de escribir"
const BAR_WIDTH := 40.0

@onready var message: Label = $Root/Message
@onready var log_panel: Panel = $Root/LogPanel
@onready var log_title: Label = $Root/LogPanel/Title
@onready var log_body: Label = $Root/LogPanel/Body
@onready var health_fill: ColorRect = $Root/Health/Fill
@onready var ammo_label: Label = $Root/Ammo
@onready var death_overlay: ColorRect = $Root/DeathOverlay
@onready var death_label: Label = $Root/DeathOverlay/Label

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
	death_overlay.modulate.a = 0.0
	death_overlay.hide()
	# call_deferred: esperar a que todo el nivel esté listo antes de leer los datos del jugador.
	refresh.call_deferred()


func refresh() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		update_health(player.health, player.MAX_HEALTH)
	update_ammo()


func update_health(value: int, max_value: int) -> void:
	var ratio := float(value) / float(max_value)
	health_fill.size.x = round(BAR_WIDTH * ratio)
	# Verde cuando está bien, rojo cuando está grave.
	health_fill.color = Color(0.85, 0.2, 0.15) if ratio <= 0.3 else Color(0.35, 0.8, 0.45)


func update_ammo() -> void:
	ammo_label.visible = GameState.has_pistol
	ammo_label.text = "%d / %d" % [GameState.ammo_clip, GameState.ammo_reserve]


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


func show_death() -> void:
	death_label.text = tr("MSG_DEAD")
	death_overlay.show()
	create_tween().tween_property(death_overlay, "modulate:a", 1.0, 1.5)


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
