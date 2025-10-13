extends CharacterBody2D

var is_hit = false
var hit_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_time = 0.0
var knockback_duration = 0.15

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
	
	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback_velocity
		move_and_slide()
		return
	

	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()
	
	var distance = global_position.distance_to(player.global_position)
	if distance <= contact_range and able_to_do_damage:
		player.take_damage(contact_damage)
		print("RED ENEMY BONKED PLAYER!")
		able_to_do_damage = false
		damage_timer.start()

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
	
	is_hit = true
	hit_timer = 0.1
	modulate = Color.RED
	
	show_healthbar = true
	healthbar_timer = 3.0
	
	if current_health <= 0:
		die()

func die():
	print("RED ENEMY died!")
	queue_free()

func _on_damage_timer_timeout():
	able_to_do_damage = true
