extends Button

func _pressed() -> void:
	Global.is_editing_hud = !Global.is_editing_hud
	if Global.is_editing_hud:
		text = "SALVAR HUD (EDITANDO...)"
		modulate = Color(1, 0.5, 0)
		# Tenta pegar a referência principal para fechar o menu temporariamente
		var world_node = get_tree().root.get_node_or_null("World")
		if world_node:
			world_node.get_node("Menu/Options").hide()
			world_node.get_node("Menu/Blur").hide()
			# Deixa o jogo pausado para poder editar com segurança no Pause!
			# Apenas escondemos os painéis.
	else:
		text = "EDIT HUD (MOBILE)"
		modulate = Color(1, 1, 1)
