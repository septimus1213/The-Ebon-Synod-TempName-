extends CharacterBody2D

enum BossState {
	IDLE,
	ROAR,      
	SLAM,      
	FEAST,     
	STUNNED    
}

# Textures
@export var sprite_idle: Texture2D
@export var sprite_roar: Texture2D
@export var sprite_slam: Texture2D
@export var sprite_feast: Texture2D
@export var sprite_stunned: Texture2D

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
var slam_spike_positions = [] 

# State
var current_state = BossState.IDLE
var state_timer = 0.0
var attack_cooldown = 3.0

# Feast tracking
var feast_started = false
var danger_tiles = []

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
		show_slam_danger_tiles()
	
	# Spikes hit at warning time
	if state_timer <= (1.5 - slam_warning_time) and slam_spike_positions.size() > 0:
		spawn_slam_spikes()
		hide_danger_tiles()  # reuse from feast
		slam_spike_positions.clear()
	
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
			# heal_boss(50)  # TODO: when boss has HP
			entity.queue_free()

func is_in_danger_zone(pos: Vector2) -> bool:
	var distance = global_position.distance_to(pos)
	var boss_radius = 64  # half of boss size
	var danger_radius = boss_radius + (2 * tile_size)  # 2 tile layers
	
	return distance <= danger_radius and distance >= boss_radius

# ===== ENEMY SPAWNING =====

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
	current_state = new_state
	
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
			state_timer = 4.0
		BossState.STUNNED:
			sprite.texture = sprite_stunned
			state_timer = 3.0

# ===== HEALTH (for later) =====

# func take_damage(amount):
# 	print("Boss took ", amount, " damage!")
# 	# TODO: subtract from boss health
# 	# TODO: die when health reaches 0

# func heal(amount):
# 	print("Boss healed ", amount, " HP!")
# 	# TODO: add to boss health (capped at max)
