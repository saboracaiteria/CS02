extends Button

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	visible = Global.is_editing_hud

func _pressed() -> void:
	Global.is_editing_hud = false
	var world_node = get_tree().root.get_node_or_null("World")
	if world_node:
		var opts = world_node.get_node_or_null("Menu/Options")
		if opts:
			opts.show()
			world_node.get_node("Menu/Blur").show()
		
		# Restaura botões
		var edits = opts.find_child("EditHUDButton", true)
		if edits:
			edits.text = "EDIT HUD (MOBILE)"
			edits.modulate = Color(1, 1, 1)
