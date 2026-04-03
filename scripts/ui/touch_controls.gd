extends CanvasLayer

func _ready():
	# Começa totalmente invisível e escondido 🧱🥊
	visible = false
	layer = 125 
	
	if has_node("FullscreenButton"):
		$FullscreenButton.pressed.connect(_on_fullscreen_pressed)
	
	print("HUD SUPREMO V999 - MENU LIMPO")

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
