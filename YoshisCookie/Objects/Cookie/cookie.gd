extends Node2D

class_name Cookie

var color
enum Colors {BLUE, PURPLE, RED, WHITE, GOLD}
var sprites = [
	preload("res://Objects/Cookie/blue.png"),
	preload("res://Objects/Cookie/purple.png"),
	preload("res://Objects/Cookie/red.png"),
	preload("res://Objects/Cookie/white.png"),
	preload("res://Objects/Cookie/gold.png")
	]

#moving animation stuff
var moving_animation_progress=0
var animation_line_type
var animation_line_direction
var animation_line_position
var animation_wrap_after 

onready var parentBoard = get_parent().get_parent() 


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


func start_move_animation(lineType, lineDirection, linePosition, wrapAfter):
	if(moving_animation_progress == 0):
		# save the motion for the animation
		animation_line_type = lineType
		animation_line_direction = lineDirection
		animation_line_position = linePosition
		animation_wrap_after = wrapAfter
		
		moving_animation_progress=1 #start the animation


# controls the moving animations and moves the cookies
func handle_animation_motion():
	if moving_animation_progress != 0:
		if moving_animation_progress >= 5: # if animation should end
			moving_animation_progress = 0
			if(animation_wrap_after):
				
				var wrapDistance = 64*parentBoard.BOARD_SIZE*animation_line_direction
				if animation_line_type==0:
					position.x -= wrapDistance
				else:
					position.y -= wrapDistance
		else: # if an animation is progress
			moving_animation_progress += 1
			if animation_line_type==parentBoard.LineType.COLUMN:
				position.y+=16 * animation_line_direction 
			else:
				position.x+=16 * animation_line_direction

func _process(delta):
	handle_animation_motion()
	
func is_animating():
	return moving_animation_progress!=0
