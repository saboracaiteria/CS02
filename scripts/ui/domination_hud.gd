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
	
	# GARANTE VISIBILIDADE V2500 🏙️🎯🥇
	show()
	visible = true
	set_process(true)

func _process(_delta):
	if !game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
		return
		
	# Atualiza Tempo ou Mensagem de Fim de Jogo V2500 🏆🏙️🎯🥈
	if game_manager.winner_team != "":
		if game_manager.winner_team == "Azul":
			time_label.text = "🏆 VITÓRIA! 🏆"
			time_label.modulate = Color(1, 0.8, 0) # Dourado Vitória
		else:
			time_label.text = "💀 DERROTA! 💀"
			time_label.modulate = Color(1, 0, 0) # Vermelho Derrota
		
		# Aumenta escala se possível (visual impact)
		time_label.scale = Vector2(2.5, 2.5) 
	else:
		var mins = int(game_manager.match_time) / 60
		var secs = int(game_manager.match_time) % 60
		time_label.text = "%02d:%02d" % [mins, secs]
		time_label.modulate = Color(1, 1, 1)
		time_label.scale = Vector2(1, 1)
	
	# Atualiza Placar e Kills V2500 🏙️🎯🥇
	blue_score.text = "AZUL: %d  |  KILLS: %d" % [int(game_manager.team_blue_score), game_manager.player_kills]
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
