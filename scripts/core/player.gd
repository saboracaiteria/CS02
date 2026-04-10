extends CharacterBody3D
class_name CSPlayer

var camera: Camera3D
var raycast: RayCast3D
var anim_player: AnimationPlayer

# Dynamic references for weapons
var weapon: Node3D
var muzzle_flash: GPUParticles3D
var gunshot_sound: AudioStreamPlayer3D

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

# Ammo Management V1870  AK-47 🏙️🎯🥇
var current_ammo : int = 50
var total_ammo : int = 150 # V2110
var max_ammo : int = 50
var is_reloading : bool = false
@export var team: String = "Azul"
@export var health: int = 100 # V2090

var default_fov : float = 75.0
var ads_fov : float = 40.0
var sprint_fov : float = 85.0
var fov_speed : float = 12.0

# INVENTÁRIO V1460 🏙️🎯🥇
var weapons_list : Array = ["AnimatedPistol", "DualSMGs"]
var current_weapon_index : int = 0

var BASE_SPEED : float = 5.5
var SPRINT_SPEED : float = 9.0
var CROUCH_SPEED : float = 3.0
var SPEED : float = 5.5
var JUMP_VELOCITY : float = 10.5 # AUMENTO DE ELITE! 🏙️🚀🎯

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	# BUSCA ROBUSTA DE NÓS V2010 🏙️🎯🥇
	camera = find_child("Camera3D", true, false)
	raycast = find_child("RayCast3D", true, false)
	anim_player = find_child("AnimationPlayer", true, false)
	
	if !camera:
		Global.log_error("ERRO CRÍTICO: Camera3D não encontrada! Tentando busca alternativa...")
		camera = get_viewport().get_camera_3d()
	
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
	
	add_to_group("player")
	
	if is_multiplayer_authority():
		if camera: 
			camera.make_current()
			Global.log_error("CAMERA ATIVADA: " + str(camera.name))
		
		var hud = find_child("TouchControls", true)
		if hud: 
			hud.visible = true
			Global.log_error("HUD MOBILE ATIVADO")

	if raycast:
		raycast.add_exception(self)

	default_fov = Global.default_fov
	ads_fov = Global.ads_fov
	if camera: camera.fov = default_fov
	print("--- PLAYER PRONTO V2010 ---")

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
			_auto_normalize_model(weapon) # MAGIA V1480: AUTO SCALE E ALIGN 📏🪄
			
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
	
	# MIRA DINÂMICA: Ajustada via Gabarito (weapon_base.gd) ou AutoNormalizer 🏙️🎯🥇
	if weapon and weapon.has_method("get"):
		pass

# --- AUTO NORMALIZER V1480 🤖📏 ---
# Qualquer GLB (arma ou futura skin) que entrar aqui ganha escala padrão 100% automática!
func get_max_dim_recursive(node: Node3D, model_root: Node3D) -> float:
	var max_dim = 0.0
	for child in node.get_children():
		if child is VisualInstance3D:
			var aabb = child.get_aabb()
			# Transformação relativa desde a raiz do GLB para obter o tamanho isolado real
			var rel_transform = model_root.global_transform.affine_inverse() * child.global_transform
			var s = rel_transform.basis.get_scale()
			var size = Vector3(aabb.size.x * s.x, aabb.size.y * s.y, aabb.size.z * s.z)
			max_dim = max(max_dim, max(size.x, max(size.y, size.z)))
		# Recursão para achar meshes filhos de esqueleto, etc.
		var child_max = get_max_dim_recursive(child, model_root)
		max_dim = max(max_dim, child_max)
	return max_dim

func get_max_dim(node: Node3D) -> float:
	# O cálculo começa isolando a matriz desde a raiz (antes do AutoScale agir na própria raiz)
	return get_max_dim_recursive(node, node)

