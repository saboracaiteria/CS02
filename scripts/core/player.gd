extends CharacterBody3D
class_name CSPlayer

@onready var camera: Camera3D = $Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $Camera3D/RayCast3D

# Dynamic references for weapons
var weapon: Node3D
var muzzle_flash: GPUParticles3D
var gunshot_sound: AudioStreamPlayer3D

## Number of shots before a player dies
@export var health : int = 2
## The xyz position of the random spawns, you can add as many as you want!
@export var spawns: PackedVector3Array = ([
	Vector3(-18, 0.2, 0),
	Vector3(18, 0.2, 0),
	Vector3(-2.8, 0.2, -6),
	Vector3(-17,0,17),
	Vector3(17,0,17),
	Vector3(17,0,-17),
	Vector3(-17,0,-17)
])
var sensitivity : float =  .005
var controller_sensitivity : float =  .010

var	mouse_captured : bool = true
var gravity: float = 28.0 # GRAVIDADE PESADA PARA FPS REALISTA! 🪐🏗️

# Movement States V1420 🏙️🎯🥇
var is_ads : bool = false
var is_sprinting : bool = false
var is_crouching : bool = false

# Ammo Management V1440  AK-47 🏙️🎯🥇
var current_ammo : int = 50
var total_ammo : int = 150
var max_ammo : int = 50
var is_reloading : bool = false

var default_fov : float = 75.0
var ads_fov : float = 40.0
var sprint_fov : float = 85.0
var fov_speed : float = 12.0

# INVENTÁRIO V1460 🏙️🎯🥇
var weapons_list : Array = ["pistol", "AnimatedPistol", "DualSMGs"]
var current_weapon_index : int = 0

var BASE_SPEED : float = 5.5
var SPRINT_SPEED : float = 9.0
var CROUCH_SPEED : float = 3.0
var SPEED : float = 5.5
var JUMP_VELOCITY : float = 10.5 # AUMENTO DE ELITE! 🏙️🚀🎯

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	# LIMPEZA INICIAL V1450: Esconde todas as armas antes de ativar a desejada! 🏙️🎯🥇
	print("--- PLAYER READY: MULTIPLAYER ID: ", multiplayer.get_unique_id(), " ---")
	
	for child in %WeaponRoot.get_children():
		if child is Node3D:
			child.visible = false

	# PRIORIDADE V1450: Se existir DualSMGs, ela é a ativa! 🏙️🥇🚀
	var dual_node = find_child("DualSMGs", true)
	if dual_node:
		dual_node.visible = true
		print("--- DUAL SMGs ATIVADAS COM SUCESSO! ---")
	else:
		# Fallback para AnimatedPistol se não houver Dual
		var anim_pistol = find_child("AnimatedPistol", true)
		if anim_pistol:
			anim_pistol.visible = true

	_update_weapon_nodes()
	
	add_to_group("player") # INDISPENSÁVEL PARA OS BOTÕES HUD! 🏙️🎯🥇
	
	if is_multiplayer_authority():
		var label = Label.new()
		label.text = "V1460 - AMMO & ARMS SELECTOR! ✨🎯🥇"
		label.modulate = Color(1, 1, 0, 1) 
		label.position = Vector2(20, 20)
		add_child(label)
		
		# DEBUG V1260 🛠️🥋🛡️
		var d_label = Label.new()
		d_label.name = "DebugLabel"
		d_label.position = Vector2(20, 50)
		d_label.modulate = Color(0, 1, 0, 0.7)
		add_child(d_label)

		# ESCONDE HUD NO PC V1260 🚫📱
		if not Global.is_mobile:
			var hud = find_child("TouchControls", true)
			if hud:
				hud.visible = false
				hud.queue_free() # Remove totalmente no PC

	# SINCRONIZA COM O SISTEMA ATIVO V1200 🚀
	default_fov = Global.default_fov
	ads_fov = Global.ads_fov
	camera.fov = default_fov
	camera.make_current()
	print("--- CAMERA PLAYER ATIVADA COM SUCESSO! ---")

