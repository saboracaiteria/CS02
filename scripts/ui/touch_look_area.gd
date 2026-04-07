extends Control

@export var sensitivity: float = 0.5
@export var player_node: CharacterBody3D

var touch_index: int = -1

func _gui_input(event):
	# PROTEÇÃO V1040: Somente o lada Direito rotaciona a câmera! 🥋🕹️🎯
	if event is InputEventScreenTouch:
		if event.pressed:
			# Bloqueio de 50% da largura da tela no toque inicial! 🧱🥊
			if event.position.x < get_viewport_rect().size.x * 0.5:
				return
				
			if touch_index == -1:
				touch_index = event.index
				accept_event()
		elif event.index == touch_index:
			touch_index = -1
			accept_event()
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			var mouse_motion = event.relative
			
			# PROTEÇÃO SUPREMA V1440: Bloqueia saltos fantasmas do navegador! 🏙️🥇🚀
			# Reduzido de 500 para 120 para evitar o giro de 360 graus.
			if mouse_motion.length() > 120: 
				return
				
			if player_node:
				# SENSIBILIDADE REFINADA: Multiplicador de suavização para Mobile! 📱✨
				var mobile_sens_adj = player_node.sensitivity * 0.75
				
				player_node.rotate_y(-mouse_motion.x * mobile_sens_adj)
				var camera = player_node.get_node("Camera3D")
				if camera:
					camera.rotate_x(-mouse_motion.y * mobile_sens_adj)
					camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
			
			accept_event()
