extends Control

@export var sensitivity: float = 0.5
@export var player_node: CharacterBody3D

var touch_index: int = -1

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_index == -1:
				touch_index = event.index
		elif event.index == touch_index:
			touch_index = -1
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			var mouse_motion = event.relative * sensitivity
			# We pass this to the player
			if player_node:
				player_node.rotate_y(-mouse_motion.x * Global.sensitivity)
				var camera = player_node.get_node("Camera3D")
				if camera:
					camera.rotate_x(-mouse_motion.y * Global.sensitivity)
					camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
