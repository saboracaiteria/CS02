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

func _ready():
	add_to_group("bot")
	add_to_group("enemy" if team == "Vermelho" else "ally")
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	# Procura objetivo inicial após o mapa carregar
	await get_tree().create_timer(1.0).timeout
	_find_next_objective()

func _physics_process(delta):
	if is_dead: return
	
	_check_for_enemies()
	
	if target_node:
		var target_pos = target_node.global_position
		nav_agent.target_position = target_pos
		
		if nav_agent.is_navigation_finished():
			_find_next_objective()
			return
			
		var current_pos = global_position
		var next_path_pos = nav_agent.get_next_path_position()
		var new_velocity = (next_path_pos - current_pos).normalized() * speed
		
		if !nav_agent.is_target_reached():
			velocity = new_velocity
			# Olhar para onde está andando
			var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		else:
			velocity = Vector3.ZERO
	
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
	var min_dist = 20.0 # Range de visão
	
	for enemy in enemies:
		if enemy == self or enemy.get("team") == team or enemy.get("health") <= 0: continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			closest_enemy = enemy
			min_dist = dist
	
	if closest_enemy:
		# Lógica de Atirar
		look_at(closest_enemy.global_position, Vector3.UP)
		_shoot()
		# Prioriza matar o inimigo antes de correr pro objetivo
		velocity = Vector3.ZERO 

func _shoot():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shoot_time < fire_rate: return
	last_shoot_time = now
	
	# Efeitos de tiro
	if gunshot_sound: gunshot_sound.play()
	
	# Raycast simplificado para o bot
	raycast.target_position = Vector3(0, 0, -30) # Frente do bot
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

@rpc("any_peer")
func recieve_damage(damage:= 1) -> void:
	health -= damage
	if health <= 0:
		_die()

func _die():
	is_dead = true
	velocity = Vector3.ZERO
	# Animação de morte / Sumir
	hide()
	await get_tree().create_timer(5.0).timeout # Espera respawn
	_respawn()

func _respawn():
	global_position = Vector3(randf_range(-10, 10), 2, randf_range(-10, 10))
	health = 2
	is_dead = false
	show()
