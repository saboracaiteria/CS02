extends CanvasLayer

func _ready():
	# Force visibility and ensure it's on top
	visible = true
	layer = 10 
	
	# Only show if we are on mobile OR we want to test
	# But for now, let's just make sure they appear
	print("Touch Controls Initialized")
