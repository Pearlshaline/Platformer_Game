extends Node2D

# ── Key tracking ─────────────────────────────────────────────────────────────
var keys_collected      = 0
const TOTAL_KEYS        = 3
var first_key_triggered = false
var heart_available     = true
var game_running        = true

# ── Timer / best time ────────────────────────────────────────────────────────
var elapsed_time    = 0.0
const BEST_TIME_KEY = "best_completion_time"

# ── Sound ─────────────────────────────────────────────────────────────────────
const PICKUP_SFX = preload("uid://cebj23nx8uaca")
var _sfx_pickup : AudioStreamPlayer

# ── World node refs ───────────────────────────────────────────────────────────
@onready var spike_ball  = $SpikeBall
@onready var pixel_heart = $PixelHeart2

@onready var _world_label = $Label
@onready var _world_panel = $GameOverPanel

# ── CanvasLayer HUD ───────────────────────────────────────────────────────────
var _canvas           : CanvasLayer
var key_label         : Label
var timer_label       : Label
var game_over_panel   : ColorRect
var go_label          : Label
var final_score_label : Label
var high_score_label  : Label
var restart_hint      : Label
var _restart_listener : Node


# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_world_label.visible = false
	_world_panel.visible = false

	# Pickup sound player
	_sfx_pickup = AudioStreamPlayer.new()
	_sfx_pickup.stream = PICKUP_SFX
	add_child(_sfx_pickup)

	var player = get_node_or_null("Player2")
	if player:
		player.add_to_group("player")

	_connect_key(get_node_or_null("Key"),  1)
	_connect_key(get_node_or_null("Key2"), 2)
	_connect_key(get_node_or_null("Key3"), 3)

	_build_hud()

	# Wire boss patrol marks
	var boss = get_node_or_null("Boss")
	if boss:
		var lm = get_node_or_null("LeftMarkforBoss")
		var rm = get_node_or_null("RightMarkforBoss")
		if lm and rm and boss.has_method("set_patrol_marks"):
			boss.set_patrol_marks(lm.global_position.x, rm.global_position.x)

	# Wire eagle patrol marks
	var eagle = get_node_or_null("Eagle")
	if eagle:
		var lm = get_node_or_null("LeftMarkforEagle")
		var rm = get_node_or_null("RightMarkforEagle")
		if lm and rm and eagle.has_method("set_patrol_marks"):
			eagle.set_patrol_marks(lm.global_position.x, rm.global_position.x)

	# Heart pickup via Area2D
	if pixel_heart:
		var heart_area = pixel_heart.get_node_or_null("Area2D")
		if heart_area:
			heart_area.body_entered.connect(_on_heart_body_entered)


# ─────────────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)

	key_label = Label.new()
	key_label.text = "Keys: 0 / 3"
	key_label.add_theme_font_size_override("font_size", 26)
	key_label.add_theme_color_override("font_color", Color.WHITE)
	key_label.position = Vector2(16, 12)
	_canvas.add_child(key_label)

	timer_label = Label.new()
	timer_label.text = "Time: 0.0s"
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.position = Vector2(16, 48)
	_canvas.add_child(timer_label)

	const PANEL_W = 400.0
	const PANEL_H = 240.0
	const PANEL_X = 280.0
	const PANEL_Y = 150.0

	game_over_panel = ColorRect.new()
	game_over_panel.color    = Color(0.08, 0.08, 0.12, 0.92)
	game_over_panel.size     = Vector2(PANEL_W, PANEL_H)
	game_over_panel.position = Vector2(PANEL_X, PANEL_Y)
	game_over_panel.visible  = false
	_canvas.add_child(game_over_panel)

	go_label = Label.new()
	go_label.text = "GAME OVER"
	go_label.add_theme_font_size_override("font_size", 36)
	go_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	go_label.size                    = Vector2(PANEL_W, 50)
	go_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	go_label.position                = Vector2(0, 20)
	game_over_panel.add_child(go_label)

	final_score_label = Label.new()
	final_score_label.text = "Your Time: --"
	final_score_label.add_theme_font_size_override("font_size", 24)
	final_score_label.add_theme_color_override("font_color", Color.WHITE)
	final_score_label.size                 = Vector2(PANEL_W, 36)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score_label.position             = Vector2(0, 88)
	game_over_panel.add_child(final_score_label)

	high_score_label = Label.new()
	high_score_label.text = "Best Time: --"
	high_score_label.add_theme_font_size_override("font_size", 24)
	high_score_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	high_score_label.size                 = Vector2(PANEL_W, 36)
	high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	high_score_label.position             = Vector2(0, 130)
	game_over_panel.add_child(high_score_label)

	restart_hint = Label.new()
	restart_hint.text = "Press  R  to Restart"
	restart_hint.add_theme_font_size_override("font_size", 20)
	restart_hint.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	restart_hint.size                 = Vector2(PANEL_W, 30)
	restart_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_hint.position             = Vector2(0, 195)
	game_over_panel.add_child(restart_hint)

	_restart_listener = Node.new()
	_restart_listener.set_script(_make_restart_script())
	_restart_listener.process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_listener.set_meta("level", self)
	add_child(_restart_listener)


