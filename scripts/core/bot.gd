extends CharacterBody3D

@export var team: String = "Vermelho"
@export var speed: float = 11.0 # DOBRO DA VELOCIDADE DO PLAYER V2500 🏎️🏃‍♂️💨🏙️🎯🥇
@export var health: int = 100
const VERSION = "V5000" # Canaã PC Fidelity V5 🏙️🎯🥇

var target_node: Node3D = null
var is_dead: bool = false
var last_shoot_time: float = 0.0
var fire_rate: float = 0.4
var shoot_timer: float = 0.0
@export var detection_range: float = 40.0
var nav_refresh_timer: float = 0.0 # V2130 - Anti-Lag
var check_enemy_timer: float = 0.0 # V2130 - Anti-Lag
var stuck_timer: float = 0.0 # V2480 - Anti-Stuck 🏙️🎯🥇
var last_pos: Vector3 = Vector3.ZERO

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
	
	# Aguarda o mundo carregar e a malha de navegação assentar V2500 ⏱️🏙️🎯🥇
	await get_tree().create_timer(1.0).timeout
	
	# SNAP DE CHÃO IMEDIATO 🏙️🚀🎯
	global_position.y = 1.0 # Força pro nível do player
	
	# Configuração do Navigation Agent
	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5
	
	# STAGGER DE ACURÁCIA: Cada bot começa com acurácia aleatória diferente 🎯
	accuracy = randf_range(0.0, 0.3)
	_find_next_objective()
	_apply_elite_skin()
	print("--- BOT %s PRONTO PARA AÇÃO ---" % name)

enum State {PATROL, COMBAT, SEARCH}
var current_state: State = State.PATROL

var last_known_position: Vector3 = Vector3.ZERO
var search_timer: float = 0.0
var accuracy: float = 0.0 # Começa em 0 e vai até 1.0 (100%)
var strafe_timer: float = 0.0
var strafe_dir: Vector3 = Vector3.ZERO

func _physics_process(delta):
	if !is_inside_tree(): return # EVITA ERROS V2390 ✨🎯🥇
	if is_dead: return
	
	# GRAVIDADE SEMPRE ATIVA
	if not is_on_floor():
		velocity.y -= gravity * 5.0 * delta
	else:
		velocity.y = -1.0
	
	match current_state:
		State.PATROL:
			if target_node == null: _find_next_objective()
			_state_patrol(delta)
		State.COMBAT:
			_state_combat(delta)
		State.SEARCH:
			_state_search(delta)
	
	move_and_slide()
	_process_aura_damage(delta)
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

		# OTIMIZAÇÃO V2130: Só recalcula rota 2x por segundo! 🏎️💨
		nav_refresh_timer -= delta
		if nav_refresh_timer <= 0:
			nav_agent.target_position = target_node.global_position
			nav_refresh_timer = 0.5
		
		if nav_agent.is_navigation_finished():
			_find_next_objective()
			return

		var next_path_pos = nav_agent.get_next_path_position()
		
		# FALLBACK V2500: Se a navegação retornar posição inválida ou presa, vai direto! 🚀🏙️🎯🥇
		if next_path_pos.distance_to(global_position) < 0.2:
			next_path_pos = target_node.global_position
			
		var dir = (next_path_pos - global_position).normalized()
		dir.y = 0
		
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_smooth_look_at(global_position + dir, delta)
		
		# SISTEMA ANTI-TRAVAMENTO V2510 🛡️🏙️🥇
		stuck_timer += delta
		if stuck_timer > 2.2: # Mais rápido para detectar!
			if global_position.distance_to(last_pos) < 0.6:
				# SALTO DE ESCAPE: Teletransporta para alto + lado aleatório MAIOR para sair de quinas 🎲🚀
				var escape_dir = Vector3(randf_range(-4.5, 4.5), 4.5, randf_range(-4.5, 4.5))
				global_position += escape_dir
				_find_next_objective() 
				print("--- BOT %s PRESO EM QUINA: EXECUTANDO SALTO DE ESCAPE AMPLIFICADO ---" % name)
			last_pos = global_position
			stuck_timer = 0
		
		# Se chegar na área ou perto dela (Raio ajustado para 2.5m - METADE) 🏙️🎯🥇
		if global_position.distance_to(target_node.global_position) < 2.5:
			# Fica na área até capturar!
			velocity.x = move_toward(velocity.x, 0, speed * delta)
			velocity.z = move_toward(velocity.z, 0, speed * delta)
			# Se a zona já for do nosso time, corre para a PRÓXIMA! 🏁🥇
			if target_node.get("owning_team") == team:
				_find_next_objective()
				return

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
	# OTIMIZAÇÃO V2130: Só procura inimigos 5x por segundo! 🕵️‍♂️
	check_enemy_timer -= get_process_delta_time()
	if check_enemy_timer > 0: return null 
	check_enemy_timer = 0.2

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

