extends CharacterBody2D

enum BossState {
	IDLE,
	ROAR,      
	SLAM,      
	FEAST,     
	STUNNED    
}
@export var animated_sprite: AnimatedSprite2D

@export var max_health = 10000
var current_health = 10000
var is_invulnerable = false
var health_bar_height = 20

# Enemies
@export var red_enemy_scene: PackedScene
@export var green_enemy_scene: PackedScene
@export var blue_enemy_scene: PackedScene

# Feast system
@export var danger_tile_texture: Texture2D  
@export var tile_size = 32 
@export var spike_texture: Texture2D

@export var slam_warning_time = 1.0  
@export var slam_spike_count = 12  
@export var slam_damage = 30
@export var feast_spike_damage = 50  # Damage for feast spikes

var slam_started = false
var slam_spikes_spawned = false
var slam_spike_positions = []

var feast_started = false
var feast_spikes_spawned = false
var danger_tiles = []

var camera: Camera2D
var shake_timer = 0.0
var shake_intensity = 0.0
var camera_original_offset = Vector2.ZERO

# State
var current_state = BossState.IDLE
var state_timer = 0.0
var attack_cooldown = 2.0

@onready var sprite = $Sprite2D

func _ready():
	add_to_group("boss")
	current_health = max_health
	camera = get_viewport().get_camera_2d()
	if camera:
		camera_original_offset = camera.offset
	change_state(BossState.IDLE)

func _physics_process(delta):
	state_timer -= delta
	
	if shake_timer > 0:
		shake_timer -= delta
		var shake_amount = shake_intensity * (shake_timer / 0.3)
		if camera:
			camera.offset = camera_original_offset + Vector2(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount)
			)
	elif camera:
		camera.offset = camera_original_offset
	
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
	
	queue_redraw() 

# ===== STATE HANDLERS =====

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
	if not slam_started:
		slam_started = true
		slam_spikes_spawned = false
		show_slam_danger_tiles()
	
	if not slam_spikes_spawned and state_timer <= slam_warning_time:
		spawn_slam_spikes()
		hide_danger_tiles()
		slam_spike_positions.clear()
		slam_spikes_spawned = true
	
	if state_timer <= 0:
		slam_started = false
		change_state(BossState.IDLE)

func show_slam_danger_tiles():
	hide_danger_tiles()
	
	for i in range(slam_spike_count):
		var random_offset = Vector2(
			randf_range(-400, 400),
			randf_range(-300, 300)
		)
		
		var tile_pos = global_position + random_offset
		slam_spike_positions.append(tile_pos)
		
		var tile = Sprite2D.new()
		tile.texture = danger_tile_texture
		tile.modulate = Color(1, 0.5, 0, 0.6)  # orange warning
		tile.global_position = tile_pos
		
		get_parent().add_child(tile)
		danger_tiles.append(tile)

func spawn_slam_spikes():
	for spike_pos in slam_spike_positions:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance = player.global_position.distance_to(spike_pos)
			if distance <= tile_size:
				print("SPIKE HIT PLAYER!")
				if player.has_method("take_damage"):
					player.take_damage(slam_damage)
		
		create_spike_visual(spike_pos)
	apply_screen_shake(0.3, 15.0)

func apply_screen_shake(duration: float, intensity: float):
	shake_timer = duration
	shake_intensity = intensity

func create_spike_visual(pos: Vector2):
	var spike = Sprite2D.new()
	spike.texture = spike_texture
	spike.global_position = pos
	get_parent().add_child(spike)
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	spike.add_child(timer)
	timer.timeout.connect(func(): spike.queue_free())
	timer.start()

func handle_feast():
	if not feast_started:
		feast_started = true
		feast_spikes_spawned = false
		show_danger_tiles()
	
	# Spawn spikes at end instead of consuming
	if not feast_spikes_spawned and state_timer <= 1.0:
		spawn_feast_spikes()
		hide_danger_tiles()
		feast_spikes_spawned = true
	
	if state_timer <= 0:
		feast_started = false
		print("Feast complete!")
		change_state(BossState.IDLE)

func spawn_feast_spikes():
	# Spawn spikes at all danger tile positions
	var boss_half_size = 64
	var spike_positions = []
	
	# Collect all danger tile positions
	for layer in range(1, 3):
		var distance = boss_half_size + (layer * tile_size)
		var tiles_per_side = int(distance * 2 / tile_size)
		
		# Top row
		for x in range(-tiles_per_side, tiles_per_side + 1):
			spike_positions.append(global_position + Vector2(x * tile_size, -distance))
		
		# Bottom row
		for x in range(-tiles_per_side, tiles_per_side + 1):
			spike_positions.append(global_position + Vector2(x * tile_size, distance))
		
		# Left column (skip corners)
		for y in range(-tiles_per_side + 1, tiles_per_side):
			spike_positions.append(global_position + Vector2(-distance, y * tile_size))
		
		# Right column (skip corners)
		for y in range(-tiles_per_side + 1, tiles_per_side):
			spike_positions.append(global_position + Vector2(distance, y * tile_size))
	
	# Check player hit and spawn visuals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		for spike_pos in spike_positions:
			var distance = player.global_position.distance_to(spike_pos)
			if distance <= tile_size:
				print("FEAST SPIKE HIT PLAYER!")
				if player.has_method("take_damage"):
					player.take_damage(feast_spike_damage)
				break  # Only hit once
	
	# Spawn spike visuals at all positions
	for spike_pos in spike_positions:
		create_spike_visual(spike_pos)
	
	apply_screen_shake(0.4, 20.0)