func _make_restart_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """extends Node
func _process(_delta):
	if not get_meta("level").game_running:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			get_meta("level")._on_restart_pressed()
"""
	s.reload()
	return s


# ─────────────────────────────────────────────────────────────────────────────
func _connect_key(key_node, key_number: int) -> void:
	if not key_node:
		return
	key_node.add_to_group("keys")
	var area = key_node.get_node_or_null("Area2D")
	if area:
		area.body_entered.connect(_on_key_picked_up.bind(key_node, key_number))


func _on_key_picked_up(body, key_node, key_number: int) -> void:
	if key_node.collected:
		return
	if not body.has_method("take_damage"):
		return
	key_node.collect()
	keys_collected += 1
	_update_key_label()
	# Play pickup sound on key collect
	_sfx_pickup.play()

	if key_number == 1 and not first_key_triggered:
		first_key_triggered = true
		if spike_ball and spike_ball.has_method("activate_fall"):
			spike_ball.activate_fall()


# ─────────────────────────────────────────────────────────────────────────────
func _on_heart_body_entered(body) -> void:
	_try_give_heart(body)


func _try_give_heart(body) -> void:
	if not heart_available:
		return
	if not (pixel_heart and pixel_heart.visible):
		return
	if not body.has_method("add_heart"):
		return

	# Always collect the heart and play sound — even if hearts are full
	heart_available = false
	pixel_heart.visible = false
	var ha = pixel_heart.get_node_or_null("Area2D")
	if ha:
		for c in ha.get_children():
			if c is CollisionShape2D:
				c.set_deferred("disabled", true)

	_sfx_pickup.play()
	# add_heart() in player handles the full-heart check — won't exceed 3
	body.add_heart()


# ─────────────────────────────────────────────────────────────────────────────
func _update_key_label() -> void:
	if key_label:
		key_label.text = "Keys: %d / 3" % keys_collected


# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not game_running:
		return

	elapsed_time += delta
	if timer_label:
		timer_label.text = "Time: %.1fs" % elapsed_time

	# Proximity fallback heart pickup
	if heart_available and pixel_heart and pixel_heart.visible:
		var player = get_node_or_null("Player2")
		if player and player.global_position.distance_to(pixel_heart.global_position) < 36.0:
			_try_give_heart(player)


# ─────────────────────────────────────────────────────────────────────────────
func show_completion() -> void:
	game_running = false
	_save_best_time(elapsed_time)

	var best = _load_best_time()

	go_label.text = "LEVEL COMPLETE!"
	go_label.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
	final_score_label.text = "Your Time: %.1fs" % elapsed_time
	high_score_label.text  = "Best Time: %.1fs" % best if best > 0.0 else "Best Time: --"
	restart_hint.text      = "Press  R  to Play Again"

	game_over_panel.visible = true
	get_tree().paused = true


func show_game_over() -> void:
	game_running = false

	var best = _load_best_time()

	go_label.text = "GAME OVER"
	go_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	final_score_label.text = "Your Time: %.1fs" % elapsed_time
	high_score_label.text  = "Best Time: %.1fs" % best if best > 0.0 else "Best Time: --"
	restart_hint.text      = "Press  R  to Restart"

	game_over_panel.visible = true
	get_tree().paused = true


# ─────────────────────────────────────────────────────────────────────────────
func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# ─────────────────────────────────────────────────────────────────────────────
func _save_best_time(time: float) -> void:
	var config = ConfigFile.new()
	var err    = config.load("user://save.cfg")
	var current_best = 0.0
	if err == OK:
		current_best = config.get_value("times", BEST_TIME_KEY, 0.0)
	if current_best <= 0.0 or time < current_best:
		config.set_value("times", BEST_TIME_KEY, time)
		config.save("user://save.cfg")


func _load_best_time() -> float:
	var config = ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		return config.get_value("times", BEST_TIME_KEY, 0.0)
	return 0.0
