extends CharacterBody3D

@export var team: String = "Vermelho"
@export var speed: float = 4.0
@export var health: int = 100

var target_node: Node3D = null
var is_dead: bool = false
var last_shoot_time: float = 0.0
var fire_rate: float = 0.4
var shoot_timer: float = 0.0
@export var detection_range: float = 40.0

@onready var nav_agent = $NavigationAgent3D
@onready var raycast = $RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var weapon = $Camera3D/WeaponRoot
@onready var gunshot_sound = $AudioStreamPlayer3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("bot")
	add_to_group("enemy" if team == "Vermelho" else "ally")
	
	# Ajuste de Máscara de Colisão V1880: Cenário (1) + Jogadores (2)
	raycast.collision_mask = 3 
	accuracy = randf_range(0.2, 0.5) # Mais agressivos!
	
	# SNAP DE CHÃO IMEDIATO 🏙️🚀🎯
	global_position.y = 1.0 # Força pro nível do player
	
	# Configuração do Navigation Agent
	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5
	
	# Aguarda o mundo carregar e busca objetivo
	await get_tree().create_timer(1.0).timeout
	# STAGGER DE ACURÁCIA: Cada bot começa com acurácia aleatória diferente 🎯
	# Isso evita que todos os bots atinjam acurácia máxima no mesmo instante!
	accuracy = randf_range(0.0, 0.3)
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
		# Se a zona já for nossa, procura outra! 🏙️🚩🥇
		if target_node.get("owning_team") == team:
			_find_next_objective()
			return

		nav_agent.target_position = target_node.global_position
		
		if nav_agent.is_navigation_finished():
			_find_next_objective()
			return

		var next_path_pos = nav_agent.get_next_path_position()
		var dir = (next_path_pos - global_position).normalized()
		dir.y = 0
		
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_smooth_look_at(global_position + dir, delta)
		
		# Se chegar na área (fallback se o nav falhar)
		if global_position.distance_to(target_node.global_position) < 2.5:
			# Fica na área até capturar!
			velocity.x = 0
			velocity.z = 0

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
	nav_agent.target_position = last_known_position
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_position).normalized()
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
		gunshot_sound.pitch_scale = randf_range(0.9, 1.1)
		gunshot_sound.play()
		
	# Muzzle Flash
	var flash = get_node_or_null("Camera3D/WeaponRoot/MuzzleFlash")
	if flash:
		flash.show()
		await get_tree().create_timer(0.05).timeout
		flash.hide()
	
	# Lógica de Rastreador de Bala (Tracer) V1800 🏙️🎯🥇
	var from_pos = global_position + Vector3.UP * 1.5
	if weapon: from_pos = weapon.global_position
	
	var to_pos = Vector3.ZERO
	if target:
		to_pos = target.global_position + Vector3.UP * 1.2
	else:
		# Se errar, atira numa direção aleatória à frente
		var forward = -global_transform.basis.z
		to_pos = from_pos + (forward.rotated(Vector3.UP, randf_range(-0.5, 0.5)) * 50.0)
	
	_spawn_bullet_tracer.rpc(from_pos, to_pos)
	
	if target and target.has_method("recieve_damage"):
		var target_auth = target.get_multiplayer_authority()
		var damage_to_deal = 15 # Dano aumentado para teste V1880
		if target_auth == multiplayer.get_unique_id():
			target.recieve_damage(damage_to_deal)
		else:
			target.recieve_damage.rpc_id(target_auth, damage_to_deal)

@rpc("call_local")
func _spawn_bullet_tracer(from: Vector3, to: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, 0.8, 0.2, 1.0) # Amarelo bala ☀️
	mesh_instance.material_override = material

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	get_parent().add_child(mesh_instance)

	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(mesh_instance.queue_free)

func _update_animations():
	if velocity.length() > 0.1: anim_player.play("move")
	else: anim_player.play("idle")

func _find_next_objective():
	# Procura a Área de Captura (A, B ou C) mais próxima que não seja nossa
	var zones = get_tree().get_nodes_in_group("capture_zone")
	if zones.is_empty(): return
	
	# Filtra apenas zonas que não são do nosso time
	var targets = []
	for z in zones:
		if z.get("owning_team") != team:
			targets.append(z)
	
	if targets.is_empty():
		# Se todas forem nossas, patrulha uma aleatória
		target_node = zones[randi() % zones.size()]
	else:
		# Pega a zona mais próxima entre as capturáveis
		var closest = targets[0]
		var min_dist = global_position.distance_to(closest.global_position)
		for t in targets:
			var d = global_position.distance_to(t.global_position)
			if d < min_dist:
				min_dist = d
				closest = t
		target_node = closest

@rpc("any_peer")
func recieve_damage(damage:= 10) -> void:
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
	# Spawns fixos ou aleatórios seguros
	global_position = Vector3(randf_range(-10, 10), 2, randf_range(-10, 10))
	health = 100
	is_dead = false
	collision_layer = 2 # VOLTA A SER ATINGÍVEL! 🎯🏙️🥇
	current_state = State.PATROL
	_find_next_objective()
	show()

