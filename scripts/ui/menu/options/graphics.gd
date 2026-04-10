extends CheckButton

func _ready():
	button_pressed = !Global.is_mobile # Start low quality on mobile

func _toggled(toggled_on: bool) -> void:
	# 1. CONTROLE DE AMBIENTE (Bloom/Glow/SSAO) V2070 🏙️🎯🥇
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = toggled_on
		world_env.environment.ssao_enabled = toggled_on
		world_env.environment.tonemap_mode = 3 if toggled_on else 0 # ACES vs Linear
	
	# 2. CONTROLE DE SOMBRAS (Luzes) V2070 🔦🚫🌑
	var lights = get_tree().get_nodes_in_group("lights")
	if lights.is_empty():
		# Busca fallback se não houver grupo
		for light in get_tree().root.find_children("", "Light3D", true, false):
			light.shadow_enabled = toggled_on
	else:
		for light in lights:
			if light is Light3D:
				light.shadow_enabled = toggled_on
				
	print("QUALIDADE GRÁFICA: ", "ALTA (Sombras/Bloom ON)" if toggled_on else "BAIXA (Sombras/Bloom OFF)")
