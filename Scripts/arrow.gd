extends Area2D

@export var speed = 600.0
var direction = Vector2.ZERO
@export var lifetime = 5
@onready var timer: Timer = $Timer

func set_direction(dir: Vector2):
	direction = dir

func _ready():
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.start()
	timer.connect("timeout", Callable(self, "queue_free"))

func _process(delta):
	position += direction * speed * delta
	
	 
	
	
	
	
	
