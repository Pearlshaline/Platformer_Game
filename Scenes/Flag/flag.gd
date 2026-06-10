extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not (body is CharacterBody2D and body.has_method("take_damage")):
		return
	if body.level_cleared:
		return

	# Need all 3 keys collected
	var collected = 0
	for key in get_tree().get_nodes_in_group("keys"):
		if key.collected:
			collected += 1

	if collected < 3:
		return

	body.level_cleared = true

	var level = get_tree().current_scene
	if level and level.has_method("show_completion"):
		level.show_completion()

	get_tree().paused = true
