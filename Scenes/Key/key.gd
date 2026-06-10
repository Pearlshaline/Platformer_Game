extends CharacterBody2D

var collected = false

func collect() -> void:
	collected = true
	visible = false
	# Disable ALL collision shapes on the key itself and its area
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		if child is Area2D:
			for grandchild in child.get_children():
				if grandchild is CollisionShape2D:
					grandchild.set_deferred("disabled", true)
	set_physics_process(false)
