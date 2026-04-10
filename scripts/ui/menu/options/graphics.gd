extends CheckButton

var shadow_btn : CheckButton
var bloom_btn : CheckButton
var res_slider : HSlider
var res_label : Label

func _ready():
	# 1. Configura o botão principal V2120: BAIXO POR PADRÃO! 🏙️🎯
	text = "Qualidade Gráfica Ultra"
	button_pressed = false 
	
	# 2. Injeta botões extras V2120 🏗️🏹🥋
	var container = get_parent()
	if container:
		# --- SLIDER DE RESOLUÇÃO (UPSCALE) V2400 🏙️🚀🎯 ---
		res_label = Label.new()
		res_label.text = "Resolução 3D (Upscale): 100%"
		container.add_child(res_label)
		
		res_slider = HSlider.new()
		res_slider.min_value = 0.4
		res_slider.max_value = 1.0
		res_slider.step = 0.05
		res_slider.value = 1.0
		res_slider.value_changed.connect(_on_res_scale_changed)
		container.add_child(res_slider)

		# Botão de Sombras
		shadow_btn = CheckButton.new()
		shadow_btn.text = "Ativar Sombras (PC/Web)"
		shadow_btn.button_pressed = false
		shadow_btn.toggled.connect(_on_shadow_toggled)
		container.add_child(shadow_btn)
		
		# Botão de Bloom
		bloom_btn = CheckButton.new()
		bloom_btn.text = "Ativar Bloom (Brilho)"
		bloom_btn.button_pressed = false
		bloom_btn.toggled.connect(_on_bloom_toggled)
		container.add_child(bloom_btn)
	
	# Garante que comece tudo desligado V2120 🔦🚫🌑
	_on_shadow_toggled(false)
	_on_bloom_toggled(false)
	_on_res_scale_changed(1.0) # Começa em 100%

func _on_res_scale_changed(value: float) -> void:
	# GODOT 4 SUPREMACIA: Resolução Interna Reduzida 🏎️💨
	get_viewport().scaling_3d_scale = value
	if value < 1.0:
		# Usa Bilinear para performance máxima em PCs fracos! 🎮
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	else:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	
	if res_label:
		res_label.text = "Resolução 3D (Upscale): %d%%" % (value * 100)
	print("RESOLUÇÃO 3D: ", value)

func _toggled(toggled_on: bool) -> void:
	_on_shadow_toggled(toggled_on)
	_on_bloom_toggled(toggled_on)
	if shadow_btn: shadow_btn.button_pressed = toggled_on
	if bloom_btn: bloom_btn.button_pressed = toggled_on
	if toggled_on:
		_on_res_scale_changed(1.0)
	else:
		_on_res_scale_changed(0.7) # "Baixa" melhora muito a performance!

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
