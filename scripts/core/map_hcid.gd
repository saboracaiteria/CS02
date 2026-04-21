extends Node3D
# MAP: UNITY LABYRINTH (Inspirado no HCID FPS) 🏗️
# Mapa aberto estilo prototype com plataformas altas, pilares cilindricos e labirinto.

const COL_FLOOR  := Color(0.85, 0.85, 0.85)   # Chão cinza claro
const COL_WALL   := Color(0.92, 0.92, 0.92)   # Paredes brancas
const COL_PLATFORM := Color(0.75, 0.75, 0.75) # Plataformas um pouco mais escuras
const COL_PILLAR := Color(0.65, 0.65, 0.65)   # Pilares

func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_labyrinth()
	_build_high_platforms()
	_build_pillars()

# ── Primitivos ──────────────────────────────────────────
func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.1
	mi.material_override = mat
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(mi)
	body.add_child(col)
	add_child(body)

func _cyl(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.1
	mi.material_override = mat
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	col.shape = sh
	body.add_child(mi)
	body.add_child(col)
	add_child(body)

# ── Construção ──────────────────────────────────────────
func _build_floor() -> void:
	_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80), COL_FLOOR)

func _build_walls() -> void:
	var h := 8.0
	_box(Vector3(0,   h/2, -40), Vector3(80, h, 1), COL_WALL)
	_box(Vector3(0,   h/2,  40), Vector3(80, h, 1), COL_WALL)
	_box(Vector3(-40, h/2,   0), Vector3(1, h, 80), COL_WALL)
	_box(Vector3(40,  h/2,   0), Vector3(1, h, 80), COL_WALL)

func _build_labyrinth() -> void:
	# Cria um labirinto central simples
	var walls_pos = [
		[Vector3(0, 1.5, 0), Vector3(20, 3, 1)],
		[Vector3(-10, 1.5, 10), Vector3(1, 3, 20)],
		[Vector3(10, 1.5, 15), Vector3(1, 3, 10)],
		[Vector3(0, 1.5, 20), Vector3(20, 3, 1)],
		[Vector3(-20, 1.5, -5), Vector3(1, 3, 15)],
		[Vector3(20, 1.5, -5), Vector3(1, 3, 15)],
		[Vector3(0, 1.5, -12), Vector3(15, 3, 1)],
	]
	for w in walls_pos:
		_box(w[0], w[1], COL_WALL)

func _build_high_platforms() -> void:
	# Plataformas com rampas e passarela superior baseadas no Unity
	# Passarela principal
	_box(Vector3(-25, 4.0, 25), Vector3(10, 0.5, 10), COL_PLATFORM)
	_box(Vector3(25, 4.0, 25),  Vector3(10, 0.5, 10), COL_PLATFORM)
	_box(Vector3(0, 4.0, 25),  Vector3(40, 0.5, 4), COL_PLATFORM)
	
	# Passarela secundária no norte
	_box(Vector3(0, 6.0, -25), Vector3(30, 0.5, 6), COL_PLATFORM)
	
	# Rampas para subir
	# Rampa para passarela sul-esquerda
	_box(Vector3(-25, 2.0, 15), Vector3(4, 0.5, 12), COL_PLATFORM) # Usaremos apenas caixas posicionadas anguladas se precisasse, mas assim o player as escadas "invisiveis"
	
	# Usando caixas menores para formar "escadas" do labirinto para a passarela
	for i in range(8):
		_box(Vector3(-25, 0.5 * i, 19 - i*1.2), Vector3(4, 0.5, 1.2), COL_PLATFORM)
		_box(Vector3(25, 0.5 * i, 19 - i*1.2),  Vector3(4, 0.5, 1.2), COL_PLATFORM)
		_box(Vector3(-15 + i*1.2, 0.5 * i + 4.0, -25),  Vector3(1.2, 0.5, 4), COL_PLATFORM) # Escada para plataforma 6m
		_box(Vector3(15 - i*1.2, 0.5 * i + 4.0, -25),  Vector3(1.2, 0.5, 4), COL_PLATFORM)

func _build_pillars() -> void:
	var pillars = [
		Vector3(-25, 2.0, 25), Vector3(25, 2.0, 25),
		Vector3(0, 2.0, 25), Vector3(-12.5, 2.0, 25), Vector3(12.5, 2.0, 25),
		Vector3(0, 3.0, -25), Vector3(-10, 3.0, -25), Vector3(10, 3.0, -25)
	]
	for pos in pillars:
		var h = pos.y * 2
		_cyl(pos, 1.0, h, COL_PILLAR)
