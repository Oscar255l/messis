class_name GameState
extends RefCounted
## Datos de la partida que deben recordarse entre escenas.
## Usa variables "static": se accede a ellas desde cualquier script con GameState.nombre.

## Nivel de acceso de la tarjeta de Gabriel. Como guardia empieza con nivel 1.
static var access_level := 1

## Registros (audios, documentos) que el jugador ya leyó.
static var logs_read: Array[String] = []


static func grant_access(level: int) -> void:
	# maxi devuelve el mayor: una tarjeta de nivel bajo no te quita acceso.
	access_level = maxi(access_level, level)


static func mark_log_read(log_id: String) -> void:
	if not logs_read.has(log_id):
		logs_read.append(log_id)
