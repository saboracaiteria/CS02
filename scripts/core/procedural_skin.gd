extends Node3D

# --- SISTEMA DE SKIN PROCEDURAL V5.2 (Fidelidade Estética) 🏙️🎯🥇 ---
# Replicando FIELMENTE a estrutura e movimentos do projeto Canaã PC.

var walk_cycle: float = 0.0
var pivots: Dictionary = {}
var materials: Dictionary = {}

func setup(team_color: Color = Color.ORANGE):
	# Limpeza
	for child in get_children():
		child.queue_free()
	
	# MATERIAIS ORIGINAIS
	materials["torso"] = StandardMaterial3D.new()
	materials["torso"].albedo_color = Color(0.15, 0.15, 0.15) # 0x222222
	
	materials["vest"] = StandardMaterial3D.new()
	materials["vest"].albedo_color = team_color # Cor de time no colete/veste
	
	materials["skin"] = StandardMaterial3D.new()
	materials["skin"].albedo_color = Color(1.0, 0.86, 0.67) # 0xffdbac
	
	materials["boot"] = StandardMaterial3D.new()
	materials["boot"].albedo_color = Color(0.06, 0.06, 0.06) # 0x111111
	
	materials["helmet"] = StandardMaterial3D.new()
	materials["helmet"].albedo_color = team_color.darkened(0.2)

	# PIVOT PRINCIPAL (PELVE) - Altura Y=1.0
	var pelve = Node3D.new()
	pelve.name = "PelvePivot"
	pelve.position.y = 1.0
	add_child(pelve)
	
	# TRONCO
	var torso = _create_mesh(pelve, CapsuleMesh.new(), Vector3(0, 0.3, 0), materials["torso"])
	torso.mesh.radius = 0.2
	torso.mesh.height = 1.0 # Em Godot, height = height + 2*radius
	
	# COLETE
	var vest = _create_mesh(pelve, CapsuleMesh.new(), Vector3(0, 0.4, 0), materials["vest"])
	vest.mesh.radius = 0.22
	vest.mesh.height = 0.84
	
	# PESCOÇO
	var neck = _create_mesh(pelve, CylinderMesh.new(), Vector3(0, 0.65, 0), materials["skin"])
	neck.mesh.top_radius = 0.06
	neck.mesh.bottom_radius = 0.08
	neck.mesh.height = 0.1
	
	# CABEÇA
	var head_pivot = Node3D.new()
	head_pivot.position.y = 0.15
	neck.add_child(head_pivot)
	pivots["head"] = head_pivot
	
	var head = _create_mesh(head_pivot, CapsuleMesh.new(), Vector3.ZERO, materials["skin"])
	head.mesh.radius = 0.12
	head.mesh.height = 0.39
	
	# OLHOS (Canaã Fidelity) 🏙️🎯🥇
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color.BLACK
	eye_mat.roughness = 0.1
	
	var l_eye = _create_mesh(head, SphereMesh.new(), Vector3(-0.06, 0.05, -0.1), eye_mat)
	l_eye.mesh.radius = 0.02
	l_eye.mesh.height = 0.04
	
	var r_eye = _create_mesh(head, SphereMesh.new(), Vector3(0.06, 0.05, -0.1), eye_mat)
	r_eye.mesh.radius = 0.02
	r_eye.mesh.height = 0.04
	
	# CAPACETE
	var helmet = _create_mesh(head_pivot, CapsuleMesh.new(), Vector3(0, 0.08, 0), materials["helmet"])
	helmet.mesh.radius = 0.13
	helmet.mesh.height = 0.34
	
	# PERNAS
	pivots["l_leg"] = _create_leg(pelve, Vector3(-0.12, 0, 0), materials["vest"], materials["boot"])
	pivots["r_leg"] = _create_leg(pelve, Vector3(0.12, 0, 0), materials["vest"], materials["boot"])
	
	# BRAÇOS
	pivots["l_arm"] = _create_arm(pelve, Vector3(-0.25, 0.75, 0), materials["skin"], materials["vest"])
	pivots["r_arm"] = _create_arm(pelve, Vector3(0.25, 0.75, 0), materials["skin"], materials["vest"])

