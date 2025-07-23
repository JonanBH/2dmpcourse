extends CharacterBody2D


func _process(delta: float) -> void:
	var movement_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	
	velocity = movement_vector * 100
	move_and_slide()