func _auto_normalize_model(model: Node3D) -> void:
	if model.has_meta("auto_scaled"): return
	model.set_meta("auto_scaled", true)
	
	# Se a arma já tem WeaponBase, ela gerencia sua própria escala/rotação 🛡️
	# Não interferir nela evita o conflito que deixava a pistola grande e ao contrário!
	if model is WeaponBase:
		print("--- SKIP AUTO-SCALE: WeaponBase detectado em ", model.name, " ---")
		return
	
	var max_size = get_max_dim(model)
	if max_size > 0.05:
		# Tamanho perfeito padrão de uma arma longa (80 centímetros):
		var target_length = 0.8
		if model.name.to_lower().contains("pistol") or model.name.to_lower().contains("handgun"):
			target_length = 0.45
			
		var auto_scale = target_length / max_size
		
		# Força a escala (apenas para armas SEM WeaponBase)
		model.scale = Vector3(auto_scale, auto_scale, auto_scale)
		print("--- AUTO-SCALE APLICADO NO ", model.name, " (MaxDimension: ", max_size, " -> Scale: ", auto_scale, ") ---")
		
	# POSIÇÃO: Só ajusta se não for WeaponBase (evita resetar braços e offsets!) 🛡️
	if not model is WeaponBase and model.position == Vector3.ZERO:
		model.position = Vector3(0.2, -0.2, -0.35)

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

	# MOVIMENTO SUAVE DE ADS V1630 🎯🏙️🥇
	if weapon and weapon.has_method("get") and "view_model_offset" in weapon:
		var target_pos = weapon.view_model_offset
		var target_fov = default_fov # FIX V1740: Global.fov não existe!
		
		if is_ads:
			target_pos = weapon.ads_offset if "ads_offset" in weapon else target_pos
			target_fov = ads_fov
		
		# Interpolação suave para a arma deslizar para o centro
		weapon.transform.origin = weapon.transform.origin.lerp(target_pos, _delta * 10.0)
		camera.fov = lerp(camera.fov, clamp(target_fov, 1.0, 179.0), _delta * 10.0)

	# CROUCH HEIGHT LERP ✨
	var target_height = 2.0 if !is_crouching else 1.2
	var target_cam_y = 1.6 if !is_crouching else 0.8
	$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, target_height, 10.0 * _delta)
	camera.position.y = lerp(camera.position.y, target_cam_y, 10.0 * _delta)

	# FOV LERP ✨
	var fov_target = default_fov
	if is_ads: fov_target = ads_fov
	elif is_sprinting: fov_target = sprint_fov
	camera.fov = lerp(camera.fov, clamp(fov_target, 1.0, 179.0), fov_speed * _delta)

	# ANIMAÇÃO 🕺
	if not is_reloading:
		# Verifica se a arma tem seu próprio player e se ele está ocupado com algo importante V1630 🎭
		var weapon_anim = weapon.find_child("AnimationPlayer", true) if weapon else null
		var is_weapon_busy = false
		if weapon_anim and weapon_anim.is_playing():
			var busy_anims = ["fire", "shoot", "Shoot", "reload", "Reload", "inspect", "Inspect"]
			if weapon_anim.current_animation in busy_anims:
				is_weapon_busy = true
		
		if not is_weapon_busy:
			var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if input_dir.length() < 0.15: input_dir = Vector2.ZERO
			
			if input_dir != Vector2.ZERO and is_on_floor():
				anim_player.play("move")
			else:
				anim_player.play("idle")
		else:
			# Se a arma está ocupada, garantimos que o player base não force um estado conflitante
			pass

	# UPDATE PREMIUM HUD V1440 ✨💎
	_update_hud(_delta)
	
	# UNIFIED CLEAN HUD V1760 ❤️🔫🏙️🥇
	if is_multiplayer_authority():
		var pc_hud = find_child("PCHUD", true)
		if pc_hud:
			var hp_lbl = pc_hud.find_child("PCHealthLabel", true)
			if hp_lbl:
				hp_lbl.text = "❤️ %d" % health
				if health > 60: hp_lbl.modulate = Color(0.4, 1.0, 0.4)
				elif health > 30: hp_lbl.modulate = Color(1.0, 1.0, 0.2)
				else: hp_lbl.modulate = Color(1.0, 0.2, 0.2)
			
			var ammo_lbl = pc_hud.find_child("AmmoHUD", true)
			if ammo_lbl and weapon:
				var current_ammo = weapon.ammo if "ammo" in weapon else 0
				var max_ammo = weapon.max_ammo if "max_ammo" in weapon else 0
				ammo_lbl.text = "🔫 %d / %d" % [current_ammo, max_ammo]
				if current_ammo <= (max_ammo * 0.25):
					ammo_lbl.modulate = Color(1.0, 0.3, 0.3)
				else:
					ammo_lbl.modulate = Color(1, 1, 1, 0.8)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# MOVIMENTAÇÃO V1440 (Agora na Physics!) 🛰️
	if not is_on_floor():
		velocity.y -= gravity * _delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# TESTE DE HP V1890 🏙️🎯🥇: Aperte K para tirar dano!
	if Input.is_key_pressed(KEY_K):
		recieve_damage(1)

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


