extends CharacterBody2D

# yep
@export var wander_speed = 60.0
@export var detection_range = 150.0    
@export var explosion_range = 80.0     
@export var explosion_delay = 1.0      

var player = null


var wander_direction = Vector2.ZERO
var wander_timer = 0.0
var wander_time = 2.0


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
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("BLUE ENEMY: No player to explode on? What's the point of existing?")
	
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
			
			# Detect player
			if distance_to_player <= detection_range:
				print("BLUE ENEMY: I SENSE PLAYER... MUST EXPLODE")
				current_state = State.DETECTED
		
		State.DETECTED:
			
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * (wander_speed * 1.5)  
			move_and_slide()
			
			
			if distance_to_player <= explosion_range:
				current_state = State.PRIMING
				is_priming = true
				prime_timer = explosion_delay
				velocity = Vector2.ZERO  # STOP
				print("BLUE ENEMY: *beep beep beep*")
			elif distance_to_player > detection_range * 1.5:
				
				current_state = State.WANDERING
				randomize_wander_direction()
		
		State.PRIMING:
			
			prime_timer -= delta
			shake_intensity = (explosion_delay - prime_timer) / explosion_delay  # ramps up
			
			# Shake effect (offset position slightly)
			var shake_offset = Vector2(
				randf_range(-shake_intensity * 5, shake_intensity * 5),
				randf_range(-shake_intensity * 5, shake_intensity * 5)
			)
			position += shake_offset
			
			
			if prime_timer <= 0:
				explode()

func explode():
	print("BLUE ENEMY: ALLAHU AKBAR!")
	
	# TODO: spawn explosion effect/particles
	# TODO: deal AOE damage to player if in range
	# TODO: damage other enemies too? 
	
	# Check if player is in explosion radius
	var distance = global_position.distance_to(player.global_position)
	if distance <= explosion_range:
		print("PLAYER HIT BY EXPLOSION! (no damage system yet)")
		# player.take_damage(25)  # big damage
	
	# Commit sudoku 
	queue_free()

func randomize_wander_direction():
	var angle = randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = wander_time