func handle_stunned():
	if state_timer <= 0:
		change_state(BossState.IDLE)

# ===== FEAST MECHANICS =====

func show_danger_tiles():
	hide_danger_tiles()
	
	var boss_half_size = 64
	
	for layer in range(1, 3):
		var distance = boss_half_size + (layer * tile_size)
		var tiles_per_side = int(distance * 2 / tile_size)
		
		# Top row
		for x in range(-tiles_per_side, tiles_per_side + 1):
			spawn_danger_tile(Vector2(x * tile_size, -distance))
		
		# Bottom row
		for x in range(-tiles_per_side, tiles_per_side + 1):
			spawn_danger_tile(Vector2(x * tile_size, distance))
		
		# Left column (skip corners)
		for y in range(-tiles_per_side + 1, tiles_per_side):
			spawn_danger_tile(Vector2(-distance, y * tile_size))
		
		# Right column (skip corners)
		for y in range(-tiles_per_side + 1, tiles_per_side):
			spawn_danger_tile(Vector2(distance, y * tile_size))

func spawn_danger_tile(offset: Vector2):
	var tile = Sprite2D.new()
	tile.texture = danger_tile_texture
	tile.global_position = global_position + offset
	
	get_parent().add_child(tile)
	danger_tiles.append(tile)

func hide_danger_tiles():
	for tile in danger_tiles:
		tile.queue_free()
	danger_tiles.clear()

# ===== ENEMY SPAWNING =====

func summon_enemies():
	var colors = ["red", "green", "blue"]
	var num_enemies = randi_range(3, 6)
	
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
			continue
		
		if enemy:
			get_parent().add_child(enemy)
			var spawn_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 128
			enemy.global_position = global_position + spawn_offset
			
			enemy.add_to_group("edible")
			
			if enemy.has_method("set_color"):
				enemy.set_color(color)
			
			print("Spawned ", color, " enemy!")

# ===== STATE MANAGEMENT =====

func change_state(new_state):
	slam_started = false
	feast_started = false
	current_state = new_state
	
	match new_state:
		BossState.IDLE:
			play_animation("idle")
			state_timer = attack_cooldown
		BossState.ROAR:
			play_animation("roar")
			state_timer = get_animation_length("roar")
		BossState.SLAM:
			play_animation("slam")
			state_timer = get_animation_length("slam") + slam_warning_time
		BossState.FEAST:
			play_animation("feast")
			state_timer = get_animation_length("feast")
		BossState.STUNNED:
			play_animation("stunned")
			state_timer = get_animation_length("stunned")

func play_animation(anim_name: String):
	print("Trying to play animation: ", anim_name)
	
	if not animated_sprite:
		print("ERROR: animated_sprite is null!")
		return
	
	print("animated_sprite exists")
	print("Available animations: ", animated_sprite.sprite_frames.get_animation_names())
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		print("Animation '", anim_name, "' found, playing...")
		animated_sprite.play(anim_name)
		animated_sprite.set_frame_and_progress(0, 0.0)
	else:
		print("Animation '", anim_name, "' NOT FOUND!")
		if animated_sprite.sprite_frames.has_animation("idle"):
			print("Falling back to idle")
			animated_sprite.play("idle")

func get_animation_length(anim_name: String) -> float:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 2.0
	
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return 2.0 
	
	var frames = animated_sprite.sprite_frames.get_frame_count(anim_name)
	var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
	
	if fps <= 0:
		return 2.0 
	
	return frames / fps

func take_damage(amount):
	if is_invulnerable:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	print("Boss took ", amount, " damage! HP: ", current_health, "/", max_health)
	
	is_invulnerable = true
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): is_invulnerable = false)
	
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		var flash_timer = get_tree().create_timer(0.1)
		flash_timer.timeout.connect(func(): animated_sprite.modulate = Color.WHITE)
	
	if current_health <= 0:
		die()

func die():
	print("BOSS DEFEATED!")
	play_animation("death")
	# Wait for death animation to finish before cleanup
	var death_length = get_animation_length("death")
	var timer = get_tree().create_timer(death_length)
	timer.timeout.connect(func(): 
		queue_free()
		get_tree().change_scene_to_file("res://Scenes/start_screen.tscn")
	)

func heal(amount):
	current_health += amount
	current_health = min(current_health, max_health)
	print("Boss healed ", amount, " HP! Now at: ", current_health, "/", max_health)
