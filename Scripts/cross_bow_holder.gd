extends Node2D
@onready var player: CharacterBody2D = $".."
@onready var crossbow: AnimatedSprite2D = $CrossBow

var radius = null

func _ready() -> void:
	radius = ((crossbow.global_position.y - player.global_position.y)**2+ (crossbow.global_position.x - player.global_position.x)**2)**0.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse = get_global_mouse_position()
	
	var rad = atan2(mouse.y - player.position.y, mouse.x - player.position.x)
	
	crossbow.global_rotation = rad
	
	crossbow.global_position = Vector2(
		player.global_position.x + cos(rad) * radius,
		player.global_position.y + sin(rad) * radius
	)
