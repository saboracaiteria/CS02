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
		
	capture_progress += delta * 12.5 # 8 segundos para capturar (100 / 8 = 12.5) ⏱️🏙️🥇
	if capture_progress >= 100.0:
		owning_team = team
		capture_progress = 100.0
		zone_captured.emit(team, zone_id)
		_on_captured()

func _on_captured():
	# Efeito visual de estouro/som aqui
	pass

func _update_visuals():
	label.text = "ÁREA %s\n%s\n%d%%" % [zone_id, owning_team, int(capture_progress)]
	
	var target_color = Color(0.5, 0.5, 0.5, 0.3)
	var label_color = Color(1, 1, 1) # Branco Neutro
	
	if owning_team == "Azul": 
		target_color = Color(0, 0.4, 1, 0.4)
		label_color = Color(0, 0.7, 1)
	elif owning_team == "Vermelho": 
		target_color = Color(1, 0.1, 0.1, 0.4)
		label_color = Color(1, 0.2, 0.2)
	elif capture_progress > 0:
		label_color = Color(1, 1, 0) # Amarelo capturando ⚠️
	
	if mesh and mesh.material_override:
		mesh.material_override.albedo_color = target_color
	
	if label:
		label.modulate = label_color
