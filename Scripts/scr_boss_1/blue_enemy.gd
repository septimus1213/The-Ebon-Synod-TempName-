extends CharacterBody2D

@export var wander_speed = 60.0
@export var detection_range = 150.0    
@export var explosion_range = 80.0     
@export var explosion_delay = 1.0
@export var explosion_damage = 75
@export var max_health = 30  

var player = null
var current_health = 30
var show_healthbar = false
var healthbar_timer = 0.0

# Wander variables
var wander_direction = Vector2.ZERO
var wander_timer = 0.0
var wander_time = 2.0

# Explosion variables
var is_priming = false
var prime_timer = 0.0
var shake_intensity = 0.0

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

func _physics_process(delta):
	if player == null:
		return
	
	wander_timer -= delta
	if wander_timer <= 0 and current_state == State.WANDERING:
		randomize_wander_direction()
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	match current_state:
		State.WANDERING:
			velocity = wander_direction * wander_speed
			move_and_slide()
			
			if distance_to_player <= detection_range:
				print("BLUE ENEMY: PLAYER DETECTED!")
				current_state = State.DETECTED
		
		State.DETECTED:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * (wander_speed * 1.5)
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
			
			# Jiggle of death
			var shake_offset = Vector2(
				randf_range(-shake_intensity * 5, shake_intensity * 5),
				randf_range(-shake_intensity * 5, shake_intensity * 5)
			)
			position += shake_offset
			
			if prime_timer <= 0:
				explode()

func _process(delta):
	# Healthbar visibility timer
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
	
	# Background (red)
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.RED)
	
	# Foreground (green)
	var health_percent = float(current_health) / float(max_health)
	draw_rect(Rect2(bar_offset, Vector2(bar_width * health_percent, bar_height)), Color.GREEN)
	
	# Border (black)
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.BLACK, false, 1)

func take_damage(amount):
	current_health -= amount
	current_health = max(0, current_health)
	
	show_healthbar = true
	healthbar_timer = 3.0
	
	if current_health <= 0:
		die()

func die():
	# Still explode on death (maybe smaller explosion?)
	explode()

func explode():
	print("BLUE ENEMY: BOOM!")
	
	# Check if player in explosion radius
	var distance = global_position.distance_to(player.global_position)
	if distance <= explosion_range:
		print("PLAYER HIT BY EXPLOSION!")
		player.take_damage(explosion_damage)
	
	# TODO: spawn explosion particle effect here
	
	queue_free()

func randomize_wander_direction():
	var angle = randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = wander_time
