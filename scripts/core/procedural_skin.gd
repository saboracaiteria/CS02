extends Node3D

# --- SISTEMA DE SKIN PROCEDURAL V4 (Canaã Port) 🏙️🎯🥇 ---
# Tradução direta da lógica WebGL para Godot 4.

var walk_cycle: float = 0.0
var pivots: Dictionary = {}
var bot_material: StandardMaterial3D

func setup(color: Color = Color.ORANGE):
	# Limpa qualquer resíduo
	for child in get_children():
		child.queue_free()
		
	bot_material = StandardMaterial3D.new()
	bot_material.albedo_color = color
	bot_material.roughness = 0.5
	
	# TRONCO (Cápsula Central)
	var torso = MeshInstance3D.new()
	torso.mesh = CapsuleMesh.new()
	torso.mesh.radius = 0.25
	torso.mesh.height = 0.8
	torso.material_override = bot_material
	torso.position.y = 1.1
	add_child(torso)
	
	# CABEÇA
	var head = MeshInstance3D.new()
	head.mesh = CapsuleMesh.new()
	head.mesh.radius = 0.15
	head.mesh.height = 0.4
	head.material_override = bot_material
	head.position.y = 0.6
	torso.add_child(head)
	
	# PERNAS
	pivots["l_leg"] = _create_leg(torso, Vector3(-0.15, -0.4, 0))
	pivots["r_leg"] = _create_leg(torso, Vector3(0.15, -0.4, 0))
	
	# BRAÇOS
	pivots["l_arm"] = _create_arm(torso, Vector3(-0.3, 0.2, 0))
	pivots["r_arm"] = _create_arm(torso, Vector3(0.3, 0.2, 0))

func _create_leg(parent: Node3D, pos: Vector3) -> Dictionary:
	var pivot = Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	
	# Coxa
	var coxa = MeshInstance3D.new()
	coxa.mesh = CapsuleMesh.new()
	coxa.mesh.radius = 0.1
	coxa.mesh.height = 0.4
	coxa.material_override = bot_material
	coxa.position.y = -0.2
	pivot.add_child(coxa)
	
	# Joelho
	var joelho = Node3D.new()
	joelho.position.y = -0.2
	coxa.add_child(joelho)
	
	# Canela
	var canela = MeshInstance3D.new()
	canela.mesh = CapsuleMesh.new()
	canela.mesh.radius = 0.08
	canela.mesh.height = 0.4
	canela.material_override = bot_material
	canela.position.y = -0.2
	joelho.add_child(canela)
	
	return {"hip": pivot, "knee": joelho}

func _create_arm(parent: Node3D, pos: Vector3) -> Dictionary:
	var pivot = Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	
	var arm = MeshInstance3D.new()
	arm.mesh = CapsuleMesh.new()
	arm.mesh.radius = 0.08
	arm.mesh.height = 0.6
	arm.material_override = bot_material
	arm.position.y = -0.3
	pivot.add_child(arm)
	
	return {"shoulder": pivot}

func update_animation(speed: float, delta: float):
	if speed > 0.1:
		walk_cycle += delta * speed * 1.5
	else:
		walk_cycle = lerp(walk_cycle, 0.0, 0.1)
		
	var swing = sin(walk_cycle) * 0.6
	var lift = abs(cos(walk_cycle)) * 0.4
	
	# Aplicando rotações nos pivôs (Estilo Canaã) 🏃‍♂️💨
	if pivots.has("l_leg"):
		pivots["l_leg"].hip.rotation.x = swing
		pivots["l_leg"].knee.rotation.x = -lift # Dobra o joelho ao levantar
		
	if pivots.has("r_leg"):
		pivots["r_leg"].hip.rotation.x = -swing
		pivots["r_leg"].knee.rotation.x = -abs(sin(walk_cycle)) * 0.4
		
	if pivots.has("l_arm"):
		pivots["l_arm"].shoulder.rotation.x = -swing * 0.8
		
	if pivots.has("r_arm"):
		pivots["r_arm"].shoulder.rotation.x = swing * 0.8
	
	# Leve balanço do corpo 🕺
	rotation.z = sin(walk_cycle * 0.5) * 0.05
