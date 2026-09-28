extends Node2D
## Objeto que contiene un registro de la historia: terminal, datapad o grabadora.
## El texto no está aquí: está en translations/strings.csv (inglés y español).

@export var log_id := "LOG_01"   # Se usa para armar las claves LOG_01_TITLE y LOG_01_BODY
@export var open_sound := ""      # Sonido extra al abrirlo (por ejemplo, "tape_click" en la grabadora)

@onready var zone: Interactable = $InteractZone


func _ready() -> void:
	zone.interacted.connect(_on_interacted)


func _on_interacted(_player: Node) -> void:
	GameState.mark_log_read(log_id)
	if open_sound != "":
		Sfx.play_ui(self, open_sound)
	HUD.find(self).show_log(log_id + "_TITLE", log_id + "_BODY")
