extends CanvasLayer

func _ready():
	# BLINDAGEM VISUAL: Forçando todos os botões a serem REDONDOS! 🏗️🕹️🎯
	var round_style = StyleBoxFlat.new()
	round_style.bg_color = Color(0.1, 0.1, 0.1, 0.25) # Translúcido elegante
	round_style.border_width_left = 2
	round_style.border_width_top = 2
	round_style.border_width_right = 2
	round_style.border_width_bottom = 2
	round_style.border_color = Color(1, 1, 1, 0.3)
	round_style.corner_radius_top_left = 100
	round_style.corner_radius_top_right = 100
	round_style.corner_radius_bottom_right = 100
	round_style.corner_radius_bottom_left = 100
	
	# MIRA BLINDADA: Painel de mira é EXATAMENTE a metade direita! 🏙️🎯🥇
	if has_node("LookArea"):
		var look_area = get_node("LookArea")
		look_area.anchor_left = 0.5
		look_area.anchor_right = 1.0
		look_area.anchor_top = 0.0
		look_area.anchor_bottom = 1.0
		look_area.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		look_area.anchor_left = 0.5
	
	# Aplicando estilo redondo nos botões 🥋🏹
	for child in get_children():
		if child is Button:
			child.add_theme_stylebox_override("normal", round_style)
			child.add_theme_stylebox_override("hover", round_style)
			child.add_theme_stylebox_override("pressed", round_style)
			child.add_theme_stylebox_override("focus", round_style)
			child.clip_contents = true
	
	# Começa totalmente invisível e escondido 🧱🥊
	visible = false
	layer = 125 
	
	if has_node("FullscreenButton"):
		$FullscreenButton.pressed.connect(_on_fullscreen_pressed)
	
	print("HUD SUPREMO V1008 - MURALHA FÍSICA E BOTÕES REDONDOS")

func _process(_delta):
	# Trava de Segurança Final: Se não estiver jogando, o HUD MORRE! 🛑⚔️🛡️
	if not Global.is_playing:
		if visible:
			visible = false
	else:
		# Se estiver jogando, o HUD PRECISA aparecer! ✨💎
		if not visible:
			visible = true

func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
