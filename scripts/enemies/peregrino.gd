extends CharacterBody2D
## Peregrino: humano infectado en la segunda etapa. Agresivo, busca la planta
## y ataca a quien se cruce. Se guía sobre todo por el SONIDO.
##
## Estados (una "máquina de estados"): el enemigo solo hace una cosa a la vez.
##   FEEDING  -> agachado junto a un cuerpo; no ve, solo escucha
##   ALERT    -> te detectó: grita un instante
##   CHASE    -> corre hacia ti
##   ATTACK   -> prepara el golpe y lo lanza
##   STAGGER  -> aturdido por un disparo
##   DEAD     -> muerto

enum State { FEEDING, ALERT, CHASE, ATTACK, STAGGER, DEAD }

@export var max_health := 4
@export var speed := 95.0              # Más rápido que caminar (60), más lento que correr (110)
@export var attack_damage := 25
@export var start_facing := 1          # 1 = mira a la derecha, -1 = a la izquierda

const GRAVITY := 700.0
const HEARING_MIN := 44.0              # A esta distancia te detecta aunque no hagas ruido
const ATTACK_RANGE := 20.0
const ATTACK_WINDUP := 0.35            # Tiempo antes de que el golpe conecte (para esquivarlo)
const ATTACK_RECOVERY := 0.6
const RUN_ANIM_FPS := 10.0

var state := State.FEEDING
var state_timer := 0.0
var health := 0
var facing := 1
var anim_time := 0.0
var attack_landed := false
var player: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	facing = start_facing
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	state_timer -= delta

	match state:
		State.FEEDING:
			velocity.x = 0.0
			sprite.frame = 0
			if can_hear_player():
				change_state(State.ALERT, 0.6)
		State.ALERT:
			velocity.x = 0.0
			face_player()
			sprite.frame = 6
			if state_timer <= 0.0:
				change_state(State.CHASE)
		State.CHASE:
			process_chase(delta)
		State.ATTACK:
			process_attack(delta)
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			sprite.frame = 6
			if state_timer <= 0.0:
				change_state(State.CHASE)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			sprite.frame = 7

	move_and_slide()
	sprite.flip_h = facing == -1


func process_chase(delta: float) -> void:
	if player == null or player.is_dead:
		velocity.x = 0.0
		sprite.frame = 6
		return
	face_player()
	velocity.x = facing * speed
	anim_time += delta * RUN_ANIM_FPS
	sprite.frame = 1 + int(anim_time) % 4
	if distance_to_player() < ATTACK_RANGE:
		attack_landed = false
		change_state(State.ATTACK, ATTACK_WINDUP + ATTACK_RECOVERY)


func process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	sprite.frame = 5
	# Cuando termina la preparación, el golpe conecta si Gabriel sigue cerca.
	if not attack_landed and state_timer <= ATTACK_RECOVERY:
		attack_landed = true
		if distance_to_player() < ATTACK_RANGE + 8.0 and absf(player.global_position.y - global_position.y) < 24.0:
			player.take_damage(attack_damage, global_position.x)
	if state_timer <= 0.0:
		change_state(State.CHASE)


func change_state(new_state: State, duration := 0.0) -> void:
	state = new_state
	state_timer = duration


func can_hear_player() -> bool:
	if player == null or player.is_dead:
		return false
	var distance := distance_to_player()
	return distance < HEARING_MIN or distance < player.get_noise_radius()


func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)


func face_player() -> void:
	facing = 1 if player.global_position.x > global_position.x else -1


## La pistola de Gabriel llama a esta función cuando la bala le pega.
func take_hit(damage: int, direction: int) -> void:
	if state == State.DEAD:
		return
	health -= damage
	velocity.x = direction * 70.0
	flash()
	if health <= 0:
		die()
	else:
		change_state(State.STAGGER, 0.25)


func flash() -> void:
	# Brillo blanco un instante para que se note el impacto.
	sprite.modulate = Color(3.0, 3.0, 3.0)
	await get_tree().create_timer(0.06).timeout
	sprite.modulate = Color.WHITE


func die() -> void:
	change_state(State.DEAD)
	# Quitarlo de la capa de colisión de enemigos: las balas lo atraviesan.
	set_collision_layer_value(2, false)
