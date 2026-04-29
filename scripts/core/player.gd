extends CharacterBody3D
class_name CSPlayer

var camera: Camera3D
var raycast: RayCast3D
var anim_player: AnimationPlayer

# Dynamic references for weapons
var weapon: Node3D
var muzzle_flash: GPUParticles3D
var gunshot_sound: AudioStreamPlayer3D

## The xyz position of the random spawns
@export var spawns: PackedVector3Array = ([
	Vector3(-18, 0.2, 0),
	Vector3(18, 0.2, 0),
	Vector3(-2.8, 0.2, -6),
	Vector3(-17,0,17),
	Vector3(17,0,17),
	Vector3(17,0,-17),
	Vector3(-17,0,-17)
])

# Cached sensititivy — read once per frame from Global
var sensitivity : float = .005
var controller_sensitivity : float = .010
var mouse_captured : bool = true
var gravity: float = 20.0

# Movement States
var is_ads : bool = false
var is_sprinting : bool = false
var is_crouching : bool = false

# Ammo Management
var current_ammo : int = 50
var total_ammo : int = 150
var max_ammo : int = 50
var is_reloading : bool = false
@export var team: String = "Azul"
@export var health: int = 100

var default_fov : float = 75.0
var ads_fov : float = 73.0
var sprint_fov : float = 82.0
# A single speed for the FOV lerp — keeping it moderate prevents snapping
const FOV_LERP_SPEED : float = 8.0

var weapons_list : Array = ["AnimatedPistol", "DualSMGs", "AKM_Unity"]
var current_weapon_index : int = 0
var weapon_cache : Dictionary = {} # V2500 - Cache para eliminar LAG 🏙️🎯🥇

var BASE_SPEED : float = 5.5
var SPRINT_SPEED : float = 9.0
var CROUCH_SPEED : float = 3.0
var SPEED : float = 5.5
var JUMP_VELOCITY : float = 10.5

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	camera = find_child("Camera3D", true, false)
	raycast = find_child("RayCast3D", true, false)
	anim_player = get_node_or_null("AnimationPlayer")
	if !anim_player:
		anim_player = find_child("AnimationPlayer", false, false)
	
	if !camera:
		Global.log_error("ERRO CRÍTICO: Camera3D não encontrada!")
		camera = get_viewport().get_camera_3d()
	
	# PRE-CACHE DE ARMAS V2500 🏎️💨
	for child in %WeaponRoot.get_children():
		if child is Node3D:
			child.visible = false
			_auto_normalize_model(child) # Normaliza TUDO no começo
			
			# Cache de sub-nós para evitar find_child no lag
			var weapon_data = {
				"node": child,
				"muzzle": child.find_child("MuzzleFlash*", true) if not child.find_child("MuzzleFlash_R", true) else child.find_child("MuzzleFlash_R", true),
				"sound": child.find_child("AudioStreamPlayer3D*", true) if not child.find_child("GunshotSound*", true) else child.find_child("GunshotSound*", true),
				"anim": child.find_child("AnimationPlayer", true)
			}
			weapon_cache[child.name.to_lower()] = weapon_data

	var initial_weapon = "DualSMGs"
	if weapon_cache.has(initial_weapon.to_lower()):
		switch_weapon(initial_weapon)
	else:
		switch_weapon(weapons_list[0])

	add_to_group("player")
	
	if is_multiplayer_authority():
		if camera:
			camera.make_current()
		var hud = find_child("TouchControls", true)
		if hud: hud.visible = true
	
	if raycast:
		raycast.add_exception(self)

	default_fov = Global.default_fov
	ads_fov = Global.ads_fov
	if Global.is_mobile:
		ads_fov = 73.0
	if weapon and weapon.name.contains("Sniper"):
		ads_fov = 15.0
	if camera: camera.fov = default_fov
	print("--- PLAYER PRONTO ---")

