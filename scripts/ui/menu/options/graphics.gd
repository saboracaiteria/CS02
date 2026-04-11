extends CheckButton

var shadow_btn : CheckButton
var bloom_btn : CheckButton
var res_slider : HSlider
var res_label : Label

func _ready():
	# 1. Configuração Visual do Botão
	text = "Qualidade Gráfica Ultra"
	button_pressed = false 
	
	# 2. Injeção Robusta V2420 ✨🎯
	# Usamos um timer curto ou deferred para garantir que o menu já esteja montado
	_setup_extra_controls.call_deferred()

func _setup_extra_controls():
	var parent = get_parent()
	if not parent: return
	
	# Ordem de Inserção Controlada 🏗️🏹🥋
	var my_idx = get_index()
	
	# --- RESOLUÇÃO ---
	res_label = Label.new()
	res_label.text = "Resolução 3D (Upscale): 100%"
	parent.add_child(res_label)
	parent.move_child(res_label, my_idx + 1)
	
	res_slider = HSlider.new()
	res_slider.min_value = 0.4
	res_slider.max_value = 1.0
	res_slider.step = 0.05
	res_slider.value = 0.5
	res_slider.value_changed.connect(_on_res_scale_changed)
	parent.add_child(res_slider)
	parent.move_child(res_slider, my_idx + 2)
	
	# --- SOMBRAS ---
	shadow_btn = CheckButton.new()
	shadow_btn.text = "Ativar Sombras (PC/Web)"
	shadow_btn.button_pressed = false
	shadow_btn.toggled.connect(_on_shadow_toggled)
	parent.add_child(shadow_btn)
	parent.move_child(shadow_btn, my_idx + 3)
	
	# --- BLOOM ---
	bloom_btn = CheckButton.new()
	bloom_btn.text = "Ativar Bloom (Brilho)"
	bloom_btn.button_pressed = false
	bloom_btn.toggled.connect(_on_bloom_toggled)
	parent.add_child(bloom_btn)
	parent.move_child(bloom_btn, my_idx + 4)
	
	# Inicialização Segura 🛡️ (V2430: Começa em 50% por padrão)
	_on_shadow_toggled(false)
	_on_bloom_toggled(false)
	_on_res_scale_changed(0.5)

func _on_res_scale_changed(value: float) -> void:
	get_viewport().scaling_3d_scale = value
	# Bilinear é o rei da performance na Web 👑
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	
	if res_label:
		res_label.text = "Resolução 3D (Upscale): %d%%" % (value * 100)
	print("LOG [GRÁFICOS]: Resolução escalada para ", value)

func _toggled(toggled_on: bool) -> void:
	_on_shadow_toggled(toggled_on)
	_on_bloom_toggled(toggled_on)
	
	# MSAA (Anti-Aliasing) V2420: Desligar se não for ULTRA 🚫🏙️
	if toggled_on:
		get_viewport().msaa_3d = Viewport.MSAA_2X
		_on_res_scale_changed(1.0)
		if res_slider: res_slider.value = 1.0
	else:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		_on_res_scale_changed(0.5) # V2430: Volta para 50%
		if res_slider: res_slider.value = 0.5
	
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
	print("LOG [GRÁFICOS]: Sombras ", "Ligadas" if toggled_on else "Desligadas")

func _on_bloom_toggled(toggled_on: bool) -> void:
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = toggled_on
		# Tonemap Filmic (3) apenas em Ultra, Linear (0) em Low
		world_env.environment.tonemap_mode = 3 if toggled_on else 0
	print("LOG [GRÁFICOS]: Bloom/HDR ", "Ligado" if toggled_on else "Desligado")
