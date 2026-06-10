extends Node2D

var falling = false
var gravity = 980.0
var velocity_y = 0.0
var _hit = false

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func activate_fall() -> void:
	falling = true

func _physics_process(delta: float) -> void:
	if falling:
		velocity_y += gravity * delta
		position.y += velocity_y * delta

func _on_body_entered(body) -> void:
	if falling and not _hit and body.has_method("take_damage"):
		_hit = true  # only deal damage once
		body.take_damage()
