extends CharacterBody2D

const SPEED = 150.0

var direction        = 1
var patrol_left      = 0.0
var patrol_right     = 0.0
var _damage_cooldown = 0.0

@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var sprite      : Sprite2D        = $BossMobs

func _ready() -> void:
	anim_player.play("run")
	patrol_left  = global_position.x - 250.0
	patrol_right = global_position.x + 250.0
	var hurt_area = get_node_or_null("HurtArea")
	if hurt_area:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

func set_patrol_marks(left_x: float, right_x: float) -> void:
	patrol_left  = min(left_x, right_x)
	patrol_right = max(left_x, right_x)
	global_position.x = patrol_left
	direction = 1

func _process(delta: float) -> void:
	global_position.x += direction * SPEED * delta

	if global_position.x >= patrol_right:
		global_position.x = patrol_right
		direction = -1
	elif global_position.x <= patrol_left:
		global_position.x = patrol_left
		direction = 1

	sprite.flip_h = direction < 0

func _physics_process(delta: float) -> void:
	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta

func _on_hurt_area_body_entered(body) -> void:
	if _damage_cooldown > 0.0:
		return
	if body.has_method("take_damage"):
		body.take_damage()
		_damage_cooldown = 1.0