func _create_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _create_leg(parent: Node3D, pos: Vector3, mat_vest: Material, mat_boot: Material) -> Dictionary:
	var pivot = Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	
	# Coxa
	var coxa = _create_mesh(pivot, CapsuleMesh.new(), Vector3(0, -0.25, 0), mat_vest)
	coxa.mesh.radius = 0.08
	coxa.mesh.height = 0.56
	
	# Canela Pivot & Joelho
	var canela_pivot = Node3D.new()
	canela_pivot.position.y = -0.25
	coxa.add_child(canela_pivot)
	
	var joelho = _create_mesh(canela_pivot, SphereMesh.new(), Vector3.ZERO, mat_boot)
	joelho.mesh.radius = 0.085
	joelho.mesh.height = 0.17
	
	# Canela
	var canela = _create_mesh(canela_pivot, CapsuleMesh.new(), Vector3(0, -0.25, 0), mat_vest)
	canela.mesh.radius = 0.08
	canela.mesh.height = 0.56
	
	# Bota
	var boot = _create_mesh(canela, BoxMesh.new(), Vector3(0, -0.28, -0.05), mat_boot)
	boot.mesh.size = Vector3(0.16, 0.14, 0.28)
	
	return {"hip": pivot, "knee": canela_pivot}

func _create_arm(parent: Node3D, pos: Vector3, mat: Material, mat_joint: Material) -> Dictionary:
	var pivot = Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	
	# Ombro
	var ombro = _create_mesh(pivot, SphereMesh.new(), Vector3.ZERO, mat_joint)
	ombro.mesh.radius = 0.075
	ombro.mesh.height = 0.15
	
	# Biceps
	var biceps = _create_mesh(pivot, CapsuleMesh.new(), Vector3(0, -0.2, 0), mat)
	biceps.mesh.radius = 0.06
	biceps.mesh.height = 0.47
	
	# Cotovelo
	var elbow = Node3D.new()
	elbow.position.y = -0.2
	biceps.add_child(elbow)
	
	var cotovelo_mesh = _create_mesh(elbow, SphereMesh.new(), Vector3.ZERO, mat_joint)
	cotovelo_mesh.mesh.radius = 0.065
	cotovelo_mesh.mesh.height = 0.13
	
	# Antebraço
	var forearm = _create_mesh(elbow, CapsuleMesh.new(), Vector3(0, -0.2, 0), mat)
	forearm.mesh.radius = 0.06
	forearm.mesh.height = 0.47
	
	return {"shoulder": pivot, "elbow": elbow}

func update_animation(speed: float, delta: float):
	if speed > 0.1:
		walk_cycle += delta * speed * 1.5
	else:
		walk_cycle = lerp(walk_cycle, 0.0, 0.1)
		
	# LOGICA EXATA DO CANAÃ PC 🏃‍♂️💨
	var wc = walk_cycle
	var baseCrouch = 0.3
	var baseKnee = -0.6
	var legSwing = sin(wc) * 0.5
	
	if pivots.has("l_leg"):
		pivots["l_leg"].hip.rotation.x = baseCrouch + legSwing
		pivots["l_leg"].knee.rotation.x = baseKnee - abs(cos(wc)) * 0.5
		
	if pivots.has("r_leg"):
		pivots["r_leg"].hip.rotation.x = baseCrouch - legSwing
		pivots["r_leg"].knee.rotation.x = baseKnee - abs(sin(wc)) * 0.5
		
	# Movimento de braços oposto as pernas
	if pivots.has("l_arm"):
		pivots["l_arm"].shoulder.rotation.x = 1.5 + legSwing * 0.8
	if pivots.has("r_arm"):
		pivots["r_arm"].shoulder.rotation.x = 1.5 - legSwing * 0.8
	
	# Balanço de cabeça
	if pivots.has("head"):
		pivots["head"].rotation.y = sin(wc * 0.2) * 0.2
