extends BaseButton

@export var action_name: String = ""

var _is_scaling: bool = false
var _scale_indicator: ColorRect = null

func _ready():
	pivot_offset = size / 2 # Escala centralizada 💎
	# Conexão nativa para o toque/clique 🥊
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	
	# Criar indicador visual de escala (Seta) mais robusto ↕️
	_scale_indicator = ColorRect.new()
	_scale_indicator.color = Color(1, 1, 0, 0.5) # Amarelo semi-transparente
	_scale_indicator.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_scale_indicator.offset_left = -40
	_scale_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child.call_deferred(_scale_indicator)
	
	# Texto Centralizado
	var l = Label.new()
	l.text = "↕"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scale_indicator.add_child.call_deferred(l)
	
	_scale_indicator.hide()

func _process(_delta):
	if _scale_indicator:
		_scale_indicator.visible = Global.is_editing_hud

func _gui_input(event):
	if Global.is_editing_hud:
		if event is InputEventScreenTouch:
			if event.pressed:
				if event.position.x > size.x * 0.6:
					_is_scaling = true
				else:
					_is_scaling = false
			accept_event()
		elif event is InputEventScreenDrag:
			if _is_scaling:
				var sensitivity = 0.01
				var scale_change = -event.relative.y * sensitivity
				var new_val = clamp(scale.x + scale_change, 0.4, 3.5)
				scale = Vector2(new_val, new_val)
			else:
				position += event.relative
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
