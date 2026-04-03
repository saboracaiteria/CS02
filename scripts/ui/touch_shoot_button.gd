extends Button

@export var action_name: String = "shoot"
@export var player_node: CharacterBody3D
var touch_index: int = -1

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Verifica se o toque foi DENTRO deste botão 🎯
			if get_global_rect().has_point(event.position):
				touch_index = event.index
				Input.action_press(action_name)
		elif event.index == touch_index:
			touch_index = -1
			Input.action_release(action_name)
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			# MECÂNICA FREE FIRE: Arraste o dedo no botão de tiro para mirar! 🏙️🎯
			# (Só ativa se for o botão de tiro real)
			if player_node and action_name == "shoot":
				var mouse_motion = event.relative
				player_node.rotate_y(-mouse_motion.x * Global.sensitivity * 0.5)
				var camera = player_node.get_node("Camera3D")
				if camera:
					camera.rotate_x(-mouse_motion.y * Global.sensitivity * 0.5)
					camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
