extends CharacterBody2D

@export var speed = 300.0
@export var dashspeed = 5000

func _physics_process(delta):
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	
	var dash = Input.is_action_just_pressed("dash")
	if dash and direction != Vector2.ZERO:
		velocity = direction * dashspeed
		
	move_and_slide()
