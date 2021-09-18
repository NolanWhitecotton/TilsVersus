extends Node

class_name cookie

var color
enum Colors {BLUE, PURPLE, RED, WHITE, GOLD}
var sprites = [
	preload("res://Objects/Cookie/blue.png"),
	preload("res://Objects/Cookie/purple.png"),
	preload("res://Objects/Cookie/red.png"),
	preload("res://Objects/Cookie/white.png"),
	preload("res://Objects/Cookie/gold.png")
	]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _draw():
	pass

func set_color(new_color):
	color = new_color
	get_node("cookie").texture = sprites[color]

func get_color():
	return color
