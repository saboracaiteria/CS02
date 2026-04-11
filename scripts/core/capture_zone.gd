extends Area3D

signal zone_captured(team_name, zone_id)

@export var zone_id: String = "A"
var capture_progress: float = 0.0
var owning_team: String = "Nenhum" # "Azul", "Vermelho"
var players_inside: Array = []

@onready var mesh = $MeshInstance3D
@onready var label = $Label3D

func _ready():
	add_to_group("capture_zone")
	
	# CONFIGURAÇÃO DE COLISÃO V2480: Detecta Jogadores e Bots (Camada 2) 🛡️🏙️🥇
	collision_layer = 0 
	collision_mask = 2 
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# SETUP VISUAL V2480: Único para cada zona! 🎨🏙️🥇
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
		mesh.material_override = mat
		
	_update_visuals()

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("bot"):
		players_inside.append(body)

func _on_body_exited(body):
	players_inside.erase(body)

func _process(delta):
	var team_balance = 0
	for body in players_inside:
		if body.get("team") == "Azul": team_balance += 1
		elif body.get("team") == "Vermelho": team_balance -= 1
	
	if team_balance > 0:
		_process_capture("Azul", delta)
	elif team_balance < 0:
		_process_capture("Vermelho", delta)
	else:
		# Regressão lenta se estiver vazio
		if players_inside.is_empty() and capture_progress > 0 and capture_progress < 100:
			capture_progress = max(0, capture_progress - delta * 5.0)
	
	_update_visuals()

func _process_capture(team, delta):
	if owning_team == team: 
		capture_progress = 100.0
		return
		
	if owning_team != "Nenhum":
		# NEUTRALIZAÇÃO V2500: Primeiro tira o controle do inimigo! 🏙️🎯🥇
		capture_progress -= delta * 20.0 # Neutraliza em ~5s
		if capture_progress <= 0:
			owning_team = "Nenhum"
			capture_progress = 0
			print("--- ÁREA %s NEUTRALIZADA ---" % zone_id)
	else:
		# CAPTURANDO: Zona neutra sendo tomada ⏱️
		capture_progress += delta * 12.5 # 8 segundos para capturar (100 / 8 = 12.5)
		if capture_progress >= 100.0:
			owning_team = team
			capture_progress = 100.0
			zone_captured.emit(team, zone_id)
			_on_captured()

func _on_captured():
	# Feedback sonoro ou vibrar pode vir aqui ⚡
	print("--- ÁREA %s RECUPERADA PELO TIME %s ---" % [zone_id, owning_team])

func _update_visuals():
	var progress_text = ""
	if owning_team == "Nenhum" and capture_progress > 0:
		progress_text = "\nCAPTURANDO..." 
	elif owning_team != "Nenhum" and capture_progress < 100:
		progress_text = "\nPERDENDO..."
		
	label.text = "ÁREA %s\n%s\n%d%%%s" % [zone_id, owning_team, int(capture_progress), progress_text]
	
	var target_color = Color(0.5, 0.5, 0.5, 0.2)
	var label_color = Color(1, 1, 1) 
	
	if owning_team == "Azul": 
		target_color = Color(0, 0.5, 1, 0.6) # Azul mais forte V2500
		label_color = Color(0, 0.8, 1)
	elif owning_team == "Vermelho": 
		target_color = Color(1, 0.2, 0.2, 0.6) # Vermelho mais forte V2500
		label_color = Color(1, 0.4, 0.4)
	elif capture_progress > 1:
		label_color = Color(1, 1, 0) # Amarelo capturando ⚠️
	
	# PINTA TODAS AS MESHES DA ZONA V2500 (Base, Poste, etc) 🎨🏙️🥇
	for child in get_children():
		if child is MeshInstance3D:
			if !child.material_override:
				# Cria material se não tiver
				var m = StandardMaterial3D.new()
				m.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
				m.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
				child.material_override = m
			
			child.material_override.albedo_color = target_color
	
	if label:
		label.modulate = label_color
