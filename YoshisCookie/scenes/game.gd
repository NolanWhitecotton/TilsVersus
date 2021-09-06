extends Node

enum Players {NOONE=0, PLAYER1=1, PLAYER2=2}

var winner = 0
var board1 = find_node("board1")
var board2 = find_node("board2")


# Called when the node enters the scene tree for the first time.
func _ready():
	board1 = find_node("board1")
	board2 = find_node("board2")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	checkForWinner()
	pass


func _draw():
	#todo display the winner somehow
	pass


func checkForWinner():
	var health = board1.find_node("health").value
	if(health==100):
		winner=Players.PLAYER1
	health = board2.find_node("health").value
	if(health==100):
		#winner=Players.PLAYER2
		pass
	

func affectOther(var id):
	if id==board1.get_instance_id():
		board2.add_points(-20)
	else:
		board1.add_points(-20)
