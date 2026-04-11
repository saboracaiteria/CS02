extends Node
# --- SHADER PREWARMER V6.0 🏙️🎯🥇 ---
# Aquece (pre-compila) shaders antes do jogo iniciar para eliminar
# travamentos de "shader stutter" durante a primeira sessão.
# No WebGL/WebGPU, este processo é essencial pois a compilação acontece em runtime.

signal prewarming_done

var _done := false

func prewarm(on_done: Callable = Callable()) -> void:
	if _done:
		if on_done.is_valid(): on_done.call()
		return

	print("[SHADER PREWARMER] Iniciando pré-aquecimento...")
	
	# Cria uma SubViewport invisível e renderiza os materiais padrão nela
	# para forçar a GPU a compilar os shaders antes do gameplay começar.
	var sv := SubViewport.new()
	sv.size = Vector2i(4, 4)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	sv.disable_3d = false
	add_child(sv)

	# Lista de materiais do jogo para pré-aquecer
	var materials_to_warm := _collect_materials()
	
	var cam := Camera3D.new()
	sv.add_child(cam)
	
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mi.mesh = mesh
	sv.add_child(mi)

	# Itera todos os materiais coletados e força renderização
	for mat in materials_to_warm:
		if mat is Material:
			mi.set_surface_override_material(0, mat)
			sv.render_target_update_mode = SubViewport.UPDATE_ONCE
			await get_tree().process_frame
	
	# Limpa a SubViewport temporária
	sv.queue_free()
	_done = true
	
	print("[SHADER PREWARMER] ✅ Pré-aquecimento concluído!")
	emit_signal("prewarming_done")
	if on_done.is_valid(): on_done.call()

func _collect_materials() -> Array:
	var mats := []
	# Coleta todos os materiais já carregados na cena (map, bots, etc.)
	var nodes := get_tree().get_nodes_in_group("bot")
	nodes.append_array(get_tree().get_nodes_in_group("player"))
	
	for node in nodes:
		for child in _get_all_children(node):
			if child is MeshInstance3D:
				for i in child.get_surface_override_material_count():
					var m = child.get_surface_override_material(i)
					if m and not mats.has(m):
						mats.append(m)
				if child.mesh:
					for i in child.mesh.get_surface_count():
						var m = child.mesh.surface_get_material(i)
						if m and not mats.has(m):
							mats.append(m)
	
	# Adiciona materiais básicos dos procedural bots
	mats.append_array(_add_standard_materials())
	return mats

func _add_standard_materials() -> Array:
	# Pré-aquece os materiais que os bots proceduais usam mais frequentemente
	var defaults := []
	var colors := [
		Color(0.15, 0.15, 0.15), Color(1.0, 0.4, 0.0),
		Color(0.0, 0.5, 1.0),    Color(1.0, 0.86, 0.67),
		Color(0.06, 0.06, 0.06), Color(0.4, 0.3, 0.2),
	]
	for c in colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		defaults.append(mat)
	return defaults

func _get_all_children(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result
