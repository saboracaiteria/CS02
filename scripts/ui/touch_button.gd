extends TextureButton

@export var action_name: String = ""

func _ready():
	# TextureButtons work with touch out of the box in Godot 4
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down():
	if action_name != "":
		Input.action_press(action_name)

func _on_button_up():
	if action_name != "":
		Input.action_release(action_name)
