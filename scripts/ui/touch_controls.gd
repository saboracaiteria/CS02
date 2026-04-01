extends CanvasLayer

func _ready():
	# Force visibility and ensure it's on top
	visible = true
	layer = 100 
	
	if has_node("FullscreenButton"):
		$FullscreenButton.pressed.connect(_on_fullscreen_pressed)
	
	print("Touch Controls Initialized at Layer 100")

func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
