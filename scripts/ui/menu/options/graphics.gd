extends CheckButton

var shadow_btn : CheckButton
var bloom_btn : CheckButton

func _ready():
	# 1. Configura o botão principal V2080 🏙️🎯
	text = "Qualidade Gráfica Ultra"
	button_pressed = !Global.is_mobile
	
	# 2. Injeta botões extras se não existirem V2080 🏗️🏹🥋
	var container = get_parent()
	if container:
		# Botão de Sombras
		shadow_btn = CheckButton.new()
		shadow_btn.text = "Ativar Sombras (PC/Web)"
		shadow_btn.button_pressed = !Global.is_mobile
		shadow_btn.toggled.connect(_on_shadow_toggled)
		container.add_child(shadow_btn)
		
		# Botão de Bloom
		bloom_btn = CheckButton.new()
		bloom_btn.text = "Ativar Bloom (Brilho)"
		bloom_btn.button_pressed = !Global.is_mobile
		bloom_btn.toggled.connect(_on_bloom_toggled)
		container.add_child(bloom_btn)

func _toggled(toggled_on: bool) -> void:
	_on_shadow_toggled(toggled_on)
	_on_bloom_toggled(toggled_on)
	if shadow_btn: shadow_btn.button_pressed = toggled_on
	if bloom_btn: bloom_btn.button_pressed = toggled_on

func _on_shadow_toggled(toggled_on: bool) -> void:
	var lights = get_tree().get_nodes_in_group("lights")
	if lights.is_empty():
		for light in get_tree().root.find_children("*", "Light3D", true, false):
			light.shadow_enabled = toggled_on
	else:
		for light in lights:
			if light is Light3D: light.shadow_enabled = toggled_on
	print("SOMBRAS: ", toggled_on)

func _on_bloom_toggled(toggled_on: bool) -> void:
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = toggled_on
		world_env.environment.tonemap_mode = 3 if toggled_on else 0
	print("BLOOM: ", toggled_on)
