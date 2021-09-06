extends Node2D

enum Players {NOONE=0, PLAYER1=1, PLAYER2=2}

var winner = 0
var board1 = find_node("board1")
var board2 = find_node("board2")

export var pos = 100

class_name board_class

# Called when the node enters the scene tree for the first time.
func _ready():
	board1 = find_node("board1")
	board2 = find_node("board2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	checkForWinner()
	update()
	
	#reset game
	if(winner!=Players.NOONE) and Input.is_action_just_pressed("ui_accept"):
		winner = Players.NOONE
		
		var label = find_node("VictoryText")
		label.text = ""
	
		board1.find_node("health").value = 0
		board2.find_node("health").value = 0
		
		get_tree().reload_current_scene()


func checkForWinner():
	var health = board1.find_node("health").value
	var label = find_node("VictoryText")
	if(health==100):
		winner=Players.PLAYER1
		label.bbcode_text = "[center]Player 1 wins!\nPress <enter> to restart.[/center]"
	health = board2.find_node("health").value
	if(health==100):
		winner=Players.PLAYER2
		label.bbcode_text = "[center]Player 2 wins!\nPress <enter> to restart.[/center]"


func affectOther(var id):
	if id==board1.get_instance_id():
		board2.add_points(-20)
	else:
		board1.add_points(-20)
