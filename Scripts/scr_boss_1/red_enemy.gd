extends CharacterBody2D

# The angry red boy. His only purpose: run at player and bonk
@export var chase_speed = 100.0  # faster than player? slower?
@export var length_to_do_damage = 30
@export var damage = 30

var player = null  # we'll find the player in _ready, hopefully they exist
var able_to_do_damage = true

@onready var damage_timer: Timer = $DamageTimer

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		print("RED ENEMY CAN'T FIND PLAYER!")
	else:
		print("RED ENEMY FOUND PLAYER AT: ", player.global_position)

func _physics_process(delta):
	if player == null:
		return  
	
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	
	
	move_and_slide()
	
	# TODO: deal damage on contact (when we have health system)
	# TODO: die when hit by player (when player can attack)
	# TODO: leave corpse when dead (for feast mechanic)

func _process(delta: float) -> void:
	var length = (player.global_position - global_position).length()
	if length <= length_to_do_damage and able_to_do_damage == true:
		player.take_damage(damage)
		able_to_do_damage = false
		damage_timer.start()

# Placeholder damage function for later
# func take_damage(amount):
# 	print("OW!")
# 	# queue_free()  # uncomment when we want them to actually die


func _on_damage_timer_timeout() -> void:
	able_to_do_damage = true
	
