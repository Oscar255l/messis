extends CharacterBody2D
## Gabriel: el personaje del jugador.
## Por ahora sabe caminar, correr, agacharse y saltar.

# --- Velocidades (en píxeles por segundo) ---
# Cambia estos números y vuelve a probar: así se "afina" cómo se siente el juego.
const WALK_SPEED := 60.0      # Caminar
const RUN_SPEED := 110.0      # Correr (manteniendo Shift)
const CROUCH_SPEED := 30.0    # Moverse agachado
const ACCELERATION := 600.0   # Qué tan rápido alcanza la velocidad
const FRICTION := 900.0       # Qué tan rápido frena al soltar las teclas

# --- Salto y gravedad ---
const GRAVITY := 700.0        # Fuerza que lo empuja hacia abajo
const JUMP_VELOCITY := -230.0 # Negativo = hacia arriba (en Godot, Y crece hacia abajo)
const JUMP_CUT := 0.5         # Si suelta el salto antes, el salto se corta a la mitad

# --- Tamaño del cuerpo (colisión) de pie y agachado ---
const STAND_HEIGHT := 26.0
const CROUCH_HEIGHT := 18.0

# --- Animación ---
const FRAME_IDLE := 0
const WALK_FRAMES := [1, 2, 3, 4]
const FRAME_CROUCH := 5
const FRAME_AIR := 6
const WALK_ANIM_FPS := 8.0    # Cuadros por segundo al caminar

var is_crouching := false
var walk_timer := 0.0

# @onready busca los nodos hijos cuando la escena ya está lista.
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


# _physics_process se ejecuta 60 veces por segundo. Aquí va todo el movimiento.
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_crouch()
	handle_jump()
	handle_horizontal_movement(delta)

	# move_and_slide mueve al personaje usando "velocity" y lo detiene contra paredes y suelo.
	move_and_slide()
	update_sprite(delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func handle_crouch() -> void:
	var wants_to_crouch := Input.is_action_pressed("crouch") and is_on_floor()

	if wants_to_crouch and not is_crouching:
		set_crouching(true)
	elif not wants_to_crouch and is_crouching and can_stand_up():
		# Solo se levanta si hay espacio encima (por ejemplo, no dentro de un ducto).
		set_crouching(false)


func handle_jump() -> void:
	# No puede saltar agachado.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# Salto variable: si suelta la tecla mientras sube, sube menos.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT


func handle_horizontal_movement(delta: float) -> void:
	# get_axis devuelve -1 (izquierda), 1 (derecha) o 0 (nada presionado).
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := get_current_speed() * direction

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func get_current_speed() -> float:
	if is_crouching:
		return CROUCH_SPEED
	if Input.is_action_pressed("run"):
		return RUN_SPEED
	return WALK_SPEED


func set_crouching(value: bool) -> void:
	is_crouching = value
	var height := CROUCH_HEIGHT if value else STAND_HEIGHT
	var shape := collision.shape as RectangleShape2D
	shape.size.y = height
	# El origen del personaje está en sus pies, así que la caja se sube la mitad de su alto.
	collision.position.y = -height / 2.0


func can_stand_up() -> bool:
	# test_move pregunta: "si me moviera hacia arriba, ¿chocaría con algo?"
	var extra_height := STAND_HEIGHT - CROUCH_HEIGHT
	return not test_move(global_transform, Vector2(0.0, -extra_height))


func update_sprite(delta: float) -> void:
	# Cuadros de la hoja de sprites (gabriel.png):
	# 0 = quieto, 1-4 = caminar, 5 = agachado, 6 = en el aire.
	if is_crouching:
		sprite.frame = FRAME_CROUCH
	elif not is_on_floor():
		sprite.frame = FRAME_AIR
	elif absf(velocity.x) > 5.0:
		# Mientras más rápido va, más rápido cambian los cuadros (al correr se nota).
		walk_timer += delta * WALK_ANIM_FPS * (absf(velocity.x) / WALK_SPEED)
		sprite.frame = WALK_FRAMES[int(walk_timer) % WALK_FRAMES.size()]
	else:
		sprite.frame = FRAME_IDLE
		walk_timer = 0.0
	# Voltear el dibujo según hacia dónde camina.
	if velocity.x < 0.0:
		sprite.flip_h = true
	elif velocity.x > 0.0:
		sprite.flip_h = false
