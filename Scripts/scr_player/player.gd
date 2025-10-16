extends CharacterBody2D

var debug_draw_hitbox = true  # set to false to hide
var hitbox_active = false

# Movement
@export var speed = 300.0
@export var dash_speed = 1000.0
@export var dash_duration = 0.2
@export var dash_cooldown = 5.0

# Combat
@export var sword_damage = 25
var sword_attack_angle = 0.0
@export var sword_ground_scene: PackedScene
@export var bow_ground_scene: PackedScene
@export var sword_knockback_force = 200.0

# Health
@export var max_health = 300
var current_health = 300

# Weapon system
enum Weapon { NONE, SWORD, BOW }
var current_weapon = Weapon.NONE
var can_shoot_bow = true
@export var bow_cooldown = 1

# Dash
var is_dash_ready = true
var is_dashing = false
var dash_timer_active = 0.0
var dash_direction = Vector2.ZERO

# Last animation played for idle
var last_walk_animation = "WalkDown"
var walk_sound_timer = 0.0
var walk_sound_interval = 0.2

# Projectile (for bow)
@export var arrow_scene: PackedScene
@export var projectile_speed = 600

# Node references
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dash_cooldown_timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $Walking
@onready var weapon_sprite: Sprite2D = $WeaponSprite  
@onready var health_bar: AnimatedSprite2D = $"../playerfollow/HealthBar"
@onready var sword_hitbox: Area2D = $SwordHitbox 
@onready var weaponicons: AnimatedSprite2D = $"../playerfollow/WeaponIcons/AnimatedSprite2D"
@onready var Healthbar: AnimatedSprite2D = $"../playerfollow/HealthBar"
@onready var attack_sprites: AnimatedSprite2D = $attack_sprites
@onready  var BowCoolddown: Timer = $BowCooldown
@onready var hurt: AnimatedSprite2D = $hurt
@onready var BowAttackSound: AudioStreamPlayer2D = $Sounds/BowAttack
@onready var SwordAttackSound: AudioStreamPlayer2D = $Sounds/SwordAttack
@onready var crossbow: AnimatedSprite2D = $CrossBowHolder/CrossBow
@onready var hurtsound: AudioStreamPlayer2D = $Sounds/Hurt
@onready var diesound: AudioStreamPlayer2D = $Sounds/Die
@onready var dashsound: AudioStreamPlayer2D = $Sounds/Dash
@onready var walkingsound: AudioStreamPlayer2D = $Sounds/walking


func _ready():
	current_health = max_health  
	dash_cooldown_timer.wait_time = dash_cooldown
	update_weapon_visuals()
	
	# ADD THIS SECTION - Connect sword hitbox
	if sword_hitbox:
		sword_hitbox.body_entered.connect(_on_sword_hit)
		sword_hitbox.monitoring = false
	
	BowCoolddown.wait_time = bow_cooldown

func _physics_process(delta):
	if is_dashing:
		handle_dash_movement(delta)
	else:
		handle_movement(delta)
	
	move_and_slide()

func _process(delta):
	handle_weapon_rotation()
	handle_attack()
	handle_drop_weapon()


func _draw():
	# ONLY draw if debug is on AND hitbox is currently active
	if not debug_draw_hitbox or not hitbox_active or not sword_hitbox:
		return
	
	var shape_node = sword_hitbox.get_node("CollisionShape2D")
	if not shape_node or not shape_node.shape:
		return
	
	var shape = shape_node.shape
	var shape_pos = sword_hitbox.position + shape_node.position
	
	if shape is RectangleShape2D:
		var rect_size = shape.size
		var center = shape_pos
		var half_size = rect_size / 2
		
		var angle = sword_hitbox.rotation
		var corners = [
			center + Vector2(-half_size.x, -half_size.y).rotated(angle),
			center + Vector2(half_size.x, -half_size.y).rotated(angle),
			center + Vector2(half_size.x, half_size.y).rotated(angle),
			center + Vector2(-half_size.x, half_size.y).rotated(angle)
		]
		
		# var color = Color.RED 
		# for i in range(4):
			# draw_line(corners[i], corners[(i+1) % 4], color, 2)

