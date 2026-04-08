extends Control

@onready var time_label = $TimeLabel
@onready var blue_score = $ScoreBoard/BlueScore
@onready var red_score = $ScoreBoard/RedScore
@onready var status_a = $Status/A
@onready var status_b = $Status/B
@onready var status_c = $Status/C

var game_manager = null

func _ready():
	# Busca o Game Manager no mundo
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _process(_delta):
	if !game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
		return
		
	# Atualiza Tempo
	var mins = int(game_manager.match_time) / 60
	var secs = int(game_manager.match_time) % 60
	time_label.text = "%02d:%02d" % [mins, secs]
	
	# Atualiza Placar
	blue_score.text = "AZUL: %d" % int(game_manager.team_blue_score)
	red_score.text = "VERMELHO: %d" % int(game_manager.team_red_score)
	
	# Atualiza Ícones das Áreas
	_update_zone_icon(status_a, game_manager.zone_ownership["A"])
	_update_zone_icon(status_b, game_manager.zone_ownership["B"])
	_update_zone_icon(status_c, game_manager.zone_ownership["C"])

func _update_zone_icon(label, owner_team):
	if owner_team == "Azul":
		label.modulate = Color(0, 0.6, 1)
	elif owner_team == "Vermelho":
		label.modulate = Color(1, 0.2, 0.2)
	else:
		label.modulate = Color(1, 1, 1, 0.3)
