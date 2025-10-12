extends CharacterBody2D

@export var projectilespeed = 600
@export var DashTimer = 5
@export var speed = 300.0
@export var dashspeed = 5000
@export var arrowdespawntimer = 5
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var player: CharacterBody2D = $"../Player"
@onready var bow: Area2D = $Bow
@onready var player_with_bow: CharacterBody2D = $"."
@onready var sprite_2d: Sprite2D = $Bow/Sprite2D
@onready var timer: Timer = $Dashtimer
@onready var bow_ground: Area2D = $"../bow_ground"



var arrow = preload("res://Scenes/PrefabScenes/arrow.tscn")

# setting dash
var is_dash_ready = true


# dash timer
func _ready() -> void:
	timer.wait_time = DashTimer
	

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
	


func _process(delta: float) -> void:
	# change bow rotation to face the mouse
	var mouse_pos = get_global_mouse_position()
	var player_pos = player_with_bow.global_position
	var angle_in_radians = atan2(mouse_pos.y - player_pos.y, mouse_pos.x - player_pos.x)
	sprite_2d.rotation = angle_in_radians

	var shoot = Input.is_action_just_pressed("Attack")
	if shoot and player_with_bow.visible == true:
		var arrow_instance = arrow.instantiate()
		get_parent().add_child(arrow_instance)
		
		arrow_instance.global_position = player_pos
		arrow_instance.rotation = angle_in_radians
		arrow_instance.direction = Vector2(cos(angle_in_radians), sin(angle_in_radians))
	
	var drop = Input.is_action_just_pressed("Drop_Item")
	if drop and player_with_bow.visible == true:
		
		# add normal player back
		player.position = player_with_bow.global_position
		player.visible = true
		
		# add sword back on the ground
		bow_ground.position = player_with_bow.global_position
		bow_ground.visible = true
		
		# delete player with sword
		player_with_bow.visible = false
	


func _on_timer_timeout() -> void:
	is_dash_ready = true