func _apply_elite_skin():
	# LIMPEZA TOTAL
	var old_model = get_node_or_null("EliteModel")
	if old_model: old_model.queue_free()
	var box_mesh = get_node_or_null("MeshInstance3D")
	if box_mesh: box_mesh.queue_free()
	
	# CRIAÇÃO DO HUMANOIDE PROCEDURAL V5 (Fidelity) 🏙️🎯🥇
	var skin_script = load("res://scripts/core/procedural_skin.gd")
	var skinner = Node3D.new()
	skinner.set_script(skin_script)
	skinner.name = "EliteModel"
	add_child(skinner)
	
	# Configura cores baseadas no time
	var bot_color = Color(1.0, 0.4, 0.0) # Elite Orange
	if team == "Azul": bot_color = Color(0.0, 0.5, 1.0)
	
	skinner.setup(bot_color)
	skinner.position.y = -0.2 # Ajuste para os pés ficarem no chão (Compensando o PelvePivot Y=1.0)
	
	Global.log_error("IA: Bot %s agora e um HUMANOIDE CANAÃ V5!" % name)

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
		var damage_to_deal = 20 # Dano aumentado V1890 🏙️🎯🥇
		if target_auth == multiplayer.get_unique_id():
			target.recieve_damage(damage_to_deal)
		else:
			target.recieve_damage.rpc_id(target_auth, damage_to_deal)

# AURA DE DANO V1890: Se chegar muito perto, toma dano garantido! 🏙️🎯🥇
func _process_aura_damage(delta):
	if is_dead: return
	var player = _check_for_enemies()
	if player and global_position.distance_to(player.global_position) < 2.5:
		if randf() < 0.05: # Chance de dano contínuo
			player.recieve_damage(5)

@rpc("call_local")
func _spawn_bullet_tracer(from: Vector3, to: Vector3):
	# SISTEMA ULTRA-LEVE V2140 🏙️🎯🥇 - Zero Lag para Bots
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, 0.7, 0, 0.8) # Laranja 🟠
	mesh_instance.material_override = material

	get_tree().root.add_child.call_deferred(mesh_instance)

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	var tracer_tween = create_tween()
	tracer_tween.tween_interval(0.05)
	tracer_tween.tween_callback(mesh_instance.queue_free)

func _update_animations():
	var model_root = get_node_or_null("EliteModel")
	if !model_root: return

	# Lógica de Morte 💀
	if is_dead:
		model_root.rotation.x = lerp(model_root.rotation.x, deg_to_rad(85), 0.2)
		return

	var speed_f = velocity.length()
	
	# Driver Procedural V4 (Canaã) 🏙️🏃‍♂️✨
	if model_root.has_method("update_animation"):
		model_root.update_animation(speed_f, get_process_delta_time())
	
	# Inclinação de ataque leve 🔫
	if speed_f > 0.5:
		model_root.rotation.x = lerp(model_root.rotation.x, -0.1, 0.1)
	else:
		model_root.rotation.x = lerp(model_root.rotation.x, 0.0, 0.1)

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
		# PRIORIDADE MÁXIMA V2500: Recuperar áreas do inimigo primeiro! 🏙️🎯🥇
		var enemy_zones = []
		for t in targets:
			if t.get("owning_team") != "Nenhum":
				enemy_zones.append(t)
		
		var list_to_search = enemy_zones if !enemy_zones.is_empty() else targets
		
		# Pega a zona mais próxima entre as filtradas
		var closest = list_to_search[0]
		var min_dist = global_position.distance_to(closest.global_position)
		for t in list_to_search:
			var d = global_position.distance_to(t.global_position)
			if d < min_dist:
				min_dist = d
				closest = t
		target_node = closest

@rpc("any_peer", "call_local")
func recieve_damage(damage:= 10, attacker_id = null) -> void:
	if is_dead: return
	health -= damage
	if health <= 0:
		# CREDITA KILL AO PLAYER V2500 🏙️🎯🥇
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			# Se o atacante for o player local (multiplayer ou single)
			if attacker_id is CSPlayer or (attacker_id is int and attacker_id == 1):
				gm.player_kills += 1
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