# UPDATE UNIFICADO HUD V1960 ✨💎
func _update_hud(_delta: float) -> void:
	# Busca o HUD que já está na cena (TouchControls ou HUD comum)
	var hud = find_child("TouchControls", true)
	if is_instance_valid(hud):
		hud.visible = true # Sempre visível!
		
		var hp_label = hud.find_child("HealthLabel", true)
		if hp_label: 
			hp_label.text = "HP: %d" % health
			hp_label.visible = true # GARANTE VERSION=V2230 💻🏹
		
		var bar = hud.find_child("HealthBar", true)
		if bar: bar.value = health
		
		var albl = hud.find_child("AmmoLabel", true)
		if albl: 
			albl.text = "%d / %d" % [current_ammo, total_ammo]
			albl.visible = true

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

	# INSPECTION V1620 🎭🏙️🎯🥇
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_inspect()

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
	# SPAWN TRACER V2100 🏙️🎯🥇
	var from_pos = camera.global_position + (-camera.global_transform.basis.z * 0.5)
	var to_pos = from_pos + (-camera.global_transform.basis.z * 100.0)
	
	if raycast.is_colliding():
		var point = raycast.get_collision_point()
		to_pos = point # Ajusta o rastro para o ponto de impacto!
		_spawn_impact_decal.rpc(point, raycast.get_collision_normal())
		
	# DISPARA O RASTRO PARA TODOS OS CLIENTES 📡🏙️🚀
	_spawn_bullet_tracer.rpc(from_pos, to_pos)
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("recieve_damage"):
			var dmg = 20 # Dano base
			if weapon and "damage" in weapon: dmg = weapon.damage
			# SMART RPC V1730: Evita erro 'RPC on yourself' 🏙️🎯🥇
			var target_auth = collider.get_multiplayer_authority()
			if target_auth == multiplayer.get_unique_id():
				collider.recieve_damage(dmg) # Chamada direta no mesmo peer
			else:
				collider.recieve_damage.rpc_id(target_auth, dmg)
	
	# RECUO V1645 🏙️🎯🔥
	_apply_recoil()

func _apply_recoil() -> void:
	if not weapon or not is_multiplayer_authority(): return
	
	var v_kick = weapon.get("recoil_vertical") if "recoil_vertical" in weapon else 0.05
	var h_kick = weapon.get("recoil_horizontal") if "recoil_horizontal" in weapon else 0.02
	
	# Recuo de Elite V1665: Mira Firme e Estável 🏙️🎯🥇
	# Removemos o salto da câmera para a mira não subir sozinha!
	camera.rotation.x += v_kick * 0.1 # Quase invisível
	rotate_y(randf_range(-h_kick, h_kick) * 0.1)
	
	# "Kick" Visual na Arma (Apenas empurrão para trás, sem subir do HUD)
	weapon.position.z += 0.05 # Empurrão leve

