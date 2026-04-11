extends Node
# --- SHADER PREWARMER V6.1 LIGHTWEIGHT 🏙️🎯🥇 ---
# Pré-compila shaders ANTES do gameplay, na tela do menu,
# para eliminar travamentos durante a primeira partida.
# Estratégia: criar objetos simples com os materiais do jogo
# e renderizá-los por 1 frame em uma SubViewport off-screen.

signal prewarming_done

var _done := false

func prewarm(on_done: Callable = Callable()) -> void:
	if _done:
		if on_done.is_valid(): on_done.call()
		return
	print("[SHADER PREWARMER] Iniciando pré-aquecimento leve...")
	_run_prewarm(on_done)

func _run_prewarm(on_done: Callable) -> void:
	# SubViewport minúscula (1x1 pixel) — invisível ao jogador
	var sv := SubViewport.new()
	sv.size = Vector2i(1, 1)
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	sv.disable_3d = false
	sv.own_world_3d = true  # Mundo isolado, não interfere na cena principal
	add_child(sv)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 2)
	sv.add_child(cam)

	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	sv.add_child(mi)

	# Lista de cores que os bots e cenário usam — força compilação dos shaders
	var warm_colors := [
		Color(0.15, 0.15, 0.15),  # Torso bot
		Color(1.0, 0.4, 0.0),     # Time vermelho
		Color(0.0, 0.5, 1.0),     # Time azul
		Color(1.0, 0.86, 0.67),   # Pele
		Color(0.06, 0.06, 0.06),  # Bota
		Color(0.1, 0.05, 0.15),   # Chão vaporwave
		Color(0, 1, 1, 0.8),      # Tracer ciano
		Color(1, 0.7, 0, 0.8),    # Tracer laranja
	]

	# Roda cada material em frames separados para não travar a thread principal
	for c in warm_colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
		mi.set_surface_override_material(0, mat)
		sv.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame  # 1 frame por shader = sem spike

	# Material unshaded (usado por tracers e HUD 3D)
	var unshaded := StandardMaterial3D.new()
	unshaded.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	unshaded.albedo_color = Color(0, 1, 1)
	mi.set_surface_override_material(0, unshaded)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame

	# Limpa
	sv.queue_free()
	_done = true
	print("[SHADER PREWARMER] ✅ Pré-aquecimento concluído!")
	emit_signal("prewarming_done")
	if on_done.is_valid(): on_done.call()
