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

var slam_started = false
var slam_spikes_spawned = false
var slam_spike_positions = []
var camera: Camera2D
var shake_timer = 0.0
var shake_intensity = 0.0
var camera_original_offset = Vector2.ZERO

# State
var current_state = BossState.IDLE
var state_timer = 0.0
var attack_cooldown = 2.0

# Feast tracking
var feast_started = false
var danger_tiles = []

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
		var shake_amount = shake_intensity * (shake_timer / 0.3)  # decay
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
	# Show danger tiles at start
	if not slam_started:
		slam_started = true
		slam_spikes_spawned = false  # Reset spike flag
		show_slam_danger_tiles()
	
	# Spikes hit near end of animation (one frame before last)
	if not slam_spikes_spawned and state_timer <= slam_warning_time:
		spawn_slam_spikes()
		hide_danger_tiles()
		slam_spike_positions.clear()
		slam_spikes_spawned = true  # Prevent retriggering
	
	# End slam
	if state_timer <= 0:
		slam_started = false
		change_state(BossState.IDLE)

func show_slam_danger_tiles():
	hide_danger_tiles()  # clear any old tiles
	
	# Spawn random danger tiles around the arena
	for i in range(slam_spike_count):
		# Random position in arena (adjust range to fit your arena size)
		var random_offset = Vector2(
			randf_range(-400, 400),
			randf_range(-300, 300)
		)
		
		var tile_pos = global_position + random_offset
		slam_spike_positions.append(tile_pos)  # remember for later
		
		# Show warning tile
		var tile = Sprite2D.new()
		tile.texture = danger_tile_texture  # reuse red tile
		tile.modulate = Color(1, 0.5, 0, 0.6)  # orange warning
		tile.global_position = tile_pos
		
		get_parent().add_child(tile)
		danger_tiles.append(tile)

func spawn_slam_spikes():
	for spike_pos in slam_spike_positions:
		# Check if player is at this spike location
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance = player.global_position.distance_to(spike_pos)
			if distance <= tile_size:  # hit radius
				print("SPIKE HIT PLAYER!")
				if player.has_method("take_damage"):
					player.take_damage(slam_damage)
		
		# Spawn visual spike
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
	
	# Use a timer to delete it
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	spike.add_child(timer)
	timer.timeout.connect(func(): spike.queue_free())
	timer.start()

func handle_feast():
	if not feast_started:
		feast_started = true
		show_danger_tiles()
	
	# Eat everything at halfway point
	if state_timer <= 1.0 and danger_tiles.size() > 0:
		consume_entities()
		hide_danger_tiles()
	
	# End feast
	if state_timer <= 0:
		feast_started = false
		print("Feast complete!")
		change_state(BossState.IDLE)

func handle_stunned():
	if state_timer <= 0:
		change_state(BossState.IDLE)

# ===== FEAST MECHANICS =====

func show_danger_tiles():
	hide_danger_tiles()  # clear old tiles first
	
	var boss_half_size = 64  # boss is 128x128, so radius is 64
	
	# Create 2 layers of danger tiles around boss
	for layer in range(1, 3):  # layer 1 and 2
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

func consume_entities():
	# Check player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_in_danger_zone(player.global_position):
		print("PLAYER GOT EATEN! Massive damage!")
		if player.has_method("take_damage"):
			player.take_damage(100)
	
	# Check enemies - just heal if you eat any
	var entities = get_tree().get_nodes_in_group("edible")
	for entity in entities:
		if is_in_danger_zone(entity.global_position):
			print("ATE ENEMY - BOSS HEALS!")
			heal(100)
			entity.queue_free()

func is_in_danger_zone(pos: Vector2) -> bool:
	var distance = global_position.distance_to(pos)
	var boss_radius = 64  # half of boss size
	var danger_radius = boss_radius + (2 * tile_size)  # 2 tile layers
	
	return distance <= danger_radius and distance >= boss_radius

# ===== ENEMY SPAWNING =====

func summon_enemies():
	var colors = ["red", "green", "blue"]
	var num_enemies = randi_range(3,6)
	
	
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
			
			# Add to edible group so feast can find them
			enemy.add_to_group("edible")
			
			# Store color on enemy
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
	if not animated_sprite:
		return
	
	# Check if animation exists
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		animated_sprite.set_frame_and_progress(0, 0.0)  # Start from beginning
	else:
		# Fallback to idle if animation missing
		if animated_sprite.sprite_frames.has_animation("idle"):
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
	
	# Brief invulnerability to prevent multi-hit from one sword swing
	is_invulnerable = true
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): is_invulnerable = false)
	
	# Flash red
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		var flash_timer = get_tree().create_timer(0.1)
		flash_timer.timeout.connect(func(): animated_sprite.modulate = Color.WHITE)
	
	if current_health <= 0:
		die()

func die():
	print("BOSS DEFEATED!")
	# TODO: Victory screen, next boss, whatever
	queue_free()

func heal(amount):
	current_health += amount
	current_health = min(current_health, max_health)
	print("Boss healed ", amount, " HP! Now at: ", current_health, "/", max_health)
