extends CharacterBody2D

@export var DashTimer = 5
@export var speed = 300.0
@export var dashspeed = 5000
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D = $"../Player"
@onready var player_with_sword: CharacterBody2D = $"."
@onready var sword_ground: Area2D = $"../Sword_Ground"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sword_In_Hand/Sprite2D

# setting dash
var is_dash_ready = true


# dash timer
func _ready() -> void:
	timer.wait_time = DashTimer
	sprite_2d.position.x = 11
	sprite_2d.position.y = -1
	sprite_2d.rotation = 0

# move left down right up and dash
func _physics_process(_delta):
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	
	
	var dash = Input.is_action_just_pressed("dash")
	if dash and direction != Vector2.ZERO and is_dash_ready == true:
		collision_shape_2d.disabled = true
		velocity = direction * dashspeed
		collision_shape_2d.disabled = false
		is_dash_ready = false
		timer.start()
		
		
	move_and_slide()

# drop item/sword
func _process(_delta: float) -> void:
	var drop = Input.is_action_just_pressed("Drop_Item")
	if drop:
		
		# add normal player back
		player.position = player_with_sword.global_position
		player.visible = true
		
		# add sword back on the ground
		sword_ground.position = player_with_sword.global_position
		sword_ground.visible = true
		
		# delete player with sword
		player_with_sword.visible = false
		
	var attack = Input.is_action_just_pressed("Attack")
	if attack and player_with_sword.visible == true:
		animation_player.play("Attack")
		
		


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	sprite_2d.position.x = 11
	sprite_2d.position.y = -1
	sprite_2d.rotation = 0