# --- SISTEMA DE TROCA DE ARMAS V1460 🏙️🎯🥇 ---
func switch_weapon(weapon_name: String) -> void:
	var weapons = %WeaponRoot.get_children()
	var found = false
	
	for w in weapons:
		if w.name.to_lower() == weapon_name.to_lower():
			w.visible = true
			weapon = w
			found = true
			print("--- ARMA SELECIONADA: ", weapon_name, " ---")
		else:
			w.visible = false
			
	if found:
		_update_weapon_nodes()
		# Reset de munição básico para teste
		current_ammo = max_ammo
		is_reloading = false
	else:
		print("--- ERRO: ARMA '", weapon_name, "' NÃO ENCONTRADA! ---")

func cycle_weapon() -> void:
	current_weapon_index = (current_weapon_index + 1) % weapons_list.size()
	switch_weapon(weapons_list[current_weapon_index])

func _update_weapon_nodes() -> void:
	# BUSCA DINÂMICA V1450: Encontra o que estiver VISÍVEL e for ARMA! 🏙️🎯🥇
	muzzle_flash = null
	gunshot_sound = null
	
	for child in %WeaponRoot.get_children():
		if child is Node3D and child.visible:
			weapon = child
			# Agora busca MuzzleFlash no modelo importado também 🛡️
			var flash_r = weapon.find_child("MuzzleFlash_R", true)
			var flash_l = weapon.find_child("MuzzleFlash_L", true)
			
			if flash_r or flash_l:
				# Para dual, muzzle_flash passa a ser uma referência dinâmica no play_shoot_effects
				pass
			else:
				muzzle_flash = weapon.find_child("GPUParticles3D*", true)
				if !muzzle_flash: muzzle_flash = weapon.find_child("MuzzleFlash*", true)
			
			gunshot_sound = weapon.find_child("AudioStreamPlayer3D*", true)
			if !gunshot_sound: gunshot_sound = weapon.find_child("GunshotSound*", true)
			break
	
	# Fallback se não achar no filho visível (tenta o player todo) 🛡️
	if !muzzle_flash: muzzle_flash = find_child("GPUParticles3D*", true)
	if !gunshot_sound: gunshot_sound = find_child("GunshotSound*", true)
	
	# MIRA DINÂMICA: Ajustada via Gabarito (weapon_base.gd) 🏙️🎯🥇
	if weapon and weapon.has_method("get"):
		# Se a arma for baseada no gabarito, ela já se auto-posicionou! 🛡️
		pass

var is_mobile_shooting : bool = false

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# GESTOR DE DISPARO INTELIGENTE V1440 🏙️🥇🚀
	# No Mobile: Só atira se o botão do HUD estiver pressionado!
	# No PC: Atira com o Mouse (Action 'shoot')
	if Global.is_mobile:
		if is_mobile_shooting:
			_shoot()
	else:
		if Input.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_shoot()

	# SENSIBILIDADE DINÂMICA ✨
	var current_sensitivity = Global.sensitivity
	if is_ads:
		current_sensitivity *= Global.ads_multiplier
	sensitivity = current_sensitivity
	controller_sensitivity = Global.controller_sensitivity
	_look_rotation(_delta)
	
	# SPRINT & CROUCH LOGIC V1420 🏃‍♂️💨🧘‍♂️
	is_sprinting = Input.is_action_pressed("sprint") and !is_ads and !is_crouching
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	
	var target_speed = BASE_SPEED
	if is_sprinting: target_speed = SPRINT_SPEED
	elif is_crouching: target_speed = CROUCH_SPEED
	
	SPEED = target_speed

	# CROUCH HEIGHT LERP ✨
	var target_height = 2.0 if !is_crouching else 1.2
	var target_cam_y = 1.6 if !is_crouching else 0.8
	$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, target_height, 10.0 * _delta)
	camera.position.y = lerp(camera.position.y, target_cam_y, 10.0 * _delta)

	# FOV LERP ✨
	var fov_target = default_fov
	if is_ads: fov_target = ads_fov
	elif is_sprinting: fov_target = sprint_fov
	camera.fov = lerp(camera.fov, fov_target, fov_speed * _delta)

	# ANIMAÇÃO 🕺
	if anim_player.current_animation != "shoot" and not is_reloading:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir.length() < 0.15: input_dir = Vector2.ZERO
		
		if input_dir != Vector2.ZERO and is_on_floor():
			var anim_to_play = "move"
			anim_player.play(anim_to_play)
		else:
			anim_player.play("idle")

	# UPDATE PREMIUM HUD V1440 ✨💎
	_update_hud(_delta)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# MOVIMENTAÇÃO V1440 (Agora na Physics!) 🛰️
	if not is_on_floor():
		velocity.y -= gravity * _delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() < 0.15: input_dir = Vector2.ZERO
		
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


