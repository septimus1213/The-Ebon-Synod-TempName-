extends CharacterBody2D

@export var DashTimer = 5
@export var speed = 200.0
@export var dashspeed = 3000
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $Walking


var is_dash_ready = true



# set timer length
func _ready() -> void:
	timer.wait_time = DashTimer
	print(animated_sprite_2d)

# walk  left right up down and dash with a timer between dash of x secconds
func _physics_process(_delta):
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	if direction.x < 0:
		animated_sprite_2d.play("WalkLeft")
	elif direction.x > 0:
		animated_sprite_2d.play("WalkRight")
	elif direction.y < 0:
		animated_sprite_2d.play("WalkUp")
	elif direction.y > 0:
		animated_sprite_2d.play("WalkDown")
	else:
		animated_sprite_2d.play("idle")
	
	
	var dash = Input.is_action_just_pressed("dash")
	if dash and direction != Vector2.ZERO and is_dash_ready == true:
		collision_shape_2d.disabled = true
		velocity = direction * dashspeed
		collision_shape_2d.disabled = false
		is_dash_ready = false
		timer.start()
		
	move_and_slide()


# timer for setting dash to true after x secconds
func _on_timer_timeout() -> void:
	is_dash_ready = true
