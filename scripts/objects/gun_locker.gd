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
	Sfx.play_at(self, "locker_open", global_position)
	Sfx.play_ui(self, "pickup_gun", -4.0)
	zone.enabled = false
	var hud := HUD.find(self)
	hud.update_ammo()
	hud.show_message(tr("MSG_PISTOL"))
