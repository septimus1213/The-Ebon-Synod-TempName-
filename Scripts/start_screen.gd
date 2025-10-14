extends Node2D

@onready var menubutton: MenuButton = $MenuButton

var droplets = preload("res://Scenes/PrefabScenes/blood_droplets.tscn")


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://root.tscn")
	


func _on_menu_button_mouse_entered() -> void:
	menubutton.add_theme_font_size_override("font_size", 28)
	# print("hovering")
	# for i in range(200):
		# var droplets_scene = droplets.instantiate()
		# get_parent().add_child(droplets_scene)
		# droplets_scene.global_position.x = randi_range(-60, 80)


func _on_menu_button_mouse_exited() -> void:
	menubutton.add_theme_font_size_override("font_size", 24)