@rpc("call_local")
func _spawn_impact_decal(pos: Vector3, _normal: Vector3) -> void:
	# IMPACTO PREMIUM ZERO LAG V2230 🏙️🎯🥇
	# 1. Luz de Impacto (Brilho rápido)
	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.8, 0.2)
	light.light_energy = 3.0
	light.omni_range = 1.2
	light.global_position = pos
	get_tree().root.add_child(light)
	
	# 2. Marca de Bala (Decal Otimizado) 🛡️
	var decal = Decal.new()
	decal.size = Vector3(0.1, 0.1, 0.1)
	decal.texture_albedo = load("res://icon.svg") # Usando ícone como placeholder
	decal.modulate = Color.BLACK
	decal.global_position = pos
	if _normal.length() > 0.1:
		decal.look_at(pos + _normal, Vector3.UP)
	get_tree().root.add_child(decal)

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(light, "light_energy", 0.0, 0.1)
	tw.tween_property(decal, "modulate:a", 0.0, 5.0).set_delay(5.0) # Some após 10s
	tw.set_parallel(false)
	tw.tween_callback(light.queue_free)
	tw.tween_callback(decal.queue_free)

@rpc("call_local")
func _spawn_bullet_tracer(from: Vector3, to: Vector3):
	# SISTEMA ULTRA-LEVE V2140 🏙️🎯🥇 - Apenas uma linha simples (Zero Lag)
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0, 1, 1, 0.8) # Ciano Transparente 💎
	mesh_instance.material_override = material

	get_tree().root.add_child(mesh_instance)

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	var tracer_tween = create_tween()
	tracer_tween.tween_interval(0.05) # Visível por apenas 0.05s
	tracer_tween.tween_callback(mesh_instance.queue_free)

func _inspect() -> void:
	if is_reloading: return
	
	var weapon_anim = weapon.find_child("AnimationPlayer", true)
	if weapon_anim:
		for anim in ["inspect", "Inspect", "INSPECT", "idle_inspect"]:
			if weapon_anim.has_animation(anim):
				weapon_anim.play(anim)
				return

func _reload() -> void:
	if is_reloading or current_ammo == max_ammo or total_ammo <= 0: return
	
	is_reloading = true
	var weapon_anim = weapon.find_child("AnimationPlayer", true)
	if weapon_anim:
		var found = false
		for anim in ["reload", "Reload", "RELOAD", "action_reload"]:
			if weapon_anim.has_animation(anim):
				weapon_anim.play(anim)
				found = true
				await weapon_anim.animation_finished
				break
		if !found: await get_tree().create_timer(1.5).timeout
	elif anim_player.has_animation("reload"):
		anim_player.play("reload")
		await anim_player.animation_finished
	else:
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
			weapon_anim.stop(true) # RESET TOTAL DA ANIMAÇÃO V1630 🎭
			
			# Tenta tocar 'fire', 'shoot' ou 'Shoot' (Nomes comuns em packs) 🛡️
			var shot_anim = ""
			if weapon_anim.has_animation("fire"): shot_anim = "fire"
			elif weapon_anim.has_animation("shoot"): shot_anim = "shoot"
			elif weapon_anim.has_animation("Shoot"): shot_anim = "Shoot"
			
			if shot_anim != "":
				weapon_anim.play(shot_anim)
				# Garante que a animação comece do zero e tenha prioridade
				weapon_anim.seek(0.0) 
		else:
			anim_player.stop(true)
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

@rpc("any_peer", "call_local")
func recieve_damage(damage:= 20) -> void:
	if not is_multiplayer_authority(): return
	if health <= 0: return
	
	health -= damage
	health = max(0, health)
	
	# FLASH DE DANO NO HUD V2020 🏙️🎯🥇
	var hud = find_child("TouchControls", true)
	if hud:
		var tw = create_tween()
		hud.modulate = Color(1, 0, 0) # Vermelho
		tw.tween_property(hud, "modulate", Color(1, 1, 1), 0.2) # Volta ao normal
	
	if health <= 0:
		Global.log_error("SISTEMA: Jogador morto. Respawn em 1s...")
		await get_tree().create_timer(1.0).timeout
		health = 100
		global_position = spawns[randi() % spawns.size()]
		_update_hud(0)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		if anim_player and anim_player.has_animation("idle"):
			anim_player.play("idle")

# --- STUBS SUPREMOS V1140 ---
func _on_input_event(_camera: Node, _event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	pass

func _on_mesh_instance_3d_child_order_changed():
	pass

