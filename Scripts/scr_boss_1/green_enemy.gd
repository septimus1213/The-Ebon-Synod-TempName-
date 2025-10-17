extends CharacterBody2D

var is_hit = false
var hit_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_time = 0.0
var knockback_duration = 0.15

@export var wander_speed = 50.0
@export var chase_speed = 100.0
@export var detection_range = 128.0
@export var attack_range = 30.0
@export var attack_cooldown = 3
@export var max_health = 500

var current_health = 500
var show_healthbar = false
var healthbar_timer = 0.0
var player = null
var can_attack = true
var attack_timer = 0.0

var wander_direction = Vector2.ZERO
var wander_timer = 0.0
var wander_time = 2.0

@onready var hurtsound: AudioStreamPlayer2D = $"../SoundsEnemy/EnemyHurt"
@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
enum State {
	WANDERING,
	CHASING,
	ATTACKING
}

var current_state = State.WANDERING

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("GREEN ENEMY: No player?")
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
	
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	wander_timer -= delta
	if wander_timer <= 0 and current_state == State.WANDERING:
		randomize_wander_direction()
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	match current_state:
		State.WANDERING:
			velocity = wander_direction * wander_speed
			move_and_slide()
			if distance_to_player <= detection_range:
				current_state = State.CHASING
			elif wander_direction == Vector2.ZERO:
				animations.play("idle")
			elif abs(wander_direction.x) > abs(wander_direction.y):
			# More horizontal
				if wander_direction.x > 0:
					animations.play("run_right")
				else:
					animations.play("run_left")
			else:
			# More vertical
				if wander_direction.y > 0:
					animations.play("run_down")
				else:
					animations.play("run_up")
		
		State.CHASING:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * chase_speed
			move_and_slide()
			if distance_to_player <= attack_range and can_attack:
				current_state = State.ATTACKING
				attack()
			elif distance_to_player > detection_range * 1.5:
				current_state = State.WANDERING
				randomize_wander_direction()
			
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
			
		State.ATTACKING:
			velocity = Vector2.ZERO
			if can_attack:
				current_state = State.CHASING

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
	queue_free()

func attack():
	print("GREEN ENEMY SWINGS SWORD!")
	can_attack = false
	attack_timer = attack_cooldown
	
	var distance = global_position.distance_to(player.global_position)
	if distance <= attack_range:
		print("SWORD HIT!")
		player.take_damage(10)

func randomize_wander_direction():
	var angle = randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = wander_time
