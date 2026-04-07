extends CheckButton

func _ready():
	button_pressed = !Global.is_mobile # Start low quality on mobile

func _toggled(toggled_on: bool) -> void:
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		world_env.environment.ssao_enabled = toggled_on
		world_env.environment.glow_enabled = toggled_on
		if toggled_on:
			world_env.environment.tonemap_mode = 3 # ACES
		else:
			world_env.environment.tonemap_mode = 0 # LINEAR
	
	print("QUALIDADE GRÁFICA: ", "ALTA" if toggled_on else "BAIXA")