# UPDATE PREMIUM HUD V1440 ✨💎
func _update_hud(_delta: float) -> void:
	var hud = find_child("TouchControls", true)
	if not hud: return
	
	hud.visible = Global.is_mobile # SÓ APARECE NO MOBILE! V1440 🏙️🎯🥇
	
	# LIMPEZA MOBILE V1460 🏙️🎯🥇: Esconde nomes e stats para tela limpa
	var state_label = hud.find_child("StateLabel", true)
	if state_label: state_label.visible = false
	
	var speed_label = hud.find_child("SpeedLabel", true)
	if speed_label: speed_label.visible = false
	
	var weapon_label = hud.find_child("WeaponLabel", true)
	if weapon_label: weapon_label.visible = false
	
	var hp_label = hud.find_child("HealthLabel", true)
	if hp_label: hp_label.visible = false
		
	# Health Bar (Mantemos a barra pois é essencial)
	var hp_bar = hud.find_child("HealthBar", true)
	if hp_bar:
		hp_bar.value = lerp(hp_bar.value, float(health) * 50.0, 10.0 * _delta) # health 2 = 100%
		
	# Ammo
	var ammo_label = hud.find_child("AmmoLabel", true)
	if ammo_label:
		ammo_label.text = str(current_ammo)
	var ammo_total_label = hud.find_child("AmmoTotal", true)
	if ammo_total_label:
		ammo_total_label.text = str(total_ammo)

func _input(event):
	if not is_multiplayer_authority(): return

	if event.is_action_just_pressed("reload"):
		_reload()

	if event is InputEventMouseButton:
		# SÓ CAPTURA O MOUSE NO PC V1200 💻🖱️
		if Global.is_mobile: return
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Só captura o mouse se o jogo NÃO estiver pausado! 🛑🖱️
			if not get_tree().paused:
				if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					mouse_captured = true

	if event is InputEventMouseMotion:
		# MODO SMART V1200: Se for mobile, movimento mouse deve ser ignorado para não travar o FOV! 📱🥊
		if Global.is_mobile: return
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# MOUSE TOTALMENTE LIBERADO V1150 💻🖱️🚀
			rotate_y(-event.relative.x * sensitivity)
			camera.rotate_x(-event.relative.y * sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)


	# NOVO SISTEMA: Sincronização de Mira & Reload 🏙️🎯🥇
	if event.is_action_just_pressed("reload"):
		_reload()

	if event.is_action_just_pressed("respawn"):
		recieve_damage(2)

	if event.is_action_just_pressed("capture"):
		if mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
			
	if event.is_action_just_pressed("ads"):
		is_ads = true
	if event.is_action_just_released("ads"):
		is_ads = false

	# ATALHO DE TECLADO V1460 🏙️🎯🥇
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		cycle_weapon()

	if event.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


var next_shoot_time : float = 0.0
var fire_rate : float = 0.08 # Mais rápido para Dual SMGs 🏙️🥇🚀

