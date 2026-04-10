extends Control

@export var base_radius: float = 100.0
@export var stick_radius: float = 40.0
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_up: String = "move_up"
@export var action_down: String = "move_down"
@export var is_floating: bool = true # CODM STYLE! 🏙️🎯🥇

# Referências aos novos nós visuais 🥋
@onready var base: Control = $Base
@onready var knob: Control = $Knob

var joystick_active: bool = false
var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO
var default_position: Vector2 # Para resetar no floating! 🏙️🚀

var _is_scaling: bool = false
var _scale_indicator: ColorRect = null

func _ready():
	# Define um tamanho real para o controle capturar o _gui_input 💎
	custom_minimum_size = Vector2(200, 200)
	size = Vector2(200, 200)
	pivot_offset = Vector2(100, 100) # Centro exato
	
	# Criar indicador visual de escala (Seta) mais robusto ↕️
	_scale_indicator = ColorRect.new()
	_scale_indicator.color = Color(1, 1, 0, 0.6)
	_scale_indicator.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_scale_indicator.offset_left = -40
	_scale_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scale_indicator)
	
	# Adiciona um texto simples por cima
	var l = Label.new()
	l.text = "↕"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scale_indicator.add_child(l)
	
	_scale_indicator.hide()
	
	default_position = global_position
	_reset_joystick()

func _process(_delta):
	if _scale_indicator:
		_scale_indicator.visible = Global.is_editing_hud
	
	# RESGATE DE EMERGÊNCIA V1060: 🛡️🏗️🎯
	# Se o joystick acha que está ativo, mas o mouse/toque não está pressionado, RESET!
	if joystick_active:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_index == -1:
			_reset_joystick()
		# Verificação extra para mobile
		elif touch_index != -1 and not DisplayServer.is_touchscreen_available():
			# No PC, se o mouse soltou, reseta independente do index
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_reset_joystick()

func _gui_input(event):
	if Global.is_editing_hud:
		if event is InputEventScreenTouch:
			if event.pressed:
				if event.position.x > size.x * 0.7: # Área maior para o Joystick
					_is_scaling = true
				else:
					_is_scaling = false
			accept_event()
		elif event is InputEventScreenDrag:
			if _is_scaling:
				var sensitivity = 0.01
				var scale_change = -event.relative.y * sensitivity
				var new_val = clamp(scale.x + scale_change, 0.7, 3.0)
				scale = Vector2(new_val, new_val)
			else:
				global_position += event.relative
				default_position = global_position
			accept_event()
		return

func _input(event):
	if Global.is_editing_hud: return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			# PROTEÇÃO: Só ativa se for no lado esquerdo da tela! 🧱🥊
			if event.position.x > get_viewport_rect().size.x * 0.45:
				return
				
			if is_floating:
				global_position = event.position - (size / 2.0 * scale)
			
			# Cálculo do centro corrigido para V1480 🏗️🎯
			var center = global_position + (size / 2.0 * scale)
			var touch_dist = (event.position - center).length()
			
			if touch_dist <= base_radius * scale.x or is_floating:
				joystick_active = true
				touch_index = event.index
				_handle_drag(event.position)
				get_viewport().set_input_as_handled()
		elif event.index == touch_index:
			_reset_joystick()
			get_viewport().set_input_as_handled()
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			_handle_drag(event.position)
			get_viewport().set_input_as_handled()


func _handle_drag(touch_pos: Vector2):
	var center = global_position + (size / 2.0 * scale)
	var vec = touch_pos - center
	var max_dist = base_radius * scale.x
	
	if vec.length() > max_dist:
		vec = vec.normalized() * max_dist
	
	# No novo sistema visual, knob centralizado com base no parent scale 🎯
	if knob:
		# Reposiciona o knob relativo ao centro do controle (100, 100) 🏗️
		knob.position = (vec / scale) + (size / 2.0) - (knob.size / 2.0)
	
	output_vector = vec / max_dist
	_update_input_map()

func _reset_joystick():
	joystick_active = false
	touch_index = -1
	output_vector = Vector2.ZERO
	if knob:
		knob.position = -knob.size / 2.0
	if is_floating:
		global_position = default_position # VOLTA PARA A BASE! 🏙️🚀
	_update_input_map()

func _update_input_map():
	# Transmite o movimento para o jogador 🏎️💨
	_set_action(action_left, -output_vector.x if output_vector.x < 0 else 0.0)
	_set_action(action_right, output_vector.x if output_vector.x > 0 else 0.0)
	_set_action(action_up, -output_vector.y if output_vector.y < 0 else 0.0)
	_set_action(action_down, output_vector.y if output_vector.y > 0 else 0.0)

func _set_action(action_name: String, strength: float):
	if action_name == "": return
	if strength > 0.1:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)

func get_value() -> Vector2:
	return output_vector
