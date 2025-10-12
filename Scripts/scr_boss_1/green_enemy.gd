extends CharacterBody2D

#values fresh from my ass
@export var wander_speed = 50.0       
@export var chase_speed = 100.0       
@export var detection_range = 128.0   
@export var attack_range = 64.0       
@export var attack_cooldown = 3

var player = null
var can_attack = true
var attack_timer = 0.0

# Wander variables 
var wander_direction = Vector2.ZERO
var wander_timer = 0.0
var wander_time = 2.0  # change direction every 2 seconds

enum State {
	WANDERING,
	CHASING,
	ATTACKING
}

var current_state = State.WANDERING

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("GREEN ENEMY: No player? Guess I'll just wander forever...")
	
	# Pick random starting wander direction
	randomize_wander_direction()

func _physics_process(delta):
	if player == null:
		return
	
	# Update timers
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
			
			# Spot the player
			if distance_to_player <= detection_range:
				current_state = State.CHASING
		
		State.CHASING:
			# Move toward player
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * chase_speed
			move_and_slide()
			
			
			if distance_to_player <= attack_range and can_attack:
				current_state = State.ATTACKING
				attack()
			elif distance_to_player > detection_range * 1.5:  # lost the player, go back to wandering
				current_state = State.WANDERING
				randomize_wander_direction()
		
		State.ATTACKING:
			# Stand still while swinging (could add lunge later)
			velocity = Vector2.ZERO
			
			# After attack, go back to chasing
			if can_attack:  # cooldown finished
				current_state = State.CHASING

func attack():
	print("GREEN ENEMY SWINGS SWORD!")
	can_attack = false
	attack_timer = attack_cooldown
	
	# Check if we actually hit
	var distance = global_position.distance_to(player.global_position)
	if distance <= attack_range:
		print("SWORD HIT!")
		player.take_damage(100)  # when we have health

func randomize_wander_direction():
	# Pick a random direction to walk
	var angle = randf() * TAU  # TAU = 2*PI = full circle
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = wander_time
