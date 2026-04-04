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
	
	# MIRA BLINDADA: Painel de mira é 100% da tela para BLINDAR contra toques fantasmas! 🏙️🎯🥇
	if has_node("LookArea"):
		var look_area = get_node("LookArea")
		look_area.anchor_left = 0.0
		look_area.anchor_right = 1.0
		look_area.anchor_top = 0.0
		look_area.anchor_bottom = 1.0
		look_area.set_anchors_preset(Control.PRESET_FULL_RECT) # 100% da tela para proteção total! 🏗️🕹️🎯
		look_area.mouse_filter = Control.MOUSE_FILTER_STOP # Agora engole tudo que os botões não pegarem! ✨🏁🥊 
		move_child(look_area, 0) # Joga para o fundo! 🛡️⚡🥋 
		
	# MURALHA FÍSICA: Bloqueio total do lado esquerdo para evitar drift! 🚧🧱⚡
	var left_shield = get_node_or_null("LeftShield")
	if not left_shield:
		left_shield = Control.new()
		left_shield.name = "LeftShield"
		add_child(left_shield)
		move_child(left_shield, 1) # Por cima da mira, mas abaixo dos controles! 🛡️⚡🥊 
	
	left_shield.anchor_left = 0.0
	left_shield.anchor_right = 0.45
	left_shield.anchor_top = 0.0
	left_shield.anchor_bottom = 1.0
	left_shield.mouse_filter = Control.MOUSE_FILTER_STOP # ENGOLIDOR DE TOQUES FANTASMAS! ✨🏹🥋 
	left_shield.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_shield.anchor_right = 0.45

	
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
	
	print("HUD SUPREMO V1020 - O MARTELO DE THOR 🧱🎯🥇")

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