# ===== MOVEMENT =====
func handle_movement(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	
	if Input.is_action_just_pressed("dash") and is_dash_ready and direction != Vector2.ZERO:
		start_dash(direction)
		return
	
	if direction != Vector2.ZERO:
		if not walkingsound.playing:
			walk_sound_timer -= delta
			if walk_sound_timer <= 0:
				walkingsound.play()
				walk_sound_timer = walk_sound_interval
		if abs(direction.x) > abs(direction.y):
			if direction.x < 0:
				animated_sprite.play("WalkLeft")
				last_walk_animation = "WalkLeft"
			else:
				animated_sprite.play("WalkRight")
				last_walk_animation = "WalkRight"
		else:
			if direction.y < 0:
				animated_sprite.play("WalkUp")
				last_walk_animation = "WalkUp"
			else:
				animated_sprite.play("WalkDown")
				last_walk_animation = "WalkDown"
				
	else:
		if walkingsound.playing:
			walkingsound.stop()
			walk_sound_timer = 0
		animated_sprite.play(last_walk_animation)
		animated_sprite.stop()

		
		
func start_dash(direction: Vector2):
	is_dashing = true
	is_dash_ready = false
	dash_direction = direction.normalized()
	dash_timer_active = dash_duration
	dashsound.play()
	
func handle_dash_movement(delta):
	dash_timer_active -= delta
	
	if dash_timer_active <= 0:
		is_dashing = false
		dash_cooldown_timer.start()
		velocity = Vector2.ZERO
	else:
		velocity = dash_direction * dash_speed

# ===== WEAPON SYSTEM =====
func pickup_weapon(weapon_type: Weapon):
	current_weapon = weapon_type
	update_weapon_visuals()

func drop_weapon() -> Weapon:
	var dropped = current_weapon
	current_weapon = Weapon.NONE
	update_weapon_visuals()
	weaponicons.play("none")
	return dropped

func handle_drop_weapon():
	if Input.is_action_just_pressed("Drop_Item") and current_weapon != Weapon.NONE:
		print("Dropping weapon: ", current_weapon)  # ADD DEBUG
		var dropped_weapon = drop_weapon()
		spawn_weapon_on_ground(dropped_weapon, global_position)

func update_weapon_visuals():
	match current_weapon:
		Weapon.NONE:
			weapon_sprite.visible = false
			crossbow.visible = false
		Weapon.SWORD:
			weapon_sprite.visible = true
			# weapon_sprite.texture = load("res://path/to/sword_sprite.png")
		Weapon.BOW:
			crossbow.visible = true

func handle_weapon_rotation():
	if current_weapon == Weapon.NONE:
		return
	
	var mouse_pos = get_global_mouse_position()
	var angle = (mouse_pos - global_position).angle()
	weapon_sprite.rotation = angle

# ===== ATTACK =====
func handle_attack():
	if not Input.is_action_just_pressed("Attack"):
		return
	
	
	
	match current_weapon:
		Weapon.SWORD:
			attack_sword()
			queue_redraw()
		Weapon.BOW:
			attack_bow()

func attack_sword():
	if not sword_hitbox:
		print("NO SWORD HITBOX!")
		return
	
	SwordAttackSound.play()
		
	# Get attack direction
	var mouse_pos = get_global_mouse_position()
	var angle = (mouse_pos - global_position).angle()
	sword_attack_angle = angle
	var angleindeg = rad_to_deg(sword_attack_angle)
	
	if angleindeg > -45 and angleindeg <= 45:
		attack_sprites.visible = true
		animated_sprite.visible = false
		attack_sprites.play("attack_right")
	elif angleindeg > 45 and angleindeg <= 135:
		attack_sprites.visible = true
		animated_sprite.visible = false
		attack_sprites.play("attack_down")
	elif angleindeg > 135 or angleindeg <= -135:
		attack_sprites.visible = true
		animated_sprite.visible = false
		attack_sprites.play("attack_left")
	elif angleindeg > -135 and angleindeg <= -45:
		attack_sprites.visible = true
		animated_sprite.visible = false
		attack_sprites.play("attack_up")
	
	# Position hitbox in front of player in attack direction
	var hitbox_distance = 20  # how far from player center
	var offset = Vector2(cos(angle), sin(angle)) * hitbox_distance
	sword_hitbox.position = offset
	sword_hitbox.rotation = angle
	
	# Enable hitbox briefly
	sword_hitbox.monitoring = true
	hitbox_active = true
	queue_redraw()
	
	# Disable after short time
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func(): 
		if sword_hitbox:
			sword_hitbox.monitoring = false
			hitbox_active = false
			queue_redraw()
	)


