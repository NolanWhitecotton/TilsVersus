extends Node

var board1 = find_node("board1")
var board2 = find_node("board2")


# Called when the node enters the scene tree for the first time.
func _ready():
	board1 = find_node("board1")
	board2 = find_node("board2")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func affectOther(var id):
	if id==board1.get_instance_id():
		board2.add_points(-20)
	else:
		board1.add_points(-20)
