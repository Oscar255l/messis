extends Node2D
## Tarjeta de acceso que se puede recoger. Sube el nivel de acceso de Gabriel.

@export var level := 2

@onready var sprite: Sprite2D = $Sprite2D
@onready var zone: Interactable = $InteractZone


func _ready() -> void:
	zone.interacted.connect(_on_interacted)


func _process(_delta: float) -> void:
	# Flota un poquito para que se note que se puede recoger.
	sprite.position.y = -4.0 + round(sin(Time.get_ticks_msec() / 300.0))


func _on_interacted(_player: Node) -> void:
	GameState.grant_access(level)
	HUD.find(self).show_message(tr("MSG_KEYCARD") % level)
	queue_free()   # La tarjeta desaparece del mundo
