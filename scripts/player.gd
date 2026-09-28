extends CharacterBody2D
## Gabriel: el personaje del jugador.
## Camina, corre, se agacha, salta, usa la linterna, interactúa, dispara y recibe daño.

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

# --- Pistola ---
const FIRE_RATE := 0.3        # Segundos entre disparos
const RELOAD_TIME := 1.2      # Segundos que tarda en recargar
const SHOT_RANGE := 260.0     # Alcance del disparo en píxeles
const SHOT_DAMAGE := 1

# --- Vida ---
const MAX_HEALTH := 100
const INVULNERABLE_TIME := 0.9   # Tras recibir un golpe, un momento sin recibir más

# --- Ruido: qué tan lejos te pueden oír los enemigos (en píxeles) ---
const NOISE_CROUCH := 20.0
const NOISE_WALK := 60.0
const NOISE_RUN := 140.0
const NOISE_SHOT := 400.0

# --- Animación ---
const FRAME_IDLE := 0
const WALK_FRAMES := [1, 2, 3, 4]
const FRAME_CROUCH := 5
const FRAME_AIR := 6
const FRAME_AIM := 7
const WALK_ANIM_FPS := 8.0    # Cuadros por segundo al caminar

var is_crouching := false
var walk_timer := 0.0

# @onready busca los nodos hijos cuando la escena ya está lista.
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var flashlight: PointLight2D = $Flashlight
@onready var muzzle_flash: PointLight2D = $MuzzleFlash
@onready var camera: Camera2D = $Camera2D

# Hacia dónde mira Gabriel: 1 = derecha, -1 = izquierda.
var facing := 1

# Objeto con el que Gabriel puede interactuar ahora mismo (puerta, terminal...).
var current_interactable: Interactable = null

var health := MAX_HEALTH
var is_dead := false
var invulnerable_timer := 0.0
var hurt_timer := 0.0         # Mientras es mayor que 0, el retroceso del golpe manda
var shoot_cooldown := 0.0
var reload_timer := 0.0
var aim_timer := 0.0          # Tiempo que mantiene el brazo extendido tras disparar
var shot_noise_timer := 0.0
var shake := 0.0              # Fuerza del temblor de cámara


# _enter_tree ocurre antes que _ready: así los enemigos ya pueden encontrar a Gabriel.
func _enter_tree() -> void:
	add_to_group("player")


# _physics_process se ejecuta 60 veces por segundo. Aquí va todo el movimiento.
func _physics_process(delta: float) -> void:
	update_timers(delta)
	apply_gravity(delta)
	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		return

	handle_crouch()
	handle_jump()
	handle_horizontal_movement(delta)
	handle_weapon()

	# move_and_slide mueve al personaje usando "velocity" y lo detiene contra paredes y suelo.
	move_and_slide()
	update_sprite(delta)
	update_flashlight()


func _process(delta: float) -> void:
	# Temblor de cámara: mover la cámara un poquito al azar y calmarla con el tiempo.
	camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)).round()
	shake = move_toward(shake, 0.0, 20.0 * delta)


func update_timers(delta: float) -> void:
	invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	shoot_cooldown = maxf(shoot_cooldown - delta, 0.0)
	aim_timer = maxf(aim_timer - delta, 0.0)
	shot_noise_timer = maxf(shot_noise_timer - delta, 0.0)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			finish_reload()
	# Parpadear mientras es invulnerable.
	sprite.visible = invulnerable_timer <= 0.0 or int(invulnerable_timer * 15.0) % 2 == 0


# _unhandled_input recibe teclas "de una sola vez" (presionar y soltar).
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("flashlight"):
		flashlight.enabled = not flashlight.enabled
	elif event.is_action_pressed("interact") and is_instance_valid(current_interactable):
		current_interactable.interact(self)
		get_viewport().set_input_as_handled()


# Las zonas de interacción llaman a estas dos funciones cuando Gabriel entra o sale.
func set_interactable(zone: Interactable) -> void:
	current_interactable = zone


func clear_interactable(zone: Interactable) -> void:
	if current_interactable == zone:
		current_interactable = null


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
	# No puede saltar agachado ni mientras recibe un golpe.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and hurt_timer <= 0.0:
		velocity.y = JUMP_VELOCITY

	# Salto variable: si suelta la tecla mientras sube, sube menos.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT


func handle_horizontal_movement(delta: float) -> void:
	if hurt_timer > 0.0:
		return   # El retroceso del golpe controla el movimiento un instante
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
	if aim_timer > 0.0:
		return WALK_SPEED * 0.5   # Al disparar se mueve más lento
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


# ------------------------------------------------------------------ Pistola

func handle_weapon() -> void:
	if not GameState.has_pistol:
		return
	if Input.is_action_just_pressed("reload"):
		start_reload()
	elif Input.is_action_just_pressed("shoot"):
		shoot()


