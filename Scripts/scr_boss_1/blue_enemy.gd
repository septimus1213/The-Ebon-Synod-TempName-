extends CharacterBody2D

var is_hit = false
var hit_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_time = 0.0
var knockback_duration = 0.15

@export var wander_speed = 60.0
@export var detection_range = 150.0
@export var explosion_range = 80.0
@export var explosion_delay = 1.0
@export var explosion_damage = 40
@export var max_health = 210

var player = null
var current_health = 210
var show_healthbar = false
var healthbar_timer = 0.0

var wander_direction = Vector2.ZERO
var wander_timer = 0.0
var wander_time = 2.0

var is_priming = false
var prime_timer = 0.0
var shake_intensity = 0.0
var has_exploded = false

@onready var hurtsound: AudioStreamPlayer2D = $"../SoundsEnemy/EnemyHurt"
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var playersprite: Sprite2D = $Sprite2D
@onready var animations: AnimatedSprite2D = $walking


enum State {
	WANDERING,
	DETECTED,
	PRIMING
}

var current_state = State.WANDERING

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("BLUE ENEMY: No player to explode on")
	randomize_wander_direction()
	print(get_parent().name)

func _physics_process(delta):
	if player == null:
		return
	
	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback_velocity
		move_and_slide()
		return
	
	wander_timer -= delta
	if wander_timer <= 0 and current_state == State.WANDERING:
		randomize_wander_direction()
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	match current_state:
		State.WANDERING:
			velocity = wander_direction * wander_speed
			playanimations(wander_direction)
			move_and_slide()
			if distance_to_player <= detection_range:
				print("BLUE ENEMY: PLAYER DETECTED!")
				current_state = State.DETECTED
		
		State.DETECTED:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * (wander_speed * 1.5)
			playanimations(direction)
			move_and_slide()
			if distance_to_player <= explosion_range:
				current_state = State.PRIMING
				is_priming = true
				prime_timer = explosion_delay
				velocity = Vector2.ZERO
				print("BLUE ENEMY: *beep beep beep*")
			elif distance_to_player > detection_range * 1.5:
				current_state = State.WANDERING
				randomize_wander_direction()
		
		State.PRIMING:
			prime_timer -= delta
			shake_intensity = (explosion_delay - prime_timer) / explosion_delay
			var shake_offset = Vector2(
				randf_range(-shake_intensity * 5, shake_intensity * 5),
				randf_range(-shake_intensity * 5, shake_intensity * 5)
			)
			position += shake_offset
			if prime_timer <= 0:
				if has_exploded == false:
					explode()
				has_exploded = true

func _process(delta):
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
			modulate = Color.WHITE
		queue_redraw()
	
	if show_healthbar:
		healthbar_timer -= delta
		if healthbar_timer <= 0:
			show_healthbar = false
		queue_redraw()

func _draw():
	if not show_healthbar:
		return
	
	var bar_width = 40
	var bar_height = 6
	var bar_offset = Vector2(-bar_width/2, -30)
	
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.RED)
	
	var health_percent = float(current_health) / float(max_health)
	draw_rect(Rect2(bar_offset, Vector2(bar_width * health_percent, bar_height)), Color.GREEN)
	
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.BLACK, false, 1)

func apply_knockback(direction: Vector2, force: float):
	knockback_velocity = direction * force
	knockback_time = knockback_duration

func take_damage(amount):
	current_health -= amount
	current_health = max(0, current_health)
	
	hurtsound.play()
	
	is_hit = true
	hit_timer = 0.1
	modulate = Color.RED
	
	show_healthbar = true
	healthbar_timer = 3.0
	
	if current_health <= 0:
		die()

func die():
	explode()

func explode():
	print("BLUE ENEMY: BOOM!")
	
	explosion.visible = true
	animations.visible = false
	explosion.play("default")
	var distance = global_position.distance_to(player.global_position)
	if distance <= explosion_range:
		print("PLAYER HIT BY EXPLOSION!")
		player.take_damage(explosion_damage)
	

func randomize_wander_direction():
	var angle = randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = wander_time


func _on_explosion_animation_finished() -> void:
	explosion.visible = false
	queue_free()
	
func playanimations(direction):
	var diff = (player.global_position - global_position)
	if diff.length() == 0:
		animations.play("idle")
	elif abs(direction.x) > abs(direction.y):
	# More horizontal
		if direction.x > 0:
			animations.play("run_right")
		else:
			animations.play("run_left")
	else:
	# More vertical
		if direction.y > 0:
			animations.play("run_down")
		else:
			animations.play("run_up")
