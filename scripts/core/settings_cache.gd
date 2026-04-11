extends Node
# --- SISTEMA DE CACHE DE CONFIGURAÇÕES V6.0 🏙️🎯🥇 ---
# Salva e carrega todas as configurações do jogo em disco.
# Compatível com Web (usa user:// que mapeia para IndexedDB no browser).

const SAVE_PATH := "user://settings.cfg"

var _cfg := ConfigFile.new()

# Valores padrão do jogo (primeira execução)
const DEFAULTS := {
	"render_scale": 0.5,      # 50%
	"shadows": false,         # Sombras desligadas por padrao
	"bloom": false,
	"sensitivity": 0.005,
	"controller_sensitivity": 0.010,
	"fov": 75.0,
	"hud_hp_x": -1.0,
	"hud_hp_y": -1.0,
	"hud_ammo_x": -1.0,
	"hud_ammo_y": -1.0,
}

func _ready():
	load_all()

func load_all():
	var err = _cfg.load(SAVE_PATH)
	if err != OK:
		# Primeira execução: cria com os padrões
		for key in DEFAULTS:
			_cfg.set_value("game", key, DEFAULTS[key])
		save_all()
		print("[CACHE] Primeira execução - defaults gravados.")
	else:
		# Garante que novos campos adicionados em updates também existam
		for key in DEFAULTS:
			if not _cfg.has_section_key("game", key):
				_cfg.set_value("game", key, DEFAULTS[key])
		print("[CACHE] Configurações carregadas com sucesso.")

func save_all():
	_cfg.save(SAVE_PATH)

# --- GETTERS / SETTERS GENÉRICOS ---

func get_val(key: String):
	return _cfg.get_value("game", key, DEFAULTS.get(key))

func set_val(key: String, value) -> void:
	_cfg.set_value("game", key, value)
	save_all()

# --- HELPERS TIPADOS ---

func get_render_scale() -> float:
	return float(get_val("render_scale"))

func set_render_scale(v: float) -> void:
	set_val("render_scale", clampf(v, 0.3, 1.0))

func get_shadows() -> bool:
	return bool(get_val("shadows"))

func set_shadows(v: bool) -> void:
	set_val("shadows", v)

func get_bloom() -> bool:
	return bool(get_val("bloom"))

func set_bloom(v: bool) -> void:
	set_val("bloom", v)

func get_sensitivity() -> float:
	return float(get_val("sensitivity"))

func set_sensitivity(v: float) -> void:
	set_val("sensitivity", v)

func get_fov() -> float:
	return float(get_val("fov"))

func set_fov(v: float) -> void:
	set_val("fov", v)

func get_hud_pos(element: String) -> Vector2:
	var x = float(get_val("hud_%s_x" % element))
	var y = float(get_val("hud_%s_y" % element))
	if x < 0 or y < 0:
		return Vector2(-1, -1) # Sinal de "usar padrão"
	return Vector2(x, y)

func set_hud_pos(element: String, pos: Vector2) -> void:
	set_val("hud_%s_x" % element, pos.x)
	set_val("hud_%s_y" % element, pos.y)
