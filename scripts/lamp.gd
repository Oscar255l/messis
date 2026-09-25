extends PointLight2D
## Lámpara de la estación. Puede parpadear (dañada) o pulsar (alarma).

@export var flicker := false   # Parpadeo irregular, como una lámpara dañada
@export var pulse := false     # Pulso suave, como una luz de emergencia

var base_energy := 1.0
var timer := 0.0
var time := 0.0


func _ready() -> void:
	base_energy = energy


func _process(delta: float) -> void:
	time += delta
	if pulse:
		# sin() sube y baja entre -1 y 1: la luz "respira".
		energy = base_energy * (0.55 + 0.45 * sin(time * 3.0))
	elif flicker:
		timer -= delta
		if timer <= 0.0:
			# La mayoría del tiempo encendida; a veces se apaga un instante.
			var on := randf() > 0.25
			energy = base_energy if on else base_energy * randf_range(0.0, 0.3)
			timer = randf_range(0.04, 0.3) if on else randf_range(0.03, 0.12)