# --- WEAPON SYSTEM ---
func switch_weapon(weapon_name: String) -> void:
	var key = weapon_name.to_lower()
	if not weapon_cache.has(key): return

	# Oculta arma atual
	if weapon: weapon.visible = false
	
	# Ativa nova arma via cache (Zero LAG) 🏎️💨
	var data = weapon_cache[key]
	weapon = data.node
	weapon.visible = true
	muzzle_flash = data.muzzle
	gunshot_sound = data.sound
	
	current_weapon_index = weapons_list.find(weapon_name)
	
	# Update ADS FOV
	if weapon.name.contains("Sniper"):
		ads_fov = 15.0
	else:
		ads_fov = Global.ads_fov if not Global.is_mobile else 73.0
	
	# Skin Arms logic
	var skin_arms = get_node_or_null("Camera3D/Skin_Arms")
	if skin_arms:
		skin_arms.visible = not weapon.name.contains("Unity")
		
	current_ammo = max_ammo
	is_reloading = false

func cycle_weapon() -> void:
	current_weapon_index = (current_weapon_index + 1) % weapons_list.size()
	switch_weapon(weapons_list[current_weapon_index])

func _update_weapon_nodes() -> void:
	# Função mantida por compatibilidade mas o switch agora faz o trabalho via cache
	pass

# --- AUTO NORMALIZER ---
func get_max_dim_recursive(node: Node3D, model_root: Node3D) -> float:
	var max_dim = 0.0
	for child in node.get_children():
		if child is VisualInstance3D:
			var aabb = child.get_aabb()
			var rel_transform = model_root.global_transform.affine_inverse() * child.global_transform
			var s = rel_transform.basis.get_scale()
			var size = Vector3(aabb.size.x * s.x, aabb.size.y * s.y, aabb.size.z * s.z)
			max_dim = max(max_dim, max(size.x, max(size.y, size.z)))
		var child_max = get_max_dim_recursive(child, model_root)
		max_dim = max(max_dim, child_max)
	return max_dim

func get_max_dim(node: Node3D) -> float:
	return get_max_dim_recursive(node, node)

func _auto_normalize_model(model: Node3D) -> void:
	if model.has_meta("auto_scaled"): return
	model.set_meta("auto_scaled", true)
	# if model is WeaponBase:
	# 	return
	var max_size = get_max_dim(model)
	if max_size > 0.05:
		var target_length = 0.8
		if model.name.to_lower().contains("pistol") or model.name.to_lower().contains("handgun"):
			target_length = 0.45
		var auto_scale = target_length / max_size
		model.scale = Vector3(auto_scale, auto_scale, auto_scale)
	
	# Fixes orientation for imported Unity models 🔄🏙️
	if model.name.contains("Unity"):
		# Force rotation on the first child (usually the Model node)
		if model.get_child_count() > 0:
			var mesh_node = model.get_child(0)
			if mesh_node is Node3D:
				if model.name.contains("Sniper"):
					mesh_node.rotation_degrees.y = 0 
				else:
					# Targeting Forward (-Z). If original is Right (+X), rotation is -90.
					mesh_node.rotation_degrees.y = -90
	
	if not model is WeaponBase and model.position == Vector3.ZERO:
		model.position = Vector3(0.2, -0.2, -0.35)

