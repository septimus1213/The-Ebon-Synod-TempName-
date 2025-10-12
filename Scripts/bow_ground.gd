extends Area2D
@onready var label: Label = $Label
@onready var player_with_bow: CharacterBody2D = $"../PlayerWithBow"
@onready var player: CharacterBody2D = $"../Player"
@onready var bow_ground: Area2D = $"."



func _process(delta: float) -> void:
	var pickup = Input.is_action_just_pressed("Pickup_Item")
	if pickup and label.visible == true:
		player_with_bow.position = player.position
		player_with_bow.visible = true
		player.visible = false
		bow_ground.visible = false

func _on_body_entered(body: Node2D) -> void:
	label.visible = true


func _on_body_exited(body: Node2D) -> void:
	label.visible = false
