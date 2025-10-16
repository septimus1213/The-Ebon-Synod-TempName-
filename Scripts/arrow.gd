extends Area2D

@export var speed = 600.0
@export var lifetime = 5.0
@export var damage = 200

var direction = Vector2.ZERO

@onready var timer: Timer = $Timer

func _ready():
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.start()
	timer.connect("timeout", Callable(self, "_on_timeout"))
	
	body_entered.connect(_on_body_entered)  # ADD THIS

func _process(delta):
	position += direction * speed * delta

func set_direction(dir: Vector2):
	direction = dir

func _on_body_entered(body):
	print("Arrow hit SOMETHING: ", body.name)
	if (body.is_in_group("edible") or body.is_in_group("boss")) and body.has_method("take_damage"):
		print("ARROW HIT: ", body.name)
		body.take_damage(damage)
		queue_free()

func _on_timeout():
	queue_free()
	
	 
	
	
	
	
	
