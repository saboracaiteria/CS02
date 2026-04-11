extends Node

signal game_over(winner_team)

var team_blue_score: float = 0.0
var team_red_score: float = 0.0
var match_time: float = 180.0 # 3 minutos
var is_active: bool = false

var zone_ownership = {"A": "Nenhum", "B": "Nenhum", "C": "Nenhum"}

var score_limit: float = 600.0 # Aumentado para partidas mais longas V2500 🏆🏙️🥇
var winner_team: String = ""
var player_kills: int = 0 # TRACKING DE KILLS INDIVIDUAL 🏙️🎯🥇

func _ready():
	add_to_group("game_manager")
	start_round()

func start_round():
	team_blue_score = 0
	team_red_score = 0
	match_time = 180.0
	winner_team = ""
	is_active = true

func _process(delta):
	if !is_active: return
	
	match_time -= delta
	if match_time <= 0:
		_finish_match("Tempo Esgotado")
		return
		
	# Ganha pontos por zonas dominadas
	var blue_zones = 0
	var red_zones = 0
	for zone in zone_ownership.values():
		if zone == "Azul": blue_zones += 1
		elif zone == "Vermelho": red_zones += 1
		
	if !is_multiplayer_authority(): return # Segurança para não multiplicar pontos 🛡️🏙️🥇
	
	team_blue_score += blue_zones * delta * 0.5 # Mais lento e estratégico
	team_red_score += red_zones * delta * 0.5
	
	# Checa Vitória por Pontuação 🏆
	if team_blue_score >= score_limit:
		_finish_match("Azul")
	elif team_red_score >= score_limit:
		_finish_match("Vermelho")

func _on_zone_captured(team, zone_id):
	zone_ownership[zone_id] = team
	print("MANJEDOURA: Time ", team, " capturou a Área ", zone_id)

func _finish_match(winner):
	if !is_active: return
	is_active = false
	winner_team = winner
	if winner == "Tempo Esgotado":
		winner_team = "Azul" if team_blue_score > team_red_score else "Vermelho"
	
	game_over.emit(winner_team)
	print("--- PARTIDA FINALIZADA! VENCEDOR: ", winner_team, " ---")
	
	# Reinicia após 10 segundos para não ser eterna! 🏙️🎯🥇
	await get_tree().create_timer(10.0).timeout
	get_tree().reload_current_scene()
