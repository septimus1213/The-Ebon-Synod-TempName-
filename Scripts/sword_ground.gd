extends Area2D


@onready var label: Label = $Label
@onready var sword_on_ground: Area2D = $"."
@onready var player: CharacterBody2D = $"../Player"
@onready var player_with_sword: CharacterBody2D = $"../PlayerWithSword"



#  pickup item/sword
func _process(_delta: float) -> void:
	var pickup = Input.is_action_just_pressed("Pickup_Item")
	if pickup and label.visible == true:
		player_with_sword.position = player.position
		player_with_sword.visible = true
		player.visible = false
		sword_on_ground.visible = false
		

# pickup label set to visible
func _on_body_entered(_body: Node2D) -> void:
	label.visible = true


# pickup label set to invisible
func _on_body_exited(_body: Node2D) -> void:
	label.visible = false
