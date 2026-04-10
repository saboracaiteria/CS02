extends Button

@export var action_name: String = "shoot"
@export var player_node: CharacterBody3D
@export var auto_ads: bool = false # CODM STYLE: 1-Tap ADS 🏙️🎯🥇
var touch_index: int = -1
var _is_scaling: bool = false # Novo sistema V1470 📏
var _scale_indicator: ColorRect = null

func _ready():
	pivot_offset = size / 2 # Garante que a escala ocorra a partir do centro 💎
	if action_name == "screenshot":
		pressed.connect(_take_screenshot)
	
	# Criar indicador visual de escala (Seta) mais robusto ↕️
	_scale_indicator = ColorRect.new()
	_scale_indicator.color = Color(1, 1, 0, 0.5) # Amarelo semi-transparente
	_scale_indicator.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_scale_indicator.offset_left = -40
	_scale_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scale_indicator)
	
	# Texto Centralizado
	var l = Label.new()
	l.text = "↕"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scale_indicator.add_child(l)
	
	_scale_indicator.hide()

func _process(_delta):
	if _scale_indicator:
		_scale_indicator.visible = Global.is_editing_hud

func _take_screenshot():
	# CAPTURA DE ELITE: Foto da tela agora! 📸✨
	var img = get_viewport().get_texture().get_image()
	var time = Time.get_datetime_dict_from_system()
	var filename = "user://screenshot_%d%d%d_%d%d.png" % [time.year, time.month, time.day, time.hour, time.minute]
	img.save_png(filename)
	print("PRINT SALVO EM: ", filename)
	
	# Feedback Visual Rápido ⚡
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1).from(0.0)
	tween.tween_property(self, "modulate:a", 0.82, 0.4)

var player : Node3D = null

func _gui_input(event):
	# NOVO SISTEMA DE EDIÇÃO V1470: SEM PINÇA, MAIS PRECISÃO 🏗️📏🎯
	if Global.is_editing_hud:
		if event is InputEventScreenTouch:
			if event.pressed:
				# Se tocar na metade direita, ativa modo ESCALA 📏
				if event.position.x > size.x * 0.6:
					_is_scaling = true
				else:
					_is_scaling = false
			accept_event()
		
		elif event is InputEventScreenDrag:
			if _is_scaling:
				# Movimento Vertical: CIMA = Aumenta | BAIXO = Diminui ↕️
				var sensitivity = 0.01
				var scale_change = -event.relative.y * sensitivity
				var new_val = clamp(scale.x + scale_change, 0.4, 3.5)
				scale = Vector2(new_val, new_val)
			else:
				# Movimento Normal: Arrastar posição 🖱️
				position += event.relative
			accept_event()
		return
	
	# SISTEMA SUPREMO DE INPUT V1440 ⛩️🕹️🎯🏙️🥇🚀
	# Os botões agora avisam o PLAYER diretamente se estão ativos!
	if event is InputEventScreenTouch:
		# Busca o player se ainda não tiver V1440 ✨
		if not player:
			player = get_tree().get_first_node_in_group("player")
			if not player: # Fallback se não estiver no grupo
				var players = get_tree().get_nodes_in_group("players")
				for p in players:
					if p.is_multiplayer_authority():
						player = p
						break
		
		# Dispara a lógica de Mira/Tiro diretamente no Player! ✨
		if event.pressed:
			if touch_index == -1:
				touch_index = event.index
				if action_name == "shoot":
					if player: player.is_mobile_shooting = true
				else:
					if action_name == "reload" and player and player.has_method("_reload"):
						player._reload()
					elif action_name == "ads" and player:
						player.is_ads = true
					elif action_name == "switch_weapon" and player and player.has_method("cycle_weapon"):
						player.cycle_weapon()
					
					var ev = InputEventAction.new()
					ev.action = action_name
					ev.pressed = true
					Input.parse_input_event(ev)
				
				if auto_ads:
					if player: player.is_ads = true
				
				accept_event()
		elif event.index == touch_index:
			touch_index = -1
			if action_name == "shoot":
				if player: player.is_mobile_shooting = false
			else:
				if action_name == "ads" and player: player.is_ads = false
				var ev = InputEventAction.new()
				ev.action = action_name
				ev.pressed = false
				Input.parse_input_event(ev)
			
			if auto_ads:
				if player: player.is_ads = false
				
			accept_event()
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			# MECÂNICA FREE FIRE: Arraste o dedo no botão de tiro ou mira para rotacionar! 🏙️🎯
			if player_node and (action_name == "shoot" or action_name == "ads"):
				var mouse_motion = event.relative
				
				# PROTEÇÃO SUPREMA V1450: Bloqueia saltos fantasmas e giros bruscos! 🛡️🕹️
				if mouse_motion.length() > 120:
					return
				
				# Sensibilidade
				var mobile_sens_adj = Global.sensitivity * 0.75
				if action_name == "ads" or (auto_ads and action_name == "shoot"):
					mobile_sens_adj *= Global.ads_multiplier
				
				player_node.rotate_y(-mouse_motion.x * mobile_sens_adj)
				var camera = player_node.get_node("Camera3D")
				if camera:
					camera.rotate_x(-mouse_motion.y * mobile_sens_adj)
					camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
				
				accept_event() # CONSUME o drag para ser suave
