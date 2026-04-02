extends BaseButton

@export var action_name: String = ""

func _ready():
	# Conexão nativa para o toque/clique 🥊
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _on_down():
	if action_name == "fullscreen":
		# Alterna o modo de tela no sistema nativo 🏁📺
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	if action_name != "":
		Input.action_press(action_name)

func _on_up():
	if action_name != "" and action_name != "fullscreen":
		Input.action_release(action_name)