func shoot() -> void:
	if shoot_cooldown > 0.0 or reload_timer > 0.0:
		return
	if GameState.ammo_clip <= 0:
		if GameState.ammo_reserve > 0:
			start_reload()
		else:
			HUD.find(self).show_message(tr("MSG_NO_AMMO"))
		return

	GameState.ammo_clip -= 1
	HUD.find(self).update_ammo()
	shoot_cooldown = FIRE_RATE
	aim_timer = 0.45
	shot_noise_timer = 0.3
	shake = 2.0

	# Disparo instantáneo ("hitscan"): se lanza un rayo invisible y se revisa qué toca primero.
	var muzzle_y := -8.0 if is_crouching else -14.0
	var origin := global_position + Vector2(11.0 * facing, muzzle_y)
	var target := origin + Vector2(SHOT_RANGE * facing, 0.0)
	# Máscara 1 + 2: choca con el mundo (capa 1) y con los enemigos (capa 2).
	var query := PhysicsRayQueryParameters2D.create(origin, target, 1 | 2, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var end := target
	if hit:
		end = hit.position
		if hit.collider.has_method("take_hit"):
			hit.collider.take_hit(SHOT_DAMAGE, facing)

	spawn_tracer(origin, end)
	flash_muzzle()


func spawn_tracer(from: Vector2, to: Vector2) -> void:
	# Una línea brillante que dura un instante: el "rastro" de la bala.
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = Color(1.0, 0.85, 0.5)
	line.add_point(from)
	line.add_point(to)
	get_parent().add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.08)
	tween.tween_callback(line.queue_free)


func flash_muzzle() -> void:
	muzzle_flash.position = Vector2(12.0 * facing, -8.0 if is_crouching else -14.0)
	muzzle_flash.enabled = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.enabled = false


func start_reload() -> void:
	if reload_timer > 0.0 or GameState.ammo_reserve <= 0 or GameState.ammo_clip >= GameState.CLIP_SIZE:
		return
	reload_timer = RELOAD_TIME
	HUD.find(self).show_message(tr("MSG_RELOADING"))


func finish_reload() -> void:
	var needed := GameState.CLIP_SIZE - GameState.ammo_clip
	var taken := mini(needed, GameState.ammo_reserve)
	GameState.ammo_clip += taken
	GameState.ammo_reserve -= taken
	HUD.find(self).update_ammo()


# ------------------------------------------------------------------ Vida

## Los enemigos llaman a esta función cuando golpean a Gabriel.
func take_damage(amount: int, from_x: float) -> void:
	if is_dead or invulnerable_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	HUD.find(self).update_health(health, MAX_HEALTH)
	invulnerable_timer = INVULNERABLE_TIME
	hurt_timer = 0.25
	shake = 4.0
	# Retroceso: empujarlo en dirección contraria al golpe.
	var push_dir := signf(global_position.x - from_x)
	velocity = Vector2(push_dir * 140.0, -90.0)
	if health <= 0:
		die()


func die() -> void:
	is_dead = true
	sprite.frame = FRAME_CROUCH
	sprite.modulate = Color(0.6, 0.3, 0.3)
	flashlight.enabled = false
	HUD.find(self).show_death()
	await get_tree().create_timer(3.0).timeout
	# Volver al último punto de control y recargar el nivel.
	GameState.load_checkpoint()
	get_tree().reload_current_scene()


## Qué tan lejos se escucha a Gabriel ahora mismo.
func get_noise_radius() -> float:
	if is_dead:
		return 0.0
	if shot_noise_timer > 0.0:
		return NOISE_SHOT
	var speed := absf(velocity.x)
	if speed < 5.0:
		return 0.0
	if is_crouching:
		return NOISE_CROUCH
	if speed > WALK_SPEED + 5.0:
		return NOISE_RUN
	return NOISE_WALK


# ------------------------------------------------------------------ Aspecto

func update_sprite(delta: float) -> void:
	# Cuadros de la hoja de sprites (gabriel.png):
	# 0 = quieto, 1-4 = caminar, 5 = agachado, 6 = en el aire, 7 = apuntando.
	if is_crouching:
		sprite.frame = FRAME_CROUCH
	elif not is_on_floor():
		sprite.frame = FRAME_AIR
	elif aim_timer > 0.0:
		sprite.frame = FRAME_AIM
	elif absf(velocity.x) > 5.0:
		# Mientras más rápido va, más rápido cambian los cuadros (al correr se nota).
		walk_timer += delta * WALK_ANIM_FPS * (absf(velocity.x) / WALK_SPEED)
		sprite.frame = WALK_FRAMES[int(walk_timer) % WALK_FRAMES.size()]
	else:
		sprite.frame = FRAME_IDLE
		walk_timer = 0.0
	# Voltear el dibujo según hacia dónde camina (no durante el retroceso de un golpe).
	if hurt_timer <= 0.0:
		var direction := Input.get_axis("move_left", "move_right")
		if direction < 0.0:
			facing = -1
		elif direction > 0.0:
			facing = 1
	sprite.flip_h = facing == -1


func update_flashlight() -> void:
	# La linterna va en el hombro: se mueve de lado y baja al agacharse.
	flashlight.position.x = 5.0 * facing
	flashlight.position.y = -9.0 if is_crouching else -17.0
	# Girarla 180 grados cuando mira a la izquierda.
	flashlight.rotation = 0.0 if facing == 1 else PI
