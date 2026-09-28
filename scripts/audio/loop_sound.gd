extends AudioStreamPlayer2D
## Sonido en bucle ubicado en el mundo (zumbido de una lámpara, alarma...).
## Se escucha más fuerte al acercarse.

@export_file("*.wav") var sound_path := ""


func _ready() -> void:
	if sound_path != "":
		stream = Sfx.load_loop(sound_path)
		play()


func _exit_tree() -> void:
	stop()   # Detener el bucle al salir, para que Godot libere el sonido limpiamente
