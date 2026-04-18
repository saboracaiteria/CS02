extends Node3D

# Script para gerar um Calango 3D e exportar como .glb na Godot 4.3
# Para usar: Anexe este script a um Node3D e rode a cena, ou use 'Run Script' no Editor.

func _ready() -> void:
	generate_and_export()

func generate_and_export() -> void:
	print("Iniciando geração do Calango 3D...")
	
	# Criar o contêiner do modelo
	var calango_root = Node3D.new()
	calango_root.name = "Calango3D"
	add_child(calango_root)
	
	# Criar Materiais
	var material_main = StandardMaterial3D.new()
	material_main.albedo_color = Color("#22c55e") # Verde Calango
	material_main.roughness = 0.5
	
	var material_dark = StandardMaterial3D.new()
	material_dark.albedo_color = Color("#166534") # Verde Escuro
	
	# 1. CORPO
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.mesh.radius = 0.4
	body.mesh.height = 1.2
	body.rotation_degrees = Vector3(0, 0, 90)
	body.material_override = material_main
	calango_root.add_child(body)
	body.owner = calango_root
	
	# 2. CABEÇA
	var head = MeshInstance3D.new()
	head.mesh = SphereMesh.new()
	head.mesh.radius = 0.35
	head.position = Vector3(0.7, 0.3, 0)
	head.material_override = material_main
	calango_root.add_child(head)
	head.owner = calango_root
	
	# 3. CAUDA
	var tail = MeshInstance3D.new()
	tail.mesh = CylinderMesh.new()
	tail.mesh.top_radius = 0.05
	tail.mesh.bottom_radius = 0.3
	tail.mesh.height = 1.0
	tail.position = Vector3(-1.0, 0, 0)
	tail.rotation_degrees = Vector3(0, 0, 70)
	tail.material_override = material_dark
	calango_root.add_child(tail)
	tail.owner = calango_root

	# 4. OLHOS
	var eye_l = MeshInstance3D.new()
	eye_l.mesh = SphereMesh.new()
	eye_l.mesh.radius = 0.08
	eye_l.position = Vector3(0.85, 0.45, 0.2)
	eye_l.material_override = StandardMaterial3D.new()
	eye_l.material_override.albedo_color = Color.BLACK
	calango_root.add_child(eye_l)
	eye_l.owner = calango_root
	
	# EXPORTAR PARA GLB
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	gltf_doc.append_from_scene(calango_root, gltf_state)
	
	var path = "res://calango_realista.glb"
	var err = gltf_doc.write_to_filesystem(gltf_state, path)
	
	if err == OK:
		print("SUCESSO! Calango exportado para: ", path)
	else:
		print("ERRO ao exportar: ", err)
	
	get_tree().quit()
