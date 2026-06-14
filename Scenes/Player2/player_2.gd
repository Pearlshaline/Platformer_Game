extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

const JUMP_SFX    = preload("uid://b3cb4attrb18h")
const DAMAGE_SFX  = preload("uid://bnn4hd3nbmio6")
const PICKUP_SFX  = preload("uid://cebj23nx8uaca")

var level_cleared = false
var hearts = 3
var invincible = false
var invincible_timer = 0.0
const INVINCIBLE_DURATION = 1.2

@onready var player_sprite: Sprite2D = $Player
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var heart1: Sprite2D = $PixelHeart2
@onready var heart2: Sprite2D = $PixelHeart3
@onready var heart3: Sprite2D = $PixelHeart4

# Audio players
var _sfx_jump   : AudioStreamPlayer
var _sfx_damage : AudioStreamPlayer
var _sfx_pickup : AudioStreamPlayer

func _ready() -> void:
	player_sprite.modulate = Color(1, 1, 1, 1)
	update_hearts()
	_sfx_jump   = _make_sfx(JUMP_SFX)
	_sfx_damage = _make_sfx(DAMAGE_SFX)
	_sfx_pickup = _make_sfx(PICKUP_SFX)

func _make_sfx(stream) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func _physics_process(delta: float) -> void:
	if level_cleared:
		velocity = Vector2.ZERO
		return

	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
			player_sprite.modulate = Color(1, 1, 1, 1)

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("mv_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_sfx_jump.play()

	var direction := Input.get_axis("mv_left", "mv_right")
	velocity.x = direction * SPEED

	if direction != 0:
		player_sprite.flip_h = direction < 0

	if invincible:
		if anim_player.current_animation != "touch":
			anim_player.play("touch")
	elif not is_on_floor():
		if velocity.y < 0:
			anim_player.play("jump")
		else:
			anim_player.play("fall")
	elif direction != 0:
		anim_player.play("run")
	else:
		anim_player.play("idle")

	move_and_slide()

func take_damage() -> void:
	if invincible or level_cleared:
		return
	hearts -= 1
	invincible = true
	invincible_timer = INVINCIBLE_DURATION
	player_sprite.modulate = Color(1, 1, 1, 1)
	anim_player.play("touch")
	_sfx_damage.play()
	update_hearts()
	if hearts <= 0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	level_cleared = true
	velocity = Vector2.ZERO
	player_sprite.modulate = Color(1, 1, 1, 1)
	var level = get_tree().current_scene
	if level and level.has_method("show_game_over"):
		level.show_game_over()

func update_hearts() -> void:
	heart1.visible = hearts >= 1
	heart2.visible = hearts >= 2
	heart3.visible = hearts >= 3

func add_heart() -> void:
	if hearts < 3:
		hearts += 1
		update_hearts()
