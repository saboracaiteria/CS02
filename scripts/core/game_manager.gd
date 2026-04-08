extends Node

signal game_over(winner_team)

var team_blue_score: float = 0.0
var team_red_score: float = 0.0
var match_time: float = 300.0 # 5 minutos
var is_active: bool = false

var zone_ownership = {"A": "Nenhum", "B": "Nenhum", "C": "Nenhum"}

func _ready():
	add_to_group("game_manager")
	start_round()

func start_round():
	team_blue_score = 0
	team_red_score = 0
	match_time = 300.0
	is_active = true

func _process(delta):
	if !is_active: return
	
	match_time -= delta
	if match_time <= 0:
		_finish_match()
		return
		
	# Ganha pontos por zonas dominadas
	var blue_zones = 0
	var red_zones = 0
	for zone in zone_ownership.values():
		if zone == "Azul": blue_zones += 1
		elif zone == "Vermelho": red_zones += 1
		
	team_blue_score += blue_zones * delta * 2.0
	team_red_score += red_zones * delta * 2.0

func _on_zone_captured(team, zone_id):
	zone_ownership[zone_id] = team
	print("MANJEDOURA: Time ", team, " capturou a Área ", zone_id)

func _finish_match():
	is_active = false
	var winner = "Azul" if team_blue_score > team_red_score else "Vermelho"
	game_over.emit(winner)
