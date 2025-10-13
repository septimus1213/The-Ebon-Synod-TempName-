extends Node2D

@onready var player: CharacterBody2D = $"../Player"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = player.global_position