func _on_sword_hit(body):
	if (body.is_in_group("edible") or body.is_in_group("boss") ) and body.has_method("take_damage"):
		print("SWORD HIT: ", body.name)
		body.take_damage(sword_damage)
		
		# Knockback (not for boss)
		if not body.is_in_group("boss"):
			var knockback_dir = (body.global_position - global_position).normalized()
			if body.has_method("apply_knockback"):
				body.apply_knockback(knockback_dir, sword_knockback_force)

func attack_bow():
	if arrow_scene == null:
		print("ERROR: Arrow scene not assigned!")
		return
	if can_shoot_bow == false:
		return
	BowAttackSound.play()
	var arrow_instance = arrow_scene.instantiate()
	get_parent().add_child(arrow_instance)
	
	var mouse_pos = get_global_mouse_position()
	var angle = (mouse_pos - global_position).angle()
	
	arrow_instance.global_position = global_position
	arrow_instance.rotation = angle
	if arrow_instance.has_method("set_direction"):
		arrow_instance.set_direction(Vector2(cos(angle), sin(angle)))
		arrow_instance.global_position = crossbow.global_position 
	can_shoot_bow = false
	
	BowCoolddown.start()
	

# ===== HEALTH =====
func take_damage(amount):
	current_health -= amount
	current_health = max(0, current_health)
	
	print("PLAYER took ", amount, " damage! HP: ", current_health, "/", max_health)  # ADD THIS
	
	update_health_bar()
	
	if current_health == 0:
		die()
		Healthbar.play("dead")
	elif current_health <= 100:
		Healthbar.play("1 heart")
	elif current_health > 100 and current_health <= 200:
		Healthbar.play("2 hearts")
	elif current_health > 200 and current_health <= 300:
		Healthbar.play("default")
	else:
		print("player has to much hp")
	
	hurt.visible = true
	animated_sprite.visible = false
	hurt.play("hurt")
	hurtsound.play()
	
	
	

func update_health_bar():
	if current_health <= 200 and current_health > 100:
		health_bar.play("2 hearts")
	elif current_health <= 100 and current_health > 0:
		health_bar.play("1 heart")
	elif current_health == 0:
		health_bar.play("dead")

func die():
	diesound.play()
	print("PLAYER DIED - GAME OVER!")
	get_tree().change_scene_to_file("res://Scenes/retry_screen.tscn")

# ===== UTILITY =====
func spawn_weapon_on_ground(weapon_type: Weapon, position: Vector2):
	var weapon_pickup = null
	
	match weapon_type:
		Weapon.SWORD:
			if sword_ground_scene:
				weapon_pickup = sword_ground_scene.instantiate()
			else:
				print("ERROR: Sword ground scene not assigned!")
		Weapon.BOW:
			if bow_ground_scene:
				weapon_pickup = bow_ground_scene.instantiate()
			else:
				print("ERROR: Bow ground scene not assigned!")
	
	if weapon_pickup:
		get_parent().add_child(weapon_pickup)
		weapon_pickup.global_position = position
		print("Spawned weapon pickup at: ", position)

func _on_timer_timeout():
	is_dash_ready = true


func _on_attack_sprites_animation_finished() -> void:
	attack_sprites.visible = false
	animated_sprite.visible = true
	

func _on_bow_cooldown_timeout() -> void:
	can_shoot_bow = true


func _on_hurt_animation_finished() -> void:
	hurt.visible = false
	animated_sprite.visible = true
