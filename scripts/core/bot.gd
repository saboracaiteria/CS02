extends CharacterBody3D

@export var team: String = "Vermelho"
@export var speed: float = 4.0
@export var health: int = 100

var target_node: Node3D = null
var is_dead: bool = false
var last_shoot_time: float = 0.0
var fire_rate: float = 0.4

@onready var nav_agent = $NavigationAgent3D
@onready var raycast = $RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var weapon = $Camera3D/WeaponRoot
@onready var gunshot_sound = $AudioStreamPlayer3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("bot")
	add_to_group("enemy" if team == "Vermelho" else "ally")
	
	# SNAP DE CHÃO IMEDIATO 🏙️🚀🎯
	global_position.y = 1.0 # Força pro nível do player
	
	# Aguarda o mundo carregar e busca objetivo
	await get_tree().create_timer(0.5).timeout
	_find_next_objective()

enum State {PATROL, COMBAT, SEARCH}
var current_state: State = State.PATROL

var last_known_position: Vector3 = Vector3.ZERO
var search_timer: float = 0.0
var accuracy: float = 0.0 # Começa em 0 e vai até 1.0 (100%)
var strafe_timer: float = 0.0
var strafe_dir: Vector3 = Vector3.ZERO

func _physics_process(delta):
	if is_dead: return
	
	# GRAVIDADE SEMPRE ATIVA
	if not is_on_floor():
		velocity.y -= gravity * 5.0 * delta
	else:
		velocity.y = -1.0
	
	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.COMBAT:
			_state_combat(delta)
		State.SEARCH:
			_state_search(delta)
	
	move_and_slide()
	_update_animations()

func _state_patrol(delta):
	if _check_for_enemies():
		current_state = State.COMBAT
		return
		
	if target_node:
		var dir = (target_node.global_position - global_position).normalized()
		dir.y = 0
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_smooth_look_at(global_position + dir, delta)
		
		# Se chegar na área ou ela for capturada, muda o patrol
		if global_position.distance_to(target_node.global_position) < 2.0:
			_find_next_objective()

func _state_combat(delta):
	var enemy = _check_for_enemies()
	if !enemy:
		current_state = State.SEARCH
		search_timer = 5.0
		accuracy = 0.0
		return
		
	last_known_position = enemy.global_position
	_smooth_look_at(enemy.global_position, delta)
	
	# MIRA GRADUAL: Fica mais preciso com o tempo 🎯
	accuracy = move_toward(accuracy, 1.0, delta * 0.5)
	
	# STRAFING: Anda pros lados para dificultar o seu tiro 🏃💨
	strafe_timer -= delta
	if strafe_timer <= 0:
		strafe_timer = randf_range(0.5, 1.5)
		strafe_dir = Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()
	
	velocity.x = strafe_dir.x * (speed * 0.5)
	velocity.z = strafe_dir.z * (speed * 0.5)
	
	# TIRO
	shoot_timer += delta
	if shoot_timer >= 1.0 / fire_rate:
		if randf() < accuracy: # Só acerta se a precisão permitir
			_shoot(enemy)
		else:
			_shoot(null) # Erra o tiro
		shoot_timer = 0

func _state_search(delta):
	search_timer -= delta
	if search_timer <= 0 or _check_for_enemies():
		current_state = State.PATROL
		return
		
	# Vai até onde viu o inimigo pela última vez 🕵️‍♂️
	var dir = (last_known_position - global_position).normalized()
	dir.y = 0
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_smooth_look_at(last_known_position, delta)

func _smooth_look_at(target: Vector3, delta: float):
	var look_pos = Vector3(target.x, global_position.y, target.z)
	if global_position.distance_to(look_pos) > 0.1:
		var new_transform = transform.looking_at(look_pos, Vector3.UP)
		transform = transform.interpolate_with(new_transform, delta * 5.0)

func _check_for_enemies():
	var enemies = get_tree().get_nodes_in_group("player")
	for e in enemies:
		if e.get("team") == team or e.get("health") <= 0: continue
		var dist = global_position.distance_to(e.global_position)
		if dist < detection_range:
			# Raycast de linha de visão
			raycast.target_position = raycast.to_local(e.global_position + Vector3(0, 1.5, 0))
			raycast.force_raycast_update()
			if !raycast.is_colliding() or raycast.get_collider() == e:
				return e
	return null

@onready var hp_bar = $HPBar

func _process(delta):
	if is_dead: return
	if hp_bar:
		hp_bar.text = "HP: %d" % health
		hp_bar.modulate = Color(1, health/100.0, 0) # Fica vermelho conforme morre

func _shoot(target):
	if gunshot_sound:
		gunshot_sound.pitch_scale = randf_range(0.9, 1.1) # Distingue os tiros 🔊
		gunshot_sound.play()
		
	# Muzzle Flash
	var flash = get_node_or_null("Camera3D/WeaponRoot/MuzzleFlash")
	if flash:
		flash.show()
		await get_tree().create_timer(0.05).timeout
		flash.hide()
	
	if target and target.has_method("recieve_damage"):
		target.recieve_damage.rpc_id(target.get_multiplayer_authority(), 1)

func _update_animations():
	if velocity.length() > 0.1: anim_player.play("move")
	else: anim_player.play("idle")

func _find_next_objective():
	# Procura a Área de Captura (A, B ou C) mais próxima que não seja nossa
	var zones = get_tree().get_nodes_in_group("capture_zone")
	if zones.is_empty(): return
	
	var best_zone = zones[randi() % zones.size()]
	target_node = best_zone

@rpc("any_peer", "call_local")
func recieve_damage(damage:= 1) -> void:
	if is_dead: return
	health -= damage
	Global.log_error("DANO: Bot %s recebeu %d de dano. Vida: %d" % [name, damage, health])
	if health <= 0:
		_die()

func _die():
	Global.log_error("SISTEMA: Bot %s foi eliminado!" % name)
	is_dead = true
	velocity = Vector3.ZERO
	collision_layer = 0 # Para de bloquear tiros
	hide()
	# Respawn após 5 segundos
	await get_tree().create_timer(5.0).timeout 
	_respawn()

func _respawn():
	global_position = Vector3(randf_range(-10, 10), 2, randf_range(-10, 10))
	health = 2
	is_dead = false
	show()
