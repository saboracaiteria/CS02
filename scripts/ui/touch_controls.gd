extends CanvasLayer

func _ready():
	# BLINDAGEM VISUAL: Forçando todos os botões a serem REDONDOS! 🏗️🕹️🎯
	var round_style = StyleBoxFlat.new()
	round_style.bg_color = Color(0.1, 0.1, 0.1, 0.4) # Dark Glassmorphism 🧱💎
	round_style.border_width_left = 3
	round_style.border_width_top = 3
	round_style.border_width_right = 3
	round_style.border_width_bottom = 3
	round_style.border_color = Color(1.0, 1.0, 1.0, 0.5) # Neon Glass Border
	round_style.corner_radius_top_left = 100
	round_style.corner_radius_top_right = 100
	round_style.corner_radius_bottom_right = 100
	round_style.corner_radius_bottom_left = 100
	round_style.shadow_color = Color(0, 0, 0, 0.3)
	round_style.shadow_size = 10
	
	var pressed_style = round_style.duplicate()
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.2)
	pressed_style.border_color = Color(1.0, 1.0, 0.2, 0.9) # Glow Amarelo COD no clique! 🥇🏙️🎯
	
	# MIRA BLINDADA: Painel de mira é 100% da tela para BLINDAR contra toques fantasmas! 🏙️🎯🥇
	if has_node("LookArea"):
		var look_area = get_node("LookArea")
		look_area.anchor_left = 0.0
		look_area.anchor_right = 1.0
		look_area.anchor_top = 0.0
		look_area.anchor_bottom = 1.0
		look_area.set_anchors_preset(Control.PRESET_FULL_RECT) # 100% da tela para proteção total! 🏗️🕹️🎯
		# MODO HIBRIDO V1140: No PC, a LookArea DEVE IGNORAR o mouse para o player.gd capturar! 💻🖱️🚀
		if Global.is_mobile:
			look_area.mouse_filter = Control.MOUSE_FILTER_STOP 
		else:
			look_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(look_area, 0) # Joga para o fundo! 🛡️⚡🥋 
		
	# AGORA OS CONTROLES FICAM NO TOPO PARA RESPONDEREM AO TOQUE! ✨💎🚀
	# Re-ordenamos para que os botões fiquem NO TOPO da LookArea! 🛡️🕹️🎯
	for child in get_children():
		if child.name != "LookArea":
			move_child(child, get_child_count() - 1)

	# Aplicando estilo redondo nos botões 🥋🏹
	for child in get_children():
		if child is Button:
			child.add_theme_stylebox_override("normal", round_style)
			child.add_theme_stylebox_override("hover", round_style)
			child.add_theme_stylebox_override("pressed", pressed_style) # FEEDBACK PREMIUM! 🥋🚀
			child.add_theme_stylebox_override("focus", round_style)
			child.clip_contents = true
	
	# REDUÇÃO DE BOTÕES EM 50% V2430 📱✨🥊
	var buttons_to_scale = ["ShootButton", "HipfireButton", "AdsButton", "ReloadButton", "SwitchButton"]
	for btn_name in buttons_to_scale:
		if has_node(btn_name):
			var btn = get_node(btn_name)
			btn.scale = Vector2(0.5, 0.5)
			# Pivot no centro para não fugir da posição original!
			btn.pivot_offset = btn.size / 2.0
	
	# Começa totalmente invisível e escondido 🧱🥊
	visible = false
	layer = 125 
	
	# Desabilita filtro de input de painéis sobrepostos para não engolir o toque dos botões na direita!
	if has_node("StatusPanel"): get_node("StatusPanel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("AmmoPanel"): get_node("AmmoPanel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("PremiumOverlay"): get_node("PremiumOverlay").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# BLINDAGEM V1280: Busca o player no mundo para os botões funcionarem! 🏙️🎯🥇🚀
	var parent_node = get_parent()
	var player_node = null
	
	if parent_node is CharacterBody3D:
		player_node = parent_node
	else:
		# Se não estiver no player, tenta buscar na cena
		player_node = get_tree().get_first_node_in_group("player")
	
	for child in get_children():
		if "player_node" in child:
			child.player_node = player_node

	if has_node("FullscreenButton"):
		$FullscreenButton.pressed.connect(_on_fullscreen_pressed)
	
	print("HUD SUPREMO V1280 - THE END OF GHOST TOUCHES 🧱🎯🍹🕶️🚀")

func _process(_delta):
	# Trava de Segurança Final: Se não estiver jogando, o HUD MORRE! 🛑⚔️🛡️
	if not Global.is_playing:
		if visible:
			visible = false
	else:
		# Se estiver jogando e for mobile, o HUD PRECISA aparecer! ✨💎
		if Global.is_mobile:
			if not visible: visible = true
		else:
			if visible: visible = false


func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
