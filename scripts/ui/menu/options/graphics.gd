extends CheckButton
# --- GRÁFICOS + CACHE V6.0 🏙️🎯🥇 ---

var shadow_btn : CheckButton
var bloom_btn : CheckButton
var res_slider : HSlider
var res_label : Label

func _ready():
	text = "Qualidade Gráfica Ultra"
	button_pressed = false
	_setup_extra_controls.call_deferred()

func _setup_extra_controls():
	var parent = get_parent()
	if not parent: return
	
	var my_idx = get_index()
	
	# --- RESOLUÇÃO ---
	res_label = Label.new()
	res_label.text = "Resolução 3D (Upscale): 50%"
	parent.add_child(res_label)
	parent.move_child(res_label, my_idx + 1)
	
	res_slider = HSlider.new()
	res_slider.min_value = 0.3
	res_slider.max_value = 1.0
	res_slider.step = 0.05
	res_slider.value = 0.5  # Padrão 50%
	res_slider.value_changed.connect(_on_res_scale_changed)
	parent.add_child(res_slider)
	parent.move_child(res_slider, my_idx + 2)
	
	# --- SOMBRAS ---
	shadow_btn = CheckButton.new()
	shadow_btn.text = "Ativar Sombras (PC/Web)"
	shadow_btn.button_pressed = false  # Desativadas por padrão
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
	
	# Antialiasing base — FXAA é leve e estável na Web
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	
	# --- CARREGA DO CACHE ---
	_load_from_cache()

func _load_from_cache():
	var cache = get_node_or_null("/root/SettingsCache")
	if not cache:
		# Sem cache, aplica padrão hardcoded
		_apply_defaults()
		return
	
	var scale_val = cache.get_render_scale()
	var shadows   = cache.get_shadows()
	var bloom     = cache.get_bloom()
	
	_on_res_scale_changed(scale_val)
	if res_slider: res_slider.value = scale_val
	
	_on_shadow_toggled(shadows)
	if shadow_btn: shadow_btn.button_pressed = shadows
	
	_on_bloom_toggled(bloom)
	if bloom_btn: bloom_btn.button_pressed = bloom
	
	print("[GRÁFICOS] Configurações carregadas do cache (escala=%.0f%%, sombras=%s, bloom=%s)" % [scale_val*100, shadows, bloom])

func _apply_defaults():
	# 50% resolucao, sombras OFF, bloom OFF
	_on_res_scale_changed(0.5)
	if res_slider: res_slider.value = 0.5
	_on_shadow_toggled(false)
	if shadow_btn: shadow_btn.button_pressed = false
	_on_bloom_toggled(false)
	if bloom_btn: bloom_btn.button_pressed = false

func _on_res_scale_changed(value: float) -> void:
	get_viewport().scaling_3d_scale = value
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	if res_label:
		res_label.text = "Resolução 3D (Upscale): %d%%" % (value * 100)
	# Salva no cache
	var cache = get_node_or_null("/root/SettingsCache")
	if cache: cache.set_render_scale(value)

func _toggled(toggled_on: bool) -> void:
	_on_shadow_toggled(toggled_on)
	_on_bloom_toggled(toggled_on)
	if toggled_on:
		get_viewport().msaa_3d = Viewport.MSAA_2X if not Global.is_mobile else Viewport.MSAA_DISABLED
		_on_res_scale_changed(1.0)
		if res_slider: res_slider.value = 1.0
	else:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		var default_scale = 0.5
		_on_res_scale_changed(default_scale)
		if res_slider: res_slider.value = default_scale
	if shadow_btn: shadow_btn.button_pressed = toggled_on
	if bloom_btn: bloom_btn.button_pressed = toggled_on

func _on_shadow_toggled(toggled_on: bool) -> void:
	for light in get_tree().root.find_children("*", "Light3D", true, false):
		light.shadow_enabled = toggled_on
	# Salva no cache
	var cache = get_node_or_null("/root/SettingsCache")
	if cache: cache.set_shadows(toggled_on)
	print("[GRÁFICOS] Sombras ", "Ligadas" if toggled_on else "Desligadas")

func _on_bloom_toggled(toggled_on: bool) -> void:
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = toggled_on
		world_env.environment.tonemap_mode = 3 if toggled_on else 0
	# Salva no cache
	var cache = get_node_or_null("/root/SettingsCache")
	if cache: cache.set_bloom(toggled_on)
	print("[GRÁFICOS] Bloom/HDR ", "Ligado" if toggled_on else "Desligado")