# FUNÇÃO DE DISPARO CONCENTRADA V1280 🏙️🎯🥇🚀
func _shoot() -> void:
	if is_reloading: return
	if current_ammo <= 0:
		_reload()
		return
		
	# Trava de Cadência ✨
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time < next_shoot_time: return
	
	next_shoot_time = current_time + fire_rate
	
	current_ammo -= 1
	play_shoot_effects.rpc()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("recieve_damage"):
			collider.recieve_damage.rpc_id(collider.get_multiplayer_authority())

func _reload() -> void:
	if is_reloading or current_ammo == max_ammo or total_ammo <= 0: return
	
	is_reloading = true
	# Se a arma tiver seu próprio player (GLB), usamos ele!
	var weapon_anim = weapon.find_child("AnimationPlayer", true)
	if weapon_anim and (weapon_anim.has_animation("reload") or weapon_anim.has_animation("Reload")):
		if weapon_anim.has_animation("reload"):
			weapon_anim.play("reload")
		else:
			weapon_anim.play("Reload")
		await weapon_anim.animation_finished
	elif anim_player.has_animation("reload"):
		anim_player.play("reload")
		await anim_player.animation_finished
	else:
		# Fallback se não tiver animação de reload
		await get_tree().create_timer(1.5).timeout
	
	var ammo_needed = max_ammo - current_ammo
	var ammo_to_add = min(ammo_needed, total_ammo)
	
	current_ammo += ammo_to_add
	total_ammo -= ammo_to_add
	is_reloading = false

# --- DEADZONE V1050: Eliminando 'Caminhada Fantasma' e 'Giro Sozinho' ---
func _look_rotation(_delta: float) -> void:
	var joy_look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if joy_look.length() > 0.1: # DEADZONE DE ELITE 🧱🏎️
		rotate_y(-joy_look.x * controller_sensitivity)
		camera.rotate_x(-joy_look.y * controller_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

var shoot_right : bool = true

@rpc("call_local")
func play_shoot_effects() -> void:
	# RE-BUSCA SE ESTIVER NULL (PREVENÇÃO V1440) 🛡️
	if !weapon:
		_update_weapon_nodes()
		
	if anim_player:
		# Se a arma tiver seu próprio player (GLB), usamos ele! 🏙️🥇🚀
		var weapon_anim = weapon.find_child("AnimationPlayer", true)
		if weapon_anim:
			weapon_anim.stop()
			# Tenta tocar 'fire', 'shoot' ou 'Shoot' (Nomes comuns em packs) 🛡️
			if weapon_anim.has_animation("fire"):
				weapon_anim.play("fire")
			elif weapon_anim.has_animation("shoot"):
				weapon_anim.play("shoot")
			elif weapon_anim.has_animation("Shoot"):
				weapon_anim.play("Shoot")
		else:
			anim_player.stop()
			anim_player.play("shoot")
	
	# LÓGICA DE DUAL MUZZLE FLASH V1450 🛡️🚀🥋
	var current_muzzle = null
	var flash_r = weapon.find_child("MuzzleFlash_R", true)
	var flash_l = weapon.find_child("MuzzleFlash_L", true)
	
	if flash_r and flash_l:
		current_muzzle = flash_r if shoot_right else flash_l
		shoot_right = !shoot_right # Alterna para o próximo tiro
	else:
		current_muzzle = weapon.find_child("GPUParticles3D*", true)
		if !current_muzzle: current_muzzle = weapon.find_child("MuzzleFlash*", true)
	
	if current_muzzle:
		current_muzzle.restart()
		current_muzzle.emitting = true
	
	if gunshot_sound:
		gunshot_sound.play()
	
	print("--- EFEITO DE TIRO EXECUTADO (ALTERNADO: ", shoot_right, ") ---")

@rpc("any_peer")
func recieve_damage(damage:= 1) -> void:
	health -= damage
	if health <= 0:
		health = 2
		position = spawns[randi() % spawns.size()]

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		anim_player.play("idle")

# --- STUBS SUPREMOS V1140: Evitando Erros de Script! 🏗️🛡️🥋 ---
func _on_input_event(_camera: Node, _event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	pass

func _on_mesh_instance_3d_child_order_changed():
	pass

