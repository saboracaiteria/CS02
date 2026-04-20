extends Node3D
# ─────────────────────────────────────────────────────────────
#  MAP: FOREST ROYALE  v1.0
#  Mini Battle Royale — Floresta com lago central  🌲🏞️
# ─────────────────────────────────────────────────────────────

const MAP_SIZE   := 80.0   # raio total do mapa
const LAKE_R     := 12.0   # raio do lago central
const TREE_COUNT := 90     # quantidade de arvores
const ROCK_COUNT := 30     # pedras de cobertura

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_ground()
	_build_lake()
	_build_perimeter_walls()
	_build_trees()
	_build_rocks()
	_build_ambient_grass()
	print("[MAP] Forest Royale carregado!")

# ─────────────────────────────────────────────────────────────
#  CHÃO VERDE
# ─────────────────────────────────────────────────────────────
func _build_ground() -> void:
	var ground = _make_box(
		Vector3(MAP_SIZE * 2.2, 1.0, MAP_SIZE * 2.2),
		Color(0.25, 0.52, 0.18),   # verde grama
		Vector3(0, -0.5, 0)
	)
	ground.name = "Ground"
	add_child(ground)

# ─────────────────────────────────────────────────────────────
#  LAGO CENTRAL
# ─────────────────────────────────────────────────────────────
func _build_lake() -> void:
	# Cama do lago (ligeiramente afundada)
	var bed = _make_cylinder(LAKE_R, 0.4, 24, Color(0.22, 0.38, 0.55))
	bed.position = Vector3(0, -0.3, 0)
	bed.name = "LakeBed"
	add_child(bed)

	# Superficie da agua (transparente/azul)
	var water_mesh = CylinderMesh.new()
	water_mesh.top_radius    = LAKE_R - 0.5
	water_mesh.bottom_radius = LAKE_R - 0.5
	water_mesh.height        = 0.05
	water_mesh.radial_segments = 32

	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color     = Color(0.1, 0.55, 0.9, 0.75)
	water_mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.metallic         = 0.0
	water_mat.roughness        = 0.05
	water_mat.emission_enabled = true
	water_mat.emission         = Color(0.05, 0.3, 0.6)
	water_mat.emission_energy_multiplier = 0.3
	water_mesh.material = water_mat

	var water = MeshInstance3D.new()
	water.mesh = water_mesh
	water.position = Vector3(0, 0.05, 0)
	water.name = "Water"
	add_child(water)

	# Colisao rasa do lago (nao bloqueia balas, so fisica de movimento)
	var lake_body = StaticBody3D.new()
	var lake_col  = CollisionShape3D.new()
	var lake_shape = CylinderShape3D.new()
	lake_shape.radius = LAKE_R
	lake_shape.height = 0.3
	lake_col.shape    = lake_shape
	lake_body.add_child(lake_col)
	lake_body.position = Vector3(0, 0.0, 0)
	lake_body.name = "LakeCollision"
	add_child(lake_body)

	# Pedras ao redor do lago
	var stone_count := 18
	for i in range(stone_count):
		var angle = (TAU / stone_count) * i + rng.randf_range(-0.2, 0.2)
		var dist  = LAKE_R + rng.randf_range(0.3, 1.8)
		var pos   = Vector3(cos(angle) * dist, 0.2, sin(angle) * dist)
		var s     = rng.randf_range(0.3, 0.9)
		var rock  = _make_box(
			Vector3(s * 1.2, s * 0.7, s),
			Color(0.45, 0.43, 0.4),
			pos
		)
		rock.rotation.y = rng.randf_range(0, TAU)
		add_child(rock)

