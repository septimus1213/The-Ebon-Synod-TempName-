extends CharacterBody2D

@export var chase_speed = 100.0
@export var contact_damage = 30
@export var contact_range = 30
@export var damage_cooldown = 1.0
@export var max_health = 50

var player = null
var able_to_do_damage = true
var current_health = 50
var show_healthbar = false
var healthbar_timer = 0.0

@onready var damage_timer: Timer = $DamageTimer

func _ready():
	current_health = max_health
	damage_timer.wait_time = damage_cooldown
	
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("RED ENEMY CAN'T FIND PLAYER!")

func _physics_process(delta):
	if player == null:
		return
	
	# Chase player aggressively
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()
	
	# Deal contact damage
	var distance = global_position.distance_to(player.global_position)
	if distance <= contact_range and able_to_do_damage:
		player.take_damage(contact_damage)
		print("RED ENEMY BONKED PLAYER!")
		able_to_do_damage = false
		damage_timer.start()

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
	
	# Draw healthbar above enemy
	var bar_width = 40
	var bar_height = 6
	var bar_offset = Vector2(-bar_width/2, -30)
	
	# Background (red)
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.RED)
	
	# Foreground (green) - scales with health
	var health_percent = float(current_health) / float(max_health)
	draw_rect(Rect2(bar_offset, Vector2(bar_width * health_percent, bar_height)), Color.GREEN)
	
	# Border (black)
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.BLACK, false, 1)

func take_damage(amount):
	current_health -= amount
	current_health = max(0, current_health)
	
	# Show healthbar for 3 seconds
	show_healthbar = true
	healthbar_timer = 3.0
	
	print("RED ENEMY took ", amount, " damage! HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die():
	print("RED ENEMY died!")
	queue_free()  # TODO: spawn corpse

func _on_damage_timer_timeout():
	able_to_do_damage = true
