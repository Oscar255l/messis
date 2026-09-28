class_name GameState
extends RefCounted
## Datos de la partida que deben recordarse entre escenas.
## Usa variables "static": se accede a ellas desde cualquier script con GameState.nombre.

const CLIP_SIZE := 8   # Balas por cargador de la pistola

## Nivel de acceso de la tarjeta de Gabriel. Como guardia empieza con nivel 1.
static var access_level := 1
## Registros (audios, documentos) que el jugador ya leyó.
static var logs_read: Array[String] = []

# --- Pistola ---
static var has_pistol := false
static var ammo_clip := 0       # Balas en el cargador
static var ammo_reserve := 0    # Balas de repuesto

## Punto de control: si Gabriel muere, vuelve aquí con lo que tenía en ese momento.
static var checkpoint := {}


static func grant_access(level: int) -> void:
	# maxi devuelve el mayor: una tarjeta de nivel bajo no te quita acceso.
	access_level = maxi(access_level, level)


static func mark_log_read(log_id: String) -> void:
	if not logs_read.has(log_id):
		logs_read.append(log_id)


static func save_checkpoint(pos: Vector2) -> void:
	checkpoint = {
		"pos": pos, "access": access_level, "pistol": has_pistol,
		"clip": ammo_clip, "reserve": ammo_reserve,
	}


## Restaura el último punto de control. Si no hay, reinicia todo.
static func load_checkpoint() -> void:
	if checkpoint.is_empty():
		reset()
		return
	access_level = checkpoint.access
	has_pistol = checkpoint.pistol
	ammo_clip = checkpoint.clip
	ammo_reserve = checkpoint.reserve


static func reset() -> void:
	access_level = 1
	logs_read.clear()
	has_pistol = false
	ammo_clip = 0
	ammo_reserve = 0
	checkpoint = {}
