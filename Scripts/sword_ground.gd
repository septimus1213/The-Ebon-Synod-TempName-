extends Area2D

@export var weapon_type: int = 1  # 0 = none, 1 = sword, 2 = bow
@onready var label: Label = $Label
@onready var weaponicons: AnimatedSprite2D = $"../playerfollow/WeaponIcons/AnimatedSprite2D"
func _process(delta):
	if Input.is_action_just_pressed("Pickup_Item") and label.visible:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.current_weapon == 0:  # only if no weapon
			player.pickup_weapon(weapon_type)
			weaponicons.play("sword")
			queue_free()  # remove weapon from ground

func _on_body_entered(body):
	if body.is_in_group("player"):
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		label.visible = false
