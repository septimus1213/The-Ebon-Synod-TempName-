extends CharacterBody2D

enum BossState {
	IDLE,
	ROAR,      
	SLAM,      
	FEAST,     
	STUNNED    
}

# Export each texture separately (Godot's type system is picky, deal with it)
@export var sprite_idle: Texture2D
@export var sprite_roar: Texture2D
@export var sprite_slam: Texture2D
@export var sprite_feast: Texture2D
@export var sprite_stunned: Texture2D

var current_state = BossState.IDLE
var state_timer = 0.0
var attack_cooldown = 3.0

@export var red_enemy_scene: PackedScene
@export var green_enemy_scene: PackedScene
@export var blue_enemy_scene: PackedScene

var corpses_in_arena = []

@onready var sprite = $Sprite2D

func _ready():
	change_state(BossState.IDLE)

func _physics_process(delta):
	state_timer -= delta
	
	match current_state:
		BossState.IDLE:
			handle_idle()
		BossState.ROAR:
			handle_roar()
		BossState.SLAM:
			handle_slam()
		BossState.FEAST:
			handle_feast()  
		BossState.STUNNED:
			handle_stunned()

func handle_idle():
	if state_timer <= 0:
		var attacks = [BossState.ROAR, BossState.SLAM, BossState.FEAST]
		var next_attack = attacks[randi() % attacks.size()]
		change_state(next_attack)

func handle_roar():
	if state_timer <= 0:
		summon_enemies()
		change_state(BossState.IDLE)

func handle_slam():
	if state_timer <= 0:
		print("SLAM! (imagine rocks falling here)")
		change_state(BossState.IDLE)

func handle_feast():
	if state_timer <= 0:
		print("NOM NOM (not implemented)")
		change_state(BossState.IDLE)

func handle_stunned():
	if state_timer <= 0:
		change_state(BossState.IDLE)

func change_state(new_state):
	current_state = new_state
	
	# Update sprite (now using the exported textures like Godot wants)
	match new_state:
		BossState.IDLE:
			sprite.texture = sprite_idle
			state_timer = attack_cooldown
		BossState.ROAR:
			sprite.texture = sprite_roar
			state_timer = 2.0
		BossState.SLAM:
			sprite.texture = sprite_slam
			state_timer = 1.5
		BossState.FEAST:
			sprite.texture = sprite_feast
			state_timer = 2.0
		BossState.STUNNED:
			sprite.texture = sprite_stunned
			state_timer = 3.0

func summon_enemies():
	var colors = ["red", "green", "blue"]
	var num_enemies = randi() % 3 + 1
	
	for i in range(num_enemies):
		var color = colors[randi() % colors.size()]
		var enemy = null
		
		if color == "red" and red_enemy_scene != null:
			enemy = red_enemy_scene.instantiate()
		elif color == "green" and green_enemy_scene != null:
			enemy = green_enemy_scene.instantiate()
		elif color == "blue" and blue_enemy_scene != null:
			enemy = blue_enemy_scene.instantiate()
		else:
			print("Spawning " + color + " enemy (not implemented yet)")
			continue
		
		if enemy:
			get_parent().add_child(enemy)
			var spawn_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 128
			enemy.global_position = global_position + spawn_offset
			print("Spawned ", color, " enemy!")

# ===== PLACEHOLDER FUNCTIONS FOR LATER =====

# func take_damage(amount):
# 	# TODO: when we have health system
# 	pass

# func die():
# 	# TODO: death animation? just disappear? delete later
# 	queue_free()
