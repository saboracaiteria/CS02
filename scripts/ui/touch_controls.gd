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
