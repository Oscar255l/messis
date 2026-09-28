extends Node2D
## Casillero de Gabriel con su pistola de servicio.

@export var starting_clip := 8
@export var starting_reserve := 16

@onready var sprite: Sprite2D = $Sprite2D
@onready var zone: Interactable = $InteractZone


func _ready() -> void:
	zone.interacted.connect(_on_interacted)


func _on_interacted(_player: Node) -> void:
	GameState.has_pistol = true
	GameState.ammo_clip = starting_clip
	GameState.ammo_reserve = starting_reserve
	sprite.frame = 1          # Casillero abierto y vacío
	zone.enabled = false
	var hud := HUD.find(self)
	hud.update_ammo()
	hud.show_message(tr("MSG_PISTOL"))