# ─────────────────────────────────────────────────────────────
#  MUROS DO PERIMETRO (invisivel — zona de morte)
# ─────────────────────────────────────────────────────────────
func _build_perimeter_walls() -> void:
	var half = MAP_SIZE + 2.0
	var h    = 12.0
	var t    = 2.0
	var walls = [
		[Vector3(0,        h/2,  half), Vector3(half*2, h, t)],
		[Vector3(0,        h/2, -half), Vector3(half*2, h, t)],
		[Vector3( half,    h/2,  0),   Vector3(t, h, half*2)],
		[Vector3(-half,    h/2,  0),   Vector3(t, h, half*2)],
	]
	for w in walls:
		var wall = StaticBody3D.new()
		var col  = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = w[1]
		col.shape  = shape
		wall.add_child(col)
		wall.position = w[0]
		add_child(wall)

# ─────────────────────────────────────────────────────────────
#  ARVORES
# ─────────────────────────────────────────────────────────────
func _build_trees() -> void:
	var attempts := 0
	var placed   := 0
	while placed < TREE_COUNT and attempts < TREE_COUNT * 6:
		attempts += 1
		var angle = rng.randf_range(0, TAU)
		var dist  = rng.randf_range(LAKE_R + 4.0, MAP_SIZE - 4.0)
		var pos   = Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		# Evita o lago
		if pos.length() < LAKE_R + 3.0:
			continue

		var trunk_h = rng.randf_range(3.5, 7.0)
		var trunk_r = rng.randf_range(0.22, 0.40)
		var leaf_r  = rng.randf_range(1.8, 3.5)

		# Cor da folhagem com variacao natural
		var green_v = rng.randf_range(0.0, 1.0)
		var leaf_color = Color(
			lerp(0.08, 0.22, green_v),
			lerp(0.38, 0.62, green_v),
			lerp(0.08, 0.18, green_v)
		)

		_spawn_tree(pos, trunk_h, trunk_r, leaf_r, leaf_color)
		placed += 1

func _spawn_tree(pos: Vector3, trunk_h: float, trunk_r: float, leaf_r: float, leaf_color: Color) -> void:
	var tree_root = StaticBody3D.new()
	tree_root.position = pos

	# Colisao do tronco
	var col   = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = trunk_r
	shape.height = trunk_h
	col.shape    = shape
	col.position = Vector3(0, trunk_h / 2.0, 0)
	tree_root.add_child(col)

	# Mesh do tronco
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius    = trunk_r * 0.6
	trunk_mesh.bottom_radius = trunk_r
	trunk_mesh.height        = trunk_h
	trunk_mesh.radial_segments = 7

	var trunk_mat = StandardMaterial3D.new()
	var brown_v   = rng.randf_range(0.0, 1.0)
	trunk_mat.albedo_color = Color(
		lerp(0.32, 0.46, brown_v),
		lerp(0.20, 0.30, brown_v),
		lerp(0.10, 0.16, brown_v)
	)
	trunk_mat.roughness = 0.95
	trunk_mesh.material = trunk_mat

	var trunk_mi = MeshInstance3D.new()
	trunk_mi.mesh     = trunk_mesh
	trunk_mi.position = Vector3(0, trunk_h / 2.0, 0)
	tree_root.add_child(trunk_mi)

	# Copa — 2 esferas sobrepostas para dar volume
	for layer in range(2):
		var leaf_mesh = SphereMesh.new()
		var ls = leaf_r * (1.0 - layer * 0.25)
		leaf_mesh.radius     = ls
		leaf_mesh.height     = ls * 2.2
		leaf_mesh.radial_segments = 8
		leaf_mesh.rings = 5

		var leaf_mat = StandardMaterial3D.new()
		leaf_mat.albedo_color = leaf_color.darkened(layer * 0.1)
		leaf_mat.roughness = 0.9
		leaf_mesh.material = leaf_mat

		var leaf_mi = MeshInstance3D.new()
		leaf_mi.mesh     = leaf_mesh
		leaf_mi.position = Vector3(
			rng.randf_range(-0.3, 0.3),
			trunk_h + ls * 0.7 - layer * (ls * 0.4),
			rng.randf_range(-0.3, 0.3)
		)
		tree_root.add_child(leaf_mi)

	# Raizes grossas no chao
	for _r in range(3):
		var root_angle = rng.randf_range(0, TAU)
		var root_dist  = trunk_r + rng.randf_range(0.1, 0.5)
		var rm = BoxMesh.new()
		rm.size = Vector3(0.15, 0.2, rng.randf_range(0.4, 0.8))
		var rmat = trunk_mat.duplicate()
		rm.material = rmat
		var rmi = MeshInstance3D.new()
		rmi.mesh = rm
		rmi.position = Vector3(cos(root_angle) * root_dist, 0.1, sin(root_angle) * root_dist)
		rmi.rotation.y = root_angle
		tree_root.add_child(rmi)

	add_child(tree_root)