var is_mobile_shooting : bool = false

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# --- DISPARO ---
	if Global.is_mobile:
		if is_mobile_shooting: _shoot()
	else:
		if Input.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_shoot()

	# --- SENSIBILIDADE (cache local, não lê Global toda frame) ---
	sensitivity = Global.sensitivity * (Global.ads_multiplier if is_ads else 1.0)
	controller_sensitivity = Global.controller_sensitivity
	_look_rotation(_delta)
	
	# --- SPRINT / CROUCH ---
	is_sprinting = Input.is_action_pressed("sprint") and !is_ads and !is_crouching
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	SPEED = SPRINT_SPEED if is_sprinting else (CROUCH_SPEED if is_crouching else BASE_SPEED)

	# --- ARMA: posição ADS (sem mexer no FOV aqui) ---
	if weapon and "view_model_offset" in weapon:
		var target_pos = weapon.ads_offset if (is_ads and "ads_offset" in weapon) else weapon.view_model_offset
		weapon.transform.origin = weapon.transform.origin.lerp(target_pos, _delta * 12.0)

	# --- FOV: UM ÚNICO LERP CONSOLIDADO ---
	var fov_target := default_fov
	if is_ads:       fov_target = ads_fov
	elif is_sprinting: fov_target = sprint_fov
	if camera: camera.fov = lerpf(camera.fov, clamp(fov_target, 1.0, 179.0), FOV_LERP_SPEED * _delta)

	# --- SNIPER SCOPE 🔭 ---
	var scope = get_node_or_null("%SniperScope")
	if scope:
		var is_sniper = weapon and (weapon.name.contains("Sniper") or weapon.name.contains("sniper"))
		scope.visible = is_ads and is_sniper
		if weapon:
			weapon.visible = not scope.visible # Hide weapon model when scoped

	# --- CROUCH HEIGHT ---
	var target_height := 2.1 if !is_crouching else 1.2
	var target_cam_y  := 1.8 if !is_crouching else 0.9
	$CollisionShape3D.shape.height = lerpf($CollisionShape3D.shape.height, target_height, 10.0 * _delta)
	if camera: camera.position.y = lerpf(camera.position.y, target_cam_y, 10.0 * _delta)

	# --- ANIMAÇÃO ---
	if not is_reloading and weapon:
		var weapon_anim = weapon.find_child("AnimationPlayer", true)
		var is_weapon_busy := false
		if weapon_anim and weapon_anim.is_playing():
			if weapon_anim.current_animation in ["fire","shoot","Shoot","reload","Reload"]:
				is_weapon_busy = true
		if not is_weapon_busy and anim_player:
			var input_dir := Input.get_vector("move_left","move_right","move_up","move_down")
			var anim_to_play = "move" if input_dir.length() > 0.15 and is_on_floor() else "idle"
			if anim_player.has_animation(anim_to_play) and anim_player.current_animation != anim_to_play:
				anim_player.play(anim_to_play)

	# --- HUD ---
	_update_hud(_delta)
	
	if is_multiplayer_authority():
		var pc_hud = find_child("PCHUD", true)
		if pc_hud:
			var hp_lbl = pc_hud.find_child("PCHealthLabel", true)
			if hp_lbl:
				hp_lbl.text = "❤️ %d" % health
				if health > 60:   hp_lbl.modulate = Color(0.4, 1.0, 0.4)
				elif health > 30: hp_lbl.modulate = Color(1.0, 1.0, 0.2)
				else:             hp_lbl.modulate = Color(1.0, 0.2, 0.2)
			var ammo_lbl = pc_hud.find_child("AmmoHUD", true)
			if ammo_lbl and weapon:
				var cur = weapon.ammo if "ammo" in weapon else 0
				var mx  = weapon.max_ammo if "max_ammo" in weapon else 0
				ammo_lbl.text = "🔫 %d / %d" % [cur, mx]
				ammo_lbl.modulate = Color(1.0, 0.3, 0.3) if cur <= mx * 0.25 else Color(1, 1, 1, 0.8)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
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

# --- HUD UPDATE ---
func _update_hud(_delta: float) -> void:
	var hud = find_child("TouchControls", true)
	if is_instance_valid(hud):
		hud.visible = true
		var hp_label = hud.find_child("HealthLabel", true)
		if hp_label:
			hp_label.text = "HP: %d" % health
			hp_label.visible = true
		var bar = hud.find_child("HealthBar", true)
		if bar: bar.value = health
		var albl = hud.find_child("AmmoLabel", true)
		if albl:
			albl.text = "%d / %d" % [current_ammo, total_ammo]
			albl.visible = true
	var pchud = find_child("PCHUD", true)
	if is_instance_valid(pchud):
		pchud.visible = not Global.is_mobile
		if pchud.visible:
			var pc_hp = pchud.find_child("PCHB", true)
			if pc_hp: pc_hp.value = health
			var pc_ammo = pchud.find_child("PCAmmo", true)
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm and pc_ammo:
				pc_ammo.text = "MUN: %d / %d  |  KILLS: %d\nAZUL: %d / %d" % [current_ammo, total_ammo, gm.player_kills, int(gm.team_blue_score), int(gm.score_limit)]
				_apply_hud_contrast(pc_ammo)

