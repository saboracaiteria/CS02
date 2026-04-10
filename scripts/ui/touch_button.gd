extends BaseButton

@export var action_name: String = ""

var _edit_touches: Dictionary = {}

func _ready():
	pivot_offset = size / 2 # Garante escala centralizada 💎
	# Conexão nativa para o toque/clique 🥊
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _gui_input(event):
	if Global.is_editing_hud:
		if event is InputEventScreenTouch:
			if event.pressed:
				_edit_touches[event.index] = event.position
			else:
				_edit_touches.erase(event.index)
			accept_event()
		elif event is InputEventScreenDrag:
			_edit_touches[event.index] = event.position
			
			if _edit_touches.size() == 1:
				position += event.relative
			elif _edit_touches.size() == 2:
				var touch_ids = _edit_touches.keys()
				var p1 = _edit_touches[touch_ids[0]]
				var p2 = _edit_touches[touch_ids[1]]
				
				var old_p1 = p1
				var old_p2 = p2
				if event.index == touch_ids[0]:
					old_p1 -= event.relative
				else:
					old_p2 -= event.relative
				
				var old_dist = old_p1.distance_to(old_p2)
				var new_dist = p1.distance_to(p2)
				
				if old_dist > 0:
					var scale_factor = new_dist / old_dist
					var new_scale = scale * scale_factor
					new_scale.x = clamp(new_scale.x, 0.5, 3.5)
					new_scale.y = clamp(new_scale.y, 0.5, 3.5)
					scale = new_scale
			
			accept_event()
		return

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