# ─────────────────────────────────────────────────────────────
#  PEDRAS (cobertura)
# ─────────────────────────────────────────────────────────────
func _build_rocks() -> void:
	for i in range(ROCK_COUNT):
		var angle = rng.randf_range(0, TAU)
		var dist  = rng.randf_range(LAKE_R + 5.0, MAP_SIZE - 6.0)
		var pos   = Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		var w = rng.randf_range(0.6, 2.2)
		var h = rng.randf_range(0.5, 1.6)
		var d = rng.randf_range(0.6, 2.0)

		var rock_body = StaticBody3D.new()
		rock_body.position = pos + Vector3(0, h / 2.0, 0)
		rock_body.rotation.y = rng.randf_range(0, TAU)

		var col   = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(w, h, d)
		col.shape  = shape
		rock_body.add_child(col)

		var mesh = BoxMesh.new()
		mesh.size = Vector3(w, h, d)
		var mat = StandardMaterial3D.new()
		var gray_v = rng.randf_range(0.0, 1.0)
		mat.albedo_color = Color(
			lerp(0.38, 0.58, gray_v),
			lerp(0.36, 0.55, gray_v),
			lerp(0.32, 0.50, gray_v)
		)
		mat.roughness = 0.9
		mesh.material = mat
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		rock_body.add_child(mi)
		add_child(rock_body)

# ─────────────────────────────────────────────────────────────
#  CAPIM / ARBUSTOS DECORATIVOS
# ─────────────────────────────────────────────────────────────
func _build_ambient_grass() -> void:
	for i in range(60):
		var angle = rng.randf_range(0, TAU)
		var dist  = rng.randf_range(LAKE_R + 2.0, MAP_SIZE - 2.0)
		var pos   = Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		var bush_mesh = SphereMesh.new()
		var s = rng.randf_range(0.3, 0.8)
		bush_mesh.radius = s
		bush_mesh.height = s * 1.2
		bush_mesh.radial_segments = 6
		bush_mesh.rings = 3

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(
			rng.randf_range(0.10, 0.20),
			rng.randf_range(0.40, 0.65),
			rng.randf_range(0.08, 0.15)
		)
		mat.roughness = 1.0
		bush_mesh.material = mat

		var mi = MeshInstance3D.new()
		mi.mesh = bush_mesh
		mi.position = pos + Vector3(0, s * 0.5, 0)
		add_child(mi)

# ─────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────
func _make_box(size: Vector3, color: Color, pos: Vector3) -> StaticBody3D:
	var body  = StaticBody3D.new()
	body.position = pos

	var col   = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape  = shape
	body.add_child(col)

	var mesh = BoxMesh.new()
	mesh.size = size
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = 0.9
	mesh.material    = mat
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	body.add_child(mi)
	return body

func _make_cylinder(radius: float, height: float, segs: int, color: Color) -> StaticBody3D:
	var body  = StaticBody3D.new()

	var col   = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)

	var mesh = CylinderMesh.new()
	mesh.top_radius    = radius
	mesh.bottom_radius = radius
	mesh.height        = height
	mesh.radial_segments = segs
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = 0.9
	mesh.material    = mat
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	body.add_child(mi)
	return body
