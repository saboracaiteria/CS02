extends CharacterBody3D

@export var team: String = "Vermelho"
@export var speed: float = 4.0
@export var health: int = 2

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
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	# Aguarda o mundo carregar
	await get_tree().create_timer(1.0).timeout
	_find_next_objective()

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var reaction_time: float = 0.6 # Segundos para reagir
var can_see_enemy: bool = false

func _physics_process(delta):
	if is_dead: return
	
	# GRAVIDADE SUPER FORTE (IMÃ DE CHÃO!) 🏙️🚀🎯
	if not is_on_floor():
		velocity.y -= gravity * 5.0 * delta # 5x mais forte
	else:
		velocity.y = -1.0 # Empurra pro chão
	
	_check_for_enemies()
	
	if target_node and !can_see_enemy:
		# MOVIMENTAÇÃO SEM NAV_MESH (DIRETA COM DESVIO) 🏙️🚩🥇
		var target_pos = target_node.global_position
		var dir = (target_pos - global_position).normalized()
		dir.y = 0 # Mantém no chão
		
		# Sensores de desvio (Simples)
		raycast.target_position = dir * 2.0
		if raycast.is_colliding():
			# Se houver parede, tenta desviar para o lado
			dir = dir.rotated(Vector3.UP, PI/2)
		
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		
		# Olhar para a direção do movimento
		var look_target = global_position + dir
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
	elif can_see_enemy:
		# Para para atirar
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
	# Animação Simples
	if velocity.length() > 0.1:
		anim_player.play("move")
	else:
		anim_player.play("idle")

func _check_for_enemies():
	# IA Reativa: Procura o player mais próximo que não seja do mesmo time
	var enemies = get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("bot")
	var closest_enemy = null
	var min_dist = detection_range
	
	for enemy in enemies:
		if enemy == self or enemy.get("team") == team or enemy.get("health") <= 0: continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			# Verifica linha de visão real!
			raycast.target_position = raycast.to_local(enemy.global_position + Vector3(0, 1.5, 0))
			raycast.force_raycast_update()
			if !raycast.is_colliding() or raycast.get_collider() == enemy:
				closest_enemy = enemy
				min_dist = dist
	
	if closest_enemy:
		if !can_see_enemy:
			can_see_enemy = true
			await get_tree().create_timer(reaction_time).timeout
		
		if can_see_enemy and !is_dead:
			look_at(closest_enemy.global_position, Vector3.UP)
			rotation.x = 0 
			_shoot()
	else:
		can_see_enemy = false

func _shoot():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shoot_time < 0.2: return # fire_rate fix
	last_shoot_time = now
	
	if gunshot_sound: gunshot_sound.play()
	
	raycast.target_position = Vector3(0, 0, -50)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var col = raycast.get_collider()
		if col.has_method("recieve_damage"):
			col.recieve_damage.rpc_id(col.get_multiplayer_authority(), 1)

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
