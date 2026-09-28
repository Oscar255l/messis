extends StaticBody2D
## Puerta que se abre con la tarjeta de acceso.
## Indicador: rojo = nivel insuficiente, ámbar = puedes abrirla, verde = abierta.

@export var required_level := 1

const COLOR_DENIED := Color(0.9, 0.15, 0.1)
const COLOR_READY := Color(1.0, 0.7, 0.15)
const COLOR_OPEN := Color(0.25, 0.9, 0.35)

var is_open := false

@onready var panel: Sprite2D = $Panel
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var indicator: Sprite2D = $Indicator
@onready var indicator_light: PointLight2D = $IndicatorLight
@onready var zone: Interactable = $InteractZone


func _ready() -> void:
	zone.interacted.connect(_on_interacted)
	zone.player_entered.connect(func(_p): update_indicator())
	update_indicator()


func _on_interacted(_player: Node) -> void:
	if is_open:
		return
	if GameState.access_level >= required_level:
		open()
	else:
		HUD.find(self).show_message(tr("MSG_ACCESS_DENIED") % required_level)
		blink_denied()


func open() -> void:
	is_open = true
	zone.enabled = false
	# set_deferred: cambiar la colisión al final del cuadro (Godot lo pide durante la física).
	collision.set_deferred("disabled", true)
	update_indicator()
	# Un Tween anima una propiedad en el tiempo: el panel sube y se esconde en la pared.
	var tween := create_tween()
	tween.tween_property(panel, "position:y", panel.position.y - 40.0, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func update_indicator() -> void:
	var color := COLOR_OPEN
	if not is_open:
		color = COLOR_READY if GameState.access_level >= required_level else COLOR_DENIED
	indicator.modulate = color
	indicator_light.color = color


func blink_denied() -> void:
	var tween := create_tween().set_loops(3)
	tween.tween_property(indicator, "modulate:a", 0.1, 0.08)
	tween.tween_property(indicator, "modulate:a", 1.0, 0.08)
