extends Node3D
# MAP: ARENA BUNKER V1.0 🏗️🎯
# Mapa procedural gerado em GDScript puro — sem arquivo .glb necessário.
# Layout: Arena militar quadrada 60×60u com bunker central, cobertura simétrica e trincheiras.

# ── Paleta ──────────────────────────────────────────────
const COL_FLOOR  := Color(0.20, 0.18, 0.15)   # Concreto escuro
const COL_WALL   := Color(0.42, 0.18, 0.06)   # Enferrujado / laranja industrial
const COL_STRUCT := Color(0.26, 0.24, 0.20)   # Concreto estrutural
const COL_RAMP   := Color(0.32, 0.28, 0.18)   # Rampa
const COL_TRENCH := Color(0.30, 0.26, 0.18)   # Parapeito de trincheira
const COL_BARREL := Color(0.14, 0.14, 0.16)   # Barril

func _ready() -> void:
	_build_floor()
	_build_outer_walls()
	_build_central_bunker()
	_build_cover()
	_build_trenches()
	_build_barrels()

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
	mat.roughness = 1.0
	mat.metallic = 0.0
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
	mat.roughness = 1.0
	mat.metallic = 0.0
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
	_box(Vector3(0, -0.5, 0), Vector3(60, 1, 60), COL_FLOOR)

func _build_outer_walls() -> void:
	var h := 5.0
	_box(Vector3(0,   h/2, -30), Vector3(60, h, 1), COL_WALL)   # Norte
	_box(Vector3(0,   h/2,  30), Vector3(60, h, 1), COL_WALL)   # Sul
	_box(Vector3(-30, h/2,   0), Vector3(1, h, 60), COL_WALL)   # Oeste
	_box(Vector3(30,  h/2,   0), Vector3(1, h, 60), COL_WALL)   # Leste

func _build_central_bunker() -> void:
	# Plataforma base
	_box(Vector3(0, 0.5, 0), Vector3(10, 1, 10), COL_STRUCT)
	# Parede Norte (fechada)
	_box(Vector3(0, 2.0, -4.75), Vector3(10, 3.0, 0.5), COL_STRUCT)
	# Parede Sul (fechada)
	_box(Vector3(0, 2.0,  4.75), Vector3(10, 3.0, 0.5), COL_STRUCT)
	# Parede Oeste (com abertura central — esquerda/direita 2u)
	_box(Vector3(-4.75, 2.0, -1.75), Vector3(0.5, 3.0, 2.5), COL_STRUCT)
	_box(Vector3(-4.75, 2.0,  1.75), Vector3(0.5, 3.0, 2.5), COL_STRUCT)
	# Parede Leste (mesma abertura)
	_box(Vector3( 4.75, 2.0, -1.75), Vector3(0.5, 3.0, 2.5), COL_STRUCT)
	_box(Vector3( 4.75, 2.0,  1.75), Vector3(0.5, 3.0, 2.5), COL_STRUCT)
	# Teto / 2º andar
	_box(Vector3(0, 3.75, 0), Vector3(11, 0.5, 11), COL_STRUCT)
	# Rampa de acesso Norte (3 degraus)
	_box(Vector3(0, 1.33, -6.0), Vector3(3, 0.33, 2.0), COL_RAMP)
	_box(Vector3(0, 2.10, -7.2), Vector3(3, 0.33, 2.0), COL_RAMP)
	_box(Vector3(0, 2.90, -8.4), Vector3(3, 0.33, 2.0), COL_RAMP)
	# Parapeito no teto
	_box(Vector3(0,   4.25, -5.25), Vector3(11, 0.5, 0.5), COL_STRUCT)
	_box(Vector3(0,   4.25,  5.25), Vector3(11, 0.5, 0.5), COL_STRUCT)
	_box(Vector3(-5.25, 4.25, 0),   Vector3(0.5, 0.5, 10), COL_STRUCT)
	_box(Vector3( 5.25, 4.25, 0),   Vector3(0.5, 0.5, 10), COL_STRUCT)

func _build_cover() -> void:
	# Containers por zona (cores vivas — estilo mapa original)
	var containers := [
		# Canto NW — stack 2 altos
		[Vector3(-17, 1.0, -17), Vector3(5, 2, 2), Color(1.0, 0.12, 0.10)],
		[Vector3(-17, 3.0, -17), Vector3(5, 2, 2), Color(1.0, 0.40, 0.10)],
		# Canto NE — stack 2 altos
		[Vector3( 17, 1.0, -17), Vector3(5, 2, 2), Color(0.10, 0.55, 1.0)],
		[Vector3( 17, 3.0, -17), Vector3(5, 2, 2), Color(0.10, 0.90, 0.55)],
		# Canto SW — stack 2 altos
		[Vector3(-17, 1.0,  17), Vector3(5, 2, 2), Color(0.2, 1.0, 0.2)],
		[Vector3(-17, 3.0,  17), Vector3(5, 2, 2), Color(1.0, 1.0, 0.1)],
		# Canto SE — stack 2 altos
		[Vector3( 17, 1.0,  17), Vector3(5, 2, 2), Color(1.0, 0.50, 0.0)],
		[Vector3( 17, 3.0,  17), Vector3(5, 2, 2), Color(0.9, 0.10, 0.9)],
		# Eixo meio Leste/Oeste (cobertura lateral)
		[Vector3(-12, 1.0, 0), Vector3(2, 2, 6), Color(0.7, 0.6, 0.10)],
		[Vector3( 12, 1.0, 0), Vector3(2, 2, 6), Color(0.1, 0.7, 0.85)],
		# Eixo Norte/Sul (cobertura frontal da entrada)
		[Vector3(0, 1.0, -13), Vector3(6, 2, 2), Color(1.0, 0.2, 0.5)],
		[Vector3(0, 1.0,  13), Vector3(6, 2, 2), Color(0.4, 0.1, 1.0)],
	]
	for c in containers:
		_box(c[0], c[1], c[2])

func _build_trenches() -> void:
	# 4 pares de parapeito em L nas diagonais do mapa
	var pairs := [
		[Vector3(-22, 0.75, -8), Vector3(1.0, 1.5, 6),  Vector3(-25, 0.75, -5), Vector3(6.0, 1.5, 1.0)],
		[Vector3( 22, 0.75,  8), Vector3(1.0, 1.5, 6),  Vector3( 25, 0.75,  5), Vector3(6.0, 1.5, 1.0)],
		[Vector3(-22, 0.75,  8), Vector3(1.0, 1.5, 6),  Vector3(-25, 0.75,  5), Vector3(6.0, 1.5, 1.0)],
		[Vector3( 22, 0.75, -8), Vector3(1.0, 1.5, 6),  Vector3( 25, 0.75, -5), Vector3(6.0, 1.5, 1.0)],
	]
	for p in pairs:
		_box(p[0], p[1], COL_TRENCH)
		_box(p[2], p[3], COL_TRENCH)

func _build_barrels() -> void:
	var positions := [
		Vector3(-21, 0.6, -21), Vector3( 21, 0.6, -21),
		Vector3(-21, 0.6,  21), Vector3( 21, 0.6,  21),
		Vector3( -9, 0.6, -12), Vector3(  9, 0.6, -12),
		Vector3( -9, 0.6,  12), Vector3(  9, 0.6,  12),
		Vector3(  0, 0.6, -23), Vector3(  0, 0.6,  23),
		Vector3(-23, 0.6,   0), Vector3( 23, 0.6,   0),
	]
	for pos in positions:
		_cyl(pos, 0.4, 1.2, COL_BARREL)