func _apply_hud_contrast(label):
	if label:
		label.add_theme_constant_override("outline_size", 10)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _input(event):
	if not is_multiplayer_authority(): return

	if event.is_action_just_pressed("reload"):
		_reload()

	if event is InputEventMouseButton:
		if Global.is_mobile: return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not get_tree().paused:
				if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					mouse_captured = true

	if event is InputEventMouseMotion:
		if Global.is_mobile: return
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * sensitivity)
			camera.rotate_x(-event.relative.y * sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

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

	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_inspect()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			cycle_weapon()
		elif event.keycode == KEY_1:
			switch_weapon(weapons_list[0])
			current_weapon_index = 0
		elif event.keycode == KEY_2 and weapons_list.size() > 1:
			switch_weapon(weapons_list[1])
			current_weapon_index = 1

# --- LOOK (gamepad only — mouse is handled in _input) ---
func _look_rotation(_delta: float) -> void:
	var joy_look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if joy_look.length() > 0.1:
		rotate_y(-joy_look.x * controller_sensitivity)
		camera.rotate_x(-joy_look.y * controller_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

# --- SHOOTING ---
var next_shoot_time : float = 0.0
var fire_rate : float = 0.08

func _shoot() -> void:
	if is_reloading: return
	if current_ammo <= 0:
		_reload()
		return
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time < next_shoot_time: return
	next_shoot_time = current_time + fire_rate
	current_ammo -= 1
	var from_pos = camera.global_position + (-camera.global_transform.basis.z * 0.5)
	var to_pos = from_pos + (-camera.global_transform.basis.z * 100.0)
	if raycast.is_colliding():
		var point = raycast.get_collision_point()
		to_pos = point
		_spawn_impact_decal.rpc(point, raycast.get_collision_normal())
	_spawn_bullet_tracer.rpc(from_pos, to_pos)
	if gunshot_sound:
		gunshot_sound.pitch_scale = randf_range(0.9, 1.1)
		gunshot_sound.play()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("recieve_damage"):
			var dmg = 20
			if weapon and "damage" in weapon: dmg = weapon.damage
			var target_auth = collider.get_multiplayer_authority()
			if target_auth == multiplayer.get_unique_id():
				collider.recieve_damage(dmg, self)
			else:
				collider.recieve_damage.rpc_id(target_auth, dmg, multiplayer.get_unique_id())
	_apply_recoil()

func _apply_recoil() -> void:
	if not weapon or not is_multiplayer_authority(): return
	var v_kick = weapon.get("recoil_vertical")   if "recoil_vertical"   in weapon else 0.05
	var h_kick = weapon.get("recoil_horizontal") if "recoil_horizontal" in weapon else 0.02
	if Global.is_mobile:
		v_kick *= 0.7
		h_kick *= 0.7
	# Kick de câmera aumentado
	camera.rotation.x += v_kick * 0.20
	rotate_y(randf_range(-h_kick, h_kick) * 0.18)
	# Movimentação física da arma: recua em Z e cai em Y
	weapon.position.z += 0.055
	weapon.position.y -= 0.022

# PRE-CACHE
var _shared_quad = QuadMesh.new()
var _shared_mat = StandardMaterial3D.new()

@rpc("call_local")
func _spawn_impact_decal(pos: Vector3, _normal: Vector3) -> void:
	var light = OmniLight3D.new()
	light.light_color = Color(1, 1, 0.5)
	light.light_energy = 5.0
	light.omni_range = 1.5
	light.global_position = pos
	get_tree().root.add_child.call_deferred(light)
	var mesh_instance = MeshInstance3D.new()
	if _shared_quad.size == Vector2.ZERO: _shared_quad.size = Vector2(0.15, 0.15)
	if _shared_mat.albedo_color == Color.WHITE:
		_shared_mat.albedo_color = Color(0.1, 0.1, 0.1, 1.0)
		_shared_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.mesh = _shared_quad
	mesh_instance.material_override = _shared_mat
	mesh_instance.global_position = pos + (_normal * 0.02)
	if _normal.length() > 0.1:
		mesh_instance.look_at_from_position(mesh_instance.global_position, pos + _normal, Vector3.UP)
	get_tree().root.call_deferred("add_child", mesh_instance)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(light, "light_energy", 0.0, 0.15)
	tw.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.5).set_delay(10.0)
	tw.set_parallel(false)
	tw.tween_callback(light.queue_free)
	tw.tween_callback(mesh_instance.queue_free)

@rpc("call_local")
func _spawn_bullet_tracer(from: Vector3, to: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0, 1, 1, 0.8)
	mesh_instance.material_override = material
	get_tree().root.add_child.call_deferred(mesh_instance)
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	var tracer_tween = create_tween()
	tracer_tween.tween_interval(0.05)
	tracer_tween.tween_callback(mesh_instance.queue_free)

func _inspect() -> void:
	if is_reloading: return
	_play_weapon_anim("inspect")

func _play_weapon_anim(keyword: String):
	if not weapon: return null
	var weapon_anim = weapon.find_child("AnimationPlayer", true)
	if not weapon_anim: return null
	
	var anim_list = weapon_anim.get_animation_list()
	var target = ""
	for a in anim_list:
		var al = a.to_lower()
		var kl = keyword.to_lower()
		if al == kl: # Prioridade exata
			target = a
			break
		if al.contains(kl):
			target = a # Melhor match parcial
			
	if target != "":
		weapon_anim.stop()
		weapon_anim.play(target)
		return weapon_anim.animation_finished
	return null

func _reload() -> void:
	if is_reloading or current_ammo == max_ammo or total_ammo <= 0: return
	is_reloading = true
	var sig = _play_weapon_anim("reload")
	if sig:
		await sig
	elif anim_player and anim_player.has_animation("reload"):
		anim_player.play("reload")
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(1.5).timeout
	var ammo_needed = max_ammo - current_ammo
	var ammo_to_add = min(ammo_needed, total_ammo)
	current_ammo += ammo_to_add
	total_ammo -= ammo_to_add
	is_reloading = false

var shoot_right : bool = true

@rpc("call_local")
func play_shoot_effects() -> void:
	if !weapon: _update_weapon_nodes()
	if anim_player:
		var played_custom = _play_weapon_anim("fire") 
		if not played_custom: played_custom = _play_weapon_anim("shoot")
		
		if not played_custom:
			anim_player.stop(true)
			anim_player.play("shoot")
	var current_muzzle = null
	var flash_r = weapon.find_child("MuzzleFlash_R", true)
	var flash_l = weapon.find_child("MuzzleFlash_L", true)
	if flash_r and flash_l:
		current_muzzle = flash_r if shoot_right else flash_l
		shoot_right = !shoot_right
	else:
		current_muzzle = weapon.find_child("GPUParticles3D*", true)
		if !current_muzzle: current_muzzle = weapon.find_child("MuzzleFlash*", true)
	if current_muzzle:
		current_muzzle.restart()
		current_muzzle.emitting = true
	if gunshot_sound: gunshot_sound.play()

@rpc("any_peer", "call_local")
func recieve_damage(damage:= 20) -> void:
	if not is_multiplayer_authority(): return
	if health <= 0: return
	health -= damage
	health = max(0, health)
	var hud = find_child("TouchControls", true)
	if hud:
		var tw = create_tween()
		hud.modulate = Color(1, 0, 0)
		tw.tween_property(hud, "modulate", Color(1, 1, 1), 0.2)
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

func _on_input_event(_camera: Node, _event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	pass

func _on_mesh_instance_3d_child_order_changed():
	pass
