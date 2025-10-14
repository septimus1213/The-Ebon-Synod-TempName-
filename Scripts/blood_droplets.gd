extends Node2D

var speed = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.y = -110
	speed = randi_range(5, 100)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y += speed * delta
	if global_position.y > 320:
		queue_free()
