extends Control

@export var sensitivity: float = 0.5
@export var player_node: CharacterBody3D

var touch_index: int = -1

func _gui_input(event):
	# NOVO SISTEMA: Respeita a ordem dos botões na tela! 🏗️🕹️🎯
	if event is InputEventScreenTouch:
		if event.pressed:
			# BLINDAGEM FÍSICA: Se o toque NASCER na metade esquerda, ignore totalmente para sempre! 🧱🥊
			var viewport_width = get_viewport_rect().size.x
			if event.position.x < viewport_width / 2:
				return
				
			if touch_index == -1:
				touch_index = event.index
				accept_event()
		elif event.index == touch_index:
			touch_index = -1
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			var mouse_motion = event.relative
			
			# AMORTECEDOR DE ELITE: Previne saltos loucos de mira causado por frames perdidos 🏁🥊
			if mouse_motion.length() > 200: 
				return
				
			if player_node:
				player_node.rotate_y(-mouse_motion.x * Global.sensitivity)
				var camera = player_node.get_node("Camera3D")
				if camera:
					camera.rotate_x(-mouse_motion.y * Global.sensitivity)
					camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
			
			accept_event()
