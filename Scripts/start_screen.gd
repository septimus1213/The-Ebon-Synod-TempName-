extends Node2D

@onready var menubutton: MenuButton = $MenuButton



func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://root.tscn")


func _on_menu_button_focus_entered() -> void:
	menubutton.add_theme_font_size_override("font_size", 28)
