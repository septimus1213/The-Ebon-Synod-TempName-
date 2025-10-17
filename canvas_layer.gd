extends Control

var boss: CharacterBody2D

func _ready():
	boss = get_tree().get_first_node_in_group("boss")

func _process(delta):
	if not boss:
		boss = get_tree().get_first_node_in_group("boss")
	queue_redraw()

func _draw():
	# Check boss exists AND has valid health before accessing it
	if not boss or not is_instance_valid(boss):
		return
	
	if boss.current_health <= 0:
		return
	
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	
	var bar_width = screen_width - 20
	var bar_height = 25
	var bar_x = 10
	var bar_y = screen_height - 50
	
	# Background (black)
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color.BLACK, true)
	
	# Health fill (deep red)
	var health_percent = float(boss.current_health) / float(boss.max_health)
	var fill_width = bar_width * health_percent
	draw_rect(Rect2(bar_x, bar_y, fill_width, bar_height), Color(0.6, 0, 0), true)
	
	# Border (brown)
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color.BROWN, false, 3)
